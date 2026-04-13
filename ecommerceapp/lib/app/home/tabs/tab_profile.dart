import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/bottom_selection_controller.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/widget_utils.dart';

// ignore: must_be_immutable
class TabProfile extends StatelessWidget {
  TabProfile({Key? key}) : super(key: key);

  BottomItemSelectionController bottomController = Get.find<BottomItemSelectionController>();
  LoginDataController loginController = Get.find<LoginDataController>();

  @override
  Widget build(BuildContext context) {
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);
    return Obx(() {
      final user = loginController.currentUser.value;
      final isLoggedIn = loginController.isLoggedIn;
      
      return Container(
        color: "#E7FEF5".toColor(),
        child: Column(
          children: [
            Column(
              children: [
                getDefaultHeader(context, "Profile", (){},color: Colors.transparent,isShowSearch: false),
                30.h.verticalSpace,
                getCircleProfileImage(
                    context,
                    user != null ? user.initials : "U",
                    90.h),
                14.h.verticalSpace,
                getCustomFont(
                    user != null ? user.displayName : "Guest User",
                    16,
                    getFontColor(context),
                    1,
                    fontWeight: FontWeight.w600),
                6.h.verticalSpace,
                getCustomFont(
                    user != null ? user.email! : "Please login",
                    14,
                    getFontColor(context),
                    1,
                    fontWeight: FontWeight.w400),
                20.h.verticalSpace,
              ],
            ),

            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: margin),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.h),
                        topRight: Radius.circular(40.h))),
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          30.h.verticalSpace,
                          buildRowWidget(context, "profile.svg", "My Profile", () {
                            if (isLoggedIn) {
                              Constant.sendToNext(context, myProfileRoute);
                            } else {
                              Constant.sendToNext(context, loginRoute);
                            }
                          }),
                          getDividerWidget(),
                          buildRowWidget(context, "my_order.svg", "My Order", () {
                            if (isLoggedIn) {
                              Constant.sendToNext(context, myOrderScreenRoute);
                            } else {
                              Constant.sendToNext(context, loginRoute);
                            }
                          }),
                          getDividerWidget(),
                          buildRowWidget(context, "location.svg", "My Address", () {
                            if (isLoggedIn) {
                              Constant.sendToNext(context, myAddressScreenRoute);
                            } else {
                              Constant.sendToNext(context, loginRoute);
                            }
                          }),
                          getDividerWidget(),
                          buildRowWidget(context, "card.svg", "Payment Method", () {
                            Constant.sendToNext(context, paymentMethodScreenRoute);
                          }),
                          getDividerWidget(),
                          buildRowWidget(context, "call.svg", "Customer Care", () {
                            Constant.sendToNext(context, customerCareScreenRoute);
                          }),
                          getDividerWidget(),
                          buildRowWidget(context, "more.svg", "More", () {
                            Constant.sendToNext(context, moreScreenRoute);
                          }),

                          20.h.verticalSpace,
                        ],
                      ),
                    ),
                    getButtonFigma(context, Colors.transparent, true,
                        isLoggedIn ? "Logout" : "Login", getAccentColor(context), () {
                      if (isLoggedIn) {
                        loginController.logout();
                        bottomController.changePos(0);
                        Constant.sendToNext(context, loginRoute);
                      } else {
                        Constant.sendToNext(context, loginRoute);
                      }
                    }, EdgeInsets.zero,
                        isBorder: true, borderColor: getAccentColor(context)),
                    20.h.verticalSpace,
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
