import 'dart:convert';


WooCartItem wooCartItemFromJson(String str) => WooCartItem.fromJson(json.decode(str));

String wooCartItemToJson(WooCartItem data) => json.encode(data.toJson());

class WooCartItem {
  WooCartItem({
    this.key,
    this.id,
    this.quantity,
    this.quantityLimits,
    this.name,
    this.shortDescription,
    this.description,
    this.sku,
    this.lowStockRemaining,
    this.backordersAllowed,
    this.showBackorderBadge,
    this.soldIndividually,
    this.permalink,
    this.images,
    this.variation,
    this.itemData,
    this.prices,
    this.totals,
    this.catalogVisibility,
    this.extensions,
    this.links,
  });

  String? key;
  int? id;
  int? quantity;
  QuantityLimits? quantityLimits;
  String? name;
  String? shortDescription;
  String? description;
  String? sku;
  dynamic lowStockRemaining;
  bool? backordersAllowed;
  bool? showBackorderBadge;
  bool? soldIndividually;
  String? permalink;
  List<Image>? images;
  List<dynamic>? variation;
  List<dynamic>? itemData;
  Prices? prices;
  Totals? totals;
  String? catalogVisibility;
  Extensions? extensions;
  Links? links;

  factory WooCartItem.fromJson(Map<String, dynamic> json) => WooCartItem(
    key: json["key"]?.toString(),
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    quantity: json["quantity"] is int ? json["quantity"] : int.tryParse(json["quantity"]?.toString() ?? ''),
    quantityLimits:(json["quantity_limits"]!=null)?QuantityLimits.fromJson(json["quantity_limits"]):null,
    name: json["name"]?.toString(),
    shortDescription: json["short_description"]?.toString(),
    description: json["description"]?.toString(),
    sku: json["sku"]?.toString(),
    lowStockRemaining: json["low_stock_remaining"],
    backordersAllowed: json["backorders_allowed"],
    showBackorderBadge: json["show_backorder_badge"],
    soldIndividually: json["sold_individually"],
    permalink: json["permalink"]?.toString(),
    images: json["images"] != null ? List<Image>.from(json["images"].map((x) => Image.fromJson(x))) : [],
    variation: json["variation"] != null ? List<dynamic>.from(json["variation"].map((x) => x)) : [],
    itemData: json["item_data"] != null ? List<dynamic>.from(json["item_data"].map((x) => x)) : [],
    prices: json["prices"] != null ? Prices.fromJson(json["prices"]) : null,
    totals: json["totals"] != null ? Totals.fromJson(json["totals"]) : null,
    catalogVisibility: json["catalog_visibility"]?.toString(),
    extensions: json["extensions"] != null ? Extensions.fromJson(json["extensions"]) : null,
    links: (json["_links"]!=null)?Links.fromJson(json["_links"]):null,
  );

  Map<String, dynamic> toJson() => {
    "key": key,
    "id": id,
    "quantity": quantity,
    "quantity_limits": quantityLimits!.toJson(),
    "name": name,
    "short_description": shortDescription,
    "description": description,
    "sku": sku,
    "low_stock_remaining": lowStockRemaining,
    "backorders_allowed": backordersAllowed,
    "show_backorder_badge": showBackorderBadge,
    "sold_individually": soldIndividually,
    "permalink": permalink,
    "images": List<dynamic>.from(images!.map((x) => x.toJson())),
    "variation": List<dynamic>.from(variation!.map((x) => x)),
    "item_data": List<dynamic>.from(itemData!.map((x) => x)),
    "prices": prices!.toJson(),
    "totals": totals!.toJson(),
    "catalog_visibility": catalogVisibility,
    "extensions": extensions!.toJson(),
    "_links": links!.toJson(),
  };
}

class Extensions {
  Extensions();

  factory Extensions.fromJson(Map<String, dynamic> json) => Extensions(
  );

  Map<String, dynamic> toJson() => {
  };
}

class Image {
  Image({
    this.id,
    this.src,
    this.thumbnail,
    this.srcset,
    this.sizes,
    this.name,
    this.alt,
  });

  int? id;
  String? src;
  String? thumbnail;
  String? srcset;
  String? sizes;
  String? name;
  String? alt;

  factory Image.fromJson(Map<String, dynamic> json) => Image(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    src: json["src"]?.toString(),
    thumbnail: json["thumbnail"]?.toString(),
    srcset: json["srcset"]?.toString(),
    sizes: json["sizes"]?.toString(),
    name: json["name"]?.toString(),
    alt: json["alt"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "src": src,
    "thumbnail": thumbnail,
    "srcset": srcset,
    "sizes": sizes,
    "name": name,
    "alt": alt,
  };
}

class Links {
  Links({
    this.self,
    this.collection,
  });

  List<Collection>? self;
  List<Collection>? collection;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    self: List<Collection>.from(json["self"].map((x) => Collection.fromJson(x))),
    collection: List<Collection>.from(json["collection"].map((x) => Collection.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "self": List<dynamic>.from(self!.map((x) => x.toJson())),
    "collection": List<dynamic>.from(collection!.map((x) => x.toJson())),
  };
}

class Collection {
  Collection({
    this.href,
  });

  String? href;

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    href: json["href"],
  );

  Map<String, dynamic> toJson() => {
    "href": href,
  };
}

class Prices {
  Prices({
    this.price,
    this.regularPrice,
    this.salePrice,
    this.priceRange,
    this.currencyCode,
    this.currencySymbol,
    this.currencyMinorUnit,
    this.currencyDecimalSeparator,
    this.currencyThousandSeparator,
    this.currencyPrefix,
    this.currencySuffix,
    this.rawPrices,
  });

