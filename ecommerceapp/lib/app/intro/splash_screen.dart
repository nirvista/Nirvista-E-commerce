import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage.dart';
import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/widget_utils.dart';
import '../../generated/assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
   return _SplashScreen();
  }
}
class _SplashScreen extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3),
          () {
            final loginController = Get.find<LoginDataController>();
            final user = loginController.currentUser.value;

            // If user is not logged in, always go to login first
            if (user == null || user.id == null || user.id!.isEmpty) {
              Constant.sendToNext(context, loginRoute);
              return;
            }

            /* 
            // Commenting out intro redirection as requested
            if (isIntroAvailable) {
              Constant.sendToNext(context, introRoute);
            } else {
            */
              
              String nextRoute = user.userRole?.toLowerCase() == 'vendor' 
                  ? vendorDashboardRoute 
                  : homeScreenRoute;
              
              Constant.sendToNext(context, nextRoute);
            /* } */
      },
    );
  }
    backClick(BuildContext context) {
    Constant.backToFinish(context);
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);

    return WillPopScope(
        child: Scaffold(
          backgroundColor: getAccentColor(context),
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Display Branding Icon
                Container(
                  width: 100.h,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 54.h,
                  ),
                ),
                20.h.verticalSpace,
                // Display Branding Text
                Text(
                  "NIRVISTA",
                  style: TextStyle(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async {
          backClick(context);
          return false;
        });
  }



}
