// controllers/tagController.js
import Tag from "../models/tagModel.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { notFound, serverError, success } from "../utils/responseMessages.js";

// CREATE a new tag
export const createTag = async (req, res) => {
    try {
        const { name, slug } = req.body;
        const tag = await Tag.create({ name, slug });
        success(res, tag, "Tag created successfully");
    } catch (error) {
        serverError(res, "Failed to create tag");
    }
};

// GET /api/tags - List all product tags
export const getAllTags = async (req, res) => {
    try {
        const tags = await Tag.findAll({
            order: [['name', 'ASC']]
        });
        
        success(res, tags, "Tags fetched successfully");
    } catch (error) {
        console.error(error);
        serverError(res, "Failed to fetch tags");
    }
};

// GET /api/tags/:id/products - Get products by tag
export const getProductsByTag = async (req, res) => {
    try {
        const { id } = req.params;

        // 1. Verify the tag exists
        const tag = await Tag.findByPk(id);
        if (!tag) return notFound(res, "Tag not found");

        // 2. Fetch products that have this specific tag
        const products = await Product.findAll({
            include: [
                {
                    // This is the crucial part: INNER JOIN on the Tag
                    model: Tag,
                    as: "tags",
                    where: { id: id }, // Only include products that have THIS tag
                    attributes: ['id', 'name'] // We don't need the whole tag object repeated
                },
                {
                    // Keep variants included so the frontend can display prices/images
                    model: ProductVariant,
                    as: "variants",
                    attributes: ["id", "variantName", "price", "discountPrice", "images", "status", "stock"]
                }
            ],
            order: [['createdAt', 'DESC']]
        });

        success(res, products, `Products with tag '${tag.name}' fetched successfully`);
    } catch (error) {
        console.error(error);
        serverError(res, "Failed to fetch products for this tag");
    }
};

// UPDATE an existing tag
export const updateTag = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, slug } = req.body;
        const [updatedRows] = await Tag.update({ name, slug }, { where: { id } });
        if (updatedRows === 0) return notFound(res, "Tag not found");
        const updatedTag = await Tag.findByPk(id);
        success(res, updatedTag, "Tag updated successfully");
    } catch (error) {
        serverError(res, "Failed to update tag");
    }
};

// DELETE a tag
export const deleteTag = async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await Tag.destroy({ where: { id } });
        if (!deleted) return notFound(res, "Tag not found");
        success(res, null, "Tag deleted successfully");
    } catch (error) {
        serverError(res, "Failed to delete tag");
    }
};