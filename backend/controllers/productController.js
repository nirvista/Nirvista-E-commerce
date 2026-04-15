import { Op, Sequelize } from "sequelize";
import User from "../models/userModel.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import Tag from "../models/tagModel.js";
import { created, notFound, serverError, success } from "../utils/responseMessages.js";

// --- Include helpers ---
const variantInclude = {
    model: ProductVariant,
    as: "variants",
    attributes: [
        "id", "variantName", "price", "size", "color", 
        "discountPrice", "images", "status", "stock", "reservedStock", "availableStock", "approvalStatus"
    ],
    where: { approvalStatus: 'approved' }, // Only show approved variants to customers
    required: false
};

const tagInclude = {
    model: Tag,
    as: "tags",
    attributes: ["id", "name", "slug"],
    through: { attributes: [] }
};

// --- Helper to build separated filter objects ---
function buildFilters(query) {
    const productFilter = {};
    const variantFilter = {};

    if (query.search) productFilter.title = { [Op.iLike]: `%${query.search}%` };

    const multiSelectFields = ['categoryId', 'brandId', 'material'];
    multiSelectFields.forEach(field => {
        if (query[field]) {
            productFilter[field] = Array.isArray(query[field]) ? { [Op.in]: query[field] } : query[field];
        }
    });

    if (query.minRating) productFilter.rating = { [Op.gte]: Number(query.minRating) };

    if (query.minPrice || query.maxPrice) {
        variantFilter.price = {};
        if (query.minPrice) variantFilter.price[Op.gte] = Number(query.minPrice);
        if (query.maxPrice) variantFilter.price[Op.lte] = Number(query.maxPrice);
    }

    if (query.color) variantFilter.color = Array.isArray(query.color) ? { [Op.in]: query.color } : query.color;
    if (query.size) variantFilter.size = Array.isArray(query.size) ? { [Op.in]: query.size } : query.size;

    // Always filter for approved variants for customers
    variantFilter.approvalStatus = 'approved';

    return { productFilter, variantFilter };
}

// --- Sorting helper ---
function getSortOrder(sort) {
    switch (sort) {
        case "price_asc":
            return [[{ model: ProductVariant, as: 'variants' }, "price", "ASC"]];
        case "price_desc":
            return [[{ model: ProductVariant, as: 'variants' }, "price", "DESC"]];
        case "rating_desc":
            return [["rating", "DESC"]];
        case "discount_desc":
            return [[{ model: ProductVariant, as: 'variants' }, "discountPrice", "DESC"]];
        default:
            return [["createdAt", "DESC"]];
    }
}

// --- Vendor: Create a new product (with variants) ---
export const createProduct = async (req, res) => {
    try {
        if (!req.body.vendorId) {
            req.body.vendorId = req.user.id;
        }
        // All variants start as pending approval
        if (req.body.variants && Array.isArray(req.body.variants)) {
            req.body.variants = req.body.variants.map(v => ({
                ...v,
                approvalStatus: 'pending'
            }));
        }
        const product = await Product.create(req.body, {
            include: [{ model: ProductVariant, as: 'variants' }]
        });
        if (req.body.tagIds && req.body.tagIds.length > 0) {
            await product.setTags(req.body.tagIds);
        }
        created(res, product, "Product created successfully and sent for admin approval");
    } catch (error) {
        console.error(error);
        serverError(res, "Server error");
    }
};

// --- Vendor: Add a new variant to a product ---
export const addVariant = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) return notFound(res, "Parent product not found");

        const variant = await ProductVariant.create({
            ...req.body,
            productId: req.params.id,
            approvalStatus: 'pending'
        });
        created(res, variant, "Variant added successfully and sent for admin approval");
    } catch (error) {
        serverError(res, "Failed to add variant");
    }
};

// --- Vendor: Update a variant (stock/price/availability) ---
export const updateVariant = async (req, res) => {
    try {
        // Any update by vendor sets status to pending
        const [updatedRows] = await ProductVariant.update(
            { ...req.body, approvalStatus: 'pending' },
            {
                where: {
                    id: req.params.variantId,
                    productId: req.params.id
                }
            }
        );
        if (updatedRows === 0) return notFound(res, "Variant not found");

        const updated = await ProductVariant.findByPk(req.params.variantId);
        success(res, updated, "Variant updated and sent for admin approval");
    } catch (error) {
        serverError(res, "Update failed");
    }
};

// --- Admin: Approve or reject a variant ---
export const adminApproveVariant = async (req, res) => {
    try {
        const { approve } = req.body; // approve: true/false
        const variant = await ProductVariant.findByPk(req.params.variantId);
        if (!variant) return notFound(res, "Variant not found");

        variant.approvalStatus = approve ? 'approved' : 'rejected';
        await variant.save();

        success(res, variant, `Variant ${approve ? 'approved' : 'rejected'} successfully`);
    } catch (error) {
        serverError(res, "Admin approval failed");
    }
};

// --- Admin: Approve all pending variants for a product (optional utility) ---
export const adminApproveAllVariants = async (req, res) => {
    try {
        const { approve } = req.body;
        const updated = await ProductVariant.update(
            { approvalStatus: approve ? 'approved' : 'rejected' },
            { where: { productId: req.params.id, approvalStatus: 'pending' } }
        );
        success(res, null, `All pending variants ${approve ? 'approved' : 'rejected'} for product`);
    } catch (error) {
        serverError(res, "Bulk approval failed");
    }
};

