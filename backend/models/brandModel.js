import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Brand = sequelize.define("Brand", {
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
    description: {
        type: DataTypes.TEXT,
    },
    logoUrl: {
        type: DataTypes.STRING, // Useful for the frontend brand carousel
    }
}, {
    timestamps: true,
    tableName: 'Brands'
});

export default Brand;