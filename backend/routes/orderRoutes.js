import express from 'express';
import { 
    createOrder,
    confirmPayment,
    cancelPayment,
    approveReturn,
    approvePartialReturn, 
    getUserOrders, 
    getOrderById, 
    cancelOrder, 
    initiateReturn,
    initiatePartialReturn, 
    downloadInvoice,
    getOrderStatus,
    updateOrderStatus,
    razorpayWebhook,
    getAllOrdersAdmin,
    getOrderByIdAdmin, 
    updateOrderAdmin 
} from '../controllers/orderController.js';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

// --- Admin Routes ---
router.get('/admin/all', verifyToken, authorizeRoles('admin'), getAllOrdersAdmin);
router.get('/admin/:id', verifyToken, authorizeRoles('admin'), getOrderByIdAdmin);
router.put('/admin/:id', verifyToken, authorizeRoles('admin'), updateOrderAdmin);

// --- User Routes ---
router.get('/', verifyToken, getUserOrders);
router.get('/:id/invoice', verifyToken, downloadInvoice);
router.get('/:id/status', verifyToken, getOrderStatus);
router.get('/:id', verifyToken, getOrderById);
router.post('/:id/confirm-payment', verifyToken, confirmPayment);
router.post('/:id/cancel-payment', verifyToken, cancelPayment);
router.post('/:id/approve-return', verifyToken, authorizeRoles('admin'), approveReturn);
router.post('/:id/approve-partial-return', verifyToken, authorizeRoles('admin'), approvePartialReturn);
router.post('/', verifyToken, createOrder);
router.put('/:id/cancel', verifyToken, cancelOrder);
router.post('/:id/return', verifyToken, initiateReturn);
router.post('/:id/partial-return', verifyToken, initiatePartialReturn);
router.put('/:id/status', verifyToken, authorizeRoles('admin'), updateOrderStatus);

router.post("/payment/webhook", express.json({ type: "*/*" }), razorpayWebhook); // Use raw body for HMAC signature verification

export default router;