import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Get the order model passed from the previous screen
    order = Get.arguments as OrderModel?;
  }

  Future<void> _handleCancelOrder() async {
    if (order == null) return;
    
    final token = loginController.accessToken ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await OrderApiService.cancelOrder(token, order!.id);
      Navigator.pop(context); // hide loading

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Canceled successfully'), backgroundColor: Colors.green)
        );
        setState(() {
          order!.orderStatus = 'canceled';
        });
        // Sync with global order list
        try {
          final orderController = Get.find<GlobalOrderController>();
          orderController.updateOrderStatusLocally(order!.id, 'canceled');
        } catch (_) {}
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

    if (order == null) {
      return Scaffold(
        body: Center(child: getCustomFont("Order not found", 18, getFontColor(context), 1)),
      );
    }

    String dateStr = '';
    if (order!.createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(order!.createdAt);
        dateStr = "${dt.day} ${_monthName(dt.month)}, ${dt.year}";
      } catch (_) { dateStr = order!.createdAt; }
    }

    bool canCancel = order!.orderStatus.toLowerCase() == 'pending' || order!.orderStatus.toLowerCase() == 'processing';

    return WillPopScope(
      onWillPop: () async {
        backClick(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: Column(
          children: [
            getDefaultHeader(context, "Order Detail", () { backClick(context); }, isShowSearch: false),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeaderInfo(context, margin, dateStr),
                  _buildCustomerInfo(context),
                  getVerSpace(20.h),
                  _buildOrderItems(context),
                  getVerSpace(20.h),
                  _buildPriceSummary(context, margin),
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
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildHeaderInfo(BuildContext context, double margin, String dateStr) {
    return Padding(
      padding: EdgeInsets.all(margin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              getCustomFont("Order ID: ", 16, getFontColor(context), 1, fontWeight: FontWeight.w400),
              getCustomFont(order!.id.length > 8 ? order!.id.substring(0, 8) : order!.id, 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
            ],
          ),
          getCustomFont(dateStr, 14, getFontGreyColor(context), 1, fontWeight: FontWeight.w400),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
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
          getMultilineCustomFont(order!.shippingAddress ?? "No address details", 14, getFontColor(context), fontWeight: FontWeight.w400),
          getVerSpace(16.h),
          Row(
            children: [
              getCustomFont("Status: ", 14, getFontGreyColor(context), 1),
              getCustomFont(order!.orderStatus, 14, Constant.getOrderStatusColor(order!.orderStatus), 1, fontWeight: FontWeight.w600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Items (${order!.items.length})", 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
          getVerSpace(12.h),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: order!.items.length,
            separatorBuilder: (ctx, i) => getDivider(setColor: Colors.grey.shade200).marginSymmetric(vertical: 12.h),
            itemBuilder: (ctx, i) {
              final item = order!.items[i];
              return Row(
                children: [
                  Container(
                    width: 60.h,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: getGreyCardColor(context),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  getHorSpace(12.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getCustomFont("Product ID: ${item.productId.substring(0, 5)}", 14, getFontColor(context), 1, fontWeight: FontWeight.w500),
                        getVerSpace(4.h),
                        getCustomFont("Qty: ${item.quantity}", 12, getFontGreyColor(context), 1),
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

  Widget _buildPriceSummary(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      child: Column(
        children: [
          buildSubtotalRow(context, "Item Total", "\u20B9${order!.totalAmount.toStringAsFixed(0)}"),
          getVerSpace(12.h),
          buildSubtotalRow(context, "Tax", "\u20B90"),
          getVerSpace(12.h),
          buildSubtotalRow(context, "Shipping", "Free"),
          getDivider(setColor: Colors.grey.shade200).marginSymmetric(vertical: 16.h),
          buildTotalRow(context, "Total Paid", "\u20B9${order!.totalAmount.toStringAsFixed(0)}"),
        ],
      ),
    );
  }
}
