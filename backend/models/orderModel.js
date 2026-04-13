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
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    orderStatus: {
        type: DataTypes.ENUM('processing', 'reserved', 'confirmed', 'shipped', 'delivered', 'cancelled', 'return_requested', 'returned'),
        defaultValue: 'processing',
    },
    paymentStatus: {
        type: DataTypes.ENUM('pending', 'reserved', 'paid', 'failed', 'refund_initiated', 'refunded'),
        defaultValue: 'pending',
    },
    paymentMethod: {
        type: DataTypes.ENUM('online', 'cod'),
        defaultValue: 'cod',
    },
    razorpayOrderId: {
        type: DataTypes.STRING,
        allowNull: true
    },
    razorpayPaymentId: {
        type: DataTypes.STRING,
        allowNull: true
    }
}, { tableName: 'Orders' });

export default Order;