import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";
import User from "./userModel.js";

const RefreshToken = sequelize.define("RefreshToken", {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: User, key: "id" },
  },
  token_hash: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  client_type: {
    type: DataTypes.ENUM("web", "mobile"),
    allowNull: false,
  },
  device_info: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: "RefreshTokens",
  timestamps: true,
});

export default RefreshToken;