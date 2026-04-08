import express from 'express';
import { createTag, updateTag, deleteTag ,getAllTags, getProductsByTag } from '../controllers/tagController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

router.get('/', getAllTags);
router.get('/:id/products', getProductsByTag);
router.post('/', verifyToken, authorizeRoles('admin'), createTag);
router.put('/:id', verifyToken, authorizeRoles('admin'), updateTag);
router.delete('/:id', verifyToken, authorizeRoles('admin'), deleteTag);

export default router;