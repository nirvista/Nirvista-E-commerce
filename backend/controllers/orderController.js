import sequelize from "../config/db.js";
import { Order, OrderItem, Cart, CartItem, UserAddress, Product, ProductVariant } from "../models/association.js"; // Adjust import based on your setup
import PDFDocument from "pdfkit";
import { success, serverError, notFound } from "../utils/responseMessages.js";

// POST /api/orders - Create new order from Cart
export const createOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const userId = req.user.id;
        const { addressId, paymentMethod } = req.body;

        if (!addressId) return res.status(400).json({ message: "Shipping address ID is required" });

        // 1. Fetch Cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) return res.status(400).json({ message: "Cart is empty" });

        const cartItems = await CartItem.findAll({ 
            where: { cartId: cart.id },
            include: [
                { model: Product, as: 'product' }, 
                { model: ProductVariant, as: 'variant' }]
        });

        if (cartItems.length === 0) return notFound(res, "Cart is empty");

        // 2. Calculate Total & Validate Stock
        let totalAmount = 0;
        const orderItemsData = [];

        for (const item of cartItems) {
            const product = item.product;
            const variant = item.variant;
            // Basic Stock Check (assuming stock is on the Product model)
            if (variant.stock < item.quantity) {
                await t.rollback();
                return serverError(res, `Insufficient stock for product variant: ${product.title} (${variant.variantName})`);
            }

            totalAmount += (variant.discountPrice * item.quantity);

            orderItemsData.push({
                productId: item.productId,
                variantId: item.variantId,
                quantity: item.quantity,
                priceAtPurchase: variant.discountPrice
            });

            // Deduct Stock
            variant.stock -= item.quantity;
            await variant.save({ transaction: t });
        }

        // 3. Create Order
        const order = await Order.create({
            userId,
            addressId,
            totalAmount,
            paymentMethod,
            paymentStatus: paymentMethod === 'COD' ? 'pending' : 'paid' 
        }, { transaction: t });

        // 4. Create Order Items
        const orderItemsWithOrderId = orderItemsData.map(item => ({ ...item, orderId: order.id }));
        await OrderItem.bulkCreate(orderItemsWithOrderId, { transaction: t });

        // 5. Clear the Cart
        await CartItem.destroy({ where: { cartId: cart.id }, transaction: t });

        // Commit transaction
        await t.commit();
        success(res, order, "Order created successfully");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to create order");
    }
};

// GET /api/orders - List user's orders (with filters)
export const getUserOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status } = req.query; // Optional filter

        const whereClause = { userId };
        if (status) whereClause.orderStatus = status;

        const orders = await Order.findAll({
            where: whereClause,
            order: [['createdAt', 'DESC']],
            include: [{ model: OrderItem, as: 'items' }, { model: UserAddress, as: 'shippingAddress' }]
        });

        success(res, orders, "Orders fetched successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch orders");
    }
};

// GET /api/orders/:id - Get order details
export const getOrderById = async (req, res) => {
    try {
        const userId = req.user.id;
        const order = await Order.findOne({
            where: { id: req.params.id, userId },
            include: [
                { model: UserAddress, as: 'shippingAddress' },
                { 
                    model: OrderItem, 
                    as: 'items',
                    include: [
                        { model: Product, as: 'product', attributes: ['title'] }, 
                        { model: ProductVariant, as: 'variant', attributes: ['variantName', 'discountPrice'] }]
                }
            ]
        });

        if (!order) return notFound(res, "Order not found");
        success(res, order, "Order fetched successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch order");
    }
};

// PUT /api/orders/:id/cancel - Cancel order
export const cancelOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const userId = req.user.id;
        const order = await Order.findOne({ 
            where: { id: req.params.id, userId },
            include: [{ model: OrderItem, as: 'items' }]
        });

        if (!order) return notFound(res, "Order not found");
        if (order.orderStatus === 'cancelled') {
            return serverError(res, "Order is already cancelled and cannot be changed.");
        }
        if (!['pending', 'processing'].includes(order.orderStatus)) {
            return serverError(res, "Cannot cancel this order at its current stage");
        }

        // Restore Stock
        for (const item of order.items) {
            const variant = await ProductVariant.findByPk(item.variantId);
            if (variant) {
                variant.stock += item.quantity;
                await variant.save({ transaction: t });
            }
        }

        order.orderStatus = 'cancelled';
        if (order.paymentStatus === 'paid') {
            order.paymentStatus = 'refund_initiated';
        }
        await order.save({ transaction: t });
        
        await t.commit();
        success(res, null, "Order cancelled successfully");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to cancel order");
    }
};

