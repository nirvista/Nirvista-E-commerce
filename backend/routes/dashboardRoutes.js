import express from 'express';
import { getDashboardStats } from '../controllers/dashboardController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

// GET /api/admin/dashboard
router.get('/', verifyToken, authorizeRoles('admin'), getDashboardStats);

export default router;