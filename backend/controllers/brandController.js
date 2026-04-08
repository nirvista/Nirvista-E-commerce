import Brand from "../models/brandModel.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { created, success, notFound, serverError } from "../utils/responseMessages.js";

// POST /api/brands/ - Add a new brand
export const createBrand = async (req, res) => {
    try {
        const { name, description, logoUrl } = req.body;
        const brand = await Brand.create({ name, description, logoUrl });
        created(res, brand, "Brand created successfully");
    } catch (error) {
        serverError(res, "Failed to create brand");
    }
};

// GET /api/brands/ - Get all brands
export const getAllBrands = async (req, res) => {
    try {
        const brands = await Brand.findAll({ order: [['name', 'ASC']] });
        success(res, brands, "Brands fetched successfully");
    } catch (error) {
        serverError(res, "Failed to fetch brands");
    }
};

// GET /api/brands/:brandId - Get brand by brandId
export const getBrandById = async (req, res) => {
    try {
        const { brandId } = req.params;
        const brand = await Brand.findByPk(brandId);
        if (!brand) return notFound(res, "Brand not found");
        success(res, brand, "Brand fetched successfully");
    } catch (error) {
        serverError(res, "Failed to fetch brand");
    }
};

// GET /api/brands/:brandId/products - Get all products along with variants by brand
export const getProductsByBrand = async (req, res) => {
    try {
        const { brandId } = req.params;
        const products = await Product.findAll({
            where: { brandId },
            include: [
                {
                    model: ProductVariant,
                    as: "variants"
                }
            ],
            order: [['createdAt', 'DESC']]
        });
        success(res, products, "Products for brand fetched successfully");
    } catch (error) {
        serverError(res, "Failed to fetch products for brand");
    }
};

// PUT /api/brands/:brandId - Update existing brand
export const updateBrand = async (req, res) => {
    try {
        const { brandId } = req.params;
        const { name, description, logoUrl } = req.body;
        const [updatedRows] = await Brand.update(
            { name, description, logoUrl },
            { where: { id: brandId } }
        );
        if (updatedRows === 0) return notFound(res, "Brand not found");
        const updatedBrand = await Brand.findByPk(brandId);
        success(res, updatedBrand, "Brand updated successfully");
    } catch (error) {
        serverError(res, "Failed to update brand");
    }
};

// DELETE /api/brands/:brandId - Delete an existing brand
export const deleteBrand = async (req, res) => {
    try {
        const { brandId } = req.params;
        const deleted = await Brand.destroy({ where: { id: brandId } });
        if (!deleted) return notFound(res, "Brand not found");
        success(res, null, "Brand deleted successfully");
    } catch (error) {
        serverError(res, "Failed to delete brand");
    }
};