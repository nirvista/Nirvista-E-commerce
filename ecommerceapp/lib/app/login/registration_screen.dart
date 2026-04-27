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
  State<StatefulWidget> createState() => _RegistrationScreen();
}

class _RegistrationScreen extends State<RegistrationScreen> {
  void backClick(BuildContext context) => Constant.backToFinish(context);

  // Independent eye-toggle per password field
  final RxBool showPass = false.obs;
  final RxBool showConfirmPass = false.obs;
  final RxBool isLoading = false.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController pass2Controller = TextEditingController();

  String? userType;
  bool isChecked = false;

  // ── Email validator ──────────────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  // ── Unified field decoration ─────────────────────────────────────────────────
  // Single source of truth — every input on this screen shares the same
  // border radius, border colour, fill colour, and font style.
  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14.sp,
        color: getFontColor(context).withOpacity(0.45),
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      filled: true,
      fillColor: getCardColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide:
            BorderSide(color: getAccentColor(context).withOpacity(0.35), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide:
            BorderSide(color: getAccentColor(context).withOpacity(0.35), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: getAccentColor(context), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      suffixIcon: suffix,
      suffixIconConstraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
    );
  }

  // ── Plain text field ─────────────────────────────────────────────────────────
  Widget _buildTextField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required double horSpace,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horSpace),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 14.sp,
          color: getFontColor(context),
          fontWeight: FontWeight.w400,
        ),
        decoration: _fieldDecoration(context: context, hint: hint),
      ),
    );
  }

  // ── Password field with eye icon ─────────────────────────────────────────────
  Widget _buildPasswordField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required RxBool showPassObs,
    required double horSpace,
    String? Function(String?)? validator,
  }) {
    return Obx(() => Container(
          margin: EdgeInsets.symmetric(horizontal: horSpace),
          child: TextFormField(
            controller: controller,
            obscureText: !showPassObs.value,
            validator: validator,
            style: TextStyle(
              fontSize: 14.sp,
              color: getFontColor(context),
              fontWeight: FontWeight.w400,
            ),
            decoration: _fieldDecoration(
              context: context,
              hint: hint,
              suffix: GestureDetector(
                onTap: () => showPassObs.value = !showPassObs.value,
                child: Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: Icon(
                    showPassObs.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: getAccentColor(context),
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    final double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);

    return buildTitleDefaultWidget(
      context,
      "Sign Up",
      () => backClick(context),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Full Name ────────────────────────────────────────────────────────
          getCustomFont("Full Name", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildTextField(
            context: context,
            hint: "Enter your name",
            controller: nameController,
            horSpace: horSpace,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your full name' : null,
          ),

          20.h.verticalSpace,

          // ── Email ────────────────────────────────────────────────────────────
          getCustomFont("Email", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildTextField(
            context: context,
            hint: "Enter Email Address",
            controller: emailController,
            horSpace: horSpace,
            keyboardType: TextInputType.emailAddress,
            validator: (email) {
              if (email == null || email.isEmpty) return 'Please enter email address';
              if (!_isValidEmail(email))
                return 'Please enter a valid email';
              return null;
            },
          ),

          20.h.verticalSpace,

          // ── Phone ────────────────────────────────────────────────────────────
          getCustomFont("Phone Number", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildTextField(
            context: context,
            hint: "Enter Phone Number",
            controller: numberController,
            horSpace: horSpace,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter phone number' : null,
          ),

          20.h.verticalSpace,

          // ── Password ─────────────────────────────────────────────────────────
          getCustomFont("Password", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildPasswordField(
            context: context,
            hint: "Enter your password",
            controller: passController,
            showPassObs: showPass,          // ← independent toggle
            horSpace: horSpace,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter password' : null,
          ),

          20.h.verticalSpace,

          // ── Confirm Password ─────────────────────────────────────────────────
          getCustomFont("Confirm Password", 16, getFontColor(context), 1)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildPasswordField(
            context: context,
            hint: "Confirm password",
            controller: pass2Controller,
            showPassObs: showConfirmPass,   // ← independent toggle
            horSpace: horSpace,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please confirm your password' : null,
          ),

          20.h.verticalSpace,

          // ── User Type ────────────────────────────────────────────────────────
          Center(
            child: getCustomFont("Select User Type", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: "customer",
                groupValue: userType,
                activeColor: getAccentColor(context),
                onChanged: (v) => setState(() => userType = v),
              ),
              getCustomFont("Customer", 14, getFontColor(context), 1),
              20.w.horizontalSpace,
              Radio<String>(
                value: "vendor",
                groupValue: userType,
                activeColor: getAccentColor(context),
                onChanged: (v) => setState(() => userType = v),
              ),
              getCustomFont("Vendor", 14, getFontColor(context), 1),
            ],
          ),

          // ── Terms & Privacy ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                activeColor: getAccentColor(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6.h))),
                side: BorderSide(color: getAccentColor(context), width: 1.h),
                value: isChecked,
                onChanged: (v) => setState(() => isChecked = v ?? false),
              ),
              getCustomFont(
                  "Accept Terms & Privacy Policy", 14, getFontColor(context), 1),
            ],
          ),

          30.h.verticalSpace,

          // ── Sign Up button ───────────────────────────────────────────────────
          Obx(() => getButtonFigma(
                context,
                getAccentColor(context),
                true,
                isLoading.value ? "Creating..." : "Sign Up",
                Colors.white,
                isLoading.value
                    ? () {}
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          _snack("Please enter your full name");
                          return;
                        }
                        if (emailController.text.trim().isEmpty) {
                          _snack("Please enter email address");
                          return;
                        }
                        if (!_isValidEmail(emailController.text)) {
                          _snack(
                              "Please enter a valid email");
                          return;
                        }
                        if (numberController.text.trim().isEmpty) {
                          _snack("Please enter phone number");
                          return;
                        }
                        if (passController.text.isEmpty) {
                          _snack("Please enter password");
                          return;
                        }
                        if (pass2Controller.text.isEmpty) {
                          _snack("Please confirm your password");
                          return;
                        }
                        if (passController.text != pass2Controller.text) {
                          _snack("Passwords do not match");
                          return;
                        }
                        if (userType == null) {
                          _snack("Select user type");
                          return;
                        }
                        if (!isChecked) {
                          _snack("Accept Terms & Privacy Policy");
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
                            if (!context.mounted) return;

                            if (userType == 'vendor') {
                              final loginResult = await ApiService.userLogin(
                                email: emailController.text.trim(),
                                password: passController.text,
                              );

                              if (!loginResult['success']) {
                                _snack(loginResult['message'] ??
                                    'Account created but login failed. Please try logging in.');
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
                              _snack(
                                  "Account created! Complete your vendor profile.");
                              Navigator.pushNamed(context, vendorProfileRoute);
                            } else {
                              _snack(
                                  "Account created successfully! Please log in.");
                              Constant.sendToNext(context, loginRoute);
                            }
                          } else {
                            _snack(result['message'] ?? 'Signup failed');
                          }
                        } catch (e) {
                          _snack("Error: $e");
                        } finally {
                          isLoading.value = false;
                        }
                      },
                EdgeInsets.symmetric(horizontal: horSpace, vertical: 40.h),
              )),

          20.h.verticalSpace,

          // ── Login link ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getCustomFont(
                  "Already have an account?", 16, getFontBlackColor(context), 1),
              InkWell(
                onTap: () => Constant.sendToNext(context, loginRoute),
                child: getCustomFont(" Login", 18, accentColor, 1,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}