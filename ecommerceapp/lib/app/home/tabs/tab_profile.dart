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
        color: getScaffoldColor(context),
        child: Column(
          children: [
            // ── Teal gradient header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20.h,
                bottom: 30.h,
              ),
              child: Column(
                children: [
                  // Avatar with white ring
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.w),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: getCircleProfileImage(context, user != null ? user.initials : "U", 80.h),
                  ),
                  14.h.verticalSpace,
                  // Name
                  Text(
                    user != null ? user.displayName : "Guest User",
                    style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w700),
                  ),
                  5.h.verticalSpace,
                  // Email
                  Text(
                    user != null ? (user.email ?? "No email") : "Please login to continue",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.sp, fontWeight: FontWeight.w400),
                  ),
                  16.h.verticalSpace,
                ],
              ),
            ),

            // ── Menu list ──
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: margin),
                color: getCardColor(context),
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ListView(
                        children: [
                          40.h.verticalSpace,
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
                    // Logout / Login button
                    GestureDetector(
                      onTap: () {
                        if (isLoggedIn) {
                          loginController.logout();
                          bottomController.changePos(0);
                          Constant.sendToNext(context, loginRoute);
                        } else {
                          Constant.sendToNext(context, loginRoute);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        margin: EdgeInsets.only(bottom: 20.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12.w),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                              color: Colors.white,
                              size: 18.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              isLoggedIn ? "Logout" : "Login",
                              style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

}
