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

  @override
  void initState() {
    super.initState();
    // Get the order model passed from the previous screen
    OrderModel? initialOrder = Get.arguments as OrderModel?;
    if (initialOrder != null) {
      orderId = initialOrder.id;
    }
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
        orderController.updateOrderStatusLocally(currentOrder.id, 'canceled');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to cancel order'), backgroundColor: Colors.red)
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
          
          if (currentOrder == null) {
            return Center(child: getCustomFont("Order not found", 18, getFontColor(context), 1));
          }

          String dateStr = '';
          if (currentOrder.createdAt.isNotEmpty) {
            try {
              final dt = DateTime.parse(currentOrder.createdAt);
              dateStr = "${dt.day} ${_monthName(dt.month)}, ${dt.year}";
            } catch (_) { dateStr = currentOrder.createdAt; }
          }

          bool canCancel = currentOrder.orderStatus.toLowerCase() == 'pending' || currentOrder.orderStatus.toLowerCase() == 'processing';

          return Column(
            children: [
              getDefaultHeader(context, "Order Detail", () { backClick(context); }, isShowSearch: false),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHeaderInfo(context, margin, dateStr, currentOrder),
                    _buildCustomerInfo(context, currentOrder),
                    getVerSpace(20.h),
                    _buildOrderItems(context, currentOrder),
                    getVerSpace(20.h),
                    _buildPriceSummary(context, margin, currentOrder),
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
                        ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, 
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
