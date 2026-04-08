import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const WishlistItem = sequelize.define("WishlistItem", {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    wishlistId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: 'Wishlists', key: 'id' },
        onDelete: 'CASCADE'
    },
    productId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: 'Products', key: 'id' }
    },
    variantId: {
        type: DataTypes.UUID,
        allowNull: false, // Ensures the exact variant is saved
        references: { model: 'ProductVariants', key: 'id' }
    }
},{ tableName: 'WishlistItems' });

export default WishlistItem;