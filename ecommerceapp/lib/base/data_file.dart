import 'package:pet_shop/app/model_ui/model_best_selling_pro.dart';
import 'package:pet_shop/app/model_ui/model_blog.dart';
import 'package:pet_shop/app/model_ui/model_cart.dart';
import 'package:pet_shop/app/model_ui/model_category.dart';
import 'package:pet_shop/app/model_ui/model_coupons.dart';
import 'package:pet_shop/app/model_ui/model_favourite.dart';
import 'package:pet_shop/app/model_ui/model_payment_method.dart';
import '../app/model/model_bottom_nav.dart';
import '../app/model/model_intro.dart';
import '../app/model_ui/model_order.dart';
import '../app/model_ui/model_popular_product.dart';
import '../app/model_ui/model_sub_category.dart';
import '../app/model_ui/model_dummy_product.dart';

class DataFile {
  static List<ModelBottomNav> getAllBottomNavList() {
    List<ModelBottomNav> bottomList = [];

    bottomList.add(ModelBottomNav("Home", "home.svg", "home_selected.svg"));
    bottomList.add(ModelBottomNav("Categories", "category.svg", "category_selected.svg"));
    // bottomList
    //     .add(ModelBottomNav("Search", "search.svg", "search_selected.svg"));
    bottomList.add(
        ModelBottomNav("Cart", "bag.svg", "bag_filled.svg"));
    bottomList.add(ModelBottomNav("Heart", "bottom_nav_fav.svg", "heart_selected.svg"));
    bottomList
        .add(ModelBottomNav("Profile", "profile.svg", "profile_selected.svg"));

    return bottomList;
  }

  static List<ModelIntro> getAllIntroList() {
    List<ModelIntro> list = [];
    list.add(ModelIntro(
        "Healthy & Tasty \nFood For Pets",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod ",
        "intro1.png"));

    list.add(ModelIntro(
        "Upgrade Your Pets & \nMake It More Stylist",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod ",
        "intro2.png"));

    list.add(ModelIntro(
        "Lorem ipsum dolor sit \namet, consectetur ",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod ",
        "intro3.png"));

    list.add(ModelIntro(
        "Lorem ipsum dolor sit \namet, consectetur ",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod ",
        "intro4.png"));

    return list;
  }

  static List<ModelPopularProduct> getAllPopularProductList(){
    List<ModelPopularProduct> list = [];

    list.add(ModelPopularProduct("popular1.png", "Pet Paw Cleaner", "\$26.00"));
    list.add(ModelPopularProduct("popular2.png", "Dry Food Mini", "\$30.00"));
    list.add(ModelPopularProduct("popular3.png", "Hand Brush", "\$26.00"));
    list.add(ModelPopularProduct("popular4.png", "Fur Care Glove", "\$30.00"));
    list.add(ModelPopularProduct("popular5.png", "Fur Care Glove", "\$19.00"));
    list.add(ModelPopularProduct("popular6.png", "Pets Grooming", "\$10.00"));
    return list;
  }

  static List<ModelCategory> getAllCategory(){
    List<ModelCategory> list = [];
    list.add(ModelCategory("cat1.png", "Mens"));
    list.add(ModelCategory("cat2.png", "Womens"));
    list.add(ModelCategory("cat3.png", "Kids"));
    list.add(ModelCategory("cat4.png", "Electronics"));
    list.add(ModelCategory("cat1.png", "Accessories"));
    list.add(ModelCategory("cat1.png", "Home & Furniture"));
    return list;
  }

  static List<ModelSubCategory> getAllSubCategory(){
    List<ModelSubCategory> list = [];
    list.add(ModelSubCategory("subCat_1.png", "Dry Food"));
    list.add(ModelSubCategory("subCat_2.png", "Treats"));
    list.add(ModelSubCategory("subCat_3.png", "Ring Toy"));
    list.add(ModelSubCategory("subCat_4.png", "COf Roll"));
    list.add(ModelSubCategory("subCat_5.png", "Glove"));
    list.add(ModelSubCategory("subCat_6.png", "Cleaner"));
    list.add(ModelSubCategory("subCat_7.png", "Brush"));
    list.add(ModelSubCategory("subCat_8.png", "Pedigree"));
    list.add(ModelSubCategory("subCat_9.png", "Fur Care"));
    list.add(ModelSubCategory("subCat_10.png", "F&T Collar"));
    return list;
  }

