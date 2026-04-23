import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/app/detail/rating_widget.dart';

/// Order item model with delivery rating support
class OrderItemModel {
  final String orderId;
  final String orderDate;
  final String status;
  final double totalPrice;
  final int itemCount;
  final List<String> productImages;
  final String shippingAddress;
  final double? deliveryRating;
  final String? deliveryFeedback;

  OrderItemModel({
    required this.orderId,
    required this.orderDate,
    required this.status,
    required this.totalPrice,
    required this.itemCount,
    required this.productImages,
    required this.shippingAddress,
    this.deliveryRating,
    this.deliveryFeedback,
  });
}

/// Orders/Order History Screen
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Sample orders data - Replace with actual API calls
  late List<OrderItemModel> orders;

  @override
  void initState() {
    super.initState();
    _initializeSampleOrders();
  }

  void _initializeSampleOrders() {
    orders = [
      OrderItemModel(
        orderId: '#ORD-123456',
        orderDate: '22 Apr 2024',
        status: 'Delivered',
        totalPrice: 1299.00,
        itemCount: 2,
        productImages: ['https://placehold.co/100', 'https://placehold.co/100'],
        shippingAddress: '123 Main Street, City, State 12345',
        deliveryRating: null,
        deliveryFeedback: null,
      ),
      OrderItemModel(
        orderId: '#ORD-123455',
        orderDate: '15 Apr 2024',
        status: 'Delivered',
        totalPrice: 2499.00,
        itemCount: 1,
        productImages: ['https://placehold.co/100'],
        shippingAddress: '123 Main Street, City, State 12345',
        deliveryRating: 4.5,
        deliveryFeedback: 'Great delivery, on time!',
      ),
      OrderItemModel(
        orderId: '#ORD-123454',
        orderDate: '08 Apr 2024',
        status: 'In Transit',
        totalPrice: 899.50,
        itemCount: 1,
        productImages: ['https://placehold.co/100'],
        shippingAddress: '456 Oak Avenue, City, State 12345',
        deliveryRating: null,
        deliveryFeedback: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: getCardColor(context),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Constant.backToPrev(context),
          child: Icon(Icons.arrow_back, color: getFontColor(context), size: 24.w),
        ),
        title: getCustomFont(
          'My Orders',
          18,
          getFontColor(context),
          1,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64.w, color: getFontGreyColor(context)),
                  SizedBox(height: 16.h),
                  getCustomFont('No orders yet', 16, getFontColor(context), 1,
                      fontWeight: FontWeight.w600),
                  SizedBox(height: 8.h),
                  getCustomFont(
                      'Your completed orders will appear here',
                      13,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w400),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(margin),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index], margin);
              },
            ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, OrderItemModel order, double margin) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: getCardColor(context),
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Column(
        children: [
          // Order header
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: getGreyCardColor(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.w),
                topRight: Radius.circular(12.w),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getCustomFont(
                      'Order ${order.orderId}',
                      13,
                      getFontColor(context),
                      1,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 4.h),
                    getCustomFont(
                      order.orderDate,
                      11,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                  child: getCustomFont(
                    order.status,
                    11,
                    Colors.white,
                    1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Order content
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product images
                if (order.productImages.isNotEmpty)
                  SizedBox(
                    height: 70.w,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.productImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 70.w,
                          height: 70.w,
                          margin: EdgeInsets.only(right: 8.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.w),
                            color: getGreyCardColor(context),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.w),
                            child: Image.network(
                              order.productImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image_not_supported,
                                    size: 30.w, color: Colors.grey);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 12.h),

                // Order details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getCustomFont(
                      '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                      12,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w500,
                    ),
                    getCustomFont(
                      '₹${order.totalPrice.toStringAsFixed(2)}',
                      14,
                      accentColor,
                      1,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Delivery address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16.w, color: getFontGreyColor(context)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: getCustomFont(
                        order.shippingAddress,
                        11,
                        getFontGreyColor(context),
                        2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Delivery rating section
                if (order.status == 'Delivered')
                  _buildDeliveryRatingSection(context, order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryRatingSection(
      BuildContext context, OrderItemModel order) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: getGreyCardColor(context),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont(
            'Delivery Rating',
            12,
            getFontColor(context),
            1,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 10.h),
          if (order.deliveryRating == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getCustomFont(
                  'How was your delivery experience?',
                  11,
                  getFontGreyColor(context),
                  1,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            _showDeliveryRatingDialog(context, order, index + 1);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 4.w),
                            child: Icon(
                              Icons.star_outline,
                              color: getFontGreyColor(context),
                              size: 24.w,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        _showDeliveryRatingDialog(context, order, 0);
                      },
                      child: getCustomFont(
                        'Rate Delivery',
                        11,
                        accentColor,
                        1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(
                            index < (order.deliveryRating ?? 0).toInt()
                                ? Icons.star
                                : Icons.star_outline,
                            color: ratedColor,
                            size: 18.w,
                          ),
                        );
                      }),
                    ),
                    SizedBox(width: 8.w),
                    getCustomFont(
                      '${(order.deliveryRating ?? 0).toStringAsFixed(1)}/5.0',
                      11,
                      getFontColor(context),
                      1,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                if (order.deliveryFeedback != null &&
                    order.deliveryFeedback!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  getCustomFont(
                    order.deliveryFeedback!,
                    11,
                    getFontGreyColor(context),
                    2,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showDeliveryRatingDialog(
      BuildContext context, OrderItemModel order, int initialRating) {
    showDialog(
      context: context,
      builder: (context) => DeliveryRatingDialog(
        orderId: order.orderId,
        onRatingSubmitted: (rating) {
          setState(() {
            // Update the order with the rating
            int orderIndex = orders.indexWhere((o) => o.orderId == order.orderId);
            if (orderIndex != -1) {
              orders[orderIndex] = OrderItemModel(
                orderId: order.orderId,
                orderDate: order.orderDate,
                status: order.status,
                totalPrice: order.totalPrice,
                itemCount: order.itemCount,
                productImages: order.productImages,
                shippingAddress: order.shippingAddress,
                deliveryRating: rating,
                deliveryFeedback: 'Thank you for rating!', // Can be enhanced with actual feedback
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery rating submitted: ${rating.toStringAsFixed(1)}/5.0'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in transit':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
