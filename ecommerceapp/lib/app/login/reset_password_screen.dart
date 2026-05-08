
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';
import '../../services/loginregisterapi.dart';


class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ResetPasswordScreen();
  }
}

class _ResetPasswordScreen extends State<ResetPasswordScreen> {
  backClick(BuildContext context) {
    Constant.backToFinish(context);
  }

  RxBool showPass = false.obs;

  // TextEditingController emailController = TextEditingController();
  TextEditingController tokenController = TextEditingController();
  TextEditingController newPassController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);

    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);
    return buildTitleDefaultWidget(context, "Reset Password", () {
      backClick(context);
    },
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont("Reset Token", 16, getFontColor(context), 1,
                    fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            getDefaultTextFiled(context, "Paste token from email", tokenController,
                getFontColor(context), (value) {}, validator: (token) {
                  if (token!.isNotEmpty) {
                    return null;
                  } else {
                    return 'Please enter the reset token';
                  }
                }),
            20.h.verticalSpace,
            getCustomFont("New password", 16, getFontColor(context), 1,
                    fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            ObxValue((p0) {
              return getPassTextFiled(
                context,
                "Create new password",
                newPassController,
                getFontColor(context),
                showPass.value,
                () {
                  showPass.value = !showPass.value;
                },
                validator: (password) {
                  if (password!.isNotEmpty) {
                    return null;
                  } else {
                    return 'Please enter password';
                  }
                },
              );
            }, showPass),

            20.h.verticalSpace,
            getCustomFont("Confirm password", 16, getFontColor(context), 1,
                    fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,

            ObxValue((p0) {
              return getPassTextFiled(
                context,
                "Confirm your password",
                confirmPassController,
                getFontColor(context),
                showPass.value,
                () {
                  showPass.value = !showPass.value;
                },
                validator: (password) {
                  if (password!.isNotEmpty) {
                    return null;
                  } else {
                    return 'Please enter password';
                  }
                },
              );
            }, showPass),

            // getDefaultTextFiledWithCustomPrefix(
            //     context,
            //     "Phone number",
            //     numberController,
            //     getFontColor(context),
            //     Container(width: 100.h,height: 24.h,color: Colors.green,)
            //     // CountryCodePicker(
            //     //   onChanged: print,
            //     //   initialSelection: 'IN',
            //     //   flagWidth: 40.h,
            //     //   padding: EdgeInsets.zero,
            //     //   textStyle:buildTextStyle(context,getFontColor(context), FontWeight.w400, 16.sp),
            //     //   favorite: const ['+91', 'IN'],
            //     //   showCountryOnly: false,
            //     //   showDropDownButton: true,
            //     //   showOnlyCountryWhenClosed: false,
            //     //   alignLeft: false,
            //     // ).marginOnly(left: 20.w)
            //     ),
            // getDefaultCountryPickerTextFiled(context, "Phone number",
            //         numberController, getFontColor(context))
            //     .marginSymmetric(horizontal: horSpace),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : getButtonFigma(
                    context, getAccentColor(context), true, "Change Password", Colors.white,
                    () async {
                      if (tokenController.text.trim().isEmpty) {
                        Get.snackbar("Error", "Please enter the reset token",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }
                      if (newPassController.text.isEmpty) {
                        Get.snackbar("Error", "Please enter a new password",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }
                      if (newPassController.text != confirmPassController.text) {
                        Get.snackbar("Error", "Passwords do not match",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }

                      setState(() => _isLoading = true);
                      final res = await ApiService.resetPassword(
                          token: tokenController.text.trim(),
                          password: newPassController.text);
                      setState(() => _isLoading = false);

                      if (res['success']) {
                        showGetDialog(context, "unlock.png", "Password Changed",
                            res['message'], "Ok", () {
                              backClick(context);
                              Constant.sendToNext(context, loginRoute);
                            },
                            dialogHeight: 464,
                            imgHeight: 146,
                            imgWidth: 146,
                            fit: BoxFit.fill);
                      } else {
                        Get.snackbar("Error", res['message'],
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                      }
                    }, EdgeInsets.symmetric(horizontal: horSpace, vertical: 60.h)),
          ],
        ));
  }
}