  static List<ModelBlog> getAllBlog(){
    List<ModelBlog> list = [];
    list.add(ModelBlog("Lbendum est ultricies integer quis auctor.", "blog1.png", "28 Sep,2022"));
    list.add(ModelBlog("Non enim praesent elementum facilisis.", "blog2.png", "26 Sep,2022"));
    list.add(ModelBlog("Ut venenatis tellus in metus vulputate eu scelerisque.", "blog3.png", "20 Sep,2022"));
    list.add(ModelBlog("Arcu vitae elementum curabitur vitae nunc ", "blog4.png", "20 Sep,2022"));
    return list;
  }

  static List<ModelBestSellingProduct> getAllBestSellProduct(){
    List<ModelBestSellingProduct> list = [];
    list.add(ModelBestSellingProduct("best_sell_1.png", "Healthy Treats", "\$12.00"));
    list.add(ModelBestSellingProduct("best_sell_2.png", "Pedigree Nutritions", "\$30.00"));
    list.add(ModelBestSellingProduct("best_sell_4.png", "Rope Leash For Dog", "\$40.00"));
    list.add(ModelBestSellingProduct("best_sell_3.png", "Dry Food Mini", "\$30.00"));
    list.add(ModelBestSellingProduct("best_sell_5.png", "Pet Ring Toy", "\$80.00"));
    list.add(ModelBestSellingProduct("best_sell_6.png", "Chiken & COD Roll", "\$20.00"));
    return list;
  }

  static List<ModelCart> getAllCartList() {
    List<ModelCart> list = [];
    list.add(ModelCart('best_sell_4.png', "Dog Rope Leash", "\$30.00", "3",attribute: {"color":"Blue","size":"5 Feet"}));
    list.add(ModelCart('best_sell_1.png', "Healthy Treats", "\$20.00", "3"));
    list.add(ModelCart('best_sell_3.png', "Dry Food", "\$30.00", "3"));
    return list;
  }

  static List<ModelCoupons> getAllCouponsList(){
    List<ModelCoupons> list = [];
    list.add(ModelCoupons("10% Off", "Mauris nunc congue nisi vitae suscipit tellus mauris a", "12 Oct,2022","QWE874"));
    list.add(ModelCoupons("15% Off", "Ac tincidunt vitae semper quis. Pellentesque adipiscing com ", "18 Oct,2022","BAC7414"));
    list.add(ModelCoupons("20% Off", "Ac tincidunt vitae semper quis. Pellentesque adipiscing com ", "18 Oct,2022","PWQ589"));
    return list;
  }

  static List<ModelPaymentMtd> getAllPaymentMthList(){
    List<ModelPaymentMtd> list = [];
    list.add(ModelPaymentMtd("paypal.svg", "Paypal",num: "XXXX XXXX XXXX 2563"));
    list.add(ModelPaymentMtd("money.svg", "Cash On Delivery",));
    list.add(ModelPaymentMtd("Stripe.svg", "Stripe",));
    return list;
  }
  
  static List<ModelOrder> getAllOrderList(){
    List<ModelOrder> list = [];
    list.add(ModelOrder("74123698", "1", "8 July,2022", "\$60.00", "Pending"));
    list.add(ModelOrder("5231874", "3", "8 July,2022", "\$20.00", "cancelled"));
    list.add(ModelOrder("74123698", "1", "8 July,2022", "\$60.00", "Delivered"));
    list.add(ModelOrder("87456932", "2", "11 July,2022", "\$40.00", "Delivered"));
    return list;
  }
  static List<ModelFavourite> getAllFavList(){
    List<ModelFavourite> list = [];
    list.add(ModelFavourite("best_sell_5.png", "Pet Ring Toy", "\$80.00"));
    list.add(ModelFavourite("best_sell_6.png", "Chiken & COD Roll", "\$20.00"));
    list.add(ModelFavourite("popular6.png", "Pets Grooming", "\$80.00"));
    list.add(ModelFavourite("subCat_10.png", "F&T Collar Dog", "\$80.00"));
    list.add(ModelFavourite("best_sell_3.png", "Dry Food", "\$80.00"));
    list.add(ModelFavourite("best_sell_4.png", "Rope Leash For Dog", "\$80.00"));
    return list;
  }

