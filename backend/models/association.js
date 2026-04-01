import Cart from './cartModel.js';
import CartItem from './cartItemModel.js';
import Product from './productModel.js';
import User from './userModel.js';
import UserAddress from './userAddresses.js';
import ProductVariant from './variantModel.js';

// Define associations
Cart.hasMany(CartItem, { foreignKey: 'cartId', as: 'items' });
CartItem.belongsTo(Cart, { foreignKey: 'cartId' });

CartItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

User.hasMany(UserAddress, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserAddress.belongsTo(User, { foreignKey: 'userId', onDelete: 'CASCADE' });

Product.hasMany(ProductVariant, { foreignKey: 'productId', as: 'variants', onDelete: 'CASCADE', hooks: true });
ProductVariant.belongsTo(Product, { foreignKey: 'productId', onDelete: 'CASCADE' });

export { Cart, CartItem, Product, User, UserAddress, ProductVariant };