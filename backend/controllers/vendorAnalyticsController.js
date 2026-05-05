/**
 * vendorAnalyticsController.js
 *
 * Analytics & reporting for authenticated vendors.
 * All queries are strictly scoped to OrderItems.vendorId = req.user.id.
 * No cross-vendor or platform-wide financial data is exposed.
 *
 * Routes (mounted under /api/vendor):
 *   GET /analytics/sales
 *   GET /analytics/performance
 *   GET /analytics/top-products
 */

import { Op, fn, col, literal, QueryTypes } from "sequelize";
import sequelize from "../config/db.js";
import { Order, OrderItem, Product, ProductVariant } from "../models/association.js";
import { success, badRequest, serverError } from "../utils/responseMessages.js";

// ── Helper: resolve timeframe to a start Date ─────────────────────────────────
function resolveTimeframe(timeframe) {
    const now = new Date();
    switch (timeframe) {
        case "today":         return new Date(now.setHours(0, 0, 0, 0));
        case "last_7_days":   return new Date(Date.now() - 7  * 24 * 60 * 60 * 1000);
        case "last_30_days":  return new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        case "last_90_days":  return new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
        case "last_12_months":return new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
        case "this_month": {
            const d = new Date();
            return new Date(d.getFullYear(), d.getMonth(), 1);
        }
        case "this_year": {
            const d = new Date();
            return new Date(d.getFullYear(), 0, 1);
        }
        default: return new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // fallback: 30 days
    }
}

