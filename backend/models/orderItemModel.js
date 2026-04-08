import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const OrderItem = sequelize.define("OrderItem", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    orderId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { 
            model: 'Orders', 
            key: 'id' },
        onDelete: 'CASCADE'
    },
    productId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { 
            model: 'Products', 
            key: 'id' }
    },
    variantId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { 
            model: 'ProductVariants', 
            key: 'id' }
    },
    quantity: {
        type: DataTypes.INTEGER,
        allowNull: false,
    },
    priceAtPurchase: {
        type: DataTypes.FLOAT,
        allowNull: false,
    }
}, { tableName: 'OrderItems', timestamps: false });

export default OrderItem;