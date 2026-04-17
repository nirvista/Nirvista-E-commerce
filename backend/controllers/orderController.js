import Razorpay from "razorpay";
import crypto from "crypto";
import sequelize from "../config/db.js";
import { Order, OrderItem, Cart, CartItem, UserAddress, Product, ProductVariant } from "../models/association.js";
import User from "../models/userModel.js";
import VendorProfile from "../models/vendorProfileModel.js";
import PDFDocument from "pdfkit";
import { success, serverError, notFound } from "../utils/responseMessages.js";
import { Op } from "sequelize";

// --- Razorpay Setup ---
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

// --- Helper: Atomic Stock Reservation ---
async function reserveStock(variantId, quantity, t) {
    // Atomically increment reservedStock if enough available
    const [affectedRows] = await ProductVariant.update(
        { reservedStock: sequelize.literal(`"reservedStock" + ${quantity}`) },
        {
            where: {
                id: variantId,
                [Op.and]: sequelize.where(
                    sequelize.literal('"stock" - "reservedStock"'),
                    '>=',
                    quantity
                )
            },
            transaction: t
        }
    );
    return affectedRows === 1;
}

// --- Helper: Release Reserved Stock ---
async function releaseReservedStock(variantId, quantity, t) {
    await ProductVariant.update(
        { reservedStock: sequelize.literal(`"reservedStock" - ${quantity}`) },
        { where: { id: variantId }, transaction: t }
    );
}

// --- Helper: Deduct Reserved Stock (on payment success) ---
async function deductReservedStock(variantId, quantity, t) {
    await ProductVariant.update(
        {
            stock: sequelize.literal(`"stock" - ${quantity}`),
            reservedStock: sequelize.literal(`"reservedStock" - ${quantity}`)
        },
        { where: { id: variantId }, transaction: t }
    );
}

// --- Helper: Restore Stock (on return/cancel) ---
async function restoreStock(variantId, quantity, t) {
    await ProductVariant.update(
        { stock: sequelize.literal(`"stock" + ${quantity}`) },
        { where: { id: variantId }, transaction: t }
    );
}

// --- Create Order: Reserve Stock Atomically ---
export const createOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const userId = req.user.id;
        const { addressId, paymentMethod } = req.body;

        if (!addressId) {
            await t.rollback();
            return res.status(400).json({ message: "Shipping address ID is required" });
        }

        // 1. Fetch Cart
        const cart = await Cart.findOne({ where: { userId } });
        if (!cart) {
            await t.rollback();
            return res.status(400).json({ message: "Cart not found" });
        }

        const cartItems = await CartItem.findAll({
            where: { cartId: cart.id },
            include: [
                { model: Product, as: 'product' },
                { model: ProductVariant, as: 'variant' }
            ]
        });

        if (cartItems.length === 0) {
            await t.rollback();
            return notFound(res, "Cart is empty");
        }

        // 2. Reserve Stock Atomically
        let totalAmount = 0;
        const orderItemsData = [];
        const processedCartItemIds = [];
        for (const item of cartItems) {
            const variant = item.variant;
            const reserved = await reserveStock(variant.id, item.quantity, t);
            
            if (!reserved) {
                await t.rollback();
                return serverError(res, `Insufficient stock for: ${variant.variantName}`);
            }

            totalAmount += (Number(variant.discountPrice) * item.quantity);
            processedCartItemIds.push(item.id); 

            orderItemsData.push({
                productId: item.productId,
                variantId: item.variantId,
                quantity: item.quantity,
                priceAtPurchase: variant.discountPrice,
                vendorId: item.product.vendorId
            });
        }

        // 3. Create Order (status: reserved, paymentStatus: reserved)
        const order = await Order.create({
            userId,
            addressId,
            totalAmount,
            paymentMethod,
            orderStatus: 'reserved',
            paymentStatus: paymentMethod === 'cod' ? 'pending' : 'reserved'
        }, { transaction: t });

        // 4. Create Order Items
        await OrderItem.bulkCreate(orderItemsData.map(i => ({ ...i, orderId: order.id })), { transaction: t });

        // 5. Clear the Cart
        await CartItem.destroy({ 
            where: { id: { [Op.in]: processedCartItemIds } }, 
            transaction: t 
        });

        if (paymentMethod === "online") {
            const razorpayOrder = await razorpay.orders.create({
                amount: Math.round(Number(totalAmount) * 100), // in paise
                currency: "INR",
                receipt: order.id,
                payment_capture: 1
            });
            // Save razorpayOrderId to DB if you want (optional)
            order.razorpayOrderId = razorpayOrder.id;
            await order.save({ transaction: t });
            await t.commit();
            return res.json({
                success: true,
                order,
                razorpayOrder,
                message: "Order placed. Proceed to payment."
            });
        }

        if (paymentMethod === "cod") {
            for (const item of cartItems) {
                await deductReservedStock(item.variantId, item.quantity, t);
            }
            order.orderStatus = "processing";
            order.paymentStatus = "pending";
            await order.save({ transaction: t});
            await t.commit();
            return res.json({
                success: true,
                order,
                message: "Order placed with Cash on Delivery."
            });
        }
    } catch (error) {
        if (!t.finished) {
            await t.rollback();
        }
        serverError(res, error.message || "Failed to create order");
    }
};

