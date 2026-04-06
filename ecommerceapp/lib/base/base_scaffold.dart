import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/BottomBar.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/data_file.dart';
import 'package:pet_shop/base/get/bottom_selection_controller.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../app/model/model_bottom_nav.dart';


class BaseScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  final bool showBottomBar;

  const BaseScaffold({
    Key? key,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.extendBodyBehindAppBar = false,
    this.showBottomBar = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BottomItemSelectionController bottomController =
        Get.find<BottomItemSelectionController>();
    final List<ModelBottomNav> allBottomNavList =
        DataFile.getAllBottomNavList();
    final double bottomNavHeight = 100.h;

    return Scaffold(
      backgroundColor: backgroundColor ?? getScaffoldColor(context),
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      bottomNavigationBar: showBottomBar 
        ? Container(
            width: double.infinity,
            height: bottomNavHeight,
            decoration: ShapeDecoration(
              shadows: const [
                BoxShadow(
                  color: Color.fromRGBO(133, 126, 150, 0.12999999523162842),
                  offset: Offset(0, -4),
                  blurRadius: 27,
                ),
              ],
              color: getCardColor(context),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius.vertical(
                  top: SmoothRadius(
                    cornerRadius: 40.h,
                    cornerSmoothing: 0.5,
                  ),
                ),
              ),
            ),
            child: Obx(
              () => BottomBar(
                onTap: (p0) {
                  bottomController.changePos(p0);
                  Get.offAllNamed(homeScreenRoute);
                },
                currentIndex: bottomController.bottomBarSelectedItem.value,
                selectedItemColor: getAccentColor(context),
                selectedColorOpacity: 1,
                unselectedItemColor: getFontBlackColor(context),
                itemShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(27.h)),
                ),
                itemPadding: EdgeInsets.symmetric(
                  horizontal: 11.w,
                  vertical: 8.h,
                ),
                items: List.generate(allBottomNavList.length, (index) {
                  return BottomBarItem(
                    icon: getSvgImageWithSize(
                      context,
                      allBottomNavList[index].icon,
                      24.h,
                      24.h,
                      fit: BoxFit.scaleDown,
                      color: getFontBlackColor(context),
                    ),
                    activeIcon: getSvgImageWithSize(
                      context,
                      allBottomNavList[index].activeIcon,
                      24.h,
                      24.h,
                      fit: BoxFit.scaleDown,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          )
        : null,
      body: body,
    );
  }
}
