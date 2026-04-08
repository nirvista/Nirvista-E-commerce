import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../../services/category_api.dart';
import 'package:pet_shop/base/get/storage_controller.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with TickerProviderStateMixin {
  // StorageController storeController = Get.find<StorageController>();

  // ProductDataController productController = Get.find<ProductDataController>();

  // HomeController homeController = Get.find<HomeController>();
  StorageController storageController = Get.find<StorageController>();
  //
  // final controller = Get.find<BottomItemSelectionController>();
  //
  // int flashSale = 17;
  
  RxInt selectedId = 0.obs;
  Future<List<CategoryModel>>? categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = fetchCategories();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final result = await CategoryApiService.getAllCategories();
    if (result['success']) {
      return (result['data'] as List).map((c) => CategoryModel.fromJson(c)).toList();
    }
    return [];
  }

  // RxList<String> favProductList = <String>[].obs;
  //
  // void getFavDataList() async {
  //   favProductList.value = await PrefData().getFavouriteList();
  //   print("getvals========${favProductList.length}");
  // }
  //
  // checkInFavouriteList(WooProduct cat) async {
  //   if (favProductList.contains(cat.id.toString())) {
  //     favProductList.remove(cat.id.toString());
  //   } else {
  //     favProductList.add(cat.id!.toString());
  //   }
  // }
  //
  // RxString imageUrl = ''.obs;
  //
  // List<WooProductCategory> catList = [];
  //
  // List<ModelSubCategory> subCategory = DataFile.getAllSubCategory();
  // List<ModelCategory> allCategory = DataFile.getAllCategory();


  @override
  Widget build(BuildContext context) {
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);
    int crossCount = 2;
    double screenWidth = context.width - 200.w - (margin * 3) + margin;
    double itemWidth = screenWidth / crossCount;
    double itemHeight = 102.w;

    Constant.setupSize(context);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: getCardColor(context),
        elevation: 0,
        automaticallyImplyLeading: false, // Explicitly remove back button
        leading: null, 
        title: getCustomFont("Categories", 18, getFontColor(context), 1,
            fontWeight: FontWeight.w700),
        centerTitle: true,
      ),
      body: Column(
        children: [
          20.h.verticalSpace,
          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: getCustomFont("No categories found", 16, getFontGreyColor(context), 1));
                }

                List<CategoryModel> allCategory = snapshot.data!;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100.w,
                      height: double.infinity,
                      color: getCardColor(context),
                      child: SizedBox(
                        width: double.infinity,
                        child: ListView.builder(
                          primary: true,
                          shrinkWrap: true,
                          itemCount: allCategory.length,
                          itemBuilder: (context, index) {
                            CategoryModel category = allCategory[index];
                            return Obx(() => InkWell(
                                  onTap: () {
                                    selectedId.value = index;
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 20.h, vertical: 5.h),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.h, vertical: 10.h),
                                    decoration: getButtonDecoration(
                                      (selectedId.value == index)
                                          ? getAccentColor(context).withOpacity(0.1)
                                          : Colors.transparent,
                                      withCorners: true,
                                      corner: 6.w,
                                      withBorder: false,
                                      borderColor: getDividerColor(context),
                                    ),
                                    child: getCustomFont(
                                      category.name,
                                      16,
                                      (selectedId.value == index)
                                          ? getAccentColor(context)
                                          : getFontColor(context),
                                      3,
                                      fontWeight: FontWeight.w500,
                                      txtHeight: 1.5,
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ));
                          },
                        ),
                      ),
                    ),
                    10.h.horizontalSpace,
                    Expanded(
                      flex: 1,
                      child: Obx(() {
                        // Watch for changes in selectedId to update subcategories
                        if (allCategory.isEmpty) return SizedBox();
                        CategoryModel selectedCat = allCategory[selectedId.value];
                        List<CategoryModel> subCategory = selectedCat.children;
                        
                        if (subCategory.isEmpty) {
                          // No subcategories to show, display products instead!
                          return FutureBuilder<Map<String, dynamic>>(
                            future: CategoryApiService.getProductsByCategory(selectedCat.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator(color: accentColor));
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Center(child: getCustomFont("No products found", 14, getFontGreyColor(context), 1));
                              }
                              var res = snapshot.data!;
                              if (!res['success']) {
                                return Center(child: getCustomFont("No products found", 14, getFontGreyColor(context), 1));
                              }
                              List<dynamic> productsList = [];
                              if (res['data'] is List) {
                                productsList = res['data'];
                              } else if (res['data'] is Map && res['data']['products'] is List) {
                                productsList = res['data']['products'];
                              }
                              var products = productsList.map((e) => ProductModel.fromJson(e)).toList();
                              
                              if (products.isEmpty) {
                                return Center(child: getCustomFont("No products found", 14, getFontGreyColor(context), 1));
                              }
                              
                              return GridView.builder(
                                padding: EdgeInsets.all(margin),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10.w,
                                  mainAxisSpacing: 10.w,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, idx) {
                                  var product = products[idx];
                                  double currentPrice = product.currentPrice;
                                  
                                  return InkWell(
                                    onTap: () {
                                      storageController.setSelectedProductModel(product);
                                      Constant.sendToNext(context, productDetailScreenRoute);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: getCardColor(context),
                                        borderRadius: BorderRadius.circular(12.w),
                                        border: Border.all(color: dividerColor, width: 0.5),
                                      ),
                                      padding: EdgeInsets.all(8.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.w),
                                                color: getGreyCardColor(context),
                                              ),
                                              child: product.imageUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(10.w),
                                                    child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image_not_supported)),
                                                  )
                                                : Icon(Icons.image_not_supported, color: getFontGreyColor(context)),
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          getCustomFont(product.title, 12, getFontColor(context), 2,
                                              fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
                                          SizedBox(height: 4.h),
                                          getCustomFont("₹${currentPrice.toStringAsFixed(0)}", 13, accentColor, 1,
                                              fontWeight: FontWeight.w700),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              );
                            }
                          );
                        }
                        
                        return Container(
                          color: getCardColor(context),
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: margin,
                            crossAxisSpacing: margin,
                            padding: EdgeInsets.only(
                                left: margin, right: margin, top: 20.h, bottom: 15.h),
                            childAspectRatio: itemWidth / itemHeight,
                            children: List.generate(
                              subCategory.length,
                              (index) {
                                CategoryModel subCat = subCategory[index];
                                return InkWell(
                                  onTap: () {
                                    storageController.setSelectedCategory(subCat.id);
                                    storageController.setSelectedCategoryName(subCat.name);
                                    // Normally you would pass the category info
                                    Constant.sendToNext(context, categoryProductsPageRoute);
                                  },
                                  child: SizedBox(
                                    height: itemHeight,
                                    width: itemWidth,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            height: double.infinity,
                                            width: double.infinity,
                                            padding: EdgeInsets.all(8.h),
                                            decoration: getButtonDecoration(
                                                getGreyCardColor(context),
                                                withCorners: true,
                                                corner: 12.h),
                                            child: Icon(Icons.category, color: getFontGreyColor(context)),
                                          ),
                                        ),
                                        7.h.verticalSpace,
                                        getCustomFont(
                                          subCat.name,
                                          15,
                                          getFontColor(context),
                                          1,
                                          fontWeight: FontWeight.w500,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
