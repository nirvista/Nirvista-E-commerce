import { Op } from "sequelize";
import { Order, OrderItem, User, Product, VendorProfile } from "../models/association.js";
import { success, serverError } from "../utils/responseMessages.js";

export const getDashboardStats = async (req, res) => {
    try {
        // 1. Basic Counts
        const totalOrders = await Order.count();
        const totalCustomers = await User.count({ where: { userRole: 'customer' } });
        const totalVendors = await User.count({ where: { userRole: 'vendor' } });
        const activeUsers = await User.count({ where: { userStatus: 'active' } });

        // 2. Monthly Sales Chart (Current Year)
        const currentYear = new Date().getFullYear();
        const ordersThisYear = await Order.findAll({
            where: {
                createdAt: {
                    [Op.gte]: new Date(`${currentYear}-01-01T00:00:00.000Z`)
                },
                paymentStatus: 'paid'
            },
            attributes: ['createdAt', 'totalAmount']
        });

        // Initialize 12 months with 0 sales
        const monthlySales = Array.from({ length: 12 }, (_, i) => ({
            month: new Date(0, i).toLocaleString('default', { month: 'short' }),
            sales: 0
        }));

        ordersThisYear.forEach(order => {
            const monthIndex = new Date(order.createdAt).getMonth();
            monthlySales[monthIndex].sales += Number(order.totalAmount);
        });

        // 3. Top Products & Top Vendors (Aggregate via OrderItems)
        const allOrderItems = await OrderItem.findAll({
            include: [
                { model: Product, as: 'product', attributes: ['id', 'title'] },
                {
                    model: User,
                    as: 'vendor',
                    attributes: ['id', 'name', 'email'],
                    include: [{ model: VendorProfile, as: 'vendorProfile', attributes: ['storeName'] }]
                }
            ]
        });

        const productSales = {};
        const vendorSales = {};
        let totalRevenue = 0;

        allOrderItems.forEach(item => {
            const itemRevenue = item.quantity * Number(item.priceAtPurchase);
            totalRevenue += itemRevenue;

            // Aggregate Products
            if (item.product) {
                if (!productSales[item.productId]) {
                    productSales[item.productId] = {
                        id: item.product.id,
                        title: item.product.title,
                        totalSold: 0,
                        revenue: 0
                    };
                }
                productSales[item.productId].totalSold += item.quantity;
                productSales[item.productId].revenue += itemRevenue;
            }

            // Aggregate Vendors
            if (item.vendor) {
                if (!vendorSales[item.vendorId]) {
                    vendorSales[item.vendorId] = {
                        id: item.vendor.id,
                        name: item.vendor.name,
                        storeName: item.vendor.vendorProfile?.storeName || item.vendor.name,
                        email: item.vendor.email,
                        totalItemsSold: 0,
                        revenue: 0
                    };
                }
                vendorSales[item.vendorId].totalItemsSold += item.quantity;
                vendorSales[item.vendorId].revenue += itemRevenue;
            }
        });

        // Sort and limit to top 5
        const topProducts = Object.values(productSales)
            .sort((a, b) => b.totalSold - a.totalSold)
            .slice(0, 5);

        const topVendors = Object.values(vendorSales)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 5);

        success(res, {
            summary: {
                totalOrders,
                totalCustomers,
                totalVendors,
                activeUsers,
                totalRevenue
            },
            monthlySales,
            topProducts,
            topVendors
        }, "Dashboard stats fetched successfully");

    } catch (error) {
        console.error("[getDashboardStats] Error:", error);
        serverError(res, `Failed to fetch dashboard stats: ${error.message}`);
    }
};