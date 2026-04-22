import 'dart:convert';

import 'package:pet_shop/woocommerce/model/customer.dart';

WooGetCreatedOrder wooGetCreatedOrderFromJson(String str) => WooGetCreatedOrder.fromJson(json.decode(str));

String wooGetCreatedOrderToJson(WooGetCreatedOrder data) => json.encode(data.toJson());

class WooGetCreatedOrder {
  WooGetCreatedOrder({
    this.id,
    this.parentId,
    this.number,
    this.orderKey,
    this.createdVia,
    this.version,
    this.status,
    this.currency,
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.discountTotal,
    this.discountTax,
    this.shippingTotal,
    this.shippingTax,
    this.cartTax,
    this.total,
    this.totalTax,
    this.pricesIncludeTax,
    this.customerId,
    this.customerIpAddress,
    this.customerUserAgent,
    this.customerNote,
    this.billing,
    this.shipping,
    this.paymentMethod,
    this.paymentMethodTitle,
    this.transactionId,
    this.datePaid,
    this.datePaidGmt,
    this.dateCompleted,
    this.dateCompletedGmt,
    this.cartHash,
    this.metaData,
    this.lineItems,
    this.taxLines,
    this.shippingLines,
    this.feeLines,
    this.couponLines,
    this.refunds,
    this.links,
  });

  int? id;
  int? parentId;
  String? number;
  String? orderKey;
  String? createdVia;
  String? version;
  String? status;
  String? currency;
  String? dateCreated;
  String? dateCreatedGmt;
  String? dateModified;
  String? dateModifiedGmt;
  String? discountTotal;
  String? discountTax;
  String? shippingTotal;
  String? shippingTax;
  String? cartTax;
  String? total;
  String? totalTax;
  bool? pricesIncludeTax;
  int? customerId;
  String? customerIpAddress;
  String? customerUserAgent;
  String? customerNote;
  Billing? billing;
  Shipping? shipping;
  String? paymentMethod;
  String? paymentMethodTitle;
  String? transactionId;
  String? datePaid;
  String? datePaidGmt;
  String? dateCompleted;
  String? dateCompletedGmt;
  String? cartHash;
  List<MetaDatum>? metaData;
  List<LineItem>? lineItems;
  List<TaxLine>? taxLines;
  List<ShippingLine>? shippingLines;
  List<dynamic>? feeLines;
  List<dynamic>? couponLines;
  List<dynamic>? refunds;
  Links? links;

