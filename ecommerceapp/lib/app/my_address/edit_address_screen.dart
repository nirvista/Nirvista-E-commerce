import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import '../../base/Constant.dart';
import '../../base/color_data.dart';
import '../../base/widget_utils.dart';
import '../../csc_picker/csc_picker.dart';
import '../../app/model/api_models.dart';
import '../../services/address_api.dart';
import '../../base/get/login_data_controller.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel? address;
  const EditAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditAddressScreen();
  }
}

class _EditAddressScreen extends State<EditAddressScreen> {
  backClick(BuildContext context) {
    Constant.backToPrev(context);
  }

  final fullNameController = TextEditingController();
  final line1Controller = TextEditingController();
  final line2Controller = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();
  
  String countryValue = "India";
  String stateValue = "Maharashtra";
  String addressLabel = "Home";
  bool isDefault = false;
  
  AddressModel? existingAddress;

  @override
  void initState() {
    super.initState();
    // Check if we are editing an existing address passed via arguments
    existingAddress = Get.arguments as AddressModel?;
    
    if (existingAddress != null) {
      fullNameController.text = existingAddress!.recipientName;
      line1Controller.text = existingAddress!.addressLine1;
      line2Controller.text = existingAddress!.addressLine2 ?? "";
      cityController.text = existingAddress!.city;
      postalCodeController.text = existingAddress!.postalCode;
      countryValue = existingAddress!.country;
      stateValue = existingAddress!.state;
      addressLabel = existingAddress!.addressLabel;
      isDefault = existingAddress!.isDefaultShipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double horSpace = FetchPixels.getDefaultHorSpaceFigma(context);

    return WillPopScope(
      onWillPop: () async {
        backClick(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: Column(
          children: [
            getDefaultHeader(context, existingAddress != null ? "Edit Address" : "Add Address", () {
              backClick(context);
            }, isShowSearch: false),
            Expanded(
              flex: 1,
              child: Container(
                color: getCardColor(context),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                margin: EdgeInsets.symmetric(vertical: 20.h),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    20.h.verticalSpace,
                    getLabel("Address Label (e.g. Home, Office)", horSpace),
                    6.h.verticalSpace,
                    _buildLabelSelector(context, horSpace),
                    20.h.verticalSpace,
                    getLabel("Full name", horSpace),
                    6.h.verticalSpace,
                    getDefaultTextFiled(context, "Full Name", fullNameController, getFontColor(context), (v){}),
                    20.h.verticalSpace,
                    getLabel("Address Line 1", horSpace),
                    6.h.verticalSpace,
                    getDefaultTextFiled(context, "Street, House No", line1Controller, getFontColor(context), (v){}),
                    20.h.verticalSpace,
                    getLabel("Address Line 2 (Optional)", horSpace),
                    6.h.verticalSpace,
                    getDefaultTextFiled(context, "Apartment, Suite, etc", line2Controller, getFontColor(context), (v){}),
                    20.h.verticalSpace,
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horSpace),
                      child: CSCPicker(
                        showStates: true,
                        showCities: false,
                        currentCountry: countryValue,
                        currentState: stateValue,
                        dropdownDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.h),
                          color: Colors.transparent,
                          border: Border.all(color: black20, width: 1.h)
                        ),
                        onCountryChanged: (v) => setState(() => countryValue = v),
                        onStateChanged: (v) => setState(() => stateValue = v ?? ""),
                        onCityChanged: (v) {},
                      ),
                    ),
                    
                    20.h.verticalSpace,
                    getLabel("City", horSpace),
                    6.h.verticalSpace,
                    getDefaultTextFiled(context, "City", cityController, getFontColor(context), (v){}),
                    20.h.verticalSpace,
                    getLabel("Postal Code", horSpace),
                    6.h.verticalSpace,
                    getDefaultTextFiled(context, "Postal Code", postalCodeController, getFontColor(context), (v){}, keyboardType: TextInputType.number),
                    
                    20.h.verticalSpace,
                    CheckboxListTile(
                      title: getCustomFont("Set as default address", 14, getFontColor(context), 1),
                      value: isDefault,
                      onChanged: (v) => setState(() => isDefault = v ?? false),
                      activeColor: getAccentColor(context),
                      contentPadding: EdgeInsets.symmetric(horizontal: horSpace),
                    )
                  ],
                ),
              ),
            ),
            getButtonFigma(context, getAccentColor(context), true, "Save Address", Colors.white, () async {
              _saveAddress();
            }, EdgeInsets.symmetric(horizontal: 20.h, vertical: 15.h)),
          ],
        ),
      ),
    );
  }

  Widget getLabel(String text, double horSpace) {
    return getCustomFont(text, 16, getFontColor(context), 1, fontWeight: FontWeight.w400).marginSymmetric(horizontal: horSpace);
  }

  Widget _buildLabelSelector(BuildContext context, double horSpace) {
    List<String> labels = ["Home", "Office", "Other"];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horSpace),
      child: DropdownButtonFormField<String>(
        value: labels.contains(addressLabel) ? addressLabel : null,
        hint: getCustomFont("Select Label", 14, getFontGreyColor(context), 1),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.h)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.h),
            borderSide: BorderSide(color: black20, width: 1.h),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.h),
            borderSide: BorderSide(color: getAccentColor(context), width: 1.h),
          ),
        ),
        items: labels.map((l) => DropdownMenuItem(
          value: l,
          child: getCustomFont(l, 14, getFontColor(context), 1),
        )).toList(),
        onChanged: (v) {
          if (v != null) setState(() => addressLabel = v);
        },
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (fullNameController.text.isEmpty || line1Controller.text.isEmpty || cityController.text.isEmpty || postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final loginController = Get.find<LoginDataController>();
    final token = loginController.accessToken ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      if (existingAddress != null) {
        res = await AddressApiService.updateAddress(
          accessToken: token,
          addressId: existingAddress!.id,
          addressLabel: addressLabel,
          recipientName: fullNameController.text,
          addressLine1: line1Controller.text,
          addressLine2: line2Controller.text,
          city: cityController.text,
          state: stateValue,
          postalCode: postalCodeController.text,
          country: countryValue,
          isDefaultShipping: isDefault,
        );
      } else {
        res = await AddressApiService.addAddress(
          accessToken: token,
          addressLabel: addressLabel,
          recipientName: fullNameController.text,
          addressLine1: line1Controller.text,
          addressLine2: line2Controller.text,
          city: cityController.text,
          state: stateValue,
          postalCode: postalCodeController.text,
          country: countryValue,
          isDefaultShipping: isDefault,
        );
      }

      Navigator.pop(context); // hide loading

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved successfully'), backgroundColor: Colors.green));
        Get.back(result: true); // Refresh calling screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to save address')));
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }
}
