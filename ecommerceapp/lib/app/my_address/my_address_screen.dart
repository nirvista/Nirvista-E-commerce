import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/get/route_key.dart';
import '../../base/Constant.dart';
import '../../base/color_data.dart';
import '../../base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../services/address_api.dart';
import '../../base/get/login_data_controller.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAddressScreen();
  }
}

class _MyAddressScreen extends State<MyAddressScreen> {
  backClick(BuildContext context) {
    Constant.backToPrev(context);
  }
  
  List<AddressModel> addresses = [];
  bool isLoading = true;
  final loginController = Get.find<LoginDataController>();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() { isLoading = true; });
    final token = loginController.accessToken;
    if (token == null || token.isEmpty) {
      setState(() { isLoading = false; addresses = []; });
      return;
    }
    try {
      final res = await AddressApiService.getUserAddresses(token);
      if (res['success'] && res['data'] != null) {
        setState(() {
          addresses = (res['data'] as List).map((e) => AddressModel.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; addresses = []; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _deleteAddress(String id) async {
    final token = loginController.accessToken ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await AddressApiService.deleteAddress(token, id);
      Navigator.pop(context); // hide loading
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted successfully'), backgroundColor: Colors.green));
        _fetchAddresses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete address'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    return WillPopScope(
      onWillPop: () async {
        backClick(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: Column(
          children: [
            getDefaultHeader(context, "My Address", () {
              backClick(context);
            }, isShowSearch: false),
            getVerSpace(20.h),
            Expanded(
              flex: 1,
              child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : (addresses.isNotEmpty)
                  ? ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: addresses.length,
                      separatorBuilder: (ctx, index) => Container(
                        color: getCardColor(context),
                        child: getDivider(setColor: Colors.grey.shade300).marginSymmetric(horizontal: 20.h),
                      ),
                      itemBuilder: (ctx, index) {
                        final addr = addresses[index];
                        return buildAddressWidget(
                          EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
                          context,
                          addr,
                          (value) {
                            switch (value) {
                              case "edit":
                                showAddressDialog(context, address: addr, onSaved: () => _fetchAddresses());
                                break;
                              case "delete":
                                getDeleteDialog(context, () {
                                  _deleteAddress(addr.id);
                                });
                                break;
                            }
                          },
                        );
                      },
                    )
                  : getEmptyWidget(
                      context,
                      "no_add_img.svg",
                      "No Address Yet!",
                      "Add your address and lets get started.",
                      "Add",
                      () {
                        showAddressDialog(context, onSaved: () => _fetchAddresses());
                      }),
            ),
          ],
        ),
        floatingActionButton: addresses.isNotEmpty ? FloatingActionButton(
          onPressed: () { showAddressDialog(context, onSaved: () => _fetchAddresses()); },
          backgroundColor: getAccentColor(context),
          child: const Icon(Icons.add, color: Colors.white),
        ) : null,
      ),
    );
  }

  getDeleteDialog(BuildContext context, Function onConfirm) {
    showGetDeleteDialog(
      context,
      "Are you sure you want to delete this address?",
      "Delete",
      () {
        onConfirm();
      },
      withCancelBtn: true,
      functionCancel: () {},
    );
  }

  Widget buildAddressWidget(
    EdgeInsets margin,
    BuildContext context,
    AddressModel addr,
    ValueChanged? menuFunction,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      color: getCardColor(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    getCustomFont(addr.addressLabel, 16, getFontColor(context), 1, fontWeight: FontWeight.w600),
                    if (addr.isDefaultShipping) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4.w)),
                        child: getCustomFont("DEFAULT", 10, Colors.green, 1, fontWeight: FontWeight.bold),
                      ),
                    ]
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: menuFunction,
                child: getSvgImageWithSize(context, "menu.svg", 20.h, 16.h),
                itemBuilder: (_) => <PopupMenuItem<String>>[
                  const PopupMenuItem<String>(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 14))),
                  const PopupMenuItem<String>(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 14))),
                ],
              )
            ],
          ),
          getVerSpace(8.h),
          getCustomFont(addr.recipientName, 15, getFontColor(context), 1, fontWeight: FontWeight.w500),
          getVerSpace(4.h),
          getCustomFont(addr.fullAddress, 14, getFontGreyColor(context), 2, fontWeight: FontWeight.w400),
        ],
      ),
      );
      // child: (homeController.currentCustomer!.shipping!=null)?:,
      
  }
}
