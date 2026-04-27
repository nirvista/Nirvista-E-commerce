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
  State<StatefulWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  void backClick(BuildContext context) => Constant.backToFinish(context);

  final RxBool showPass = false.obs;
  final RxBool isLoading = false.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  String? userType;

  // ── Email validator ──────────────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  // ── Unified field style ──────────────────────────────────────────────────────
  // Used for BOTH plain-text fields and password fields so every input
  // looks identical (same border radius, border colour, background, font).
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

  // ── Plain text field (email, name, phone …) ──────────────────────────────────
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

  // ── Password field (with eye icon) ───────────────────────────────────────────
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
    final RxBool agreeTerm = false.obs;
    Constant.setupSize(context);
    final double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);

    return buildTitleDefaultWidget(
      context,
      "Login",
      () => backClick(context),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email ────────────────────────────────────────────────────────────
          getCustomFont("Email", 16, getFontColor(context), 1,
                  fontWeight: FontWeight.w400)
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

          // ── Password ─────────────────────────────────────────────────────────
          getCustomFont("Password", 16, getFontColor(context), 1,
                  fontWeight: FontWeight.w400)
              .marginSymmetric(horizontal: horSpace),
          8.h.verticalSpace,
          _buildPasswordField(
            context: context,
            hint: "Enter Password",
            controller: passController,
            showPassObs: showPass,
            horSpace: horSpace,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter password' : null,
          ),

          20.h.verticalSpace,

          // ── Remember me + Forgot password ────────────────────────────────────
          Row(
            children: [
              ObxValue(
                (p0) => Checkbox(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: getAccentColor(context), width: 1.h),
                  activeColor: getAccentColor(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.h))),
                  onChanged: (v) => agreeTerm.value = v!,
                  value: agreeTerm.value,
                ),
                agreeTerm,
              ),
              getCustomFont("Remember me", 14, getFontColor(context), 1,
                  fontWeight: FontWeight.w400),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () =>
                        Constant.sendToNext(context, forgotPassScreenRoute),
                    child: getCustomFont(
                        "Forgot password ?", 16, getFontColor(context), 1,
                        fontWeight: FontWeight.w400),
                  ),
                ).paddingOnly(right: horSpace),
              ),
            ],
          ),

          20.h.verticalSpace,

          // ── User Type ────────────────────────────────────────────────────────
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
                onChanged: (v) => setState(() => userType = v!),
              ),
              getCustomFont("Customer", 14, getFontColor(context), 1),
              20.w.horizontalSpace,
              Radio<String>(
                value: "vendor",
                groupValue: userType,
                activeColor: getAccentColor(context),
                onChanged: (v) => setState(() => userType = v!),
              ),
              getCustomFont("Vendor", 14, getFontColor(context), 1),
            ],
          ),

          20.h.verticalSpace,

          // ── Log In button ────────────────────────────────────────────────────
          ObxValue(
            (loading) => getButtonFigma(
              context,
              getAccentColor(context),
              true,
              isLoading.value ? "Logging in..." : "Log In",
              Colors.white,
              isLoading.value
                  ? () {}
                  : () async {
                      if (emailController.text.isEmpty) {
                        _snack("Please enter email");
                        return;
                      }
                      if (!_isValidEmail(emailController.text)) {
                        _snack(
                            "Please enter a valid email");
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
                          final accessToken = result['data']['accessToken'];
                          final refreshToken = result['data']['refreshToken'];

                          final serverRole =
                              userData['userRole'].toString().toLowerCase();
                          final selectedRole = userType!.toLowerCase();

                          if (serverRole != selectedRole) {
                            isLoading.value = false;
                            _snack("This account is registered as $serverRole");
                            return;
                          }

                          final loggedInUser = User(
                            id: userData['id'],
                            name: userData['name'],
                            email: userData['email'],
                            phone: userData['phone'],
                            userRole: userData['userRole'],
                          );

                          final loginController = Get.find<LoginDataController>();

                          if (serverRole == 'vendor') {
                            final meResult =
                                await VendorApiService.getCurrentUser(accessToken);

                            if (meResult['success'] != true) {
                              _snack("Unable to verify vendor status");
                              isLoading.value = false;
                              return;
                            }

                            final status = meResult['data']?['userStatus']
                                ?.toString()
                                .toLowerCase();

                            if (status != 'active') {
                              _snack(status == 'pending'
                                  ? "Your account is under review. Wait for admin approval."
                                  : "Account is $status");
                              isLoading.value = false;
                              return;
                            }
                          }

                          loginController.saveUser(loggedInUser,
                              accessToken: accessToken,
                              refreshToken: refreshToken);

                          _snack("Login successful");

                          if (serverRole == 'vendor') {
                            Constant.sendToNext(context, vendorDashboardRoute);
                          } else {
                            Constant.sendToNext(context, homeScreenRoute);
                          }
                        } else {
                          _snack(result['message']?.toString() ?? 'Login failed');
                        }
                      } catch (e) {
                        _snack("Error: $e");
                      } finally {
                        isLoading.value = false;
                      }
                    },
              EdgeInsets.symmetric(horizontal: horSpace, vertical: 60.h),
            ),
            isLoading,
          ),

          30.h.verticalSpace,

          // ── Sign up link ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getCustomFont(
                  "Don't have an account?", 16, getFontBlackColor(context), 1),
              InkWell(
                onTap: () => Constant.sendToNext(context, registrationRoute),
                child: getCustomFont(" Sign up", 18, accentColor, 1,
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