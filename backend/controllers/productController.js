import { Op, Sequelize } from "sequelize";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import Tag from "../models/tagModel.js";
import { created, notFound, serverError, success } from "../utils/responseMessages.js";

const variantInclude = {
    model: ProductVariant,
    as: "variants",
    attributes: [
        "id", "variantName", "price", "size", "color", 
        "discountPrice", "images", "status", "stock"
    ]
};

const tagInclude = {
    model: Tag,
    as: "tags",
    attributes: ["id", "name", "slug"],
    through: { attributes: [] } 
};


// Helper to build separated filter objects
function buildFilters(query) {
    const productFilter = {};
    const variantFilter = {};

    // 1. Product Filters
    if (query.search) productFilter.title = { [Op.iLike]: `%${query.search}%` };
    
    const multiSelectFields = ['categoryId', 'brandId', 'material'];
    multiSelectFields.forEach(field => {
        if (query[field]) {
            productFilter[field] = Array.isArray(query[field]) ? { [Op.in]: query[field] } : query[field];
        }
    });

    if (query.minRating) productFilter.rating = { [Op.gte]: Number(query.minRating) };

    // 2. Variant Filters (Fields that moved to the variant table)
    if (query.minPrice || query.maxPrice) {
        variantFilter.price = {};
        if (query.minPrice) variantFilter.price[Op.gte] = Number(query.minPrice);
        if (query.maxPrice) variantFilter.price[Op.lte] = Number(query.maxPrice);
    }
    
    if (query.color) variantFilter.color = Array.isArray(query.color) ? { [Op.in]: query.color } : query.color;
    if (query.size) variantFilter.size = Array.isArray(query.size) ? { [Op.in]: query.size } : query.size;

    return { productFilter, variantFilter };
}

// Sorting helper updated for One-To-Many
function getSortOrder(sort) {
    switch (sort) {
        case "price_asc":
            return [[{ model: ProductVariant, as: 'variants' }, "price", "ASC"]];
        case "price_desc":
            return [[{ model: ProductVariant, as: 'variants' }, "price", "DESC"]];
        case "rating_desc":
            return [["rating", "DESC"]]; // Rating is still on Product
        case "discount_desc":
            return [[{ model: ProductVariant, as: 'variants' }, "discountPrice", "DESC"]];
        default:
            return [["createdAt", "DESC"]];
    }
}

//Create a new product
export const createProduct = async (req, res) => {
    try {
        const product = await Product.create(req.body, {
            include: [{ model: ProductVariant, as: 'variants' }] // Allows creating base product + first variant in one payload
        });
        if (req.body.tagIds && req.body.tagIds.length > 0) {
            await product.setTags(req.body.tagIds);
        }
        created(res, product, "Product created successfully");
    } catch (error) {
        console.error(error);
        serverError(res, "Server error");
    }
}

// Get a single product by ID
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
}


// // Helper to build filter object
// function buildProductFilters(query) {
//     const filter = {};

//     if (query.search) filter.title = { [Op.iLike]: `%${query.search}%` };

//     const multiSelectFields = ['category', 'brand', 'material'];
//     multiSelectFields.forEach(field => {
//         if (query[field]) {
//             filter[field] = Array.isArray(query[field]) ? { [Op.in]: query[field] } : query[field];
//         }
//     });

//     if (query.minPrice || query.maxPrice) {
//         filter.price = {};
//         if (query.minPrice) filter.price[Op.gte] = Number(query.minPrice);
//         if (query.maxPrice) filter.price[Op.lte] = Number(query.maxPrice);
//     }

//     if (query.minRating) filter.rating = { [Op.gte]: Number(query.minRating) };
//     if (query.minDiscount) filter.discount = { [Op.gte]: Number(query.minDiscount) };

//     return filter;
// }

// // Sorting helper
// function getSortOrder(sort) {
//     switch (sort) {
//         case "price_asc":
//             return [["price", "ASC"]];
//         case "price_desc":
//             return [["price", "DESC"]];
//         case "rating_desc":
//             return [["rating", "DESC"]];
//         case "discount_desc":
//             return [["discount", "DESC"]];
//         // Add more as needed
//         default:
//             return [["createdAt", "DESC"]]; // Relevance/Featured
//     }
// }

// Get All Products with filtering, sorting
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
                    ...variantInclude,
                    // If variant filters exist, this acts as an INNER JOIN, 
                    // only returning products that have variants matching the filter
                    where: Object.keys(variantFilter).length > 0 ? variantFilter : undefined, 
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

// Update a product
export const updateProduct = async (req, res) => {
    try {
        const [updatedRows] = await Product.update(req.body, {
            where: { id: req.params.id }
        });

        const product = await Product.findByPk(req.params.id);
        if (!product) return notFound(res, "Product not found");

        // MAGIC METHOD: Update tags if provided
        if (req.body.tagIds) {
            await product.setTags(req.body.tagIds); // This completely overwrites the old tags
        }

        const updatedProduct = await Product.findByPk(req.params.id, {
            include: [variantInclude, tagInclude]
        });
        success(res, updatedProduct, "Product updated successfully");
    } catch (error) {
        serverError(res, "Server error");
    }
};

// Delete a product
export const deleteProduct = async (req, res) => {
    try {
        const deletedProduct = await Product.destroy({where: {id: req.params.id}});
        if (!deletedProduct) return notFound(res, "Product not found");
        success(res, null, "Product deleted successfully"); // Usually better to return null on delete
    } catch (error) {
        serverError(res, "Server error");
    }
};

// Search products by keyword
export const searchProducts = async (req, res) => {
    try {
        const {keyword} = req.query;
        const products = await Product.findAll({
            where: {
                [Op.or]: [
                    { title: { [Op.iLike]: `%${keyword}%` } },
                    { description: { [Op.iLike]: `%${keyword}%` } }
                ]
            },
            include: [variantInclude, tagInclude],
            limit: 30
        })
        success(res, products, "Search results fetched successfully");
    } catch (error) {
        serverError(res, "Search Failed");
    }
}

// Get New Arrivals
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

// Get Top Rated Products
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
}

// Get Related Products by Category and Brand
export const getRelatedProducts = async (req, res) => {
    try {
        const currentProduct = await Product.findByPk(req.params.id, {
            attributes: ['id', 'categoryId', 'brandId'] 
        });

        if (!currentProduct) return notFound(res, "Product not found");

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
                            WHEN "brand" = '${currentProduct.brandId}' AND "category" = '${currentProduct.categoryId}' THEN 1 
                            WHEN "category" = '${currentProduct.categoryId}' THEN 2
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

//------------Variant Specific Controllers-------------

// Get all Product Variants for a Product
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

// Create a new variant for a product
export const addVariant = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) return notFound(res, "Parent product not found");

        const variant = await ProductVariant.create({
            ...req.body,
            productId: req.params.id
        });
        created(res, variant, "Variant added successfully");
    } catch (error) {
        serverError(res, "Failed to add variant");
    }
};

// Update a product variant
export const updateVariant = async (req, res) => {
    try {
        const [updatedRows] = await ProductVariant.update(req.body, {
            where: { 
                id: req.params.variantId,
                productId: req.params.id 
            }
        });

        if (updatedRows === 0) return notFound(res, "Variant not found");
        
        const updated = await ProductVariant.findByPk(req.params.variantId);
        success(res, updated, "Variant updated successfully");
    } catch (error) {
        serverError(res, "Update failed");
    }
};

// Delete a product variant
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