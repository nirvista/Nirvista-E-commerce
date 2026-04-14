
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/checkout_slider.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/cart_contr/shipping_add_controller.dart';
import 'package:pet_shop/base/get/home_controller.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/woocommerce/model/customer.dart';

import '../../base/get/route_key.dart';
import '../../base/get/login_data_controller.dart';
import '../../services/address_api.dart';
import '../../csc_picker/csc_picker.dart';

class CheckOutShippingAdd extends StatefulWidget {
  const CheckOutShippingAdd({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CheckOutShippingAdd();
  }
}

class _CheckOutShippingAdd extends State<CheckOutShippingAdd> {
  backClick(BuildContext context) {
    Constant.backToPrev(context);
  }


  StorageController storageController = Get.find<StorageController>();
  HomeController homeController = Get.find<HomeController>();
  ShippingAddressController shippingAddressController = Get.put(ShippingAddressController());
  LoginDataController loginController = Get.find<LoginDataController>();

  TextEditingController fullNameController = TextEditingController();
  TextEditingController addressLabelController = TextEditingController(text: "Home");

  @override
  void initState() {
    super.initState();
    shippingAddressController.fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return WillPopScope(
        child: Scaffold(
          backgroundColor: getScaffoldColor(context),
          body: Column(
            children: [
              getDefaultHeader(context, "Check Out", () {
                backClick(context);
              }, isShowSearch: false),
              20.h.verticalSpace,
              CheckOutSlider(
                icons: Constant.icons,
                filledIcons: Constant.filledIcon,
                itemSize: 24,
                completeColor: getAccentColor(context),
                currentColor: getFontColor(context),
                currentPos: 0,
              ).marginSymmetric(horizontal: margin),
              20.h.verticalSpace,
              Expanded(
                flex: 1,
                child: Obx(() {
                  if (shippingAddressController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      // Saved Addresses Section
                      if (shippingAddressController.addresses.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10.h),
                          child: getCustomFont("Select Saved Address", 18, getFontColor(context), 1, fontWeight: FontWeight.w700),
                        ),
                        ...shippingAddressController.addresses.map((addr) => Column(
                          children: [
                            buildAddressWidget(
                                EdgeInsets.symmetric(horizontal: margin, vertical: 10.h),
                                context,
                                addr.addressLabel,
                                addr.fullAddress,
                                addr.recipientName,
                                shippingAddressController.selectedAddress.value?.id == addr.id, () {
                              shippingAddressController.selectAddress(addr);
                            }),
                            Container(
                              color: getCardColor(context),
                              child: getDivider(setColor: Colors.grey.shade300).marginSymmetric(horizontal: 20.h),
                            ),
                          ],
                        )).toList(),
                      ],

                      // Add New Address Button
                      getVerSpace(20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: margin),
                        child: GestureDetector(
                          onTap: () {
                            showAddressDialog(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: getAccentColor(context),
                              borderRadius: BorderRadius.circular(12.w),
                            ),
                            child: Center(
                              child: getCustomFont("+ Add New Address", 16, Colors.white, 1, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      getVerSpace(20.h),
                    ],
                  );
                }),
              ),
              getButtonFigma(context, getAccentColor(context), true, "Next", Colors.white, () async {
                if (shippingAddressController.selectedAddress.value != null) {
                  Constant.sendToNext(context, checkoutScreenRoute);
                } else {
                  // If no address selected, maybe try to save the form if it's partially filled?
                  // Best to force selection or save.
                  showCustomToast("Please select or add an address first");
                }
              }, EdgeInsets.symmetric(horizontal: margin, vertical: 15.h))
            ],
          ),
        ),
        onWillPop: () async {
          backClick(context);
          return true;
        });
  }


  Container buildAddressWidget(
      EdgeInsets margin,
      BuildContext context,
      String title,
      String add,
      String recipient,
      bool isSelected,
      Function click) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.all(20.h),
      width: double.infinity,
      child: InkWell(
        onTap: () {
          click();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: getCustomFont(title, 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
                ),
                getSvgImageWithSize(
                  context,
                  (isSelected) ? "selected_radio.svg" : "unselected_radio.svg",
                  24.h,
                  24.h,
                )
              ],
            ),
            getVerSpace(8.h),
            getCustomFont(recipient, 14, getFontColor(context), 1, fontWeight: FontWeight.w500),
            getVerSpace(4.h),
            getMultilineCustomFont(add, 14, getFontColor(context), fontWeight: FontWeight.w400),
          ],
        ),
      ),
    );
  }

  Row buildTotalRow(BuildContext context, String total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont("Total", 22, getFontColor(context), 1, fontWeight: FontWeight.w700),
        getCustomFont(total, 22, getFontColor(context), 1, fontWeight: FontWeight.w700),
      ],
    );
  }
}
