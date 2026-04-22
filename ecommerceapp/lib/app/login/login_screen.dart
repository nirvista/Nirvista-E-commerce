
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
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    RxBool agreeTerm = false.obs;
    Constant.setupSize(context);

    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);
    return buildTitleDefaultWidget(context, "Login", () {
      backClick(context);
    },
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont("Email", 16, getFontColor(context), 1,
                    fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            getDefaultTextFiled(context, "Enter Email Address", emailController,
                getFontColor(context), (value) {}, validator: (email) {
              if (email!.isNotEmpty) {
                return null;
              } else {
                return 'Please enter email address';
              }
            }),
            20.h.verticalSpace,
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
            Row(
              children: [
                ObxValue((p0) {
                  return Checkbox(
                    visualDensity: VisualDensity.compact,
                    side:
                        BorderSide(color: getAccentColor(context), width: 1.h),
                    activeColor: getAccentColor(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6.h))),
                    onChanged: (value) {
                      agreeTerm.value = value!;
                    },
                    value: agreeTerm.value,
                  );
                }, agreeTerm),
                getCustomFont("Remember me", 14, getFontColor(context), 1,
                    fontWeight: FontWeight.w400),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Constant.sendToNext(context, forgotPassScreenRoute);
                      },
                      child: getCustomFont(
                          "Forgot password ?", 16, getFontColor(context), 1,
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.end),
                    ),
                  ).paddingOnly(right: horSpace),
                ),
              ],
            ),
            20.h.verticalSpace,
            Center(
              child: getCustomFont("Select User Type", 16, getFontColor(context), 1,
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
                getCustomFont("Customer", 14, getFontColor(context), 1,
                    fontWeight: FontWeight.w400),
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
                getCustomFont("Vendor", 14, getFontColor(context), 1,
                    fontWeight: FontWeight.w400),
              ],
            ),
            ObxValue((loading) {
              return getButtonFigma(
                context,
                getAccentColor(context),
                true,
                isLoading.value ? "Logging in..." : "Log In",
                Colors.white,
                isLoading.value ? () {} : () async {
                  // Validation
                  if (emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter email address"))
                    );
                    return;
                  }
                  if (passController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter password"))
                    );
                    return;
                  }
                  if (userType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a user type"))
                    );
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
                      final accessToken = result['data']['accessToken'];
                      final refreshToken = result['data']['refreshToken'];

                      // ── ROLE VERIFICATION ──
                      // Compare the role returned by server with the selection in UI
                      final serverRole = userData['userRole'].toString().toLowerCase();
                      final selectedRole = userType!.toLowerCase();
                      
                      if (serverRole != selectedRole) {
                        isLoading.value = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Access denied: This account is registered as a $serverRole. Please select the correct user type."),
                            backgroundColor: Colors.orange.shade800,
                          )
                        );
                        return;
                      }

                      User LoggedInUser =User(
                        id :userData['id'],
                        name:userData['name'],
                        email: userData['email'],
                        phone: userData['phone'],
                        userRole: userData['userRole'],
                      );
                      final loginController = Get.find<LoginDataController>();
                      loginController.saveUser(
                        LoggedInUser,
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Login successful!"))
                      );
                      String nextRoute = LoggedInUser.userRole?.toLowerCase() == 'vendor' 
                          ? vendorDashboardRoute 
                          : homeScreenRoute;
                      Constant.sendToNext(context, nextRoute);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Login failed'),
                          backgroundColor: Colors.red,
                        )
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      )
                    );
                  } finally {
                    isLoading.value = false;
                  }
                },
                EdgeInsets.symmetric(horizontal: horSpace, vertical: 62.h)
              );
            }, isLoading),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     Expanded(
            //       child:
            //           getDivider(setColor: getCurrentTheme(context).hintColor),
            //       flex: 1,
            //     ),
            //     // getCustomFont(" OR Sign in with ", 16, getFontColor(context), 1,
            //     //     fontWeight: FontWeight.w400, textAlign: TextAlign.center),
            //     Expanded(
            //       child:
            //           getDivider(setColor: getCurrentTheme(context).hintColor),
            //       flex: 1,
            //     )
            //   ],
            // ).marginSymmetric(horizontal: horSpace),
            30.h.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                getCustomFont(
                  "Don't have an account?",
                  16,
                  getFontBlackColor(context),
                  1,
                  fontWeight: FontWeight.w400,
                ),
                InkWell(
                  onTap: () {
                    Constant.sendToNext(context, registrationRoute);
                  },
                  child: getCustomFont(
                    " Sign up",
                    18,
                    accentColor,
                    1,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            )
          ],
        ));
  }
}
