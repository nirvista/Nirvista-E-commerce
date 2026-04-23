import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/woocommerce/model/user.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';
import '../../services/loginregisterapi.dart';
import '../../services/vendor_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  backClick(BuildContext context) {
    Constant.backToFinish(context);
  }

  RxBool showPass = false.obs;
  RxBool isLoading = false.obs;

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  String? userType;

  @override
  Widget build(BuildContext context) {
    RxBool agreeTerm = false.obs;

    Constant.setupSize(context);
    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);

    return buildTitleDefaultWidget(
      context,
      "Login",
      () {
        backClick(context);
      },
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// EMAIL
          getCustomFont("Email", 16, getFontColor(context), 1,
                  fontWeight: FontWeight.w400)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          getDefaultTextFiled(
              context,
              "Enter Email Address",
              emailController,
              getFontColor(context), (value) {}, validator: (email) {
            if (email!.isNotEmpty) {
              return null;
            } else {
              return 'Please enter email address';
            }
          }),

          20.h.verticalSpace,

          /// PASSWORD
          getCustomFont("Password", 16, getFontColor(context), 1,
                  fontWeight: FontWeight.w400)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          ObxValue((p0) {
            return getPassTextFiled(
              context,
              "Enter Password",
              passController,
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

          /// REMEMBER + FORGOT
          Row(
            children: [
              ObxValue((p0) {
                return Checkbox(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                      color: getAccentColor(context), width: 1.h),
                  activeColor: getAccentColor(context),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(6.h))),
                  onChanged: (value) {
                    agreeTerm.value = value!;
                  },
                  value: agreeTerm.value,
                );
              }, agreeTerm),
              getCustomFont("Remember me", 14, getFontColor(context), 1,
                  fontWeight: FontWeight.w400),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Constant.sendToNext(
                          context, forgotPassScreenRoute);
                    },
                    child: getCustomFont(
                        "Forgot password ?",
                        16,
                        getFontColor(context),
                        1,
                        fontWeight: FontWeight.w400),
                  ),
                ).paddingOnly(right: horSpace),
              ),
            ],
          ),

          20.h.verticalSpace,

          /// USER TYPE
          Center(
            child: getCustomFont("Select User Type", 16,
                getFontColor(context), 1,
                fontWeight: FontWeight.w500),
          ),
          8.h.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: "customer",
                groupValue: userType,
                activeColor: getAccentColor(context),
                onChanged: (String? value) {
                  setState(() {
                    userType = value!;
                  });
                },
              ),
              getCustomFont("Customer", 14, getFontColor(context), 1),
              20.w.horizontalSpace,
              Radio<String>(
                value: "vendor",
                groupValue: userType,
                activeColor: getAccentColor(context),
                onChanged: (String? value) {
                  setState(() {
                    userType = value!;
                  });
                },
              ),
              getCustomFont("Vendor", 14, getFontColor(context), 1),
            ],
          ),

          20.h.verticalSpace,

          /// LOGIN BUTTON
          ObxValue((loading) {
            return getButtonFigma(
              context,
              getAccentColor(context),
              true,
              isLoading.value ? "Logging in..." : "Log In",
              Colors.white,
              isLoading.value
                  ? () {}
                  : () async {
                      /// VALIDATION
                      if (emailController.text.isEmpty) {
                        _snack("Please enter email");
                        return;
                      }
                      if (passController.text.isEmpty) {
                        _snack("Please enter password");
                        return;
                      }
                      if (userType == null) {
                        _snack("Select user type");
                        return;
                      }

                      isLoading.value = true;

                      try {
                        final result = await ApiService.userLogin(
                          email: emailController.text.trim(),
                          password: passController.text,
                        );

                        if (result['success']) {
                          final userData = result['data']['user'];
                          final accessToken =
                              result['data']['accessToken'];
                          final refreshToken =
                              result['data']['refreshToken'];

                          final serverRole =
                              userData['userRole'].toString().toLowerCase();
                          final selectedRole =
                              userType!.toLowerCase();

                          /// ROLE CHECK
                          if (serverRole != selectedRole) {
                            isLoading.value = false;
                            _snack(
                                "This account is registered as $serverRole");
                            return;
                          }

                          User loggedInUser = User(
                            id: userData['id'],
                            name: userData['name'],
                            email: userData['email'],
                            phone: userData['phone'],
                            userRole: userData['userRole'],
                          );

                          final loginController =
                              Get.find<LoginDataController>();

                          /// 🚨 VENDOR STATUS CHECK
                          if (serverRole == 'vendor') {
                            final meResult =
                                await VendorApiService.getCurrentUser(
                                    accessToken);

                            if (meResult['success'] != true) {
                              _snack("Unable to verify vendor status");
                              isLoading.value = false;
                              return;
                            }

                            final status = meResult['data']
                                    ?['userStatus']
                                ?.toString()
                                .toLowerCase();

                            if (status != 'active') {
                              _snack(
                                status == 'pending'
                                    ? "Your account is under review. Wait for admin approval."
                                    : "Account is $status",
                              );
                              isLoading.value = false;
                              return;
                            }
                          }

                          /// SAVE USER (ONLY IF ALLOWED)
                          loginController.saveUser(
                            loggedInUser,
                            accessToken: accessToken,
                            refreshToken: refreshToken,
                          );

                          _snack("Login successful");

                          /// NAVIGATION
                          if (serverRole == 'vendor') {
                            Constant.sendToNext(
                                context, vendorDashboardRoute);
                          } else {
                            Constant.sendToNext(
                                context, homeScreenRoute);
                          }
                        } else {
                          _snack(result['message'] ?? 'Login failed');
                        }
                      } catch (e) {
                        _snack("Error: $e");
                      } finally {
                        isLoading.value = false;
                      }
                    },
              EdgeInsets.symmetric(
                  horizontal: horSpace, vertical: 60.h),
            );
          }, isLoading),

          30.h.verticalSpace,

          /// SIGNUP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getCustomFont(
                  "Don't have an account?", 16,
                  getFontBlackColor(context), 1),
              InkWell(
                onTap: () {
                  Constant.sendToNext(context, registrationRoute);
                },
                child: getCustomFont(
                    " Sign up", 18, accentColor, 1,
                    fontWeight: FontWeight.w700),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}