// POST /api/orders/:id/return - Initiate return request
export const initiateReturn = async (req, res) => {
    try {
        const userId = req.user.id;
        const order = await Order.findOne({ where: { id: req.params.id, userId } });

        if (!order) return notFound(res, "Order not found");
        if (order.orderStatus !== 'delivered') {
            return serverError(res, "Only delivered orders can be returned");
        }

        order.orderStatus = 'return_requested';
        await order.save();

        success(res, null, "Return request initiated");
    } catch (error) {
        serverError(res, error.message || "Failed to initiate return");
    }
};

// GET /api/orders/:id/invoice - Download order invoice
export const downloadInvoice = async (req, res) => {
    try {
        const userId = req.user.id;
        const order = await Order.findOne({
            where: { id: req.params.id, userId },
            include: [
                { model: UserAddress, as: 'shippingAddress' },
                { 
                    model: OrderItem, 
                    as: 'items',
                    include: [{ model: Product, as: 'product' }, { model: ProductVariant, as: 'variant' }]
                }
            ]
        });

        if (!order) return notFound(res, "Order not found");

        // Set Headers for PDF Download
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=invoice-${order.id}.pdf`);

        // Generate PDF
        const doc = new PDFDocument({ margin: 50 });
        doc.pipe(res); // Stream directly to the client

        // Build PDF Content
        doc.fontSize(20).text('INVOICE', { align: 'center' });
        doc.moveDown();
        doc.fontSize(12).text(`Order ID: ${order.id}`);
        doc.text(`Date: ${new Date(order.createdAt).toLocaleDateString()}`);
        doc.text(`Status: ${order.orderStatus.toUpperCase()}`);
        doc.moveDown();

        doc.text(`Shipping To: ${order.shippingAddress.addressLine1}, ${order.shippingAddress.addressLine2}, ${order.shippingAddress.city}, ${order.shippingAddress.state}, ${order.shippingAddress.postal_code}, ${order.shippingAddress.country}`);
        doc.moveDown();

        doc.text('Items:', { underline: true });
        order.items.forEach(item => {
            doc.text(`${item.product.title} (${item.variant.variantName}) - Qty: ${item.quantity} - $${item.priceAtPurchase}`);
        });

        doc.moveDown();
        doc.fontSize(16).text(`Total: $${order.totalAmount}`, { align: 'right' });

        doc.end();
    } catch (error) {
        serverError(res, error.message || "Failed to generate invoice");
    }
};

export const getOrderStatus = async (req, res) => {
    try {
        const order = await Order.findOne({
            where: { id: req.params.id },
            attributes: ['orderStatus', 'paymentStatus']
        });
        if (!order) return notFound(res, "Order not found");
        success(res, order, "Order status fetched successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch order status");
    }
};

export const updateOrderStatus = async (req, res) => {
    try {
        // You should add admin authentication/authorization check here
        const { status } = req.body;
        const allowedStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'return_requested', 'returned'];
        if (!allowedStatuses.includes(status)) {
            return res.status(400).json({ message: "Invalid status value" });
        }

        const order = await Order.findByPk(req.params.id);
        if (!order) return notFound(res, "Order not found");

        // Prevent status change if already cancelled
        if (order.orderStatus === 'cancelled') {
            return serverError(res, "Order is already cancelled and cannot be changed.");
        }

        order.orderStatus = status;

        // If admin cancels and payment was paid, initiate refund
        if (status === 'cancelled' && order.paymentStatus === 'paid') {
            order.paymentStatus = 'refund_initiated';
        }

        await order.save();
        success(res, order, "Order status updated successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to update order status");
    }
};