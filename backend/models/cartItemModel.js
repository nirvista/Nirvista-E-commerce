import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const CartItem = sequelize.define("CartItem", {
    cartId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Carts',
            key: 'id'
        }
    },
    productId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Products',
            key: 'id'
        }
    },
    quantity: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1
    }
},{
    tableName: 'CartItems'
});

export default CartItem;