import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Cart = sequelize.define("Cart", {
    userId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Users',
            key: 'id'
        }
    }
},{
    tableName: 'Carts'
});

export default Cart;