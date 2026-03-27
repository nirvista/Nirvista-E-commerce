import express from 'express';
import { userSignup, userLogin, adminSignUp, adminLogin, getCurrentUserProfile, updateUserProfile } from '../controllers/authController.js';

const router = express.Router();

router.post('/signup', userSignup);
router.post('/login', userLogin);
router.post('/adminsignup', adminSignUp);
router.post('/adminlogin', adminLogin);
router.get('/me', getCurrentUserProfile);
router.put('/profile', updateUserProfile);

export default router;