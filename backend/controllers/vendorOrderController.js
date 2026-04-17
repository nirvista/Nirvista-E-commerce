/**
 * vendorOrderController.js
 *
 * Order management & fulfillment for authenticated vendors.
 * Vendors only see OrderItems where OrderItem.vendorId === req.user.id.
 * Customer PII is limited to the shipping address needed for fulfillment.
 *
 * Routes (mounted under /api/vendor):
 *   GET   /orders
 *   GET   /orders/:orderId
 *   PATCH /orders/:orderId/fulfillment
 *   POST  /orders/:orderId/refunds
 */

import { Op } from "sequelize";
import sequelize from "../config/db.js";
import Razorpay from "razorpay";
import { Order, OrderItem, Product, ProductVariant, UserAddress } from "../models/association.js";
import User from "../models/userModel.js";
//import Order from "../models/orderModel.js";
import { success, notFound, badRequest, serverError } from "../utils/responseMessages.js";

// ── Razorpay client (for refund processing) ───────────────────────────────────
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Refund window in days — platform rule enforced server-side
const REFUND_WINDOW_DAYS = 10;

// ── Helper: build vendor-scoped order item include ────────────────────────────
function buildVendorOrderItemInclude(vendorId, extraWhere = {}) {
    return {
        model: OrderItem,
        as: "items",
        where: { vendorId, ...extraWhere },
        required: true, // Only return orders that have at least one item from this vendor
        include: [
            {
                model: Product,
                as: "product",
                attributes: ["id", "title"],
            },
            {
                model: ProductVariant,
                as: "variant",
                attributes: ["id", "sku", "variantName", "price", "discountPrice", "images"],
            },
        ],
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/orders
// List all incoming orders that contain at least one item from this vendor
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorOrders = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const {
            fulfillmentStatus, // Filter by item-level fulfillment status
            page  = 1,
            limit = 20,
            sortOrder = "DESC",
        } = req.query;

        const pageNum  = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
        const offset   = (pageNum - 1) * limitNum;

        const itemWhere = { vendorId };
        if (fulfillmentStatus) itemWhere.fulfillmentStatus = fulfillmentStatus;

        const { count, rows: orders } = await Order.findAndCountAll({
            include: [
                buildVendorOrderItemInclude(vendorId, fulfillmentStatus ? { fulfillmentStatus } : {}),
                {
                    model: UserAddress,
                    as: "shippingAddress",
                    // Only expose fields needed for fulfillment — no customer PII beyond shipping
                    attributes: [
                        "recipientName", "addressLine1", "addressLine2",
                        "city", "state", "postal_code", "country"
                    ],
                },
            ],
            // Expose only safe order-level fields to vendor
            attributes: [
                "id", "totalAmount", "orderStatus", "paymentStatus",
                "paymentMethod", "createdAt", "updatedAt"
            ],
            order: [["createdAt", sortOrder.toUpperCase() === "ASC" ? "ASC" : "DESC"]],
            limit: limitNum,
            offset,
            distinct: true,
        });

        success(res, {
            orders,
            pagination: {
                total: count,
                page: pageNum,
                limit: limitNum,
                totalPages: Math.ceil(count / limitNum),
            },
        }, "Orders fetched successfully");
    } catch (error) {
        console.error("[getVendorOrders]", error);
        serverError(res, "Failed to fetch orders");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/orders/:orderId
// Full detail of a specific order — only vendor's items are included
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorOrderById = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { orderId } = req.params;

        const order = await Order.findOne({
            where: { id: orderId },
            include: [
                buildVendorOrderItemInclude(vendorId),
                {
                    model: UserAddress,
                    as: "shippingAddress",
                    attributes: [
                        "recipientName", "addressLine1", "addressLine2",
                        "city", "state", "postal_code", "country"
                    ],
                },
            ],
            attributes: [
                "id", "totalAmount", "orderStatus", "paymentStatus",
                "paymentMethod", "razorpayOrderId", "createdAt", "updatedAt"
            ],
        });

        if (!order || order.items.length === 0) {
            return notFound(res, "Order not found");
        }

        success(res, order, "Order details fetched successfully");
    } catch (error) {
        console.error("[getVendorOrderById]", error);
        serverError(res, "Failed to fetch order details");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/vendor/orders/:orderId/fulfillment
// Advance fulfillment status and/or set tracking info for vendor's items
//
// Body: {
//   fulfillmentStatus: 'processing' | 'shipped' | 'delivered' | 'cancelled',
//   carrierName?: string,
//   trackingNumber?: string,
//   orderItemIds?: UUID[]  — optionally scope to specific items in the order
// }
// ─────────────────────────────────────────────────────────────────────────────
export const updateFulfillment = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const vendorId = req.user.id;
        const { orderId } = req.params;
        const { fulfillmentStatus, carrierName, trackingNumber, orderItemIds } = req.body;

        const allowedStatuses = ["processing", "shipped", "delivered", "cancelled"];
        if (!fulfillmentStatus || !allowedStatuses.includes(fulfillmentStatus)) {
            await t.rollback();
            return badRequest(res, `fulfillmentStatus must be one of: ${allowedStatuses.join(", ")}`);
        }

        // ── Find the vendor's items in this order ─────────────────────────────
        const itemWhere = { orderId, vendorId };
        if (Array.isArray(orderItemIds) && orderItemIds.length > 0) {
            itemWhere.id = { [Op.in]: orderItemIds };
        }

        const items = await OrderItem.findAll({ where: itemWhere, transaction: t });

        if (items.length === 0) {
            await t.rollback();
            return notFound(res, "No vendor items found in this order");
        }

        // ── Validate status transition ─────────────────────────────────────────
        // Vendors cannot un-ship or rewind status
        const statusRank = { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: -1 };
        for (const item of items) {
            if (item.fulfillmentStatus === "delivered" || item.fulfillmentStatus === "cancelled") {
                await t.rollback();
                return badRequest(
                    res,
                    `Item ${item.id} is already '${item.fulfillmentStatus}' and cannot be changed`
                );
            }
            if (
                statusRank[fulfillmentStatus] !== -1 &&
                statusRank[fulfillmentStatus] < statusRank[item.fulfillmentStatus]
            ) {
                await t.rollback();
                return badRequest(
                    res,
                    `Cannot move item ${item.id} from '${item.fulfillmentStatus}' to '${fulfillmentStatus}'`
                );
            }
        }

        // ── Build update payload ──────────────────────────────────────────────
        const updatePayload = { fulfillmentStatus };
        if (carrierName)    updatePayload.carrierName    = carrierName;
        if (trackingNumber) updatePayload.trackingNumber = trackingNumber;
        if (fulfillmentStatus === "shipped")   updatePayload.shippedAt   = new Date();
        if (fulfillmentStatus === "delivered") updatePayload.deliveredAt = new Date();

        await OrderItem.update(updatePayload, { where: itemWhere, transaction: t });

        // 1. If the vendor cancels the item, restore the stock
        if (fulfillmentStatus === "cancelled") {
            for (const item of items) {
                await ProductVariant.update(
                    { stock: sequelize.literal(`"stock" + ${item.quantity}`) },
                    { where: { id: item.variantId }, transaction: t }
                );
            }   
        }

        // 2. Check if the parent Order status needs to be updated // All items in this loop belong to the same order
        const allOrderItems = await OrderItem.findAll({ where: { orderId }, transaction: t });

        const allShipped = allOrderItems.every(i => ['shipped', 'delivered'].includes(i.fulfillmentStatus));
        const allDelivered = allOrderItems.every(i => i.fulfillmentStatus === 'delivered');
        const allCancelled = allOrderItems.every(i => i.fulfillmentStatus === 'cancelled');

        const parentOrder = await Order.findByPk(orderId, { transaction: t });

        if (allDelivered && parentOrder.orderStatus !== 'delivered') {
            parentOrder.orderStatus = 'delivered';
        } else if (allShipped && parentOrder.orderStatus !== 'shipped' && parentOrder.orderStatus !== 'delivered') {
            parentOrder.orderStatus = 'shipped';
        } else if (allCancelled && parentOrder.orderStatus !== 'cancelled') {
            parentOrder.orderStatus = 'cancelled';
        }

        await parentOrder.save({ transaction: t });

        await t.commit();

        // ── Trigger customer notification (placeholder) ───────────────────────
        // In production: await sendShipmentNotification(order.userId, { trackingNumber, carrierName });
        console.info(
            `[updateFulfillment] Notification should be sent for order ${orderId} — status: ${fulfillmentStatus}`
        );

        const updatedItems = await OrderItem.findAll({ where: itemWhere });

        success(res, { orderId, updatedItems }, `Fulfillment status updated to '${fulfillmentStatus}'`);
    } catch (error) {
        await t.rollback();
        console.error("[updateFulfillment]", error);
        serverError(res, "Failed to update fulfillment status");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/vendor/orders/:orderId/refunds
// Initiate a full or partial refund for vendor's portion of an order
//
// Body: {
//   orderItemId: UUID,       — the specific line item to refund
//   refundQuantity: number,  — how many units (partial refund)
//   reason: string
// }
// ─────────────────────────────────────────────────────────────────────────────
export const initiateVendorRefund = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const vendorId = req.user.id;
        const { orderId } = req.params;
        const { orderItemId, refundQuantity, reason } = req.body;

        if (!orderItemId || !refundQuantity || !Number.isInteger(refundQuantity) || refundQuantity < 1) {
            await t.rollback();
            return badRequest(res, "orderItemId and a positive integer refundQuantity are required");
        }

        // ── Find the specific order item belonging to this vendor ─────────────
        const item = await OrderItem.findOne({
            where: { id: orderItemId, orderId, vendorId },
            include: [{ model: Order, as: "order" }],
            transaction: t,
        });

        if (!item) {
            await t.rollback();
            return notFound(res, "Order item not found or access denied");
        }

        const order = item.order;

        // ── Platform rule: refunds only allowed within REFUND_WINDOW_DAYS ─────
        const orderDate   = new Date(order.createdAt);
        const daysSince   = (Date.now() - orderDate.getTime()) / (1000 * 60 * 60 * 24);
        if (daysSince > REFUND_WINDOW_DAYS) {
            await t.rollback();
            return badRequest(
                res,
                `Refund window of ${REFUND_WINDOW_DAYS} days has passed for this order`
            );
        }

        // ── Validate quantity ─────────────────────────────────────────────────
        const refundableQty = item.quantity - (item.returnedQuantity || 0);
        if (refundQuantity > refundableQty) {
            await t.rollback();
            return badRequest(
                res,
                `Cannot refund ${refundQuantity} units. Only ${refundableQty} unit(s) are eligible.`
            );
        }

        // ── Ensure order was paid (no refund on pending / failed) ─────────────
        if (order.paymentStatus !== "paid") {
            await t.rollback();
            return badRequest(res, "Refunds can only be processed for paid orders");
        }

        // ── Calculate refund amount ───────────────────────────────────────────
        const refundAmount = parseFloat(item.priceAtPurchase) * refundQuantity;

        // ── Razorpay refund ───────────────────────────────────────────────────
        let razorpayRefund = null;
        if (order.razorpayPaymentId) {
            try {
                razorpayRefund = await razorpay.payments.refund(order.razorpayPaymentId, {
                    amount: Math.round(refundAmount * 100), // paise
                    notes: {
                        orderId,
                        orderItemId,
                        reason: reason || "Vendor-initiated refund",
                        refundQuantity,
                    },
                });
            } catch (rzpErr) {
                await t.rollback();
                console.error("[initiateVendorRefund] Razorpay error:", rzpErr);
                return serverError(res, "Payment gateway refund failed. Please try again.");
            }
        }

        // ── Update item record ────────────────────────────────────────────────
        await item.update(
            {
                returnStatus: "approved",
                returnedQuantity: (item.returnedQuantity || 0) + refundQuantity,
                refundAmount: (parseFloat(item.refundAmount) || 0) + refundAmount,
                refundInitiatedAt: new Date(),
            },
            { transaction: t }
        );

        // Restore stock based on the refunded quantity
        await ProductVariant.update(
            { stock: sequelize.literal(`"stock" + ${refundQuantity}`) },
            { where: { id: item.variantId }, transaction: t }
        );

        // ── Update order-level payment status ─────────────────────────────────
        await order.update({ paymentStatus: "refund_initiated" }, { transaction: t });

        await t.commit();

        success(res, {
            orderItemId,
            refundQuantity,
            refundAmount,
            razorpayRefundId: razorpayRefund?.id || null,
            newReturnedQuantity: item.returnedQuantity,
        }, `Refund of ₹${refundAmount.toFixed(2)} initiated successfully`);
    } catch (error) {
        if (t) await t.rollback();
        console.error("[initiateVendorRefund]", error);
        serverError(res, "Failed to process refund");
    }
};