import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Order = sequelize.define("Order", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    userId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: 'Users', key: 'id' }
    },
    addressId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: 'UserAddresses', key: 'id' }
    },
    totalAmount: {
        type: DataTypes.FLOAT,
        allowNull: false,
    },
    orderStatus: {
        type: DataTypes.ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'return_requested', 'returned'),
        defaultValue: 'pending',
    },
    paymentStatus: {
        type: DataTypes.ENUM('pending', 'paid', 'failed', 'refund_initiated', 'refunded'),
        defaultValue: 'pending',
    },
    paymentMethod: {
        type: DataTypes.ENUM('debit card', 'credit card', 'COD', 'stripe', 'razorpay'),
        defaultValue: 'COD',
    }
}, { tableName: 'Orders' });

export default Order;