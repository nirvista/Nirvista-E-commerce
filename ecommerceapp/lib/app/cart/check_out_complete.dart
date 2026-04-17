import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:pet_shop/base/checkout_slider.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/already_in_cart.dart';
import 'package:pet_shop/base/get/home_controller.dart';
import 'package:pet_shop/base/get/product_data.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import '../../base/get/cart_contr/cart_controller.dart';
import '../../base/get/cart_contr/shipping_add_controller.dart';
import '../../base/get/login_data_controller.dart';
import '../../services/order_api.dart';
import '../../services/address_api.dart';
import '../../woocommerce/model/model_shipping_method.dart';
import '../../woocommerce/model/model_tax.dart';
import '../../app/model/api_models.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class CheckOutComplete extends StatefulWidget {
  const CheckOutComplete({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CheckOutComplete();
  }
}

class _CheckOutComplete extends State<CheckOutComplete> {
  backClick(BuildContext context) {
    Constant.sendToNext(context, homeScreenRoute);
  }
  
  late Razorpay _razorpay;

  RxBool isCouponApply = false.obs;
  String inputCoupon = '';
  String finalInputCoupon = '';

  StorageController storageController = Get.find<StorageController>();
  ProductDataController productDataController =
  Get.find<ProductDataController>();
  HomeController homeController = Get.find<HomeController>();
  CartController cartController = Get.find<CartController>();
  AlreadyInCart alreadyInCart = Get.find<AlreadyInCart>();
  Rx<ModelShippingMethod?> selectedShippingMethod =
      (null).obs;
  List<ModelShippingMethod> shippingMethods = [];
  RxBool shippingMthLoaded = false.obs;

  // Rx<List<ModelShippingMethod?>> shippingMethods = (null as List<ModelShippingMethod?>).obs;

  ShippingAddressController shippingAddressController = Get.find<ShippingAddressController>();

  Rx<ModelTax?> taxModel = (null).obs;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    getShippingMethods();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    cartController.clearCartAction();
    Constant.sendToNext(context, orderConfirmScreenRoute);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  void openCheckout(Map<String, dynamic> razorpayOrderData, String userEmail, String userPhone) async {
    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];
    
