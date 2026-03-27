import express from 'express';
import { createProduct, getProductById, getAllProducts, updateProduct, deleteProduct } from '../controllers/productController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router  = express.Router();

router.post("/", verifyToken, authorizeRoles("admin"), createProduct);

router.get("/:id", getProductById);

router.get("/", getAllProducts);

router.put("/:id", verifyToken, authorizeRoles("admin"), updateProduct);

router.delete("/:id", verifyToken, authorizeRoles("admin"), deleteProduct);

export default router;