  static List<DummyProduct> getAllDummyProducts() {
    List<DummyProduct> list = [];

    // Fashion - Kurtas
    list.add(DummyProduct(
      id: 101,
      name: "Women Viscose Rayon Kurta Pant Dupatta Set",
      brand: "FABUNNA COTTON",
      category: "fashion",
      subCategory: "kurta",
      price: 307,
      originalPrice: 2099,
      rating: 4.2,
      reviewCount: 1200,
      imageUrl: "https://images.unsplash.com/photo-1610189352649-6b88573f3428?w=400&q=80",
      colors: ["Pink", "Blue", "Green"],
      sizes: ["XS", "S", "M", "L", "XL", "XXL"],
      description: "Featuring a beautiful embroidered and printed pattern, this women's kurta, pants, and dupatta set offers an attractive, elegant aesthetic. The intricate embroidery adds a touch of sophistication, enhancing the overall appeal of the outfit.",
      isBestSelling: true,
      isTopDeal: true,
    ));

    list.add(DummyProduct(
      id: 102,
      name: "Premium Silk Ethnic Kurta",
      brand: "Jaipur Traditional",
      category: "fashion",
      subCategory: "kurta",
      price: 1299,
      originalPrice: 3499,
      rating: 4.5,
      reviewCount: 856,
      imageUrl: "https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400&q=80",
      colors: ["Maroon", "Navy", "Gold"],
      sizes: ["XS", "S", "M", "L", "XL", "XXL"],
      description: "Premium silk ethnic kurta with traditional embroidery work perfect for festive occasions.",
      isBestSelling: true,
    ));

    // Fashion - Shirts
    list.add(DummyProduct(
      id: 103,
      name: "Men's Casual Cotton Shirt",
      brand: "ColorPlus",
      category: "fashion",
      subCategory: "shirts",
      price: 599,
      originalPrice: 1299,
      rating: 4.1,
      reviewCount: 2341,
      imageUrl: "https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&q=80",
      colors: ["White", "Sky Blue", "Charcoal"],
      sizes: ["XS", "S", "M", "L", "XL", "XXL"],
      description: "Comfortable casual cotton shirt perfect for daily wear and weekend outings.",
      isBestSelling: false,
      isTopDeal: true,
    ));

    // Fashion - Dress
    list.add(DummyProduct(
      id: 104,
      name: "Women's Fit & Flare Dress",
      brand: "Fashion Trend",
      category: "fashion",
      subCategory: "dresses",
      price: 849,
      originalPrice: 2199,
      rating: 4.3,
      reviewCount: 1567,
      imageUrl: "https://images.unsplash.com/photo-1612336307429-8a898d10e223?w=400&q=80",
      colors: ["Black", "Red", "Navy"],
      sizes: ["XS", "S", "M", "L", "XL"],
      description: "Elegant fit and flare dress ideal for parties and casual gatherings.",
    ));

    // Mobiles - Smartphones
    list.add(DummyProduct(
      id: 201,
      name: "Samsung Galaxy S24 Ultra",
      brand: "Samsung",
      category: "mobiles",
      subCategory: "smartphones",
      price: 89999,
      originalPrice: 129999,
      rating: 4.6,
      reviewCount: 5623,
      imageUrl: "https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=400&q=80",
      colors: ["Black", "White", "Silver"],
      sizes: [],
      description: "Latest Samsung flagship with 200MP camera and 6.8\" display.",
      isBestSelling: true,
    ));

    list.add(DummyProduct(
      id: 202,
      name: "Redmi Note 14 Pro",
      brand: "Xiaomi",
      category: "mobiles",
      subCategory: "smartphones",
      price: 25999,
      originalPrice: 39999,
      rating: 4.4,
      reviewCount: 8934,
      imageUrl: "https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=400&q=80",
      colors: ["Blue", "Green", "Black"],
      sizes: [],
      description: "Powerful smartphone with 50MP camera and 120Hz display at affordable price.",
      isBestSelling: true,
      isTopDeal: true,
    ));

    // Mobiles - Earphones
    list.add(DummyProduct(
      id: 203,
      name: "boAt Airdopes 131",
      brand: "boAt",
      category: "mobiles",
      subCategory: "earphones",
      price: 1299,
      originalPrice: 4990,
      rating: 4.0,
      reviewCount: 12400,
      imageUrl: "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400&q=80",
      colors: ["Black", "White", "Red"],
      sizes: [],
      description: "Wireless earbuds with 8 hours battery life and IPX5 water resistance.",
      isTopDeal: true,
    ));

    // Mobiles - Charger
    list.add(DummyProduct(
      id: 204,
      name: "65W Fast Charger",
      brand: "Ambrane",
      category: "mobiles",
      subCategory: "chargers",
      price: 799,
      originalPrice: 2499,
      rating: 4.2,
      reviewCount: 3456,
      imageUrl: "https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=400&q=80",
      colors: ["Black", "White"],
      sizes: [],
      description: "Fast charging adapter compatible with all major smartphone brands.",
    ));

    // Beauty - Lipstick
    list.add(DummyProduct(
      id: 301,
      name: "Maybelline SuperStay Matte",
      brand: "Maybelline",
      category: "beauty",
      subCategory: "lipstick",
      price: 399,
      originalPrice: 699,
      rating: 4.3,
      reviewCount: 4521,
      imageUrl: "https://images.unsplash.com/photo-1586495777744-4e6232bf0849?w=400&q=80",
      colors: ["Red", "Nude", "Coral", "Berry"],
      sizes: [],
      description: "Long-lasting matte liquid lipstick with 16H wear time.",
      isBestSelling: true,
    ));

    list.add(DummyProduct(
      id: 302,
      name: "Lakme Absolute Lip Gloss",
      brand: "Lakme",
      category: "beauty",
      subCategory: "lipstick",
      price: 349,
      originalPrice: 549,
      rating: 4.1,
      reviewCount: 2834,
      imageUrl: "https://images.unsplash.com/photo-1625093742435-6d63d3fd4abb?w=400&q=80",
      colors: ["Pink", "Plum", "Peach"],
      sizes: [],
      description: "Glossy finish lipstick with SPF protection.",
    ));

    // Beauty - Foundation
    list.add(DummyProduct(
      id: 303,
      name: "Lakme 9 to 5 Foundation",
      brand: "Lakme",
      category: "beauty",
      subCategory: "foundation",
      price: 445,
      originalPrice: 695,
      rating: 4.4,
      reviewCount: 5678,
      imageUrl: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&q=80",
      colors: ["Fair", "Medium", "Olive"],
      sizes: [],
      description: "Lightweight liquid foundation with 12-hour staying power.",
      isBestSelling: true,
      isTopDeal: true,
    ));

    // Beauty - Eye Makeup
    list.add(DummyProduct(
      id: 304,
      name: "Nykaa Eyeshadow Palette",
      brand: "Nykaa",
      category: "beauty",
      subCategory: "eyeshadow",
      price: 599,
      originalPrice: 999,
      rating: 4.5,
      reviewCount: 3921,
      imageUrl: "https://images.unsplash.com/photo-1512207736890-6ffed8a84e8d?w=400&q=80",
      colors: ["Warm", "Cool", "Neutral"],
      sizes: [],
      description: "12-shade professional eyeshadow palette with rich pigmentation.",
    ));

    // Electronics - Earbuds
    list.add(DummyProduct(
      id: 401,
      name: "Sony WF-C700 Earbuds",
      brand: "Sony",
      category: "electronics",
      subCategory: "earbuds",
      price: 6990,
      originalPrice: 11990,
      rating: 4.4,
      reviewCount: 6234,
      imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80",
      colors: ["Black", "White"],
      sizes: [],
      description: "Premium wireless earbuds with active noise cancellation.",
      isBestSelling: true,
    ));

    // Electronics - Hair Appliance
    list.add(DummyProduct(
      id: 402,
      name: "Philips Hair Dryer 2100W",
      brand: "Philips",
      category: "electronics",
      subCategory: "hair_appliances",
      price: 1899,
      originalPrice: 3495,
      rating: 4.2,
      reviewCount: 2167,
      imageUrl: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80",
      colors: ["Black"],
      sizes: [],
      description: "Professional hair dryer with ionic technology and 6 heat settings.",
      isTopDeal: true,
    ));

    // Electronics - Smart Watch
    list.add(DummyProduct(
      id: 403,
      name: "Realme Watch 3 Pro",
      brand: "Realme",
      category: "electronics",
      subCategory: "smartwatch",
      price: 4999,
      originalPrice: 9999,
      rating: 4.1,
      reviewCount: 4562,
      imageUrl: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80",
      colors: ["Black", "Silver"],
      sizes: [],
      description: "Smartwatch with AMOLED display and 10-day battery life.",
      isBestSelling: true,
      isTopDeal: true,
    ));

    // Electronics - Power Bank
    list.add(DummyProduct(
      id: 404,
      name: "Anker PowerCore 20000mAh",
      brand: "Anker",
      category: "electronics",
      subCategory: "power_banks",
      price: 1499,
      originalPrice: 2999,
      rating: 4.3,
      reviewCount: 7845,
      imageUrl: "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400&q=80",
      colors: ["Black", "White"],
      sizes: [],
      description: "High-capacity power bank with fast charging support.",
    ));

    // Home Decor - Clock
    list.add(DummyProduct(
      id: 501,
      name: "Wooden Wall Clock",
      brand: "Home Essence",
      category: "home_decor",
      subCategory: "clocks",
      price: 499,
      originalPrice: 1299,
      rating: 4.0,
      reviewCount: 1234,
      imageUrl: "https://images.unsplash.com/photo-1563861826100-9cb868fdbe1c?w=400&q=80",
      colors: ["Natural", "Brown", "Black"],
      sizes: [],
      description: "Elegant wooden wall clock perfect for living rooms and offices.",
      isBestSelling: true,
    ));

    // Home Decor - Candles
    list.add(DummyProduct(
      id: 502,
      name: "Scented Candle Set",
      brand: "Aroma Feel",
      category: "home_decor",
      subCategory: "candles",
      price: 799,
      originalPrice: 1999,
      rating: 4.4,
      reviewCount: 2156,
      imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80",
      colors: ["Lavender", "Rose", "Vanilla"],
      sizes: [],
      description: "Premium scented candles set with natural ingredients.",
      isTopDeal: true,
    ));

    // Home Decor - Photo Frame
    list.add(DummyProduct(
      id: 503,
      name: "Digital Photo Frame",
      brand: "TechView",
      category: "home_decor",
      subCategory: "frames",
      price: 2499,
      originalPrice: 5999,
      rating: 4.2,
      reviewCount: 892,
      imageUrl: "https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=400&q=80",
      colors: ["Black", "White"],
      sizes: [],
      description: "7\" digital photo frame with WiFi connectivity.",
      isBestSelling: true,
      isTopDeal: true,
    ));

    // Home Decor - Table Lamp
    list.add(DummyProduct(
      id: 504,
      name: "LED Table Lamp",
      brand: "Luminous",
      category: "home_decor",
      subCategory: "lamps",
      price: 649,
      originalPrice: 1599,
      rating: 4.1,
      reviewCount: 1567,
      imageUrl: "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400&q=80",
      colors: ["Silver", "Gold", "Bronze"],
      sizes: [],
      description: "Modern LED table lamp with touch control and 3 brightness levels.",
    ));

    return list;
  }

  static List<DummyProduct> getProductsByCategory(String category) {
    return getAllDummyProducts()
        .where((product) => product.category == category)
        .toList();
  }

  static List<String> getFeaturedBrands() {
    return [
      "H&M",
      "Zara",
      "Samsung",
      "Apple",
      "Maybelline",
      "Lakme",
      "boAt",
      "Philips"
    ];
  }

}
