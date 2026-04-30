import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
// fetch_pixels not needed in card-centered layout
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

  // ── Password field with eye icon ─────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);

    return buildTitleDefaultWidget(
      context,
      "Sign Up",
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
              // ── Header text ──────────────────────────────────────────────────
              Text(
                "Create Account ✨",
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
                "Join us and start shopping",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: getFontColor(context).withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 24.h),

              // ── Full Name ────────────────────────────────────────────────────
              _fieldLabel(context, "Full Name"),
              SizedBox(height: 6.h),
              _buildTextField(
                context: context,
                hint: "Enter your full name",
                controller: nameController,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter your full name' : null,
              ),

              SizedBox(height: 16.h),

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
                  if (email == null || email.isEmpty)
                    return 'Please enter email address';
                  if (!_isValidEmail(email)) return 'Please enter a valid email';
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              // ── Phone ────────────────────────────────────────────────────────
              _fieldLabel(context, "Phone Number"),
              SizedBox(height: 6.h),
              _buildTextField(
                context: context,
                hint: "Enter phone number",
                controller: numberController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter phone number' : null,
              ),

              SizedBox(height: 16.h),

              // ── Password ─────────────────────────────────────────────────────
              _fieldLabel(context, "Password"),
              SizedBox(height: 6.h),
              _buildPasswordField(
                context: context,
                hint: "Create a password",
                controller: passController,
                showPassObs: showPass,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter password' : null,
              ),

              SizedBox(height: 16.h),

              // ── Confirm Password ─────────────────────────────────────────────
              _fieldLabel(context, "Confirm Password"),
              SizedBox(height: 6.h),
              _buildPasswordField(
                context: context,
                hint: "Repeat your password",
                controller: pass2Controller,
                showPassObs: showConfirmPass,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please confirm your password' : null,
              ),

              SizedBox(height: 20.h),

              // ── User Type selector ───────────────────────────────────────────
              Text(
                "Register as",
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

              SizedBox(height: 16.h),

              // ── Terms & Privacy ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      activeColor: getAccentColor(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r)),
                      side: BorderSide(
                          color: getAccentColor(context), width: 1.5),
                      value: isChecked,
                      onChanged: (v) =>
                          setState(() => isChecked = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "I agree to the ",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: getFontColor(context).withOpacity(0.65),
                        ),
                        children: [
                          TextSpan(
                            text: "Terms & Privacy Policy",
                            style: TextStyle(
                              color: getAccentColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22.h),

              // ── Sign Up button ───────────────────────────────────────────────
              Obx(() => SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : _onSignup,
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
                              "Create Account",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  )),

              SizedBox(height: 18.h),

              // ── Login link ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: getFontColor(context).withOpacity(0.6),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Constant.sendToNext(context, loginRoute),
                    child: Text(
                      "Log In",
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

  // ── Sign Up action ───────────────────────────────────────────────────────────
  Future<void> _onSignup() async {
    if (nameController.text.trim().isEmpty) {
      _snack("Please enter your full name");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _snack("Please enter email address");
      return;
    }
    if (!_isValidEmail(emailController.text)) {
      _snack("Please enter a valid email");
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
          final accessToken = loginResult['data']['accessToken'];
          final refreshToken = loginResult['data']['refreshToken'];

          final loginController = Get.find<LoginDataController>();
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
          _snack("Account created! Complete your vendor profile.");
          Navigator.pushNamed(context, vendorProfileRoute);
        } else {
          _snack("Account created successfully! Please log in.");
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
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}