// --- Get a single product by ID (for customers: only approved variants) ---
export const getProductById = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id, {
            include: [variantInclude, tagInclude]
        });
        if (!product) return notFound(res, "Product not found");
        success(res, product, "Product fetched successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
};

// --- Get all products (for customers: only approved variants) ---
export const getAllProducts = async (req, res) => {
    try {
        const { productFilter, variantFilter } = buildFilters(req.query);
        const sortOrder = getSortOrder(req.query.sort);

        const { count, rows } = await Product.findAndCountAll({
            where: productFilter,
            order: sortOrder,
            include: [
                tagInclude,
                {
                    model: ProductVariant,
                    as: "variants",
                    attributes: [
                        "id", "variantName", "price", "size", "color",
                        "discountPrice", "images", "status", "stock", "reservedStock", "approvalStatus"
                    ],
                    where: variantFilter,
                    required: false
                }, {
                    model: User,
                    as: 'vendor',
                    where: { userStatus: 'active' },
                    required: true,
                    attributes: []
                }
            ],
            distinct: true
        });

        if (count === 0) {
            return success(res, { products: [], total: 0 }, "No products found");
        }
        success(res, { products: rows, total: count }, "Products fetched successfully");
    } catch (error) {
        console.error(error);
        serverError(res, "Server error");
    }
};

// --- Update a product (admin) ---
export const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { tagIds, ...updateData } = req.body;

        // Returns [affectedCount]
        const [updatedRows] = await Product.update(updateData, {
            where: { id }
        });

        const product = await Product.findByPk(id);
        if (!product) return notFound(res, "Product not found");

        if (tagIds && Array.isArray(tagIds)) {
            await product.setTags(tagIds);
        }

        const updatedProduct = await Product.findByPk(id, {
            include: [variantInclude, tagInclude]
        });

        success(res, updatedProduct, "Product updated successfully");
    } catch (error) {
        console.error("Update Product Error:", error);
        serverError(res, "Server error during product update");
    }
};

// --- Delete a product ---
export const deleteProduct = async (req, res) => {
    try {
        const deletedProduct = await Product.destroy({ where: { id: req.params.id } });
        if (!deletedProduct) return notFound(res, "Product not found");
        success(res, null, "Product deleted successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
};

// --- Search products by keyword (only approved variants) ---
export const searchProducts = async (req, res) => {
    try {
        const { search } = req.query;
        const products = await Product.findAll({
            where: {
                [Op.or]: [
                    { title: { [Op.iLike]: `%${search}%` } },
                    { description: { [Op.iLike]: `%${search}%` } }
                ]
            },
            include: [
                {
                    ...variantInclude,
                    where: { approvalStatus: 'approved' }
                },
                tagInclude
            ],
            limit: 30
        });
        success(res, products, "Search results fetched successfully");
    } catch (error) {
        serverError(res, "Search Failed");
    }
};

// --- Get New Arrivals (only approved variants) ---
export const getNewArrivals = async (req, res) => {
    try {
        const products = await Product.findAll({
            order: [['createdAt', 'DESC']],
            include: [variantInclude, tagInclude],
            limit: 12
        });
        success(res, products, "New arrivals fetched");
    } catch (error) {
        serverError(res, "Error fetching new arrivals");
    }
};

// --- Get Top Rated Products (only approved variants) ---
export const getTopRatedProducts = async (req, res) => {
    try {
        const products = await Product.findAll({
            order: [['rating', 'DESC']],
            include: [variantInclude, tagInclude],
            limit: 12
        });
        success(res, products, "Top rated products fetched");
    } catch (error) {
        serverError(res, "Error fetching top rated products");
    }
};

// --- Get Related Products by Category and Brand (only approved variants) ---
export const getRelatedProducts = async (req, res) => {
    try {
        const currentProduct = await Product.findByPk(req.params.id);
        if (!currentProduct) return notFound(res, "Product not found");

        const bId = sequelize.escape(currentProduct.brandId);
        const cId = sequelize.escape(currentProduct.categoryId);

        const related = await Product.findAll({
            where: {
                id: { [Op.ne]: currentProduct.id },
                [Op.or]: [
                    { categoryId: currentProduct.categoryId },
                    { brandId: currentProduct.brandId }
                ]
            },
            include: [variantInclude, tagInclude],
            order: [
                [
                    Sequelize.literal(`
                        CASE 
                            WHEN "brandId"::text = '${bId}' AND "categoryId"::text = '${cId}' THEN 1 
                            WHEN "categoryId"::text = '${cId}' THEN 2
                            ELSE 3 
                        END
                    `),
                    'ASC'
                ],
                [Sequelize.literal('RANDOM()')]
            ],
            limit: 12
        });
        success(res, related, "Related products fetched successfully");
    } catch (error) {
        serverError(res, "Error fetching related products");
    }
};

// --- Get all Product Variants for a Product (admin/vendor: all statuses) ---
export const getProductVariants = async (req, res) => {
    try {
        const variants = await ProductVariant.findAll({
            where: { productId: req.params.id }
        });
        success(res, variants, "Variants fetched successfully");
    } catch (error) {
        serverError(res, "Error fetching variants");
    }
};

// --- Delete a product variant ---
export const deleteVariant = async (req, res) => {
    try {
        const deleted = await ProductVariant.destroy({
            where: {
                id: req.params.variantId,
                productId: req.params.id
            }
        });
        if (!deleted) return notFound(res, "Variant not found");
        success(res, null, "Variant deleted successfully");
    } catch (error) {
        serverError(res, "Delete failed");
    }
};