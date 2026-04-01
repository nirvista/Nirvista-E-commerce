
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/fetch_pixels.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';
import '../../services/loginregisterapi.dart';

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
    return buildTitleDefaultWidget(context, "Sign Up", () {
      backClick(context);
    },
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont("Full Name", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            getDefaultTextFiled(context, "Enter your name", nameController,
                getFontColor(context), (value) {}, validator: (email) {
                  if (email!.isNotEmpty) {
                    return null;
                  } else {
                    return 'Please enter full name';
                  }
                }),
            20.h.verticalSpace,
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
            getCustomFont("Phone Number", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            getDefaultTextFiled(context, "Enter Phone Number", numberController,
                getFontColor(context), (value) {}, validator: (phone) {
                  if (phone!.isNotEmpty) {
                    return null;
                  } else {
                    return 'Please enter phone number';
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
                "Enter your password",
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
            getCustomFont("Confirm Password", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w400)
                .marginSymmetric(horizontal: horSpace),
            8.h.verticalSpace,
            ObxValue((p0) {
              return getPassTextFiled(
                context,
                "Enter your password",
                pass2Controller,
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
             SizedBox(height: 20,),
                       getCustomFont("Select User Type", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w400),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [                       
                            Radio<String>(
                              value: "customer",
                              groupValue: userType,
                              onChanged: (String? value) {
                                setState(() {
                                  userType = value!;
                                });
                              },
                            ),
                            getCustomFont("Customer", 14, getFontColor(context), 1,
        fontWeight: FontWeight.w400),
                        
                            Radio<String>(
                              value: "vendor",
                              groupValue: userType,
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
                         SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(value: isChecked, onChanged: (value){
                              setState(() {
                                isChecked = value!;
                              });
                            }),
                            getCustomFont("I Accept the Terms & Privacy Policy", 14, getFontColor(context), 1,
                                fontWeight: FontWeight.w400,textAlign: TextAlign.center),
                            // Flexible(child:Text("I Accept the Terms & Privacy Policy",textAlign: TextAlign.center,))         
                          ],
                        ),
            SizedBox(height: 40),
            ObxValue((loading) {
              return getButtonFigma(
                context,
                getAccentColor(context),
                true,
                isLoading.value ? "Creating Account..." : "Sign Up",
                Colors.white,
                isLoading.value ? () {} : () async {
                  // Validation
                  if (!isChecked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(20),
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text("Please accept Terms & Privacy Policy", 
                                style: TextStyle(fontWeight: FontWeight.bold),)
                            ),
                          ],
                        ),
                        duration: Duration(seconds: 5),
                      ),
                    );
                    return;
                  }
                  
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter your full name"))
                    );
                    return;
                  }
                  
                  if (emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter email address"))
                    );
                    return;
                  }
                  
                  if (numberController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter phone number"))
                    );
                    return;
                  }
                  
                  if (passController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter password"))
                    );
                    return;
                  }
                  
                  if (pass2Controller.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please confirm password"))
                    );
                    return;
                  }
                  
                  if (passController.text != pass2Controller.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Passwords do not match"),
                        backgroundColor: Colors.red,
                      )
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
                    final result = await ApiService.userSignup(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passController.text,
                      confirmPassword: pass2Controller.text,
                      phone: numberController.text.trim(),
                      userRole: userType!,
                    );
                    
                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Account created successfully!"))
                      );
                      Constant.sendToNext(context, verificationScreenRoute);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Signup failed'),
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
                EdgeInsets.symmetric(horizontal: horSpace, vertical: 50.h)
              );
            }, isLoading),
            30.h.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                getCustomFont(
                  "Already have an account?",
                  16,
                  getFontBlackColor(context),
                  1,
                  fontWeight: FontWeight.w400,
                ),
                InkWell(
                  onTap: () {
                    Constant.sendToNext(context, loginRoute);
                  },
                  child: getCustomFont(
                    " Login",
                    18,
                    accentColor,
                    1,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            ),
          ],
        ));
  }
}







// class LoginScreen extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() {
//     return _LoginScreen();
//   }
// }
//
// class _LoginScreen extends State<LoginScreen> {
//   backClick(BuildContext context) {
//     Constant.backToFinish(context);
//   }
//
//   RxBool showPass = false.obs;
//
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     Constant.setupSize(context);
//
//     double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);
//     return buildTitleDefaultWidget(context, "Login", "Glad to meet you again! ",
//         () {
//       backClick(context);
//     },
//         Column(
//           children: [
//             getDefaultTextFiled(
//                 context, "Email", emailController, getFontColor(context),(value) {
//
//                 }),
//             20.h.verticalSpace,
//             ObxValue((p0) {
//               return getPassTextFiled(context, "Password", passController,
//                   getFontColor(context), showPass.value, () {
//                 showPass.value = !showPass.value;
//               });
//             }, showPass),
//             20.h.verticalSpace,
//             Align(
//               alignment: Alignment.bottomRight,
//               child: InkWell(
//                 onTap: () {
//                   Constant.sendToNext(context, forgotPassRoute);
//                 },
//                 child: getCustomFont(
//                     "Forgot password ?", 16, getFontColor(context), 1,
//                     fontWeight: FontWeight.w400, textAlign: TextAlign.end),
//               ),
//             ).paddingOnly(right: horSpace),
//             getButtonFigma(
//                 context,
//                 getAccentColor(context),
//                 true,
//                 "Log In",
//                 Colors.white,
//                 () {},
//                 EdgeInsets.symmetric(horizontal: horSpace, vertical: 40.h)),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child:
//                       getDivider(setColor: getCurrentTheme(context).hintColor),
//                   flex: 1,
//                 ),
//                 getCustomFont(" OR Sign in with ", 16, getFontColor(context), 1,
//                     fontWeight: FontWeight.w400, textAlign: TextAlign.center),
//                 Expanded(
//                   child:
//                       getDivider(setColor: getCurrentTheme(context).hintColor),
//                   flex: 1,
//                 )
//               ],
//             ).marginSymmetric(horizontal: horSpace),
//             30.h.verticalSpace,
//             getButtonFigma(
//                 context,
//                 getCardColor(context),
//                 true,
//                 "Login with Google",
//                 getFontColor(context),
//                 () {},
//                 EdgeInsets.zero,
//                 isIcon: true,
//                 icons: "Google.svg",
//                 shadow: [
//                   const BoxShadow(
//                       color: Color.fromRGBO(130, 164, 131, 0.2199999988079071),
//                       offset: Offset(0, 7),
//                       blurRadius: 33)
//                 ]).marginSymmetric(horizontal: horSpace, vertical: 10.h),
//             getButtonFigma(
//                 context,
//                 getCardColor(context),
//                 true,
//                 "Login with Facebook",
//                 getFontColor(context),
//                 () {},
//                 EdgeInsets.zero,
//                 isIcon: true,
//                 icons: "Facebook.svg",
//                 shadow: [
//                   BoxShadow(
//                       color: Color.fromRGBO(130, 164, 131, 0.2199999988079071),
//                       offset: Offset(0, 7),
//                       blurRadius: 33)
//                 ]).marginSymmetric(horizontal: horSpace, vertical: 10.h),
//             80.h.verticalSpace,
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 getCustomFont(
//                   "Already have an account?",
//                   16,
//                   getFontBlackColor(context),
//                   1,
//                   fontWeight: FontWeight.w400,
//                 ),
//                 getCustomFont(
//                   " Sign up",
//                   18,
//                   getFontBlackColor(context),
//                   1,
//                   fontWeight: FontWeight.w700,
//                 )
//               ],
//             )
//           ],
//         ));
//   }
// }
