import 'package:get/get.dart';
import 'package:pet_shop/app/model/model_dummy_selected_add.dart';

import '../../app/model/woo_payment_gateway.dart';
import '../../woocommerce/model/cart_item.dart';
import '../../woocommerce/model/product_variation.dart';
import '../../woocommerce/model/products.dart';
import '../../app/model_ui/model_dummy_product.dart';
import '../../app/model/api_models.dart';

class StorageController extends GetxController {
  WooProduct? selectedProduct;
  DummyProduct? selectedDummyProduct;
  ProductModel? selectedProductModel;
  RxInt currentQuantity=1.obs;
  Rx<WooProductVariation?> variationModel = (null).obs;
  Rx<WooCartItem?> wooCartItem=(null).obs;
  RxString selectedCategory = "for_you".obs;
  RxString selectedCategoryName = "".obs;
  RxString selectedColor = "".obs;
  RxString selectedSize = "".obs;

  // WooCartItem? wooCartItem;

  // var variationModel = WooProductVariation().obs;

  List<WooProductItemAttribute> attributeList = [];
  WooPaymentGateway? selectedPaymentGateway;
  ModelDummySelectedAdd? selectedShippingAddress;


  setCurrentQuantity(int quantity, {bool isRefresh = true})
  {
    print("setval===$quantity");
    bool isSame=currentQuantity.value==quantity;
    currentQuantity.value=quantity;
    if(isRefresh) {
      print('Called----refresh');
      update();
    }
    else{
      if(!isSame) {
        print('Called----same');
        update();
      }
    }
  }

  // refreshStorageController()
  // {
  //   update();
  // }

  addCurrentQuantity()
  {
    currentQuantity.value=currentQuantity.value+1;
    update();

  }

  removeCurrentQuantity()
  {
    currentQuantity.value=currentQuantity.value-1;
    update();
  }
  clearProductVariation()
  {
    variationModel.value=null;
    attributeList=[];
  }

  setSelectedWooProduct(WooProduct product) {
    attributeList=[];
    selectedProduct = product;
    if (selectedProduct != null && selectedProduct!.attributes.isNotEmpty) {
      print("Variatiob===${selectedProduct!.attributes}");
      selectedProduct!.attributes.forEach((element) {
        if (element.variation!) {
          attributeList.add(element);
        }
      });
      print("getsize===${attributeList.length}");
    }
  }

  setSelectedDummyProduct(DummyProduct product) {
    selectedDummyProduct = product;
    if (product.colors.isNotEmpty) {
      selectedColor.value = product.colors[0];
    }
    if (product.sizes.isNotEmpty) {
      selectedSize.value = product.sizes[0];
    }
    update();
  }

  setSelectedCategory(String category) {
    selectedCategory.value = category;
    update();
  }

  setSelectedCategoryName(String name) {
    selectedCategoryName.value = name;
    update();
  }

  setSelectedProductModel(ProductModel product) {
    selectedProductModel = product;
    // Assuming UI does variant selection directly, but wait, variants have color/size.
    // If you want to default:
    if (product.variants.isNotEmpty) {
       var v = product.variants.first;
       if (v.color != null) selectedColor.value = v.color!;
       if (v.size != null) selectedSize.value = v.size!;
    }
    update();
  }

  setSelectedColor(String color) {
    selectedColor.value = color;
    update();
  }

  setSelectedSize(String size) {
    selectedSize.value = size;
    update();
  }
}
