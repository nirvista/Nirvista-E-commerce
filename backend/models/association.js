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

// Define associations
Cart.hasMany(CartItem, { foreignKey: 'cartId', as: 'items' });
CartItem.belongsTo(Cart, { foreignKey: 'cartId' });

CartItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

User.hasMany(UserAddress, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserAddress.belongsTo(User, { foreignKey: 'userId', onDelete: 'CASCADE' });

Product.hasMany(ProductVariant, { foreignKey: 'productId', as: 'variants', onDelete: 'CASCADE', hooks: true });
ProductVariant.belongsTo(Product, { foreignKey: 'productId', onDelete: 'CASCADE' });

// Category Self-Referencing (For sub-categories)
Category.hasMany(Category, { as: "children", foreignKey: "parentId" });
Category.belongsTo(Category, { as: "parent", foreignKey: "parentId" });

Category.hasMany(Product, { foreignKey: "categoryId", as: "products" });
Product.belongsTo(Category, { foreignKey: "categoryId", as: "category" });

Brand.hasMany(Product, { foreignKey: "brandId", as: "products" });
Product.belongsTo(Brand, { foreignKey: "brandId", as: "brand" });

Product.belongsToMany(Tag, { 
    through: "ProductTags", // The name of the junction table
    as: "tags", 
    foreignKey: "productId" 
});
Tag.belongsToMany(Product, { 
    through: "ProductTags", 
    as: "products", 
    foreignKey: "tagId" 
});

User.hasOne(Wishlist, { foreignKey: 'userId', as: 'wishlist' });
Wishlist.belongsTo(User, { foreignKey: 'userId' });

Wishlist.hasMany(WishlistItem, { foreignKey: 'wishlistId', as: 'items', onDelete: 'CASCADE' });
WishlistItem.belongsTo(Wishlist, { foreignKey: 'wishlistId' });

WishlistItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
WishlistItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

CartItem.belongsTo(ProductVariant, { foreignKey: 'variantId', as: 'variant' });

export { Cart, CartItem, Product, User, UserAddress, ProductVariant, Category, Brand, Tag, Wishlist, WishlistItem };