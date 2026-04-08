import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Product = sequelize.define("Product", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
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
    }
},{
    timestamps: true,
    tableName: 'Products'
});

export default Product;