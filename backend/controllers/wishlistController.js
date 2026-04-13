// controllers/wishlistController.js
import { Wishlist, WishlistItem, Cart, CartItem, Product, ProductVariant } from "../models/association.js";
import { serverError, notFound, success, badRequest } from "../utils/responseMessages.js";

// Helper: Get user ID safely (assuming you use auth middleware that sets req.user)
const getUserId = (req) => req.query.userId || req.body.userId ;

// GET /api/wishlist - Get user's wishlist
export const getWishlist = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return unauthorized(res, "User not authenticated");

        let wishlist = await Wishlist.findOne({
            where: { userId },
            include: [{
                model: WishlistItem,
                as: 'items',
                include: [
                    { model: Product, as: 'product', attributes: ['id', 'title'] },
                    { model: ProductVariant, as: 'variant', attributes: ['id', 'variantName', 'price', 'images', 'status'] }
                ]
            }]
        });

        // If no wishlist exists, return an empty structure
        if (!wishlist) {
            return success(res, { items: [] }, "Wishlist fetched successfully");
        }

        success(res, wishlist, "Wishlist fetched successfully");
    } catch (error) {
        serverError(res, error);
    }
};

// POST /api/wishlist/items - Add item to wishlist
export const addToWishlist = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { productId, variantId } = req.body;

        if (!userId || !productId || !variantId) {
            return badRequest(res, "userId, productId, and variantId are required");
        }

        // Find or create the user's wishlist
        let [wishlist] = await Wishlist.findOrCreate({ where: { userId } });

        // Check if this exact variant is already in the wishlist
        const existingItem = await WishlistItem.findOne({
            where: { wishlistId: wishlist.id, productId, variantId }
        });

        if (existingItem) {
            return success(res, null, "Item is already in your wishlist");
        }

        // Add to wishlist
        const item = await WishlistItem.create({
            wishlistId: wishlist.id,
            productId,
            variantId
        });

        success(res, item, "Item added to wishlist successfully");
    } catch (error) {
        serverError(res, error);
    }
};

// DELETE /api/wishlist/items/:itemId - Remove item from wishlist
export const removeFromWishlist = async (req, res) => {
    try {
        const { itemId } = req.params; // This is the WishlistItem's PK

        const deleted = await WishlistItem.destroy({ where: { id: itemId } });
        
        if (!deleted) return notFound(res, "Item not found in wishlist");

        success(res, null, "Item removed from wishlist successfully");
    } catch (error) {
        serverError(res, error);
    }
};

// POST /api/wishlist/move-to-cart/:itemId - Move item to cart
export const moveToCart = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { itemId } = req.params;

        // 1. Find the wishlist item to get its productId and variantId
        const wishlistItem = await WishlistItem.findByPk(itemId);
        if (!wishlistItem) return notFound(res, "Item not found in wishlist");

        // 2. Find or create the user's Cart
        let [cart] = await Cart.findOrCreate({ where: { userId } });

        // 3. Check if this exact product variant is already in the cart
        let cartItem = await CartItem.findOne({ 
            where: { cartId: cart.id, productId: wishlistItem.productId, variantId: wishlistItem.variantId } 
        });

        // 4. Add to cart or increment quantity
        if (cartItem) {
            cartItem.quantity += 1;
            await cartItem.save();
        } else {
            await CartItem.create({ 
                cartId: cart.id, 
                productId: wishlistItem.productId, 
                variantId: wishlistItem.variantId, 
                quantity: 1 
            });
        }

        // 5. Remove from wishlist
        await wishlistItem.destroy();

        success(res, null, "Item moved to cart successfully");
    } catch (error) {
        serverError(res, error);
    }
};

// DELETE /api/wishlist - Clear wishlist
export const clearWishlist = async (req, res) => {
    try {
        const userId = getUserId(req);
        const wishlist = await Wishlist.findOne({ where: { userId } });

        if (!wishlist) return notFound(res, "Wishlist not found");

        // Delete all items associated with this wishlist
        await WishlistItem.destroy({ where: { wishlistId: wishlist.id } });

        success(res, null, "Wishlist cleared successfully");
    } catch (error) {
        serverError(res, error);
    }
};