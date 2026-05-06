import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/woocommerce/model/user.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
// fetch_pixels not needed in card-centered layout
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
  final RxBool rememberMe = false.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  String? userType;

  // ── Email validator ──────────────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  // ── Unified field decoration ─────────────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14.sp,
        color: getFontColor(context).withOpacity(0.4),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, color: getAccentColor(context), size: 20.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      filled: true,
      fillColor: getCardColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide:
            BorderSide(color: getAccentColor(context).withOpacity(0.25), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide:
            BorderSide(color: getAccentColor(context).withOpacity(0.25), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: getAccentColor(context), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
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
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14.sp,
        color: getFontColor(context),
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(
          context: context, hint: hint, prefixIcon: prefixIcon),
    );
  }

  // ── Password field ───────────────────────────────────────────────────────────
  Widget _buildPasswordField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required RxBool showPassObs,
    String? Function(String?)? validator,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          obscureText: !showPassObs.value,
          validator: validator,
          style: TextStyle(
            fontSize: 14.sp,
            color: getFontColor(context),
            fontWeight: FontWeight.w500,
          ),
          decoration: _fieldDecoration(
            context: context,
            hint: hint,
            prefixIcon: Icons.lock_outline_rounded,
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);

    return buildTitleDefaultWidget(
      context,
      "Login",
      () => backClick(context),
      // ── Card-style centered form ─────────────────────────────────────────────
      Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Welcome text ─────────────────────────────────────────────────
              Text(
                "Welcome",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: getFontColor(context),
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Sign in to your account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: getFontColor(context).withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 24.h),

              // ── Email ────────────────────────────────────────────────────────
              _fieldLabel(context, "Email Address"),
              SizedBox(height: 6.h),
              _buildTextField(
                context: context,
                hint: "Enter your email",
                controller: emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (email) {
                  if (email == null || email.isEmpty) return 'Please enter email address';
                  if (!_isValidEmail(email)) return 'Please enter a valid email';
                  return null;
                },
              ),

              SizedBox(height: 18.h),

              // ── Password ─────────────────────────────────────────────────────
              _fieldLabel(context, "Password"),
              SizedBox(height: 6.h),
              _buildPasswordField(
                context: context,
                hint: "Enter your password",
                controller: passController,
                showPassObs: showPass,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter password' : null,
              ),

              SizedBox(height: 12.h),

              // ── Remember me + Forgot password ────────────────────────────────
              Row(
                children: [
                  Obx(() => Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: getAccentColor(context), width: 1.5),
                          activeColor: getAccentColor(context),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.r)),
                          onChanged: (v) => rememberMe.value = v!,
                          value: rememberMe.value,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )),
                  Text(
                    "Remember me",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: getFontColor(context),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Constant.sendToNext(context, forgotPassScreenRoute),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: getAccentColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // ── User Type selector ───────────────────────────────────────────
              Text(
                "Login as",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: getFontColor(context).withOpacity(0.7),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(child: _roleChip(context, "Customer", "customer")),
                  SizedBox(width: 12.w),
                  Expanded(child: _roleChip(context, "Vendor", "vendor")),
                ],
              ),

              SizedBox(height: 24.h),

              // ── Log In button ────────────────────────────────────────────────
              Obx(() => SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getAccentColor(context),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            getAccentColor(context).withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: isLoading.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  )),

              SizedBox(height: 20.h),

              // ── Sign up link ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: getFontColor(context).withOpacity(0.6),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Constant.sendToNext(context, registrationRoute),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: getAccentColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Role chip widget ─────────────────────────────────────────────────────────
  Widget _roleChip(BuildContext context, String label, String value) {
    final bool selected = userType == value;
    return GestureDetector(
      onTap: () => setState(() => userType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44.h,
        decoration: BoxDecoration(
          color: selected
              ? getAccentColor(context)
              : getAccentColor(context).withOpacity(0.07),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? getAccentColor(context)
                : getAccentColor(context).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : getAccentColor(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Field label ──────────────────────────────────────────────────────────────
  Widget _fieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: getFontColor(context).withOpacity(0.75),
      ),
    );
  }

  // ── Login action ─────────────────────────────────────────────────────────────
  Future<void> _onLogin() async {
    if (emailController.text.isEmpty) {
      _snack("Please enter email");
      return;
    }
    if (!_isValidEmail(emailController.text)) {
      _snack("Please enter a valid email");
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
            refreshToken: refreshToken,
            rememberMe: rememberMe.value);

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
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}