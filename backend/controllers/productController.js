import { Op } from "sequelize";
import Product from "../models/productModel.js";
import { created, notFound, serverError } from "../utils/responseMessages.js";

//Create a new product
export const createProduct = async (req, res) => {
    try {
        const product = await Product.create(req.body);
        created(res, product, "Product created successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
}

// Get a single product by ID
export const getProductById = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) return notFound(res, "Product not found");
        created(res, product, "Product fetched successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
}


// Get all products
export const getAllProducts = async (req, res) => {
    try {
        const {search, category} = req.query;
        let filter = {};
        if (search) {
            filter.title = { [Op.iLike]: `%${search}%` };
        }
        if (category) {
            filter.category = category;
        }
        const getProducts = await Product.findAll({ where: filter, order: [['createdAt', 'DESC']] });
        created(res, getProducts, "Products fetched successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
}

// Update a product
export const updateProduct = async (req, res) => {
    try {
        const updatedProduct = await Product.update(req.body, {where: {id: req.params.id}}, {new: true});
        if (!updatedProduct) return notFound(res, "Product not found");
        created(res, updatedProduct, "Product updated successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
}

// Delete a product
export const deleteProduct = async (req, res) => {
    try {
        const deletedProduct = await Product.destroy({where: {id: req.params.id}});
        if (!deletedProduct) return notFound(res, "Product not found");
        created(res, deletedProduct, "Product deleted successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
}