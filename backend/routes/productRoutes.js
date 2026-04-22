import express from 'express';
import { 
    createProduct, 
    getProductById, 
    getAllProducts, 
    updateProduct, 
    deleteProduct, 
    getNewArrivals, 
    getTopRatedProducts, 
    getRelatedProducts, 
    searchProducts,
    getProductVariants,
    updateVariant,
    addVariant,
    deleteVariant,
    adminApproveVariant,
    adminApproveAllVariants,
    getAllProductsAdmin,
    addReview,
    updateReviewStatus,
    getProductReviews,
    adminApproveAllReviews,
    getProductReviewsAdmin
 } from '../controllers/productController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router  = express.Router();

// =======================
// Admin Routes
// =======================
// GET  /api/products/admin/all — List all products (for admin)
router.get("/admin/all", verifyToken, authorizeRoles("admin"), getAllProductsAdmin);
router.get("/admin/:id/reviews", verifyToken, authorizeRoles("admin"), getProductReviewsAdmin);
// =======================
// Public Routes
// =======================
router.get("/", getAllProducts);
router.get("/search", searchProducts);
router.get("/new-arrivals", getNewArrivals);
router.get("/top-rated", getTopRatedProducts);
router.get("/:id/variants", getProductVariants);
router.get("/:id/related", getRelatedProducts);
router.get("/:id/reviews", getProductReviews); // Fetch approved reviews for a product
router.get("/:id", getProductById);

// =======================
// Role-based Routes
// =======================

// Product & Variant Creation / Updates
router.post("/", verifyToken, authorizeRoles("admin", "vendor"), createProduct);
router.post("/:id/variants", verifyToken, authorizeRoles("admin", "vendor"), addVariant);
router.put("/:id", verifyToken, authorizeRoles("admin", "vendor"), updateProduct);

// Variant Management
router.put("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), updateVariant);
router.delete("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), deleteVariant);

// Product Deletion
router.delete("/:id", verifyToken, authorizeRoles("admin"), deleteProduct);

// Admin Approvals
router.put("/:id/variants/:variantId/approve", verifyToken, authorizeRoles("admin"), adminApproveVariant);
router.post("/:id/variants/approve-all", verifyToken, authorizeRoles("admin"), adminApproveAllVariants);

// =======================
// Review & Rating Routes
// =======================

// Customer: Submit a new review
router.post("/:id/reviews", verifyToken, authorizeRoles("customer"), addReview); 

// Admin: Approve or Reject a review (Triggers rating recalculation on approval)
router.patch("/reviews/:reviewId/status", verifyToken, authorizeRoles("admin"), updateReviewStatus);
// Admin: Approve all pending reviews for a product and recalculate average rating
router.post("/:id/reviews/approve-all", verifyToken, authorizeRoles("admin"), adminApproveAllReviews);


export default router;