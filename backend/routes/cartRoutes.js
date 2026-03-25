import express from 'express';
import { addToCart, getCartByUserId, increaseItemQuantity ,reduceItemQuantity, updateCartItemQuantity, deleteCart } from '../controllers/cartController.js'; 

const router = express.Router();

router.post("/add", addToCart);
router.post("/reduce", reduceItemQuantity);
router.post("/increase", increaseItemQuantity);
router.post("/update", updateCartItemQuantity);
router.get("/:userId", getCartByUserId);
router.delete("/", deleteCart);
export default router;