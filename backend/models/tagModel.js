// models/tagModel.js
import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Tag = sequelize.define("Tag", {
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
    }
}, {
    timestamps: true,
    tableName: 'Tags'
});

export default Tag;