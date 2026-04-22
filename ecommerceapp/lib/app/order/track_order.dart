import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import '../../base/color_data.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../services/order_api.dart';
import '../../base/get/order_controller.dart';

class TrackOrder extends StatefulWidget {
  const TrackOrder({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TrackOrder();
  }
}

class _TrackOrder extends State<TrackOrder> {
  backClick(BuildContext context) {
    Constant.backToPrev(context);
  }

  OrderModel? order;
  final loginController = Get.find<LoginDataController>();
  final orderController = Get.find<GlobalOrderController>();
  late String orderId;

  final Rx<OrderModel?> detailedOrder = Rx<OrderModel?>(null);
  final RxBool isLoadingDetails = true.obs;

  @override
  void initState() {
    super.initState();
    // Get the order model passed from the previous screen
    OrderModel? initialOrder = Get.arguments as OrderModel?;
    if (initialOrder != null) {
      orderId = initialOrder.id;
      _fetchOrderDetails();
    }
  }

  Future<void> _fetchOrderDetails() async {
    final token = loginController.accessToken ?? '';
    final res = await OrderApiService.getOrderById(token, orderId);
    if (res['success'] && res['data'] != null) {
      detailedOrder.value = OrderModel.fromJson(res['data']);
    }
    isLoadingDetails.value = false;
  }

