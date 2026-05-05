// controllers/categoryController.js
import Category from "../models/categoryModel.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { created, notFound, serverError, success } from "../utils/responseMessages.js";

const variantInclude = {
    model: ProductVariant,
    as: "variants",
    attributes: [
        "id", "variantName", "price", "size", "color", 
        "discountPrice", "images", "status", "stock"
    ],
    where: { approvalStatus: 'approved' },

};

// List all categories (Tree Structure)
export const getAllCategories = async (req, res) => {
    try {
        // Fetch all categories as flat plain objects
        const categories = await Category.findAll({ raw: true });

        // Helper function to recursively build the tree
        const buildTree = (cats, parentId = null) => {
            return cats
                .filter(cat => cat.parentId === parentId)
                .map(cat => ({
                    ...cat,
                    children: buildTree(cats, cat.id)
                }));
        };

        const categoryTree = buildTree(categories);
        success(res, categoryTree, "Categories fetched successfully");
    } catch (error) {
        console.error(error);
        serverError(res, "Failed to fetch categories");
    }
};

// Get category details
export const getCategoryById = async (req, res) => {
    try {
        const category = await Category.findByPk(req.params.id, {
            include: [{ model: Category, as: 'children' }] // Pull immediate sub-categories
        });
        if (!category) return notFound(res, "Category not found");
        
        success(res, category, "Category details fetched");
    } catch (error) {
        serverError(res, "Failed to fetch category");
    }
};

// Get products by category
export const getProductsByCategory = async (req, res) => {
    try {
        const { id } = req.params;
        
        // Check if category exists
        const category = await Category.findByPk(id);
        if (!category) return notFound(res, "Category not found");

        // Fetch products that belong to this category
        const products = await Product.findAll({
            where: { categoryId: id },
            include: [ variantInclude],
        });

        success(res, products, `Products for category ${category.name} fetched`);
    } catch (error) {
        serverError(res, "Failed to fetch products for category");
    }
};

// Create category (admin)
export const createCategory = async (req, res) => {
    try {
        // req.body should include { name, slug, description, parentId (optional) }
        const category = await Category.create(req.body);
        created(res, category, "Category created successfully");
    } catch (error) {
        console.error(error);
        serverError(res, "Failed to create category");
    }
};

// Update category (admin)
export const updateCategory = async (req, res) => {
    try {
        const [updatedRows] = await Category.update(req.body, {
            where: { id: req.params.id }
        });

        if (updatedRows === 0) return notFound(res, "Category not found");

        const updatedCategory = await Category.findByPk(req.params.id);
        success(res, updatedCategory, "Category updated successfully");
    } catch (error) {
        serverError(res, "Failed to update category");
    }
};

// Delete category (admin)
export const deleteCategory = async (req, res) => {
    try {
        const deleted = await Category.destroy({
            where: { id: req.params.id }
        });

        if (!deleted) return notFound(res, "Category not found");
        success(res, null, "Category deleted successfully");
    } catch (error) {
        serverError(res, "Failed to delete category");
    }
};