import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const VendorProfile = sequelize.define("VendorProfile", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    userId: {
        type: DataTypes.UUID,
        allowNull: false,
        unique: true, // One profile per vendor
        references: {
            model: 'Users',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    storeName: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    storeDescription: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    businessRegistrationNumber: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    businessRegistrationDocUrl: {
        type: DataTypes.STRING, // URL to uploaded doc (e.g., S3 link)
        allowNull: true,
    },
    taxId: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    // Bank account details (store encrypted or via a payment gateway reference in production)
    bankAccountName: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    bankAccountNumber: {
        type: DataTypes.STRING, // Masked in responses: show last 4 digits only
        allowNull: true,
    },
    bankName: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    bankIFSC: {
        type: DataTypes.STRING, // For Indian banks; adapt as needed
        allowNull: true,
    },
    // Admin review fields
    vendorStatus: {
        type: DataTypes.ENUM('pending', 'approved', 'suspended', 'rejected'),
        defaultValue: 'pending',
        allowNull: false,
    },
    statusReason: {
        type: DataTypes.TEXT, // Admin's reason for suspension/rejection
        allowNull: true,
    },
    statusUpdatedAt: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    // Contact & address
    businessEmail: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    businessPhone: {
        type: DataTypes.STRING,
        allowNull: true,
    },
    businessAddress: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
}, {
    timestamps: true,
    tableName: 'VendorProfiles',
    indexes: [
        { fields: ['userId'] },
        { fields: ['vendorStatus'] },
        { fields: ['storeName'] },
    ]
});

export default VendorProfile;