// ── Helper: group-by label for time-series (daily / weekly / monthly) ─────────
function getGroupByExpression(granularity) {
    switch (granularity) {
        case "day":   return `DATE("OrderItem"."createdAt")`;
        case "week":  return `DATE_TRUNC('week', "OrderItem"."createdAt")`;
        case "month": return `DATE_TRUNC('month', "OrderItem"."createdAt")`;
        default:      return `DATE("OrderItem"."createdAt")`;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/analytics/sales
// Revenue and order trends over a time window
//
// Query params:
//   timeframe: 'today' | 'last_7_days' | 'last_30_days' | 'last_90_days' |
//              'last_12_months' | 'this_month' | 'this_year'
//   granularity: 'day' | 'week' | 'month'  (default: 'day')
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorSalesAnalytics = async (req, res) => {
    try {
        const vendorId    = req.user.id;
        const { timeframe = "last_30_days", granularity = "day" } = req.query;

        const allowedGranularity = ["day", "week", "month"];
        if (!allowedGranularity.includes(granularity)) {
            return badRequest(res, `granularity must be one of: ${allowedGranularity.join(", ")}`);
        }

        const startDate = resolveTimeframe(timeframe);
        const groupExpr = getGroupByExpression(granularity);

        // ── Aggregate totals ──────────────────────────────────────────────────
        const [totals] = await sequelize.query(
            `
            SELECT
                COUNT(DISTINCT "OrderItem"."orderId")                          AS "orderCount",
                SUM("OrderItem"."quantity")                                    AS "unitsSold",
                SUM("OrderItem"."priceAtPurchase" * "OrderItem"."quantity")             AS "totalRevenue",
                AVG(o."totalAmount")                                   AS "avgOrderValue",
                SUM(CASE WHEN "OrderItem"."returnStatus" = 'completed' THEN "OrderItem"."refundAmount" ELSE 0 END)
                                                                      AS "totalRefunded"
            FROM "OrderItems" "OrderItem"
            JOIN "Orders"   o  ON o."id" = "OrderItem"."orderId"
            WHERE "OrderItem"."vendorId" = :vendorId
              AND "OrderItem"."createdAt" >= :startDate
              AND o."paymentStatus" IN ('paid', 'refund_initiated', 'refunded')
            `,
            {
                replacements: { vendorId, startDate },
                type: QueryTypes.SELECT,
            }
        );

        // ── Time-series breakdown ─────────────────────────────────────────────
        const timeSeries = await sequelize.query(
            `
            SELECT
                ${groupExpr}                                          AS "period",
                COUNT(DISTINCT "OrderItem"."orderId")                          AS "orderCount",
                SUM("OrderItem"."quantity")                                    AS "unitsSold",
                SUM("OrderItem"."priceAtPurchase" * "OrderItem"."quantity")             AS "revenue"
            FROM "OrderItems" "OrderItem"
            JOIN "Orders"   o  ON o."id" = "OrderItem"."orderId"
            WHERE "OrderItem"."vendorId" = :vendorId
              AND "OrderItem"."createdAt" >= :startDate
              AND o."paymentStatus" IN ('paid', 'refund_initiated', 'refunded')
            GROUP BY ${groupExpr}
            ORDER BY ${groupExpr} ASC
            `,
            {
                replacements: { vendorId, startDate },
                type: QueryTypes.SELECT,
            }
        );

        success(res, {
            timeframe,
            granularity,
            startDate,
            summary: {
                orderCount:    parseInt(totals?.orderCount  || 0),
                unitsSold:     parseInt(totals?.unitsSold   || 0),
                totalRevenue:  parseFloat(totals?.totalRevenue || 0).toFixed(2),
                avgOrderValue: parseFloat(totals?.avgOrderValue || 0).toFixed(2),
                totalRefunded: parseFloat(totals?.totalRefunded || 0).toFixed(2),
            },
            timeSeries,
        }, "Sales analytics fetched successfully");
    } catch (error) {
        console.error("[getVendorSalesAnalytics]", error);
        serverError(res, "Failed to fetch sales analytics");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/analytics/performance
// Operational health: fulfillment time, cancellation rate, return rate
//
// Query params:
//   timeframe: same options as sales
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorPerformanceAnalytics = async (req, res) => {
    try {
        const vendorId  = req.user.id;
        const { timeframe = "last_30_days" } = req.query;
        const startDate = resolveTimeframe(timeframe);

        // ── Fulfillment time: avg hours from order creation to shipped ────────
        const [fulfillmentMetrics] = await sequelize.query(
            `
            SELECT
                COUNT(*)                                                      AS "totalItems",
                COUNT(CASE WHEN "OrderItem"."fulfillmentStatus" = 'shipped'   THEN 1 END) AS "shippedCount",
                COUNT(CASE WHEN "OrderItem"."fulfillmentStatus" = 'delivered' THEN 1 END) AS "deliveredCount",
                COUNT(CASE WHEN "OrderItem"."fulfillmentStatus" = 'cancelled' THEN 1 END) AS "cancelledCount",
                AVG(
                    CASE WHEN "OrderItem"."shippedAt" IS NOT NULL
                    THEN EXTRACT(EPOCH FROM ("OrderItem"."shippedAt" - "OrderItem"."createdAt")) / 3600.0
                    END
                )                                                              AS "avgHoursToShip"
            FROM "OrderItems" "OrderItem"
            JOIN "Orders" o ON o."id" = "OrderItem"."orderId"
            WHERE "OrderItem"."vendorId" = :vendorId
              AND "OrderItem"."createdAt" >= :startDate
            `,
            { replacements: { vendorId, startDate }, type: QueryTypes.SELECT }
        );

        // ── Return / refund rate ──────────────────────────────────────────────
        const [returnMetrics] = await sequelize.query(
            `
            SELECT
                COUNT(*)                                                    AS "totalItems",
                COUNT(CASE WHEN "OrderItem"."returnStatus" != 'none' THEN 1 END)    AS "returnRequests",
                COUNT(CASE WHEN "OrderItem"."returnStatus" = 'completed' THEN 1 END) AS "completedReturns",
                SUM(CASE WHEN "OrderItem"."returnStatus" = 'completed' THEN "OrderItem"."refundAmount" ELSE 0 END)
                                                                            AS "totalRefunded"
            FROM "OrderItems" "OrderItem"
            WHERE "OrderItem"."vendorId" = :vendorId
              AND "OrderItem"."createdAt" >= :startDate
            `,
            { replacements: { vendorId, startDate }, type: QueryTypes.SELECT }
        );

        const totalItems      = parseInt(fulfillmentMetrics?.totalItems || 0);
        const cancelledCount  = parseInt(fulfillmentMetrics?.cancelledCount || 0);
        const returnRequests  = parseInt(returnMetrics?.returnRequests || 0);

        const cancellationRate = totalItems > 0
            ? ((cancelledCount / totalItems) * 100).toFixed(2)
            : "0.00";
        const returnRate = totalItems > 0
            ? ((returnRequests / totalItems) * 100).toFixed(2)
            : "0.00";

        success(res, {
            timeframe,
            startDate,
            fulfillment: {
                totalItems,
                shippedCount:    parseInt(fulfillmentMetrics?.shippedCount   || 0),
                deliveredCount:  parseInt(fulfillmentMetrics?.deliveredCount  || 0),
                cancelledCount,
                avgHoursToShip:  parseFloat(fulfillmentMetrics?.avgHoursToShip || 0).toFixed(1),
                cancellationRate: `${cancellationRate}%`,
            },
            returns: {
                returnRequests,
                completedReturns: parseInt(returnMetrics?.completedReturns || 0),
                totalRefunded:    parseFloat(returnMetrics?.totalRefunded   || 0).toFixed(2),
                returnRate: `${returnRate}%`,
            },
        }, "Performance analytics fetched successfully");
    } catch (error) {
        console.error("[getVendorPerformanceAnalytics]", error);
        serverError(res, "Failed to fetch performance analytics");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/analytics/top-products
// Best-selling SKUs by revenue or volume
//
// Query params:
//   timeframe: same options
//   metric: 'revenue' | 'volume'  (default: 'revenue')
//   limit: number (default: 10, max: 50)
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorTopProducts = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const {
            timeframe = "last_30_days",
            metric    = "revenue",
            limit     = 10,
        } = req.query;

        const allowedMetrics = ["revenue", "volume"];
        if (!allowedMetrics.includes(metric)) {
            return badRequest(res, `metric must be one of: ${allowedMetrics.join(", ")}`);
        }

        const limitNum  = Math.min(50, Math.max(1, parseInt(limit, 10)));
        const startDate = resolveTimeframe(timeframe);

        const orderExpr = metric === "revenue"
            ? `SUM("OrderItem"."priceAtPurchase" * "OrderItem"."quantity") DESC`
            : `SUM("OrderItem"."quantity") DESC`;

        const topProducts = await sequelize.query(
            `
            SELECT
                p."id"                                                  AS "productId",
                p."title"                                               AS "productTitle",
                pv."id"                                                 AS "variantId",
                pv."sku"                                                AS "sku",
                pv."variantName"                                        AS "variantName",
                pv."color"                                              AS "color",
                pv."size"                                               AS "size",
                SUM("OrderItem"."quantity")                                      AS "unitsSold",
                SUM("OrderItem"."priceAtPurchase" * "OrderItem"."quantity")              AS "revenue",
                COUNT(DISTINCT "OrderItem"."orderId")                            AS "orderCount"
            FROM "OrderItems"      "OrderItem"
            JOIN "Orders"          o   ON o."id"  = "OrderItem"."orderId"
            JOIN "Products"        p   ON p."id"  = "OrderItem"."productId"
            JOIN "ProductVariants" pv  ON pv."id" = "OrderItem"."variantId"
            WHERE "OrderItem"."vendorId" = :vendorId
              AND "OrderItem"."createdAt" >= :startDate
              AND o."paymentStatus" IN ('paid', 'refund_initiated', 'refunded')
            GROUP BY p."id", p."title", pv."id", pv."sku", pv."variantName", pv."color", pv."size"
            ORDER BY ${orderExpr}
            LIMIT :limit
            `,
            {
                replacements: { vendorId, startDate, limit: limitNum },
                type: QueryTypes.SELECT,
            }
        );

        success(res, {
            timeframe,
            metric,
            startDate,
            topProducts: topProducts.map((row, idx) => ({
                rank: idx + 1,
                productId:    row.productId,
                productTitle: row.productTitle,
                variantId:    row.variantId,
                sku:          row.sku,
                variantName:  row.variantName,
                color:        row.color,
                size:         row.size,
                unitsSold:    parseInt(row.unitsSold),
                revenue:      parseFloat(row.revenue).toFixed(2),
                orderCount:   parseInt(row.orderCount),
            })),
        }, "Top products fetched successfully");
    } catch (error) {
        console.error("[getVendorTopProducts]", error);
        serverError(res, "Failed to fetch top products");
    }
};