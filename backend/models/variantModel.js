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
    variantName: { type: DataTypes.STRING }, // e.g., "Red / XL"
    price: { type: DataTypes.FLOAT, allowNull: false },
    discountPrice: { type: DataTypes.FLOAT },
    images: { type: DataTypes.ARRAY(DataTypes.STRING) }, // Image gallery
    color: { type: DataTypes.STRING }, // For auto-linking swatches
    size: { type: DataTypes.STRING },
    status: { 
        type: DataTypes.ENUM('in-stock', 'out-of-stock', 'discontinued'),
        defaultValue: 'in-stock'
    },
    stock: { type: DataTypes.INTEGER, defaultValue: 0 }
});

export default ProductVariant;