    var options = {
      'key': razorpayKey,
      'amount': razorpayOrderData['amount'],
      'name': 'Nirvista E-commerce',
      'order_id': razorpayOrderData['id'],
      'description': 'Purchase from Nirvista',
      'timeout': 300, 
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  // getTaxRates() async {
  //   List<ModelTax> rateList = await homeController.wooCommerce!.getAllTax();
  //   if (rateList.isNotEmpty) {
  //     String countrySet = await CSCPickerState().getCountriesCode(
  //         storageController.selectedShippingAddress!.country) ??
  //         "";
  //     print('country-----$countrySet');
  //
  //     for (int i = 0; i < rateList.length; i++) {
  //       ModelTax modelTax = rateList[i];
  //       print("modelTax----${modelTax.country}");
  //       if (modelTax.country == countrySet) {
  //         taxModel.value = modelTax;
  //         return;
  //       }
  //     }
  //   }
  // }

  getShippingMethods() async {
    shippingMthLoaded.value = true;
  }

  Widget _buildCheckOutCartItem(BuildContext context, CartItemModel item) {
    String name = item.product?.title ?? "Unknown Product";
    String variantName = item.variant?.variantName ?? "";
    double price = item.variant?.discountPrice != null && item.variant!.discountPrice! > 0 
           ? item.variant!.discountPrice! 
           : (item.variant?.price ?? 0.0);
    String img = item.displayImage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(8.w),
             color: Colors.grey.shade100,
          ),
          clipBehavior: Clip.antiAlias,
          child: img.isNotEmpty 
            ? Image.network(
                img, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 24.w, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                },
              )
            : Center(child: Icon(Icons.image_not_supported_outlined, size: 24.w, color: Colors.grey)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               getCustomFont(name, 16, getFontColor(context), 2, fontWeight: FontWeight.w600),
               SizedBox(height: 4.h),
               getCustomFont(variantName, 12, getFontHint(context), 1),
               SizedBox(height: 8.h),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   getCustomFont("₹${price.toStringAsFixed(0)}", 16, getAccentColor(context), 1, fontWeight: FontWeight.w700),
                   getCustomFont("Qty: ${item.quantity}", 14, getFontColor(context), 1, fontWeight: FontWeight.w500),
                 ]
               )
            ]
          )
        )
      ]
    );
  }

  Widget _buildAddressSection(BuildContext context, double margin) {
    return Obx(() {
      if (shippingAddressController.isLoading.value) {
        return Container(
          color: getCardColor(context),
          padding: EdgeInsets.all(margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleWidget(context, "Shipping Address"),
              getVerSpace(12.h),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      }

      final selectedAddress = shippingAddressController.selectedAddress.value;

      return Container(
        color: getCardColor(context),
        padding: EdgeInsets.all(margin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildTitleWidget(context, "Shipping Address"),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => showAddressSelectorBottomSheet(context),
                      child: getCustomFont("Change", 14, getAccentColor(context), 1, fontWeight: FontWeight.w600),
                    ),
                    getHorSpace(8.w),
                    TextButton(
                      onPressed: () => showAddressDialog(context),
                      child: getCustomFont("Add New", 14, getAccentColor(context), 1, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            getVerSpace(8.h),
            if (selectedAddress == null)
              getMultilineCustomFont(
                  "No address selected. Please add or select a shipping address.",
                  14,
                  getFontColor(context),
                  fontWeight: FontWeight.w400)
            else ...[
              getCustomFont(selectedAddress.recipientName, 15, getFontColor(context), 1, fontWeight: FontWeight.w600),
              getVerSpace(4.h),
              getMultilineCustomFont(
                  selectedAddress.fullAddress,
                  14,
                  getFontColor(context),
                  fontWeight: FontWeight.w400),
              getVerSpace(4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: getAccentColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: getCustomFont(selectedAddress.addressLabel, 12, getAccentColor(context), 1, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    WidgetsBinding.instance.addPostFrameCallback((_){

    });
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);
    return WillPopScope(
        child: Scaffold(
          backgroundColor: getScaffoldColor(context),
          body: Column(
            children: [
              getDefaultHeader(context, "Check Out", () {
                backClick(context);
              }, isShowSearch: false),
              CheckOutSlider(
                icons: Constant.icons,
                filledIcons: Constant.filledIcon,
                itemSize: 24,
                completeColor: getAccentColor(context),
                currentColor: black40,
                currentPos: 2,
              ).marginSymmetric(horizontal: margin,vertical: margin),
              Expanded(
                flex: 1,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildAddressSection(context, margin),
                    getVerSpace(20.h),
                    Container(
                      color: getCardColor(context),
                      padding: EdgeInsets.all(margin),
                      child: Builder(
                        builder: (context) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildTitleWidget(context, "Payment Method"),
                              getVerSpace(12.h),
                              Obx(() {
                                bool isCod = storageController.selectedPaymentMethod.value == "cod";
                                return Row(
                                  children: [
                                    Icon(isCod ? Icons.money : Icons.payment, color: getAccentColor(context), size: 40.w),
                                    getHorSpace(12.h),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        getCustomFont(isCod ? "Cash On Delivery" : "Razorpay (Online)", 14, getFontColor(context), 1, fontWeight: FontWeight.w400),
                                        getVerSpace(6.h),
                                        getCustomFont(
                                            isCod ? "Pay when you receive" : "Safe and secure online payment",
                                            14,
                                            getFontColor(context), 1,
                                            fontWeight: FontWeight.w400),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                    getVerSpace(20.h),
                    Container(
                      padding: EdgeInsets.all(20.h),
                      color: getCardColor(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTitleWidget(context,"Cart Detail"),
                          getVerSpace(20.h),
                          Obx(() => ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (cartController.cartModel.value == null) return const SizedBox();
                              CartItemModel cart = cartController.cartModel.value!.items[index];
                              return _buildCheckOutCartItem(context, cart);
                            },
                            itemCount: cartController.cartModel.value?.items.length ?? 0,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return getDivider(setColor: Colors.grey.shade300).marginSymmetric(
                                  vertical: 20.h);
                            },
                          )),
                        ],
                      ),
                    ),
                    getVerSpace(20.h),
                    Container(
                      color: getCardColor(context),
                      child: Obx(() {
                            return Column(
                              children: [
                                buildSubtotalRow(
                                    context,
                                    "Subtotal",
                                    "₹${cartController.cartSubTotal.toStringAsFixed(0)}"),
                                getDivider(setColor: Colors.grey.shade300)
                                    .marginSymmetric(vertical: 14.h),
                                buildSubtotalRow(
                                    context,
                                    "Shipping",
                                    "Free"),
                                getDivider(setColor: Colors.grey.shade300)
                                    .marginSymmetric(vertical: 14.h),
                                buildSubtotalRow(
                                  context,
                                  "Tax",
                                  "+₹0",),
                                getDivider(setColor: Colors.grey.shade300)
                                    .marginSymmetric(vertical: 14.h),
                                buildSubtotalRow(
                                    context,
                                    "Discount",
                                    "-₹${cartController.promoPrice.value.toStringAsFixed(0)}"),
                                getDivider(setColor: Colors.grey.shade300)
                                    .marginSymmetric(vertical: 14.h),
                                buildTotalRow(
                                  context,
                                  "Total",
                                  "₹${cartController.cartTotal.toStringAsFixed(0)}",
                                ),
                              ],
                            ).marginSymmetric(
                                horizontal: margin, vertical: 20.h);
                          }),
                    )
                  ],
                ),
              ),
              getButtonFigma(context, getAccentColor(context), true,
                  "Confirm Order", Colors.white, () async {
                
                final loginController = Get.find<LoginDataController>();
                final token = loginController.accessToken;
                if (token == null || token.isEmpty) {
                   Constant.sendToNext(context, loginRoute);
                   return;
                }

                // Validate address
                if (shippingAddressController.selectedAddress.value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add or select a shipping address'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                String paymentMethod = storageController.selectedPaymentMethod.value;
                
                final res = await OrderApiService.createOrder(
                   accessToken: token,
                   addressId: shippingAddressController.selectedAddress.value!.id,
                   paymentMethod: paymentMethod,
                );
                
                Navigator.pop(context); // Dismiss loading dialog

                if (res['success']) {
                   if (paymentMethod == "online") {
                      // Backend returns razorpayOrder and user info might be needed
                      // For prefill, we use existing login data
                      openCheckout(
                        res['razorpayOrder'],
                        loginController.currentUser.value?.email ?? "", 
                        loginController.currentUser.value?.phone ?? ""
                      );
                   } else {
                      await cartController.clearCartAction();
                      Constant.sendToNext(context, orderConfirmScreenRoute);
                   }
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to place order')));
                }
              }, EdgeInsets.symmetric(horizontal: margin, vertical: 20.h))
            ],
          ),
        ),
        onWillPop: () async {
          backClick(context);
          return true;
        });
  }

  String getTotalString() {
    return cartController.cartTotal.toStringAsFixed(2);
  }

  String getSubTotal() {
    return cartController.cartSubTotal.toStringAsFixed(2);
  }

  String getTax() {
    return "0.00";
  }

  Widget buildTitleWidget(BuildContext context,String title) {
    return getCustomFont(title, 17, getFontColor(context), 1,
        fontWeight: FontWeight.w600);
  }
}