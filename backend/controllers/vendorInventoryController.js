/**
 * vendorInventoryController.js
 *
 * Inventory management for authenticated vendors.
 * Scoped strictly to the vendor's own SKUs via vendorId on the Product.
 *
 * Routes (mounted under /api/vendor):
 *   GET   /inventory
 *   PATCH /inventory/:sku
 */

import { Op } from "sequelize";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { success, notFound, badRequest, serverError } from "../utils/responseMessages.js";

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/inventory
// Full stock overview for all of the vendor's SKUs, with low-stock alerts
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorInventory = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const {
            lowStockOnly, // '1' | 'true' — only show low-stock items
            status,       // 'in-stock' | 'out-of-stock' | 'discontinued'
            search,       // search by SKU or variantName
            page  = 1,
            limit = 50,
        } = req.query;

        const pageNum  = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(200, Math.max(1, parseInt(limit, 10)));
        const offset   = (pageNum - 1) * limitNum;

        // ── Build variant-level filter ────────────────────────────────────────
        const variantWhere = {};
        if (status) variantWhere.status = status;
        if (search) {
            variantWhere[Op.or] = [
                { sku: { [Op.iLike]: `%${search}%` } },
                { variantName: { [Op.iLike]: `%${search}%` } },
            ];
        }

        // Low-stock: availableStock (stock - reservedStock) <= lowStockThreshold
        // We use a raw WHERE on the columns since availableStock is VIRTUAL
        if (lowStockOnly === "1" || lowStockOnly === "true") {
            variantWhere[Op.and] = [
                // stock - reservedStock <= lowStockThreshold
                // Expressed via Sequelize col comparison isn't directly supported,
                // so we use a literal condition
                ...(variantWhere[Op.and] || []),
            ];
        }

        // Fetch variants belonging to this vendor's products
        const { count, rows: variants } = await ProductVariant.findAndCountAll({
            where: variantWhere,
            include: [
                {
                    model: Product,
                    as: "product",   // ProductVariant.belongsTo(Product) with no alias — using default
                    where: { vendorId },
                    required: true,  // INNER JOIN — only vendor's products
                    attributes: ["id", "title", "listingStatus", "categoryId"],
                }
            ],
            attributes: [
                "id", "sku", "variantName", "price", "discountPrice",
                "color", "size", "status", "stock", "reservedStock",
                "availableStock", "lowStockThreshold", "approvalStatus"
            ],
            order: [["stock", "ASC"]], // Low stock items first
            limit: limitNum,
            offset,
        });

        // ── Build enriched inventory rows with alert flags ─────────────────────
        const inventory = variants.map(v => {
            const available = v.stock - v.reservedStock;
            const isLowStock = available <= v.lowStockThreshold && available > 0;
            const isOutOfStock = available <= 0;

            return {
                id: v.id,
                sku: v.sku,
                variantName: v.variantName,
                productId: v.product?.id,
                productTitle: v.product?.title,
                listingStatus: v.product?.listingStatus,
                price: v.price,
                discountPrice: v.discountPrice,
                color: v.color,
                size: v.size,
                status: v.status,
                stock: v.stock,
                reservedStock: v.reservedStock,
                availableStock: available,
                lowStockThreshold: v.lowStockThreshold,
                approvalStatus: v.approvalStatus,
                alerts: {
                    lowStock: isLowStock,
                    outOfStock: isOutOfStock,
                },
            };
        });

        // Filter by lowStockOnly in JS (since VIRTUAL field can't be WHERE'd in SQL)
        const filtered = (lowStockOnly === "1" || lowStockOnly === "true")
            ? inventory.filter(i => i.alerts.lowStock || i.alerts.outOfStock)
            : inventory;

        // Summary stats
        const totalSKUs = count;
        const lowStockCount  = inventory.filter(i => i.alerts.lowStock).length;
        const outOfStockCount = inventory.filter(i => i.alerts.outOfStock).length;

        success(res, {
            summary: { totalSKUs, lowStockCount, outOfStockCount },
            inventory: filtered,
            pagination: {
                total: count,
                page: pageNum,
                limit: limitNum,
                totalPages: Math.ceil(count / limitNum),
            },
        }, "Inventory fetched successfully");
    } catch (error) {
        console.error("[getVendorInventory]", error);
        serverError(res, "Failed to fetch inventory");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/vendor/inventory/:sku
// Adjust stock for a specific variant by SKU
//
// Body: { quantity: number, operation: 'set' | 'increment' | 'decrement' }
// ─────────────────────────────────────────────────────────────────────────────
export const adjustVendorInventory = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { sku }  = req.params;
        const { quantity, operation, lowStockThreshold } = req.body;

        // ── Validate inputs ───────────────────────────────────────────────────
        const allowedOps = ["set", "increment", "decrement"];
        if (!operation || !allowedOps.includes(operation)) {
            return badRequest(res, `operation must be one of: ${allowedOps.join(", ")}`);
        }
        if (typeof quantity !== "number" || !Number.isInteger(quantity) || quantity < 0) {
            return badRequest(res, "quantity must be a non-negative integer");
        }

        // ── Find variant + ownership check ────────────────────────────────────
        const variant = await ProductVariant.findOne({
            where: { sku },
            include: [
                {
                    model: Product,
                    as: "product",
                    where: { vendorId },
                    required: true,
                    attributes: ["id", "title"],
                }
            ],
        });

        if (!variant) {
            return notFound(res, `SKU '${sku}' not found or does not belong to your account`);
        }

        // ── Apply stock operation ─────────────────────────────────────────────
        let newStock;
        switch (operation) {
            case "set":
                newStock = quantity;
                break;
            case "increment":
                newStock = variant.stock + quantity;
                break;
            case "decrement":
                newStock = Math.max(0, variant.stock - quantity); // Never go below 0
                break;
        }

        // ── Determine new status based on stock ───────────────────────────────
        let newStatus = variant.status;
        const available = newStock - variant.reservedStock;
        if (available <= 0 && variant.status !== "discontinued") {
            newStatus = "out-of-stock";
        } else if (available > 0 && variant.status === "out-of-stock") {
            newStatus = "in-stock"; // Auto-reactivate when stock comes back
        }

        // ── Build update payload ──────────────────────────────────────────────
        const updatePayload = { stock: newStock, status: newStatus };
        if (lowStockThreshold !== undefined && Number.isInteger(lowStockThreshold) && lowStockThreshold >= 0) {
            updatePayload.lowStockThreshold = lowStockThreshold;
        }

        await variant.update(updatePayload);

        const updatedAvailable = newStock - variant.reservedStock;
        const isLowStock  = updatedAvailable <= variant.lowStockThreshold && updatedAvailable > 0;
        const isOutOfStock = updatedAvailable <= 0;

        success(res, {
            sku: variant.sku,
            variantId: variant.id,
            variantName: variant.variantName,
            productId: variant.product?.id,
            productTitle: variant.product?.title,
            previousStock: variant.stock, // before save (still old via in-memory)
            newStock,
            reservedStock: variant.reservedStock,
            availableStock: updatedAvailable,
            status: newStatus,
            alerts: { lowStock: isLowStock, outOfStock: isOutOfStock },
        }, `Stock ${operation === "set" ? "set to" : operation + "d by"} ${quantity} for SKU '${sku}'`);
    } catch (error) {
        console.error("[adjustVendorInventory]", error);
        serverError(res, "Failed to adjust inventory");
    }
};