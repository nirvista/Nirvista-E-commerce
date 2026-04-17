import { Cart, CartItem } from "../models/association.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { serverError } from "../utils/responseMessages.js";

//Add to cart
export const addToCart = async (req, res) => {
    try {
        const {userId, productId, variantId} = req.body;
        if (!userId || !productId || !variantId) {
            return res.status(400).json({ message: "userId, productId, and variantId are required" });
        }

        // Check if product exists
        const product = await Product.findByPk(productId);
        if (!product) {
            return res.status(404).json({ message: "Product does not exist" });
        }

        // Check if variant exists
        const variant = await ProductVariant.findByPk(variantId);
        if (!variant) {
            return res.status(404).json({ message: "Product variant does not exist" });
        }

        let cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            cart = await Cart.create({ userId });
        }
        let cartItem = await CartItem.findOne({ where: { cartId: cart.id, productId, variantId } });
        if (cartItem) {
            cartItem.quantity += 1;
            await cartItem.save();
        } else {
            await CartItem.create({ cartId: cart.id, productId, variantId, quantity: 1 });
        }
        res.status(200).json({ message: "Product added to cart successfully" });
    } catch (error) {
        serverError(res, error);
    }
}

// Reduce item quantity in cart
export const reduceItemQuantity = async (req, res) => {
    try {
        const { userId, productId, variantId } = req.body;
        if (!userId || !productId || !variantId) {
            return res.status(400).json({ message: "userId, productId, and variantId are required" });
        }

        // Find the user's cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            return res.status(404).json({ message: "Cart not found for this user" });
        }

        // Find the cart item
        const cartItem = await CartItem.findOne({ where: { cartId: cart.id, productId, variantId } });
        if (!cartItem) {
            return res.status(404).json({ message: "Product not found in cart" });
        }

        // Decrement quantity or remove item
        if (cartItem.quantity > 1) {
            cartItem.quantity -= 1;
            await cartItem.save();
            return res.status(200).json({ message: "Product quantity decreased in cart" });
        } else {
            await cartItem.destroy();
            return res.status(200).json({ message: "Product removed from cart" });
        }
    } catch (error) {
        serverError(res, error);
    }
};

// Increase item quantity in cart
export const increaseItemQuantity = async (req, res) => {
    try {
        const { userId, productId, variantId } = req.body;
        if (!userId || !productId || !variantId) {
            return res.status(400).json({ message: "userId, productId, and variantId are required" });
        }

        // Find the user's cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            return res.status(404).json({ message: "Cart not found for this user" });
        }

        // Find the cart item
        const cartItem = await CartItem.findOne({ where: { cartId: cart.id, productId, variantId } });
        if (!cartItem) {
            return res.status(404).json({ message: "Product not found in cart" });
        }

        // Increment quantity or remove item
        if (cartItem.quantity >= 1) {
            cartItem.quantity += 1;
            await cartItem.save();
            return res.status(200).json({ message: "Product quantity increased in cart" });
        } else {
            await cartItem.destroy();
            return res.status(200).json({ message: "Product removed from cart" });
        }
    } catch (error) {
        serverError(res, error);
    }
};

// Update quantity of an item in cart
export const updateCartItemQuantity = async (req, res) => {
    try {
        const { userId, productId, variantId, quantity } = req.body;
        if (!userId || !productId || !variantId || typeof quantity !== "number") {
            return res.status(400).json({ message: "userId, productId, variantId, and quantity are required" });
        }
        if (quantity < 0) {
            return res.status(400).json({ message: "Quantity must be a non-negative integer" });
        }

        // Find the user's cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            return res.status(404).json({ message: "Cart not found for this user" });
        }

        // Find the cart item
        const cartItem = await CartItem.findOne({ where: { cartId: cart.id, productId, variantId } });
        if (!cartItem) {
            return res.status(404).json({ message: "Product not found in cart" });
        }

        // If quantity is 0, remove the item
        if (quantity === 0) {
            await cartItem.destroy();
            return res.status(200).json({ message: "Product removed from cart" });
        }

        // Update the quantity
        cartItem.quantity = quantity;
        await cartItem.save();
        return res.status(200).json({ message: "Product quantity updated in cart" });
    } catch (error) {
        serverError(res, error);
    }
};

// Get cart by userId
export const getCartByUserId = async (req, res) => {
    try {
        // Accept userId from query, params, or body
        const userId = req.query.userId || req.params.userId || req.body.userId;
        if (!userId) {
            return res.status(400).json({ message: "userId is required" });
        }

        // Find the user's cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            return res.status(404).json({ message: "Cart not found for this user" });
        }

        // Get all items in the cart, including product details
        const cartItems = await CartItem.findAll({
            where: { cartId: cart.id },
            include: [
                {
                    model: Product,
                    as: 'product',
                    attributes: ["id", "title", "description"] // Add more fields as needed
                },
                {
                    model: ProductVariant,
                    as: 'variant',
                    attributes: ["id", "variantName", "price", "discountPrice", "images"] // Add more fields as needed
                }
            ]
        });

        // Format the response
        const items = cartItems.map(item => ({
            productId: item.productId,
            quantity: item.quantity,
            product: item.product, // Will be null if product is missing
            variant: item.variant // Will be null if variant is missing
        }));

        return res.status(200).json({
            cartId: cart.id,
            userId: cart.userId,
            items
        });
    } catch (error) {
        serverError(res, error);
    }
};

//Delete entire cart
export const deleteCart = async (req, res) => {
    try {
        // Accept userId from query, params, or body
        const userId = req.query.userId || req.params.userId || req.body.userId;
        if (!userId) {
            return res.status(400).json({ message: "userId is required" });
        }

        // Find the user's cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            return res.status(404).json({ message: "Cart not found for this user" });
        }

        // Delete all items in the cart
        await CartItem.destroy({ where: { cartId: cart.id } });

        // Delete the cart
        await cart.destroy();

        return res.status(200).json({ message: "Cart deleted successfully" });
    } catch (error) {
        serverError(res, error);
    }
};
