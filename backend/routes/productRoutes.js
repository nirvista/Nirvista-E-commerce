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
    getAllProductsAdmin
 } from '../controllers/productController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router  = express.Router();

// Admin Routes
// GET  /api/admin/products/all           — List all products (for admin)
router.get("/admin/all", getAllProductsAdmin);

// Public routes
router.get("/", getAllProducts);
router.get("/search", searchProducts);
router.get("/new-arrivals", getNewArrivals);
router.get("/top-rated", getTopRatedProducts);
router.get("/:id/variants", getProductVariants);
router.get("/:id/related", getRelatedProducts);
router.get("/:id", getProductById);

// Role-based Routes
router.post("/", verifyToken, authorizeRoles("admin", "vendor"), createProduct);
router.post("/:id/variants", verifyToken, authorizeRoles("admin", "vendor"), addVariant);
router.put("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), updateVariant);
router.delete("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), deleteVariant);
router.put("/:id/variants/:variantId/approve", verifyToken, authorizeRoles("admin"), adminApproveVariant);
router.post("/:id/variants/approve-all", verifyToken, authorizeRoles("admin"), adminApproveAllVariants);
router.put("/:id", verifyToken, authorizeRoles("admin", "vendor"), updateProduct);
router.delete("/:id", verifyToken, authorizeRoles("admin"), deleteProduct);


export default router;