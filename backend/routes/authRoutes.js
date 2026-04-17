import express from 'express';
import rateLimit from 'express-rate-limit';
import { 
    userSignup, 
    userLogin, 
    refresh, 
    logout, 
    logoutAll, 
    adminSignUp, 
    adminLogin, 
    getCurrentUserProfile, 
    updateUserProfile,
    forgotPassword,
    resetPassword
 } from '../controllers/authController.js';
import verifyToken from '../middlewares/authMiddleware.js';

const router = express.Router();
const forgotPasswordLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, 
    message: { success: false, message: "Too many password reset requests from this IP, please try again after an hour." }
});

router.post('/signup', userSignup);
router.post('/login', userLogin);
router.post('/adminsignup', adminSignUp);
router.post('/adminlogin', adminLogin);
router.get('/me', getCurrentUserProfile);
router.put('/profile', verifyToken, updateUserProfile);
router.post('/refresh', refresh);
router.post('/logout', logout);
router.post('/logout-all', verifyToken, logoutAll);
router.post('/forgot-password',forgotPasswordLimiter, forgotPassword);
router.post('/reset-password/:token', resetPassword);

export default router;