  factory WooGetCreatedOrder.fromJson(Map<String, dynamic> json) => WooGetCreatedOrder(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    parentId: json["parent_id"] is int ? json["parent_id"] : int.tryParse(json["parent_id"]?.toString() ?? ''),
    number: json["number"]?.toString(),
    orderKey: json["order_key"]?.toString(),
    createdVia: json["created_via"]?.toString(),
    version: json["version"]?.toString(),
    status: json["status"]?.toString(),
    currency: json["currency"]?.toString(),
    dateCreated: json["date_created"]?.toString(),
    dateCreatedGmt: json["date_created_gmt"]?.toString(),
    dateModified: json["date_modified"]?.toString(),
    dateModifiedGmt: json["date_modified_gmt"]?.toString(),
    discountTotal: json["discount_total"]?.toString(),
    discountTax: json["discount_tax"]?.toString(),
    shippingTotal: json["shipping_total"]?.toString(),
    shippingTax: json["shipping_tax"]?.toString(),
    cartTax: json["cart_tax"]?.toString(),
    total: json["total"]?.toString(),
    totalTax: json["total_tax"]?.toString(),
    pricesIncludeTax: json["prices_include_tax"],
    customerId: json["customer_id"] is int ? json["customer_id"] : int.tryParse(json["customer_id"]?.toString() ?? ''),
    customerIpAddress: json["customer_ip_address"]?.toString(),
    customerUserAgent: json["customer_user_agent"]?.toString(),
    customerNote: json["customer_note"]?.toString(),
    billing: json["billing"] != null ? Billing.fromJson(json["billing"]) : null,
    shipping: json["shipping"] != null ? Shipping.fromJson(json["shipping"]) : null,
    paymentMethod: json["payment_method"]?.toString(),
    paymentMethodTitle: json["payment_method_title"]?.toString(),
    transactionId: json["transaction_id"]?.toString(),
    datePaid: json["date_paid"]?.toString(),
    datePaidGmt: json["date_paid_gmt"]?.toString(),
    dateCompleted: json["date_completed"]?.toString(),
    dateCompletedGmt: json["date_completed_gmt"]?.toString(),
    cartHash: json["cart_hash"]?.toString(),
    metaData: json["meta_data"] != null ? List<MetaDatum>.from(json["meta_data"].map((x) => MetaDatum.fromJson(x))) : [],
    lineItems: json["line_items"] != null ? List<LineItem>.from(json["line_items"].map((x) => LineItem.fromJson(x))) : [],
    taxLines: json["tax_lines"] != null ? List<TaxLine>.from(json["tax_lines"].map((x) => TaxLine.fromJson(x))) : [],
    shippingLines: json["shipping_lines"] != null ? List<ShippingLine>.from(json["shipping_lines"].map((x) => ShippingLine.fromJson(x))) : [],
    feeLines: json["fee_lines"] != null ? List<dynamic>.from(json["fee_lines"].map((x) => x)) : [],
    couponLines: json["coupon_lines"] != null ? List<dynamic>.from(json["coupon_lines"].map((x) => x)) : [],
    refunds: json["refunds"] != null ? List<dynamic>.from(json["refunds"].map((x) => x)) : [],
    links: json["_links"] != null ? Links.fromJson(json["_links"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "parent_id": parentId,
    "number": number,
    "order_key": orderKey,
    "created_via": createdVia,
    "version": version,
    "status": status,
    "currency": currency,
    "date_created": dateCreated,
    "date_created_gmt": dateCreatedGmt,
    "date_modified": dateModified,
    "date_modified_gmt": dateModifiedGmt,
    "discount_total": discountTotal,
    "discount_tax": discountTax,
    "shipping_total": shippingTotal,
    "shipping_tax": shippingTax,
    "cart_tax": cartTax,
    "total": total,
    "total_tax": totalTax,
    "prices_include_tax": pricesIncludeTax,
    "customer_id": customerId,
    "customer_ip_address": customerIpAddress,
    "customer_user_agent": customerUserAgent,
    "customer_note": customerNote,
    "billing": billing!.toJson(),
    "shipping": shipping!.toJson(),
    "payment_method": paymentMethod,
    "payment_method_title": paymentMethodTitle,
    "transaction_id": transactionId,
    "date_paid": datePaid,
    "date_paid_gmt": datePaidGmt,
    "date_completed": dateCompleted,
    "date_completed_gmt": dateCompletedGmt,
    "cart_hash": cartHash,
    "meta_data": List<dynamic>.from(metaData!.map((x) => x.toJson())),
    "line_items": List<dynamic>.from(lineItems!.map((x) => x.toJson())),
    "tax_lines": List<dynamic>.from(taxLines!.map((x) => x.toJson())),
    "shipping_lines": List<dynamic>.from(shippingLines!.map((x) => x.toJson())),
    "fee_lines": List<dynamic>.from(feeLines!.map((x) => x)),
    "coupon_lines": List<dynamic>.from(couponLines!.map((x) => x)),
    "refunds": List<dynamic>.from(refunds!.map((x) => x)),
    "_links": links!.toJson(),
  };
}


class LineItem {
  LineItem({
    this.id,
    this.name,
    this.productId,
    this.variationId,
    this.quantity,
    this.taxClass,
    this.subtotal,
    this.subtotalTax,
    this.total,
    this.totalTax,
    this.taxes,
    this.metaData,
    this.sku,
    this.price,
  });

  int? id;
  String? name;
  int? productId;
  int? variationId;
  int? quantity;
  String? taxClass;
  String? subtotal;
  String? subtotalTax;
  String? total;
  String? totalTax;
  List<Tax>? taxes;
  List<MetaDatum>? metaData;
  String? sku;
  String? price;

  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    name: json["name"]?.toString(),
    productId: json["product_id"] is int ? json["product_id"] : int.tryParse(json["product_id"]?.toString() ?? ''),
    variationId: json["variation_id"] is int ? json["variation_id"] : int.tryParse(json["variation_id"]?.toString() ?? ''),
    quantity: json["quantity"] is int ? json["quantity"] : int.tryParse(json["quantity"]?.toString() ?? ''),
    taxClass: json["tax_class"]?.toString(),
    subtotal: json["subtotal"]?.toString(),
    subtotalTax: json["subtotal_tax"]?.toString(),
    total: json["total"]?.toString(),
    totalTax: json["total_tax"]?.toString(),
    taxes: json["taxes"] != null ? List<Tax>.from(json["taxes"].map((x) => Tax.fromJson(x))) : [],
    metaData: json["meta_data"] != null ? List<MetaDatum>.from(json["meta_data"].map((x) => MetaDatum.fromJson(x))) : [],
    sku: json["sku"]?.toString(),
    price: json["price"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "product_id": productId,
    "variation_id": variationId,
    "quantity": quantity,
    "tax_class": taxClass,
    "subtotal": subtotal,
    "subtotal_tax": subtotalTax,
    "total": total,
    "total_tax": totalTax,
    "taxes": List<dynamic>.from(taxes!.map((x) => x.toJson())),
    "meta_data": List<dynamic>.from(metaData!.map((x) => x.toJson())),
    "sku": sku,
    "price": price,
  };
}

class MetaDatum {
  MetaDatum({
    this.id,
    this.key,
    this.value,
  });

  int? id;
  String? key;
  String? value;

  factory MetaDatum.fromJson(Map<String, dynamic> json) => MetaDatum(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    key: json["key"]?.toString(),
    value: json["value"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "key": key,
    "value": value,
  };
}

class Tax {
  Tax({
    this.id,
    this.total,
    this.subtotal,
  });

  int? id;
  String? total;
  String? subtotal;

  factory Tax.fromJson(Map<String, dynamic> json) => Tax(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    total: json["total"]?.toString(),
    subtotal: json["subtotal"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "total": total,
    "subtotal": subtotal,
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

class ShippingLine {
  ShippingLine({
    this.id,
    this.methodTitle,
    this.methodId,
    this.total,
    this.totalTax,
    this.taxes,
    this.metaData,
  });

  int? id;
  String? methodTitle;
  String? methodId;
  String? total;
  String? totalTax;
  List<dynamic>? taxes;
  List<dynamic>? metaData;

  factory ShippingLine.fromJson(Map<String, dynamic> json) => ShippingLine(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    methodTitle: json["method_title"]?.toString(),
    methodId: json["method_id"]?.toString(),
    total: json["total"]?.toString(),
    totalTax: json["total_tax"]?.toString(),
    taxes: json["taxes"] != null ? List<dynamic>.from(json["taxes"].map((x) => x)) : [],
    metaData: json["meta_data"] != null ? List<dynamic>.from(json["meta_data"].map((x) => x)) : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "method_title": methodTitle,
    "method_id": methodId,
    "total": total,
    "total_tax": totalTax,
    "taxes": List<dynamic>.from(taxes!.map((x) => x)),
    "meta_data": List<dynamic>.from(metaData!.map((x) => x)),
  };
}

class TaxLine {
  TaxLine({
    this.id,
    this.rateCode,
    this.rateId,
    this.label,
    this.compound,
    this.taxTotal,
    this.shippingTaxTotal,
    this.metaData,
  });

  int? id;
  String? rateCode;
  int? rateId;
  String? label;
  bool? compound;
  String? taxTotal;
  String? shippingTaxTotal;
  List<dynamic>? metaData;

  factory TaxLine.fromJson(Map<String, dynamic> json) => TaxLine(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    rateCode: json["rate_code"]?.toString(),
    rateId: json["rate_id"] is int ? json["rate_id"] : int.tryParse(json["rate_id"]?.toString() ?? ''),
    label: json["label"]?.toString(),
    compound: json["compound"],
    taxTotal: json["tax_total"]?.toString(),
    shippingTaxTotal: json["shipping_tax_total"]?.toString(),
    metaData: json["meta_data"] != null ? List<dynamic>.from(json["meta_data"].map((x) => x)) : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "rate_code": rateCode,
    "rate_id": rateId,
    "label": label,
    "compound": compound,
    "tax_total": taxTotal,
    "shipping_tax_total": shippingTaxTotal,
    "meta_data": List<dynamic>.from(metaData!.map((x) => x)),
  };
}
