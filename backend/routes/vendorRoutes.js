/**
 * vendorRoutes.js
 *
 * All routes under /api/vendor — protected by verifyToken + authorizeRoles('vendor')
 *
 * Register in your main app.js:
 *   import vendorRoutes from './routes/vendorRoutes.js';
 *   app.use('/api/vendor', vendorRoutes);
 */

import express from "express";
import verifyToken     from "../middlewares/authMiddleware.js";
import authorizeRoles  from "../middlewares/roleMiddleware.js";
import { createVendorProfileIfNotExists } from "../controllers/vendorController.js";
// Product & Catalog
import {
    getVendorProducts,
    createVendorProduct,
    updateVendorProduct,
    updateVendorProductStatus,
    addVariantImageUrls,
} from "../controllers/vendorProductController.js";

// Inventory
import {
    getVendorInventory,
    adjustVendorInventory,
} from "../controllers/vendorInventoryController.js";

// Orders & Fulfillment
import {
    getVendorOrders,
    getVendorOrderById,
    updateFulfillment,
    initiateVendorRefund,
} from "../controllers/vendorOrderController.js";

// Analytics
import {
    getVendorSalesAnalytics,
    getVendorPerformanceAnalytics,
    getVendorTopProducts,
} from "../controllers/vendorAnalyticsController.js";

const router = express.Router();

// ── Apply auth to all vendor routes ──────────────────────────────────────────
router.use(verifyToken, authorizeRoles("vendor"));

router.post("/profile", createVendorProfileIfNotExists);

// ── Product & Catalog ─────────────────────────────────────────────────────────
router.get( "/products",                       getVendorProducts);
router.post("/products",                       createVendorProduct);
router.put( "/products/:productId",            updateVendorProduct);
router.patch("/products/:productId/status",    updateVendorProductStatus);
router.post("/products/:productId/images",     addVariantImageUrls);

// ── Inventory ─────────────────────────────────────────────────────────────────
router.get(  "/inventory",      getVendorInventory);
router.patch("/inventory/:sku", adjustVendorInventory);

// ── Orders & Fulfillment ──────────────────────────────────────────────────────
router.get(  "/orders",                        getVendorOrders);
router.get(  "/orders/:orderId",               getVendorOrderById);
router.patch("/orders/:orderId/fulfillment",   updateFulfillment);
router.post( "/orders/:orderId/refunds",       initiateVendorRefund);

// ── Analytics ─────────────────────────────────────────────────────────────────
router.get("/analytics/sales",        getVendorSalesAnalytics);
router.get("/analytics/performance",  getVendorPerformanceAnalytics);
router.get("/analytics/top-products", getVendorTopProducts);

export default router;