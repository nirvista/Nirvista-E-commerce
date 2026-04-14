import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/image_controller.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/widget_utils.dart';
import 'package:pet_shop/woocommerce/model/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditProfile();
}

class _EditProfile extends State<EditProfile> {
  final imageController = Get.put(ImageController());
  final loginController = Get.find<LoginDataController>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = loginController.currentUser.value;
    if (user != null) {
      nameController.text = user.name ?? "";
      phoneController.text = user.phone ?? "";
      emailController.text = user.email ?? "";
    }
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
      onWillPop: () async {
        onBackClick(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            getDefaultHeader(
              context,
              "Edit Profile",
              () => onBackClick(context),
              isShowSearch: false,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: horSpace),
                children: [
                  30.h.verticalSpace,
                  Center(
                    child: Obx(
                      () => getCircleProfileImage(
                        context,
                        loginController.currentUser.value?.initials ?? "U",
                        90.h,
                      ),
                    ),
                  ),
                  24.h.verticalSpace,
                  getCustomFont(
                    "Full Name",
                    12,
                    getFontColor(context),
                    1,
                    fontWeight: FontWeight.w500,
                  ),
                  8.h.verticalSpace,
                   Container(
                   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                   decoration: BoxDecoration(
                   border: Border(bottom: BorderSide(color: getFontHint(context))),
                 ),
                 child: TextFormField(
                   controller: nameController,
                   style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                   decoration: InputDecoration(
                   hintText: 'Enter your full name',
                   hintStyle: TextStyle(color: getFontHint(context)),
                   border: InputBorder.none,
                   contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                   ),
                 ),
                 ),
                   24.h.verticalSpace,
                   getCustomFont(
                     "Email Address",
                     12,
                     getFontColor(context),
                     1,
                     fontWeight: FontWeight.w500,
                   ),
                   6.h.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: getFontHint(context))),
                      ),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: TextStyle(color: getFontHint(context), fontSize: 12.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        ),
                      ),
                    ),
                   24.h.verticalSpace,
                   getCustomFont(
                     "Phone Number",
                     12,
                     getFontColor(context),
                     1,
                     fontWeight: FontWeight.w500,
                   ),
                   6.h.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: getFontHint(context))),
                      ),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(color: getFontHint(context), fontSize: 12.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        ),
                      ),
                    ),
                   24.h.verticalSpace,
                ],
              ),
            ),
            getButtonFigma(
              context,
              getAccentColor(context),
              true,
              'Save',
              Colors.white,
              () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter your name")),
                  );
                  return;
                }
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter your email")),
                  );
                  return;
                }

                final user = loginController.currentUser.value;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User data not found. Please login again.")),
                  );
                  return;
                }

                try {
                  await dotenv.load(fileName: ".env");
                  String? baseUrl = dotenv.env['BASE_URL'];
                  String? accessToken = loginController.accessToken;

                  if (baseUrl == null || baseUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Base URL not configured")),
                    );
                    return;
                  }

                  if (accessToken == null || accessToken.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please login again to update profile")),
                    );
                    return;
                  }

                  final response = await http.put(
                    Uri.parse('$baseUrl/api/auth/profile'),
                    headers: {
                      'Authorization': 'Bearer $accessToken',
                      'Content-Type': 'application/json',
                      'x-client-type': 'mobile',
                    },
                    body: jsonEncode({
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                    }),
                  );
                  
                  if (response.statusCode == 200) {
                    final responseData = jsonDecode(response.body);
                    if (responseData['success'] == true && responseData['data'] != null) {
                      // Use the updated user data from the response
                      final updatedUserData = responseData['data'];
                      final updatedUser = User.fromJson(updatedUserData);
                      loginController.saveUser(updatedUser);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile updated successfully!")),
                      );
                      Constant.backToPrev(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(responseData['message'] ?? "Failed to update profile"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to update profile: ${response.statusCode}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              edgeInsets,
            ).marginSymmetric(vertical: 30.h),
          ],
        ),
      ),
    );
  }

  // getProfileCell(BuildContext context) {
  //   return Center(
  //     child: SizedBox(
  //       width: 90.h,
  //       height: 90.h,
  //       child: Stack(
  //         children: [
  //           Positioned.fill(
  //             child: Align(
  //                 alignment: Alignment.topLeft,
  //                 child: Obx(
  //                   () => getCircleImageProfile(
  //                     context,
  //                     (imageController.imagePath.value.isNotEmpty)
  //                         ? imageController.imagePath.value
  //                         : homeController.currentCustomer!.avatarUrl ?? "",
  //                     100.h,
  //                     fileImage: (imageController.imagePath.value.isNotEmpty),
  //                   ),
  //                 )),
  //           ),
  //           Positioned.fill(
  //             child: Align(
  //               alignment: Alignment.bottomRight,
  //               child: InkWell(
  //                 onTap: () {
  //                   imageController.getImage();
  //                 },
  //                 child: Container(
  //                   width: 32.h,
  //                   height: 32.h,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Color(0x2d7a6054),
  //                         blurRadius: 23,
  //                         offset: Offset(1, 8),
  //                       ),
  //                     ],
  //                     color: Colors.white,
  //                   ),
  //                   child: Center(
  //                     child: getSvgImage(
  //                       context,
  //                       'camera.svg',
  //                       18,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
