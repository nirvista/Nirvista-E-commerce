import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const User = sequelize.define("User", {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  userRole: {
    type: DataTypes.ENUM('customer', 'vendor', 'admin'),
    allowNull: false,
  },
  userStatus: {
    type: DataTypes.ENUM('active', 'pending', 'suspended', 'deleted'),
    defaultValue: 'pending',
  }
},{
  timestamps: true,
  last_login_at: {
    type: DataTypes.DATE,
  },
  tableName: 'Users'
});

export default User;