  Future<void> _handleCancelOrder() async {
    final currentOrder = orderController.userOrders.firstWhereOrNull((o) => o.id == orderId);
    if (currentOrder == null) return;
    
    final token = loginController.accessToken ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await OrderApiService.cancelOrder(token, currentOrder.id);
      Navigator.pop(context); // hide loading

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Canceled successfully'), backgroundColor: Colors.green)
        );
        // Sync with global order list
        orderController.updateOrderStatusLocally(currentOrder.id, 'cancelled');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to cancel order'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleReturnOrder() async {
    final token = loginController.accessToken ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await OrderApiService.initiateReturn(token, orderId);
      Navigator.pop(context); // hide loading

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return request initiated successfully'), backgroundColor: Colors.green)
        );
        // Update local status if necessary
        orderController.updateOrderStatusLocally(orderId, 'return_initiated');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to initiate return'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return WillPopScope(
      onWillPop: () async {
        backClick(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: Obx(() {
          // ── Reactive: picks the order from the controller's list ──
          final currentOrder = orderController.userOrders.firstWhereOrNull((o) => o.id == orderId);
          
          if (currentOrder == null && detailedOrder.value == null) {
            return Center(child: getCustomFont("Order not found", 18, getFontColor(context), 1));
          }

          if (isLoadingDetails.value) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          // Use detailedOrder if available to show full product info; fallback to currentOrder
          final displayOrder = detailedOrder.value ?? currentOrder!;
          
          // However, we want to maintain the reactive status from currentOrder
          if (currentOrder != null) {
            displayOrder.orderStatus = currentOrder.orderStatus;
          }

          String dateStr = '';
          if (displayOrder.createdAt.isNotEmpty) {
            try {
              final dt = DateTime.parse(displayOrder.createdAt);
              dateStr = "${dt.day} ${_monthName(dt.month)}, ${dt.year}";
            } catch (_) { dateStr = displayOrder.createdAt; }
          }

          final status = displayOrder.orderStatus.toLowerCase();
          bool canCancel = ['pending', 'processing', 'shipped', 'out_for_delivery', 'confirmed', 'reserved'].contains(status);
          bool isDelivered = status == 'delivered';
          
          bool canReturn = false;
          if (isDelivered) {
            try {
              final dt = DateTime.parse(displayOrder.createdAt);
              final now = DateTime.now();
              if (now.difference(dt).inDays <= 7) {
                canReturn = true;
              }
            } catch (_) {}
          }

          return Column(
            children: [
              getDefaultHeader(context, "Order Detail", () { backClick(context); }, isShowSearch: false),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildOrderStatusStepper(context, displayOrder),
                    getVerSpace(20.h),
                    _buildCustomerInfo(context, displayOrder),
                    getVerSpace(20.h),
                    _buildOrderItems(context, displayOrder),
                    getVerSpace(20.h),
                    _buildPriceSummary(context, margin, displayOrder),
                    if (canCancel) ...[
                      getVerSpace(20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: margin),
                        child: getButtonFigma(context, Colors.red, true, "Cancel Order", Colors.white, () {
                          showGetDeleteDialog(
                            context, 
                            "Are you sure you want to cancel this order?", 
                            "Cancel Order", 
                            () { _handleCancelOrder(); },
                            withCancelBtn: true,
                            btnTextCancel: "No, Keep it",
                            functionCancel: () {}
                          );
                        }, EdgeInsets.zero),
                      ),
                    ],
                    if (canReturn) ...[
                      getVerSpace(20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: margin),
                        child: getButtonFigma(context, accentColor, true, "Return Product", Colors.white, () {
                          showGetDeleteDialog(
                            context, 
                            "Are you sure you want to return this product? You can return it within 1 week of delivery.", 
                            "Return Product", 
                            () { _handleReturnOrder(); },
                            withCancelBtn: true,
                            btnTextCancel: "No, Cancel",
                            functionCancel: () {}
                          );
                        }, EdgeInsets.zero),
                      ),
                    ],
                    if (isDelivered) ...[
                      getVerSpace(20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: margin),
                        child: getButtonFigma(context, Colors.blueGrey, true, "Download Invoice", Colors.white, () {
                          OrderApiService.downloadInvoice(loginController.accessToken ?? '', displayOrder.id);
                        }, EdgeInsets.zero),
                      ),
                    ],
                    getVerSpace(40.h),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  int _getStepIndex(String status) {
    status = status.toLowerCase();
    if (status == 'delivered') return 3;
    if (status == 'shipped') return 1;
    // We can add 'out_for_delivery' if backend supports it later
    if (status == 'confirmed' || status == 'processing' || status == 'reserved') return 0;
    return 0;
  }

  String _getStatusDescription(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'processing':
      case 'confirmed':
      case 'reserved':
        return "Your order has been placed and is being processed.";
      case 'shipped':
        return "Package has been shipped and is on its way.";
      case 'delivered':
        return "Package has been delivered successfully.";
      case 'cancelled':
        return "This order has been cancelled.";
      default:
        return "Status: $status";
    }
  }

  Widget _buildOrderStatusStepper(BuildContext context, OrderModel order) {
    int currentStep = _getStepIndex(order.orderStatus);
    bool isCancelled = order.orderStatus.toLowerCase() == 'cancelled';
    Color activeColor = isCancelled ? Colors.red : accentColor;
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return Container(
      color: getCardColor(context),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 24.h),
      child: Column(
        children: [
          getCustomFont(
            order.orderStatus.capitalizeFirst ?? order.orderStatus,
            24,
            isCancelled ? Colors.red : getFontColor(context),
            1,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
          ),
          getVerSpace(8.h),
          getMultilineCustomFont(
            _getStatusDescription(order.orderStatus),
            14,
            getFontGreyColor(context),
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.center,
          ),
          getVerSpace(30.h),
          if (!isCancelled) ...[
            Row(
              children: [
                _buildStepCircle(0, currentStep, activeColor),
                _buildStepLine(0, currentStep, activeColor),
                _buildStepCircle(1, currentStep, activeColor),
                _buildStepLine(1, currentStep, activeColor),
                _buildStepCircle(2, currentStep, activeColor),
                _buildStepLine(2, currentStep, activeColor),
                _buildStepCircle(3, currentStep, activeColor),
              ],
            ),
            getVerSpace(12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepLabel("Ordered", 0, currentStep, context),
                _buildStepLabel("Shipped", 1, currentStep, context),
                _buildStepLabel("Out for delivery", 2, currentStep, context, textAlign: TextAlign.center),
                _buildStepLabel("Delivered", 3, currentStep, context, textAlign: TextAlign.right),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, int currentStep, Color activeColor) {
    bool isCompleted = index <= currentStep;
    return Container(
      width: 24.h,
      height: 24.h,
      decoration: BoxDecoration(
        color: isCompleted ? activeColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? activeColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: isCompleted
          ? Icon(Icons.check, color: Colors.white, size: 14.h)
          : null,
    );
  }

  Widget _buildStepLine(int index, int currentStep, Color activeColor) {
    bool isCompleted = index < currentStep;
    return Expanded(
      child: Container(
        height: 4.h,
        color: isCompleted ? activeColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepLabel(String label, int index, int currentStep, BuildContext context, {TextAlign textAlign = TextAlign.left}) {
    bool isActive = index == currentStep;
    bool isCompleted = index <= currentStep;
    
    return Expanded(
      child: getCustomFont(
        label,
        12,
        isActive ? getFontColor(context) : getFontGreyColor(context),
        2,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, double margin, String dateStr, OrderModel order) {
    return Padding(
      padding: EdgeInsets.all(margin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              getCustomFont("Order ID: ", 16, getFontColor(context), 1, fontWeight: FontWeight.w400),
              getCustomFont(order.id.length > 8 ? order.id.substring(0, 8) : order.id, 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
            ],
          ),
          getCustomFont(dateStr, 14, getFontGreyColor(context), 1, fontWeight: FontWeight.w400),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, OrderModel order) {
    final user = loginController.currentUser.value;
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Shipping Details", 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
          getVerSpace(16.h),
          Row(
            children: [
              getAssetImage(context, "dummy_profile.png", 50.h, 50.h),
              getHorSpace(12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getCustomFont(user?.name ?? "Customer", 16, getFontColor(context), 1, fontWeight: FontWeight.w500),
                    getVerSpace(4.h),
                    getCustomFont(user?.email ?? "", 14, getFontGreyColor(context), 1),
                  ],
                ),
              ),
            ],
          ),
          getVerSpace(20.h),
          getDivider(setColor: Colors.grey.shade200),
          getVerSpace(15.h),
          getCustomFont("Shipping Address", 14, getFontGreyColor(context), 1, fontWeight: FontWeight.w600),
          getVerSpace(6.h),
          getMultilineCustomFont(order.shippingAddress ?? "No address details", 14, getFontColor(context), fontWeight: FontWeight.w400),
          getVerSpace(16.h),
          Row(
            children: [
              getCustomFont("Status: ", 14, getFontGreyColor(context), 1),
              getCustomFont(order.orderStatus, 14, Constant.getOrderStatusColor(order.orderStatus), 1, fontWeight: FontWeight.w600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, OrderModel order) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Items (${order.items.length})", 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
          getVerSpace(12.h),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: order.items.length,
            separatorBuilder: (ctx, i) => getDivider(setColor: Colors.grey.shade200).marginSymmetric(vertical: 12.h),
            itemBuilder: (ctx, i) {
              final item = order.items[i];
              String img = item.displayImage;
              String title = (item.product?.title.isNotEmpty == true) ? item.product!.title : "Product ID: ${item.productId.length > 5 ? item.productId.substring(0, 5) : item.productId}";
              
              return Row(
                children: [
                  Container(
                    width: 60.h,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: getGreyCardColor(context),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.w),
                      child: img.isNotEmpty 
                        ? CachedNetworkImage(imageUrl: img, fit: BoxFit.contain, 
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported))
                        : const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                  getHorSpace(12.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getCustomFont(title, 14, getFontColor(context), 1, fontWeight: FontWeight.w500),
                        getVerSpace(4.h),
                        getCustomFont("Qty: ${item.quantity}", 12, getFontGreyColor(context), 1),
                        if (item.variant?.variantName != null) 
                          getCustomFont("Variant: ${item.variant!.variantName}", 12, getFontGreyColor(context), 1),
                      ],
                    ),
                  ),
                  getCustomFont("\u20B9${item.priceAtPurchase.toStringAsFixed(0)}", 14, getAccentColor(context), 1, fontWeight: FontWeight.w700),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context, double margin, OrderModel order) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      child: Column(
        children: [
          buildSubtotalRow(context, "Item Total", "\u20B9${order.totalAmount.toStringAsFixed(0)}"),
          getVerSpace(12.h),
          buildSubtotalRow(context, "Tax", "\u20B90"),
          getVerSpace(12.h),
          buildSubtotalRow(context, "Shipping", "Free"),
          getDivider(setColor: Colors.grey.shade200).marginSymmetric(vertical: 16.h),
          buildTotalRow(context, "Total Paid", "\u20B9${order.totalAmount.toStringAsFixed(0)}"),
        ],
      ),
    );
  }
}
