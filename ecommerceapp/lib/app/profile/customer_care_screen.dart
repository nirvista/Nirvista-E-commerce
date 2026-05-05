import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/widget_utils.dart';

class CustomerCareScreen extends StatefulWidget {
  const CustomerCareScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CustomerCareScreen();
  }
}

class _CustomerCareScreen extends State<CustomerCareScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    return WillPopScope(
        child: Scaffold(
          backgroundColor: getScaffoldColor(context),

          body: Column(
            children: [
              getDefaultHeader(context, "Customer Care", (){backClick();},isShowSearch: false),
              getVerSpace(20.h),
              Flexible(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: getCardColor(context),
                        borderRadius: BorderRadius.circular(16.h),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24.h),
                      child: Column(
                        children: [
                          // Email Section
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.h),
                                decoration: BoxDecoration(
                                  color: getAccentColor(context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.h),
                                ),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: getAccentColor(context),
                                  size: 24.h,
                                ),
                              ),
                              16.w.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getCustomFont(
                                      "Email",
                                      14,
                                      getFontColor(context).withOpacity(0.7),
                                      1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    4.h.verticalSpace,
                                    getCustomFont(
                                      "support@nirvista.com",
                                      16,
                                      getFontColor(context),
                                      1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          getVerSpace(24.h),
                          getDividerWidget(),
                          getVerSpace(24.h),
                          // Phone Section
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.h),
                                decoration: BoxDecoration(
                                  color: getAccentColor(context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.h),
                                ),
                                child: Icon(
                                  Icons.phone_outlined,
                                  color: getAccentColor(context),
                                  size: 24.h,
                                ),
                              ),
                              16.w.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getCustomFont(
                                      "Contact Number",
                                      14,
                                      getFontColor(context).withOpacity(0.7),
                                      1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    4.h.verticalSpace,
                                    getCustomFont(
                                      "+1 234 567 8900",
                                      16,
                                      getFontColor(context),
                                      1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    20.h.verticalSpace,
                    // Additional info card
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(20.h),
                      decoration: BoxDecoration(
                        color: getCardColor(context),
                        borderRadius: BorderRadius.circular(16.h),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getCustomFont(
                            "Business Hours",
                            16,
                            getFontColor(context),
                            1,
                            fontWeight: FontWeight.w600,
                          ),
                          12.h.verticalSpace,
                          getCustomFont(
                            "Monday - Friday: 9:00 AM - 6:00 PM",
                            14,
                            getFontColor(context).withOpacity(0.7),
                            1,
                            fontWeight: FontWeight.w400,
                          ),
                          8.h.verticalSpace,
                          getCustomFont(
                            "Saturday - Sunday: 10:00 AM - 4:00 PM",
                            14,
                            getFontColor(context).withOpacity(0.7),
                            1,
                            fontWeight: FontWeight.w400,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        onWillPop: () async {
          backClick();
          return false;
        });
  }
}