  String? price;
  String? regularPrice;
  String? salePrice;
  dynamic priceRange;
  String? currencyCode;
  String? currencySymbol;
  int? currencyMinorUnit;
  String? currencyDecimalSeparator;
  String? currencyThousandSeparator;
  String? currencyPrefix;
  String? currencySuffix;
  RawPrices? rawPrices;

  factory Prices.fromJson(Map<String, dynamic> json) => Prices(
    price: json["price"]?.toString(),
    regularPrice: json["regular_price"]?.toString(),
    salePrice: json["sale_price"]?.toString(),
    priceRange: json["price_range"],
    currencyCode: json["currency_code"]?.toString(),
    currencySymbol: json["currency_symbol"]?.toString(),
    currencyMinorUnit: json["currency_minor_unit"] is int ? json["currency_minor_unit"] : int.tryParse(json["currency_minor_unit"]?.toString() ?? ''),
    currencyDecimalSeparator: json["currency_decimal_separator"]?.toString(),
    currencyThousandSeparator: json["currency_thousand_separator"]?.toString(),
    currencyPrefix: json["currency_prefix"]?.toString(),
    currencySuffix: json["currency_suffix"]?.toString(),
    rawPrices: json["raw_prices"] != null ? RawPrices.fromJson(json["raw_prices"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "price": price,
    "regular_price": regularPrice,
    "sale_price": salePrice,
    "price_range": priceRange,
    "currency_code": currencyCode,
    "currency_symbol": currencySymbol,
    "currency_minor_unit": currencyMinorUnit,
    "currency_decimal_separator": currencyDecimalSeparator,
    "currency_thousand_separator": currencyThousandSeparator,
    "currency_prefix": currencyPrefix,
    "currency_suffix": currencySuffix,
    "raw_prices": rawPrices!.toJson(),
  };
}

class RawPrices {
  RawPrices({
    this.precision,
    this.price,
    this.regularPrice,
    this.salePrice,
  });

  int? precision;
  String? price;
  String? regularPrice;
  String? salePrice;

  factory RawPrices.fromJson(Map<String, dynamic> json) => RawPrices(
    precision: json["precision"] is int ? json["precision"] : int.tryParse(json["precision"]?.toString() ?? ''),
    price: json["price"]?.toString(),
    regularPrice: json["regular_price"]?.toString(),
    salePrice: json["sale_price"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "precision": precision,
    "price": price,
    "regular_price": regularPrice,
    "sale_price": salePrice,
  };
}

class QuantityLimits {
  QuantityLimits({
    this.minimum,
    this.maximum,
    this.multipleOf,
    this.editable,
  });

  int? minimum;
  int? maximum;
  int? multipleOf;
  bool? editable;

  factory QuantityLimits.fromJson(Map<String, dynamic> json) => QuantityLimits(
    minimum: json["minimum"] is int ? json["minimum"] : int.tryParse(json["minimum"]?.toString() ?? ''),
    maximum: json["maximum"] is int ? json["maximum"] : int.tryParse(json["maximum"]?.toString() ?? ''),
    multipleOf: json["multiple_of"] is int ? json["multiple_of"] : int.tryParse(json["multiple_of"]?.toString() ?? ''),
    editable: json["editable"],
  );

  Map<String, dynamic> toJson() => {
    "minimum": minimum,
    "maximum": maximum,
    "multiple_of": multipleOf,
    "editable": editable,
  };
}

class Totals {
  Totals({
    this.lineSubtotal,
    this.lineSubtotalTax,
    this.lineTotal,
    this.lineTotalTax,
    this.currencyCode,
    this.currencySymbol,
    this.currencyMinorUnit,
    this.currencyDecimalSeparator,
    this.currencyThousandSeparator,
    this.currencyPrefix,
    this.currencySuffix,
  });

  String? lineSubtotal;
  String? lineSubtotalTax;
  String? lineTotal;
  String? lineTotalTax;
  String? currencyCode;
  String? currencySymbol;
  int? currencyMinorUnit;
  String? currencyDecimalSeparator;
  String? currencyThousandSeparator;
  String? currencyPrefix;
  String? currencySuffix;

  factory Totals.fromJson(Map<String, dynamic> json) => Totals(
    lineSubtotal: json["line_subtotal"]?.toString(),
    lineSubtotalTax: json["line_subtotal_tax"]?.toString(),
    lineTotal: json["line_total"]?.toString(),
    lineTotalTax: json["line_total_tax"]?.toString(),
    currencyCode: json["currency_code"]?.toString(),
    currencySymbol: json["currency_symbol"]?.toString(),
    currencyMinorUnit: json["currency_minor_unit"] is int ? json["currency_minor_unit"] : int.tryParse(json["currency_minor_unit"]?.toString() ?? ''),
    currencyDecimalSeparator: json["currency_decimal_separator"]?.toString(),
    currencyThousandSeparator: json["currency_thousand_separator"]?.toString(),
    currencyPrefix: json["currency_prefix"]?.toString(),
    currencySuffix: json["currency_suffix"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "line_subtotal": lineSubtotal,
    "line_subtotal_tax": lineSubtotalTax,
    "line_total": lineTotal,
    "line_total_tax": lineTotalTax,
    "currency_code": currencyCode,
    "currency_symbol": currencySymbol,
    "currency_minor_unit": currencyMinorUnit,
    "currency_decimal_separator": currencyDecimalSeparator,
    "currency_thousand_separator": currencyThousandSeparator,
    "currency_prefix": currencyPrefix,
    "currency_suffix": currencySuffix,
  };
}

