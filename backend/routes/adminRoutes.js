import express from "express";
import {
    getAllVendors,
    getVendorById,
    createVendorByAdmin,
    updateVendorStatus,
    updateVendorDetails
} from "../controllers/vendorController.js";
import verifyToken from "../middlewares/authMiddleware.js";
import authorizeRoles from "../middlewares/roleMiddleware.js";

const router = express.Router();

// All routes require a valid JWT + admin role
router.use(verifyToken, authorizeRoles("admin"));

// GET  /api/admin/vendors          — List vendors (paginated, filterable, sortable)
router.get("/", getAllVendors);

// GET  /api/admin/vendors/:vendorId — Full vendor detail
router.get("/:vendorId", getVendorById);

// POST /api/admin/vendors           — Manually provision a vendor
router.post("/", createVendorByAdmin);

// PATCH /api/admin/vendors/:vendorId/status — Approve / suspend / reject
router.put("/:vendorId/status", updateVendorStatus);

// PUT /api/admin/vendors/:vendorId/details — Update vendor details
router.put("/:vendorId/details", updateVendorDetails);

export default router;