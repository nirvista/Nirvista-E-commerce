import UserAddress from "../models/userAddresses.js";
import sequelize from "../config/db.js";
import jwt from "jsonwebtoken";

export const getUserAddresses = async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const addresses = await UserAddress.findAll({
            where: { userId: decoded.id },
            order: [['updatedAt', 'DESC']]
        });

        res.status(200).json({ success: true, data: addresses, message: "Addresses fetched successfully" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Server error" });
    }
};

export const addUserAddress = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Set all previous addresses to not default
        await UserAddress.update(
            { isDefaultBilling: false, isDefaultShipping: false },
            { where: { userId: decoded.id }, transaction: t }
        );

        // Add new address as default
        const address = await UserAddress.create(
            {
                ...req.body,
                userId: decoded.id,
                isDefaultBilling: true,
                isDefaultShipping: true
            },
            { transaction: t }
        );

        await t.commit();
        res.status(201).json({ success: true, data: address, message: "Address added and set as default" });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ success: false, message: "Server error" });
    }
};

export const updateUserAddress = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const { addressId } = req.params;
        const address = await UserAddress.findOne({ where: { id: addressId, userId: decoded.id } });
        if (!address) {
            await t.rollback();
            return res.status(404).json({ success: false, message: "Address not found" });
        }

        // If making this address default, unset others
        if (req.body.isDefaultBilling || req.body.isDefaultShipping) {
            await UserAddress.update(
                { isDefaultBilling: false, isDefaultShipping: false },
                { where: { userId: decoded.id }, transaction: t }
            );
        }

        await address.update(req.body, { transaction: t });
        await t.commit();
        res.status(200).json({ success: true, data: address, message: "Address updated" });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ success: false, message: "Server error" });
    }
};

export const deleteUserAddress = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const { addressId } = req.params;
        const address = await UserAddress.findOne({ where: { id: addressId, userId: decoded.id } });
        if (!address) {
            await t.rollback();
            return res.status(404).json({ success: false, message: "Address not found" });
        }

        const wasDefault = address.isDefaultBilling || address.isDefaultShipping;
        await address.destroy({ transaction: t });

        // If deleted address was default, set another as default
        if (wasDefault) {
            const another = await UserAddress.findOne({ where: { userId: decoded.id }, order: [['updatedAt', 'DESC']] });
            if (another) {
                await another.update({ isDefaultBilling: true, isDefaultShipping: true }, { transaction: t });
            }
        }

        await t.commit();
        res.status(200).json({ success: true, message: "Address deleted" });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ success: false, message: "Server error" });
    }
};

export const setDefaultUserAddress = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const { addressId } = req.params;

        // Find the address and ensure it belongs to the user
        const address = await UserAddress.findOne({ where: { id: addressId, userId: decoded.id } });
        if (!address) {
            await t.rollback();
            return res.status(404).json({ success: false, message: "Address not found" });
        }

        // Unset default for all addresses of the user
        await UserAddress.update(
            { isDefaultBilling: false, isDefaultShipping: false },
            { where: { userId: decoded.id }, transaction: t }
        );

        // Set the selected address as default
        await address.update(
            { isDefaultBilling: true, isDefaultShipping: true },
            { transaction: t }
        );

        await t.commit();
        res.status(200).json({ success: true, data: address, message: "Default address set successfully" });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ success: false, message: "Server error" });
    }
};