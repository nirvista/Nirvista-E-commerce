import express from 'express';
import { 
    createOrder, 
    getUserOrders, 
    getOrderById, 
    cancelOrder, 
    initiateReturn, 
    downloadInvoice,
    getOrderStatus,
    updateOrderStatus 
} from '../controllers/orderController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

// All order routes require authentication
router.use(verifyToken);

router.post('/', createOrder);
router.get('/', getUserOrders);
router.get('/:id', getOrderById);
router.put('/:id/cancel', cancelOrder);
router.post('/:id/return', initiateReturn);
router.get('/:id/invoice', downloadInvoice);
router.get('/:id/status', getOrderStatus);
router.put('/:id/status', authorizeRoles('admin'), updateOrderStatus);

export default router;