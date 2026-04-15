// models/variantModel.js
import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const ProductVariant = sequelize.define("ProductVariant", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    productId: {
        type: DataTypes.UUID,
        allowNull: false,
    },
    sku: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        comment: 'Stock Keeping Unit — unique identifier for inventory management'
    },
    variantName: { 
        type: DataTypes.STRING 
    }, // e.g., "Red / XL"
    price: { 
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false 
    },
    discountPrice: { 
        type: DataTypes.DECIMAL(10, 2)
    },
    images: { 
        type: DataTypes.ARRAY(DataTypes.STRING)
    }, // Image gallery
    color: { 
        type: DataTypes.STRING
    }, // For auto-linking swatches
    size: { 
        type: DataTypes.STRING
    },
    status: { 
        type: DataTypes.ENUM('in-stock', 'out-of-stock', 'discontinued'),
        defaultValue: 'in-stock'
    },
    stock: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
    },
    reservedStock: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0
    },
    availableStock: {
        type: DataTypes.VIRTUAL,
        get() {
            return this.stock - this.reservedStock;
        },
        set(value) {
            throw new Error('Do not set availableStock directly');
        }
    },
    lowStockThreshold: {
        type: DataTypes.INTEGER,
        defaultValue: 5,
        allowNull: false,
    },
    approvalStatus: {
        type: DataTypes.ENUM('pending', 'approved', 'rejected'),
        defaultValue: 'pending',
    }
}, {
    tableName: 'ProductVariants',
    timestamps: true,
    indexes: [
        { fields: ['sku'] },
        { fields: ['productId'] },
        { fields: ['status'] },
    ]
});

export default ProductVariant;