// --- Razorpay Webhook Handler ---
export const razorpayWebhook = async (req, res) => {
    // Razorpay sends events to this endpoint
    // Set this route as POST /api/payment/webhook
    // In Razorpay dashboard, set the webhook secret (e.g., process.env.RAZORPAY_WEBHOOK_SECRET)
    try {
        const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
        const signature = req.headers["x-razorpay-signature"];
        const body = req.body.toString();

        // Verify HMAC
        const expectedSignature = crypto
            .createHmac("sha256", secret)
            .update(body)
            .digest("hex");

        if (signature !== expectedSignature) {
            return res.status(400).json({ message: "Invalid signature" });
        }

        // Handle payment event
        const event = req.body.event;
        const payload = req.body.payload;

        if (event === "payment.captured") {
            // Payment successful
            const razorpayOrderId = payload.payment.entity.order_id;
            const paymentId = payload.payment.entity.id;

            // Find order by razorpayOrderId
            const order = await Order.findOne({ where: { razorpayOrderId } });
            if (!order) return res.status(404).json({ message: "Order not found" });

            // Deduct reserved stock
            const t = await sequelize.transaction();
            try {
                const orderItems = await OrderItem.findAll({ where: { orderId: order.id }, transaction: t });
                for (const item of orderItems) {
                    await deductReservedStock(item.variantId, item.quantity, t);
                }
                order.paymentStatus = "paid";
                order.orderStatus = "confirmed";
                order.razorpayPaymentId = paymentId;
                await order.save({ transaction: t });
                await t.commit();

                // Optionally, generate and send invoice here
                // await generateAndSendInvoice(order);

                return res.json({ success: true, message: "Payment captured and order confirmed" });
            } catch (err) {
                await t.rollback();
                return res.status(500).json({ message: "Failed to update order after payment" });
            }
        } else if (event === "payment.failed") {
            // Payment failed, release reserved stock
            const razorpayOrderId = payload.payment.entity.order_id;
            const order = await Order.findOne({ where: { razorpayOrderId } });
            if (!order) return res.status(404).json({ message: "Order not found" });

            const t = await sequelize.transaction();
            try {
                const orderItems = await OrderItem.findAll({ where: { orderId: order.id }, transaction: t });
                for (const item of orderItems) {
                    await releaseReservedStock(item.variantId, item.quantity, t);
                }
                order.paymentStatus = "failed";
                order.orderStatus = "cancelled";
                await order.save({ transaction: t });
                await t.commit();
                return res.json({ success: true, message: "Payment failed, stock released" });
            } catch (err) {
                await t.rollback();
                return res.status(500).json({ message: "Failed to update order after payment failure" });
            }
        } else {
            // Ignore other events
            return res.json({ success: true, message: "Event ignored" });
        }
    } catch (error) {
        return res.status(500).json({ message: "Webhook error" });
    }
};

