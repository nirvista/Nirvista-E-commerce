// models/categoryModel.js
import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Category = sequelize.define("Category", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    slug: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
    },
    description: {
        type: DataTypes.TEXT,
    },
    parentId: {
        type: DataTypes.UUID,
        allowNull: true, // If null, this is a top-level category
        references: {
            model: 'Categories',
            key: 'id'
        },
        onDelete: 'SET NULL' // If parent is deleted, children become top-level
    }
}, {
    timestamps: true,
    tableName: 'Categories'
});

export default Category;