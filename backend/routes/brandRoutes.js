import express from 'express';
import { createBrand, getAllBrands, getBrandById, getProductsByBrand, updateBrand, deleteBrand } from '../controllers/brandController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

router.get('/', getAllBrands);
router.get('/:brandId', getBrandById);
router.get('/:brandId/products', getProductsByBrand);
router.post('/', verifyToken, authorizeRoles('admin'), createBrand);
router.put('/:brandId', verifyToken, authorizeRoles('admin'), updateBrand);
router.delete('/:brandId', verifyToken, authorizeRoles('admin'), deleteBrand);

export default router;