// --- Invoice Generation (can be called after payment confirmation) ---
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

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=invoice-${order.id}.pdf`);

        const doc = new PDFDocument({ margin: 50 });
        doc.pipe(res);

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

// --- Payment Success: Deduct Reserved Stock ---
export const confirmPayment = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { orderId } = req.body;
        const order = await Order.findByPk(orderId, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }
        if (order.paymentStatus === 'paid') {
            await t.rollback();
            return serverError(res, "Order already paid");
        }

        // Deduct reserved stock
        for (const item of order.items) {
            await deductReservedStock(item.variantId, item.quantity, t);
        }

        order.paymentStatus = 'paid';
        order.orderStatus = 'processing';
        await order.save({ transaction: t });

        await t.commit();
        success(res, order, "Payment confirmed, stock deducted");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to confirm payment");
    }
};

// --- Payment Failure: Release Reserved Stock ---
export const cancelPayment = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { orderId } = req.body;
        const order = await Order.findByPk(orderId, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }
        if (order.paymentStatus === 'failed') {
            await t.rollback();
            return serverError(res, "Order already marked as failed");
        }

        // Release reserved stock
        for (const item of order.items) {
            await releaseReservedStock(item.variantId, item.quantity, t);
        }

        order.paymentStatus = 'failed';
        order.orderStatus = 'cancelled';
        await order.save({ transaction: t });

        await t.commit();
        success(res, order, "Payment failed, reserved stock released");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to cancel payment");
    }
};

// --- Cancel Order (after payment): Restore Stock ---
export const cancelOrder = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const userId = req.user.id;
        const order = await Order.findOne({
            where: { id: req.params.id, userId },
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }
        if (order.orderStatus === 'cancelled') {
            await t.rollback();
            return serverError(res, "Order is already cancelled and cannot be changed.");
        }
        if (!['processing', 'shipped', 'delivered', 'return_requested', 'returned', 'reserved'].includes(order.orderStatus)) {
            await t.rollback();
            return serverError(res, "Cannot cancel this order at its current stage");
        }

        // Restore stock if already paid
        if (order.paymentStatus === 'paid') {
            for (const item of order.items) {
                await restoreStock(item.variantId, item.quantity, t);
            }
            order.paymentStatus = 'refund_initiated';
        } else if (order.paymentStatus === 'reserved') {
            // If only reserved, release reserved stock
            for (const item of order.items) {
                await releaseReservedStock(item.variantId, item.quantity, t);
            }
            order.paymentStatus = 'failed';
        }

        order.orderStatus = 'cancelled';
        await order.save({ transaction: t });

        await t.commit();
        success(res, null, "Order cancelled and stock restored/released");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to cancel order");
    }
};

// --- Return Order: Restore Stock ---
export const initiateReturn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const userId = req.user.id;
        const order = await Order.findOne({
            where: { id: req.params.id, userId },
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }
        if (order.orderStatus !== 'delivered') {
            await t.rollback();
            return serverError(res, "Only delivered orders can be returned");
        }

        // Mark as return requested
        order.orderStatus = 'return_requested';
        await order.save({ transaction: t });

        await t.commit();
        success(res, null, "Return request initiated");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to initiate return");
    }
};

// --- Admin: Approve Return (restore stock) ---
export const approveReturn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        // Admin endpoint
        const order = await Order.findByPk(req.params.id, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }
        if (order.orderStatus !== 'return_requested') {
            await t.rollback();
            return serverError(res, "Order is not in return requested state");
        }

        // Restore stock
        for (const item of order.items) {
            await restoreStock(item.variantId, item.quantity, t);
        }

        order.orderStatus = 'returned';
        order.paymentStatus = 'refund_initiated';
        await order.save({ transaction: t });

        await t.commit();
        success(res, order, "Return approved and stock restored");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to approve return");
    }
};

export const initiatePartialReturn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { orderId } = req.params;
        const { itemsToReturn } = req.body; // Array: [{ orderItemId: UUID, quantity: Number }]

        const order = await Order.findOne({
            where: { id: orderId, userId: req.user.id },
            transaction: t
        });

        if (!order || order.orderStatus !== 'delivered') {
            await t.rollback();
            return serverError(res, "Only delivered orders can be returned.");
        }

        for (const item of itemsToReturn) {
            const orderItem = await OrderItem.findOne({
                where: { id: item.orderItemId, orderId },
                transaction: t
            });

            if (!orderItem || item.quantity > orderItem.quantity) {
                await t.rollback();
                return serverError(res, "Invalid return quantity for item.");
            }

            orderItem.returnStatus = 'requested';
            orderItem.returnedQuantity = item.quantity;
            await orderItem.save({ transaction: t });
        }

        order.orderStatus = 'return_requested'; // Overall order status
        await order.save({ transaction: t });

        await t.commit();
        success(res, null, "Partial return request initiated.");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message);
    }
};

export const approvePartialReturn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { orderId, orderItemId } = req.params;
        const { approve } = req.body;

        const orderItem = await OrderItem.findOne({
            where: { id: orderItemId, orderId },
            include: [{ model: Order, as: 'order' }],
            transaction: t
        });

        if (!orderItem || orderItem.returnStatus !== 'requested') {
            await t.rollback();
            return notFound(res, "Return request not found.");
        }

        if (approve) {
            // Restore stock only for the quantity being returned
            await restoreStock(orderItem.variantId, orderItem.returnedQuantity, t);
            orderItem.returnStatus = 'completed';
            
            // Calculate partial refund amount
            const refundAmount = orderItem.priceAtPurchase * orderItem.returnedQuantity;
            // Trigger Razorpay partial refund logic here if integrated
        } else {
            orderItem.returnStatus = 'rejected';
        }

        await orderItem.save({ transaction: t });
        
        // Update overall order status if all items are processed
        const pendingReturns = await OrderItem.count({
            where: { orderId, returnStatus: 'requested' },
            transaction: t
        });

        if (pendingReturns === 0) {
            orderItem.order.orderStatus = 'returned'; // or 'partially_returned'
            await orderItem.order.save({ transaction: t });
        }

        await t.commit();
        success(res, null, `Return ${approve ? 'approved' : 'rejected'}.`);
    } catch (error) {
        await t.rollback();
        serverError(res, error.message);
    }
};

// --- Get User Orders ---
export const getUserOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status } = req.query;
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

// --- Get Order Details ---
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
                        { model: ProductVariant, as: 'variant', attributes: ['variantName', 'discountPrice', 'images'] }
                    ]
                }
            ]
        });

        if (!order) return notFound(res, "Order not found");
        success(res, order, "Order fetched successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch order");
    }
};

// --- Get Order Status ---
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

// --- Update Order Status (admin) ---
export const updateOrderStatus = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { status } = req.body;
        const order = await Order.findByPk(req.params.id, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }

        // Logic Check: If moving to 'cancelled', handle stock based on current paymentStatus
        if (status === 'cancelled' && order.orderStatus !== 'cancelled') {
            if (order.paymentStatus === 'paid') {
                for (const item of order.items) { await restoreStock(item.variantId, item.quantity, t); }
                order.paymentStatus = 'refund_initiated';
            } else if (order.paymentStatus === 'reserved') {
                // FIX: Release stock if it was only reserved but not yet paid/deducted
                for (const item of order.items) { await releaseReservedStock(item.variantId, item.quantity, t); }
                order.paymentStatus = 'failed';
            }
        }

        order.orderStatus = status;
        await order.save({ transaction: t });
        await t.commit();
        success(res, order, "Order status updated and stock managed.");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to update order status");
    }
};

// Admin API endpoints to view and manage all orders, including filtering, sorting, and detailed views with user and vendor info.

export const getAllOrdersAdmin = async (req, res) => {
    try {
        const { status, paymentStatus, sort } = req.query;
        const whereClause = {};
        
        if (status) whereClause.orderStatus = status;
        if (paymentStatus) whereClause.paymentStatus = paymentStatus;

        let orderClause = [['createdAt', 'DESC']];
        if (sort === 'oldest') orderClause = [['createdAt', 'ASC']];
        if (sort === 'amount_desc') orderClause = [['totalAmount', 'DESC']];
        if (sort === 'amount_asc') orderClause = [['totalAmount', 'ASC']];

        const { count, rows } = await Order.findAndCountAll({
            where: whereClause,
            order: orderClause,
            include: [
                { model: User, as: 'user', attributes: ['name', 'email'] },
                { 
                    model: OrderItem, 
                    as: 'items', 
                    attributes: ['id', 'quantity'],
                    // NEW: Include vendor and vendorProfile to populate the list view column
                    include: [
                        { 
                            model: User, 
                            as: 'vendor', 
                            attributes: ['id', 'name', 'email'],
                            include: [
                                { 
                                    model: VendorProfile, 
                                    as: 'vendorProfile', 
                                    attributes: ['storeName'] 
                                }
                            ]
                        }
                    ]
                }
            ],
            distinct: true
        });

        success(res, { orders: rows, total: count }, "All orders fetched for admin");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch all orders");
    }
};

export const getOrderByIdAdmin = async (req, res) => {
    try {
        const order = await Order.findByPk(req.params.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'name', 'email', 'phone'] },
                { model: UserAddress, as: 'shippingAddress' },
                {
                    model: OrderItem,
                    as: 'items',
                    include: [
                        { model: Product, as: 'product', attributes: ['id', 'title'] },
                        { model: ProductVariant, as: 'variant', attributes: ['id', 'variantName', 'sku', 'price', 'discountPrice'] },
                        { 
                            model: User, 
                            as: 'vendor', 
                            attributes: ['id', 'name', 'email', 'phone'],
                            include: [{ model: VendorProfile, as: 'vendorProfile', attributes: ['storeName', 'businessPhone'] }]
                        }
                    ]
                }
            ]
        });

        if (!order) return notFound(res, "Order not found");
        success(res, order, "Order fetched successfully");
    } catch (error) {
        serverError(res, error.message || "Failed to fetch order details");
    }
};

export const updateOrderAdmin = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { orderStatus, paymentStatus } = req.body;
        const order = await Order.findByPk(req.params.id, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t
        });

        if (!order) {
            await t.rollback();
            return notFound(res, "Order not found");
        }

        // Handles Stock Logic seamlessly when updating statuses
        if (orderStatus && orderStatus !== order.orderStatus) {
            if (orderStatus === 'cancelled' && order.orderStatus !== 'cancelled') {
                if (order.paymentStatus === 'paid') {
                    for (const item of order.items) { await restoreStock(item.variantId, item.quantity, t); }
                    if(!paymentStatus) order.paymentStatus = 'refund_initiated';
                } else if (order.paymentStatus === 'reserved') {
                    for (const item of order.items) { await releaseReservedStock(item.variantId, item.quantity, t); }
                    if(!paymentStatus) order.paymentStatus = 'failed';
                }
            }
            order.orderStatus = orderStatus;
        }

        if (paymentStatus && paymentStatus !== order.paymentStatus) {
            order.paymentStatus = paymentStatus;
        }

        await order.save({ transaction: t });
        await t.commit();
        success(res, order, "Order updated successfully");
    } catch (error) {
        await t.rollback();
        serverError(res, error.message || "Failed to update order");
    }
};
