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
    deleteVariant
 } from '../controllers/productController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router  = express.Router();

router.post("/", verifyToken, authorizeRoles("admin"), createProduct);
router.get("/", getAllProducts);

// Additional routes for special product collections
router.get("/search", searchProducts);
router.get("/new-arrivals", getNewArrivals);
router.get("/top-rated", getTopRatedProducts);

// Variant Specific Routes
router.get("/:id/variants", getProductVariants);
router.post("/:id/variants", verifyToken, authorizeRoles("admin"), addVariant);
router.put("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), updateVariant);
router.delete("/:id/variants/:variantId", verifyToken, authorizeRoles("admin"), deleteVariant);


router.get("/:id/related", getRelatedProducts);

router.get("/:id", getProductById);

router.put("/:id", verifyToken, authorizeRoles("admin"), updateProduct);

router.delete("/:id", verifyToken, authorizeRoles("admin"), deleteProduct);


export default router;