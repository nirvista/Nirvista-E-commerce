import Cart from './cartModel.js';
import CartItem from './cartItemModel.js';
import Product from './productModel.js';


// Define associations
Cart.hasMany(CartItem, { foreignKey: 'cartId', as: 'items' });
CartItem.belongsTo(Cart, { foreignKey: 'cartId' });

CartItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

export { Cart, CartItem, Product };