import express from 'express';
import {
    getAllCategories,
    getCategoryById,
    getProductsByCategory,
    createCategory,
    updateCategory,
    deleteCategory
} from '../controllers/categoryController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

// Public Routes
router.get('/', getAllCategories);
router.get('/:id', getCategoryById);
router.get('/:id/products', getProductsByCategory);

// Admin Protected Routes
router.post('/', verifyToken, authorizeRoles('admin'), createCategory);
router.put('/:id', verifyToken, authorizeRoles('admin'), updateCategory);
router.delete('/:id', verifyToken, authorizeRoles('admin'), deleteCategory);

export default router;