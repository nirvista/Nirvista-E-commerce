import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Product = sequelize.define("Product", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    vendorId: {
        type: DataTypes.UUID,
        allowNull: false, // allowNull for backward-compat with existing rows; set NOT NULL after migration
        references: {
            model: 'Users',
            key: 'id'
        },
        onDelete: 'SET NULL'
    },
    title: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    description: {
        type: DataTypes.TEXT,
    },
    categoryId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'Categories',
            key: 'id'
        },
        onDelete: 'RESTRICT',
    },
    brandId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'Brands',
            key: 'id'
        },
        onDelete: 'RESTRICT',
    },
    material: {
        type: DataTypes.STRING,
    },
    rating: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
    },
    listingStatus: {
        type: DataTypes.ENUM('active', 'draft', 'archived'),
        defaultValue: 'draft', // New listings start as draft until published
        allowNull: false,
    }
},{
    timestamps: true,
    tableName: 'Products',
    indexes: [
        { fields: ['vendorId'] },
        { fields: ['listingStatus'] },
        { fields: ['categoryId'] },
    ]
});

export default Product;