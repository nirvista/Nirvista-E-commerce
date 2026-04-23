import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';
import '../../services/loginregisterapi.dart';
import '../../woocommerce/model/user.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RegistrationScreen();
  }
}

class _RegistrationScreen extends State<RegistrationScreen> {
  backClick(BuildContext context) {
    Constant.backToFinish(context);
  }

  RxBool showPass = false.obs;
  RxBool isLoading = false.obs;

  TextEditingController emailController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController pass2Controller = TextEditingController();

  String? userType;
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);

    return buildTitleDefaultWidget(
      context,
      "Sign Up",
      () {
        backClick(context);
      },
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Full Name", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          getDefaultTextFiled(
            context,
            "Enter your name",
            nameController,
            getFontColor(context),
            (value) {},
          ),

          20.h.verticalSpace,
          getCustomFont("Email", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          getDefaultTextFiled(
            context,
            "Enter Email Address",
            emailController,
            getFontColor(context),
            (value) {},
          ),

          20.h.verticalSpace,
          getCustomFont("Phone Number", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          getDefaultTextFiled(
            context,
            "Enter Phone Number",
            numberController,
            getFontColor(context),
            (value) {},
          ),

          20.h.verticalSpace,
          getCustomFont("Password", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          Obx(() => getPassTextFiled(
                context,
                "Enter your password",
                passController,
                getFontColor(context),
                showPass.value,
                () => showPass.value = !showPass.value,
              )),

          20.h.verticalSpace,
          getCustomFont("Confirm Password", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          Obx(() => getPassTextFiled(
                context,
                "Confirm password",
                pass2Controller,
                getFontColor(context),
                showPass.value,
                () => showPass.value = !showPass.value,
              )),

          20.h.verticalSpace,

          Center(
            child: getCustomFont(
                "Select User Type", 16, getFontColor(context), 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: "customer",
                groupValue: userType,
                onChanged: (val) => setState(() => userType = val),
              ),
              const Text("Customer"),
              20.w.horizontalSpace,
              Radio<String>(
                value: "vendor",
                groupValue: userType,
                onChanged: (val) => setState(() => userType = val),
              ),
              const Text("Vendor"),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (val) =>
                    setState(() => isChecked = val ?? false),
              ),
              const Text("Accept Terms & Privacy Policy"),
            ],
          ),

          30.h.verticalSpace,

          Obx(() {
            return getButtonFigma(
              context,
              getAccentColor(context),
              true,
              isLoading.value ? "Creating..." : "Sign Up",
              Colors.white,
              isLoading.value
                  ? () {}
                  : () async {
                      if (!isChecked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Accept Terms & Privacy Policy")),
                        );
                        return;
                      }

                      if (userType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Select user type")),
                        );
                        return;
                      }

                      if (passController.text != pass2Controller.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Passwords do not match")),
                        );
                        return;
                      }

                      isLoading.value = true;

                      try {
                        final result = await ApiService.userSignup(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passController.text,
                          confirmPassword: pass2Controller.text,
                          phone: numberController.text.trim(),
                          userRole: userType!,
                        );

                        if (result['success']) {
                          if (userType == 'vendor') {
                            // Signup returns no token, so auto-login immediately
                            // to get a valid token for the profile screen.
                            final loginResult = await ApiService.userLogin(
                              email: emailController.text.trim(),
                              password: passController.text,
                            );

                            if (!loginResult['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loginResult['message'] ??
                                      'Account created but login failed. Please try logging in.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final userData = loginResult['data']['user'];
                            final accessToken =
                                loginResult['data']['accessToken'];
                            final refreshToken =
                                loginResult['data']['refreshToken'];

                            final loginController =
                                Get.find<LoginDataController>();
                            loginController.saveUser(
                              User(
                                id: userData['id']?.toString(),
                                name: userData['name']?.toString(),
                                email: userData['email']?.toString(),
                                phone: userData['phone']?.toString(),
                                userRole: userData['userRole']?.toString(),
                              ),
                              accessToken: accessToken,
                              refreshToken: refreshToken,
                            );

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Account created! Complete your vendor profile."),
                              ),
                            );
                            Navigator.pushNamed(context, vendorProfileRoute);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Account created successfully")),
                            );
                            Constant.sendToNext(
                                context, verificationScreenRoute);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  result['message'] ?? 'Signup failed'),
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
                      } finally {
                        isLoading.value = false;
                      }
                    },
              EdgeInsets.symmetric(horizontal: horSpace, vertical: 40.h),
            );
          }),

          20.h.verticalSpace,

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account?"),
              InkWell(
                onTap: () {
                  Constant.sendToNext(context, loginRoute);
                },
                child: const Text(
                  " Login",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}