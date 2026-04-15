/**
 * vendorProductController.js
 *
 * Handles all product & catalog management endpoints for authenticated vendors.
 * Every operation is scoped to req.user.id — a vendor can only read/write
 * their own products.
 *
 * Routes (mounted under /api/vendor):
 *   GET    /products
 *   POST   /products
 *   PUT    /products/:productId
 *   PATCH  /products/:productId/status
 *   POST   /products/:productId/images
 */

import { Op } from "sequelize";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import Tag from "../models/tagModel.js";
import { success, created, notFound, badRequest, serverError } from "../utils/responseMessages.js";

// ── Shared include helpers ────────────────────────────────────────────────────
const variantInclude = {
    model: ProductVariant,
    as: "variants",
    // Vendors see ALL approval statuses for their own products
    attributes: [
        "id", "sku", "variantName", "price", "discountPrice",
        "color", "size", "images", "status", "stock",
        "reservedStock", "availableStock", "lowStockThreshold", "approvalStatus"
    ],
};

const tagInclude = {
    model: Tag,
    as: "tags",
    attributes: ["id", "name", "slug"],
    through: { attributes: [] },
};

// ── Helper: ownership guard ───────────────────────────────────────────────────
async function findVendorProduct(productId, vendorId) {
    const product = await Product.findOne({
        where: { id: productId, vendorId },
        include: [variantInclude, tagInclude],
    });
    return product; // null if not found or not owned
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/vendor/products
// List the authenticated vendor's own products (paginated + filterable)
// ─────────────────────────────────────────────────────────────────────────────
export const getVendorProducts = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const {
            listingStatus, // 'active' | 'draft' | 'archived'
            categoryId,
            search,
            page = 1,
            limit = 20,
            sortBy = "createdAt",
            sortOrder = "DESC",
        } = req.query;

        const pageNum  = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
        const offset   = (pageNum - 1) * limitNum;

        const where = { vendorId };
        if (listingStatus) where.listingStatus = listingStatus;
        if (categoryId)    where.categoryId    = categoryId;
        if (search)        where.title         = { [Op.iLike]: `%${search}%` };

        const allowedSort  = ["createdAt", "updatedAt", "title", "rating"];
        const safeSortBy   = allowedSort.includes(sortBy) ? sortBy : "createdAt";
        const safeSortOrder = sortOrder.toUpperCase() === "ASC" ? "ASC" : "DESC";

        const { count, rows } = await Product.findAndCountAll({
            where,
            include: [variantInclude, tagInclude],
            order: [[safeSortBy, safeSortOrder]],
            limit: limitNum,
            offset,
            distinct: true,
        });

        success(res, {
            products: rows,
            pagination: {
                total: count,
                page: pageNum,
                limit: limitNum,
                totalPages: Math.ceil(count / limitNum),
            },
        }, "Products fetched successfully");
    } catch (error) {
        console.error("[getVendorProducts]", error);
        serverError(res, "Failed to fetch products");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/vendor/products
// Create a new product listing owned by the authenticated vendor
// ─────────────────────────────────────────────────────────────────────────────
export const createVendorProduct = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { title, description, categoryId, brandId, material, tagIds, variants } = req.body;

        if (!title || !categoryId || !brandId) {
            return badRequest(res, "title, categoryId, and brandId are required");
        }

        // All variants start as pending approval — admin must approve before going live
        const preparedVariants = Array.isArray(variants)
            ? variants.map(v => ({ ...v, approvalStatus: "pending" }))
            : [];

        const product = await Product.create(
            {
                vendorId,
                title,
                description,
                categoryId,
                brandId,
                material,
                listingStatus: "draft", // Vendor must explicitly publish
                variants: preparedVariants,
            },
            { include: [{ model: ProductVariant, as: "variants" }] }
        );

        // Attach tags if provided
        if (Array.isArray(tagIds) && tagIds.length > 0) {
            await product.setTags(tagIds);
        }

        // Re-fetch with full associations for the response
        const freshProduct = await Product.findByPk(product.id, {
            include: [variantInclude, tagInclude],
        });

        created(res, freshProduct, "Product created successfully. Variants are pending admin approval.");
    } catch (error) {
        console.error("[createVendorProduct]", error);
        serverError(res, "Failed to create product");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/vendor/products/:productId
// Update an existing product — vendor must own the product
// ─────────────────────────────────────────────────────────────────────────────
export const updateVendorProduct = async (req, res) => {
    try {
        const vendorId  = req.user.id;
        const { productId } = req.params;

        // ── Ownership check ──────────────────────────────────────────────────
        const product = await Product.findOne({ where: { id: productId, vendorId } });
        if (!product) {
            return notFound(res, "Product not found or you do not have permission to edit it");
        }

        const { tagIds, variants, listingStatus, ...productData } = req.body;

        // Prevent vendor from force-setting to 'active' if variants aren't approved
        // (they can draft / archive freely; publishing goes through approval flow)
        if (listingStatus) productData.listingStatus = listingStatus;

        await product.update(productData);

        // Update tags
        if (Array.isArray(tagIds)) {
            await product.setTags(tagIds);
        }

        // Upsert variants — any change triggers re-approval
        if (Array.isArray(variants)) {
            for (const v of variants) {
                if (v.id) {
                    // Update existing variant → reset to pending approval
                    await ProductVariant.update(
                        { ...v, approvalStatus: "pending" },
                        { where: { id: v.id, productId } }
                    );
                } else {
                    // New variant
                    await ProductVariant.create({
                        ...v,
                        productId,
                        approvalStatus: "pending",
                    });
                }
            }
        }

        const updatedProduct = await Product.findByPk(productId, {
            include: [variantInclude, tagInclude],
        });

        success(res, updatedProduct, "Product updated. Any modified variants are pending re-approval.");
    } catch (error) {
        console.error("[updateVendorProduct]", error);
        serverError(res, "Failed to update product");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/vendor/products/:productId/status
// Toggle listing visibility: active | draft | archived
// ─────────────────────────────────────────────────────────────────────────────
export const updateVendorProductStatus = async (req, res) => {
    try {
        const vendorId  = req.user.id;
        const { productId } = req.params;
        const { listingStatus } = req.body;

        const allowed = ["active", "draft", "archived"];
        if (!listingStatus || !allowed.includes(listingStatus)) {
            return badRequest(res, `listingStatus must be one of: ${allowed.join(", ")}`);
        }

        // Ownership check
        const product = await Product.findOne({ where: { id: productId, vendorId } });
        if (!product) {
            return notFound(res, "Product not found or access denied");
        }

        // Guard: cannot publish if no approved variants exist
        if (listingStatus === "active") {
            const approvedCount = await ProductVariant.count({
                where: { productId, approvalStatus: "approved" },
            });
            if (approvedCount === 0) {
                return badRequest(
                    res,
                    "Cannot publish product: it has no admin-approved variants. Submit variants for approval first."
                );
            }
        }

        await product.update({ listingStatus });

        success(res, { id: product.id, listingStatus }, `Product status updated to '${listingStatus}'`);
    } catch (error) {
        console.error("[updateVendorProductStatus]", error);
        serverError(res, "Failed to update product status");
    }
};

// POST /api/vendor/products/:productId/images
// Attach external image URLs to a specific variant.
export const addVariantImageUrls = async (req, res) => {
    try {
        const vendorId = req.user.id;
        const { productId } = req.params;
        const { variantId, imageUrls } = req.body;

        if (!variantId) {
            return badRequest(res, "variantId is required");
        }

        if (!Array.isArray(imageUrls) || imageUrls.length === 0) {
            return badRequest(res, "imageUrls must be a non-empty array of strings");
        }

        // Validate URLs to prevent bad data
        const isValidUrl = (url) => {
            try {
                new URL(url);
                return true;
            } catch (err) {
                return false;
            }
        };

        if (!imageUrls.every(isValidUrl)) {
            return badRequest(res, "One or more image URLs are invalid");
        }

        // Ownership check
        const product = await Product.findOne({ where: { id: productId, vendorId } });
        if (!product) {
            return notFound(res, "Product not found or access denied");
        }

        // Ensure the variant belongs to this product
        const variant = await ProductVariant.findOne({
            where: { id: variantId, productId },
        });
        
        if (!variant) {
            return notFound(res, "Variant not found for this product");
        }

        // Append new URLs to the existing images array
        const existingImages = variant.images || [];
        await variant.update({ images: [...existingImages, ...imageUrls] });

        success(res, { variantId, images: variant.images }, "Image URLs successfully added to variant");
    } catch (error) {
        console.error("[addVariantImageUrls]", error);
        serverError(res, "Failed to add image URLs");
    }
};