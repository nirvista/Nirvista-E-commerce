import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Review = sequelize.define("Review", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    productId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'Products',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    userId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'Users',
            key: 'id'
        },
        onDelete: 'CASCADE' // If a user is deleted, their reviews are removed
    },
    headline: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    comment: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    rating: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: {
            min: 1,
            max: 5
        }
    },
    media: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        defaultValue: [],
        comment: "Array of image or video URLs uploaded by the user"
    },
    status: {
        type: DataTypes.ENUM('pending', 'approved', 'rejected'),
        defaultValue: 'pending', // All new reviews must be approved by admin
        allowNull: false,
    }
}, {
    timestamps: true,
    tableName: 'Reviews',
    indexes: [
        { fields: ['productId'] },
        { fields: ['userId'] },
        { fields: ['status'] }
    ]
});

export default Review;