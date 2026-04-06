import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// import 'package:pet_shop/base/get/home_controller.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/woocommerce/model/user.dart';
import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyProfileScreen();
  }
}

class _MyProfileScreen extends State<MyProfileScreen> {
  // HomeController homeController = Get.find<HomeController>();
  final LoginDataController loginController = Get.find<LoginDataController>();
  User? user;


  @override
  void initState() {
    super.initState();
    user = loginController.currentUser.value;
  }


  void onBackClick(BuildContext context) {
    Constant.backToPrev(context);
  }

  @override
  Widget build(BuildContext context) {

    Constant.setupSize(context);

    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);
    EdgeInsets edgeInsets = EdgeInsets.symmetric(horizontal: horSpace);

    return WillPopScope(
      onWillPop:() async{
        onBackClick(context);
        return false;
      },
        child: Scaffold(
          backgroundColor: getScaffoldColor(context),
          body: Column(
            children: [
              getDefaultHeader(context, "My Profile", (){onBackClick(context);},isShowSearch: false,),
              Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      30.h.verticalSpace,
                      Center(
                          child: getCircleProfileImage(
                              context,user?.initials ?? "U", 90.h)),
                      40.h.verticalSpace,
                      getDefaultUnderlineTextFiled(
                          context,
                          'Name',
                          TextEditingController(text: user?.displayName ??""),
                          getFontHint(context),
                              (value) {},
                          readOnly: true,),
                      30.h.verticalSpace,
                      getDefaultUnderlineTextFiled(
                          context,
                          'Email Address',
                          TextEditingController(text: user?.email ??""),
                          getFontHint(context),
                              (value) {},
                          readOnly: true),
                      30.h.verticalSpace,
                      getDefaultUnderlineTextFiled(
                          context,
                          'Phone Number',
                          TextEditingController(
                              text:user?.phone ?? ""),
                          getFontHint(context),
                              (value) {},
                          readOnly: true,),

                    ],
                  )),
              getButtonFigma(
                  context,
                  getAccentColor(context),
                  true,
                  'Edit profile',
                  Colors.white, () {
                Constant.sendToNextWithBackResult(context, editProfileRoute,(val){
                  //refresh user data when coming back from edit profile screen
                  loginController.loadCurrentUser();
                  setState(() {
                    user = loginController.currentUser.value;
                  });
                });
              },
                  edgeInsets)
                  .marginSymmetric(vertical: 30.h)
            ],
          ),
        ),
       );
  }
}
