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
class _SplashScreen extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.1), // Wait a bit
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 15.0)
            .chain(CurveTween(curve: Curves.easeInExpo)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
  }

  void _navigateToNext() {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;

    // If user is not logged in, always go to login first
    if (user == null || user.id == null || user.id!.isEmpty) {
      Constant.sendToNext(context, loginRoute);
      return;
    }

    String nextRoute = user.userRole?.toLowerCase() == 'vendor'
        ? vendorDashboardRoute
        : homeScreenRoute;

    Constant.sendToNext(context, nextRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                // Display Branding Icon and Logo with Zoom Animation
                ScaleTransition(
                  scale: _animation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      10.h.verticalSpace,
                      getAssetImage(
                        context,
                        "nirvista_logo.png",
                        260.w,
                        100.h,
                        boxFit: BoxFit.contain,
                      ),
                    ],
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
