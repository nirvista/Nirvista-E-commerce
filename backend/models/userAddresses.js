import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";
import User from "./userModel.js";

const UserAddress = sequelize.define("UserAddress", {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
    onDelete: 'CASCADE', // Ensures ON DELETE CASCADE
  },
  addressLabel: {
    type: DataTypes.ENUM('Home', 'Office', 'Other'),
    allowNull: false,
  },
  recipientName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  addressLine1: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  addressLine2: {
    type: DataTypes.STRING,
  },
  city: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  state: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  postal_code: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  country: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  isDefaultBilling: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  isDefaultShipping: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  }
}, {
  tableName: 'UserAddresses',
  indexes: [
    {
      fields: ['userId'],
    },
  ],
  timestamps: true,
});

export default UserAddress;