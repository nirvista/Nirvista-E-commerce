import Cart from './cartModel.js';
import CartItem from './cartItemModel.js';
import Product from './productModel.js';
import User from './userModel.js';
import UserAddress from './userAddresses.js';
import ProductVariant from './variantModel.js';
import Category from './categoryModel.js';
import Brand from './brandModel.js';
import Tag from './tagModel.js';
import Wishlist from './wishlistModel.js';
import WishlistItem from './wishlistItemModel.js';
import Order from './orderModel.js';
import OrderItem from './orderItemModel.js';
import VendorProfile from './vendorProfileModel.js';

// --- Cart ---
Cart.hasMany(CartItem, { foreignKey: 'cartId', as: 'items' });
CartItem.belongsTo(Cart, { foreignKey: 'cartId' });
CartItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
CartItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

// --- User & Addresses ---
User.hasMany(UserAddress, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserAddress.belongsTo(User, { foreignKey: 'userId', onDelete: 'CASCADE' });

// --- Vendor Profile (1:1) ---
User.hasOne(VendorProfile, { foreignKey: 'userId', as: 'vendorProfile', onDelete: 'CASCADE' });
VendorProfile.belongsTo(User, { foreignKey: 'userId' });

// --- Vendor -> Products (1:M) ---
User.hasMany(Product, { foreignKey: 'vendorId', as: 'vendorProducts', onDelete: 'SET NULL' });
Product.belongsTo(User, { foreignKey: 'vendorId', as: 'vendor' });

// --- Product Variants ---
Product.hasMany(ProductVariant, { foreignKey: 'productId', as: 'variants', onDelete: 'CASCADE', hooks: true });
ProductVariant.belongsTo(Product, { foreignKey: 'productId', onDelete: 'CASCADE' });

// --- Category Self-Referencing (sub-categories) ---
Category.hasMany(Category, { as: "children", foreignKey: "parentId" });
Category.belongsTo(Category, { as: "parent", foreignKey: "parentId" });

Category.hasMany(Product, { foreignKey: "categoryId", as: "products" });
Product.belongsTo(Category, { foreignKey: "categoryId", as: "category" });

// --- Brand & Products ---
Brand.hasMany(Product, { foreignKey: "brandId", as: "products" });
Product.belongsTo(Brand, { foreignKey: "brandId", as: "brand" });

// --- Product Tags (Many-to-Many) ---
Product.belongsToMany(Tag, {
    through: "ProductTags",
    as: "tags",
    foreignKey: "productId"
});
Tag.belongsToMany(Product, {
    through: "ProductTags",
    as: "products",
    foreignKey: "tagId"
});

// --- Wishlist ---
User.hasOne(Wishlist, { foreignKey: 'userId', as: 'wishlist' });
Wishlist.belongsTo(User, { foreignKey: 'userId' });

Wishlist.hasMany(WishlistItem, { foreignKey: 'wishlistId', as: 'items', onDelete: 'CASCADE' });
WishlistItem.belongsTo(Wishlist, { foreignKey: 'wishlistId' });

WishlistItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
WishlistItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

// --- Orders ---
// FIX: Added 'as: user' and 'as: orders' aliases
User.hasMany(Order, { foreignKey: 'userId', as: 'orders' });
Order.belongsTo(User, { foreignKey: 'userId', as: 'user' });

UserAddress.hasMany(Order, { foreignKey: 'addressId' });
Order.belongsTo(UserAddress, { foreignKey: 'addressId', as: 'shippingAddress' });

Order.hasMany(OrderItem, { foreignKey: 'orderId', as: 'items', onDelete: 'CASCADE' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId' });

OrderItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
OrderItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

// Vendor Specific Aliases
User.hasMany(OrderItem, { foreignKey: 'vendorId', as: 'vendorOrderItems' });
OrderItem.belongsTo(User, { foreignKey: 'vendorId', as: 'vendor' });

export {
    Cart, CartItem, Product, User, UserAddress, ProductVariant,
    Category, Brand, Tag, Wishlist, WishlistItem, Order, OrderItem,
    VendorProfile
};