import express from 'express';
import { userSignup, userLogin, refresh, logout, logoutAll, adminSignUp, adminLogin, getCurrentUserProfile, updateUserProfile } from '../controllers/authController.js';
import verifyToken from '../middlewares/authMiddleware.js';

const router = express.Router();

router.post('/signup', userSignup);
router.post('/login', userLogin);
router.post('/adminsignup', adminSignUp);
router.post('/adminlogin', adminLogin);
router.get('/me', getCurrentUserProfile);
router.put('/profile', updateUserProfile);
router.post('/refresh', refresh);
router.post('/logout', logout);
router.post('/logout-all', verifyToken, logoutAll);

export default router;