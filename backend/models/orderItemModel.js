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
    vendorId: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'Users',
            key: 'id'
        },
        onDelete: 'SET NULL'
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
    },
    fulfillmentStatus: {
        type: DataTypes.ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled'),
        defaultValue: 'pending',
        allowNull: false,
    },
    // Shipment tracking
    carrierName: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'e.g., FedEx, UPS, DHL, BlueDart'
    },
    trackingNumber: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    shippedAt: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    deliveredAt: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    returnStatus: {
        type: DataTypes.ENUM('none', 'requested', 'approved', 'rejected', 'completed'),
        defaultValue: 'none',
    },
    returnedQuantity: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
    },
    refundAmount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
        comment: 'Actual amount refunded for this line item'
    },
    refundInitiatedAt: {
        type: DataTypes.DATE,
        allowNull: true,
    }
}, { 
    tableName: 'OrderItems',
    indexes: [
        { fields: ['orderId'] },
        { fields: ['vendorId'] },
        { fields: ['fulfillmentStatus'] },
    ]
 });

export default OrderItem;