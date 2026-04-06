import express from 'express';
import { getWishlist, addToWishlist, removeFromWishlist, moveToCart, clearWishlist } from '../controllers/wishlistController.js'; 

const router = express.Router();

router.get('/', getWishlist);
router.post('/', addToWishlist);
router.delete('/:itemId', removeFromWishlist);
router.post('/move-to-cart/:itemId', moveToCart);
router.delete('/', clearWishlist);

export default router;