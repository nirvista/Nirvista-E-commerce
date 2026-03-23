import express from 'express';
import { addToCart, getCartByUserId, removeFromCart, updateCartItemQuantity } from '../controllers/cartController.js'; 

const router = express.Router();

router.post("/add", addToCart);
router.post("/remove", removeFromCart);
router.post("/update", updateCartItemQuantity);
router.get("/:userId", getCartByUserId);

export default router;