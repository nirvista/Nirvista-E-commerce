
import 'dart:convert';



List<ModelShippingMethod> modelShippingMethodFromJson(String str) => List<ModelShippingMethod>.from(json.decode(str).map((x) => ModelShippingMethod.fromJson(x)));

String modelShippingMethodToJson(List<ModelShippingMethod> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ModelShippingMethod {
  ModelShippingMethod({
    this.id,
    this.instanceId,
    this.title,
    this.order,
    this.enabled,
    this.methodId,
    this.methodTitle,
    this.methodDescription,
    this.settings,
    this.links,
  });

  int? id;
  int? instanceId;
  String? title;
  int? order;
  bool? enabled;
  String? methodId;
  String? methodTitle;
  String? methodDescription;
  Settings? settings;
  Links? links;

  factory ModelShippingMethod.fromJson(Map<String, dynamic> json) => ModelShippingMethod(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? ''),
    instanceId: json["instance_id"] is int ? json["instance_id"] : int.tryParse(json["instance_id"]?.toString() ?? ''),
    title: json["title"]?.toString(),
    order: json["order"] is int ? json["order"] : int.tryParse(json["order"]?.toString() ?? ''),
    enabled: json["enabled"],
    methodId: json["method_id"]?.toString(),
    methodTitle: json["method_title"]?.toString(),
    methodDescription: json["method_description"]?.toString(),
    settings: json["settings"] != null ? Settings.fromJson(json["settings"]) : null,
    links: json["_links"] != null ? Links.fromJson(json["_links"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "instance_id": instanceId,
    "title": title,
    "order": order,
    "enabled": enabled,
    "method_id": methodId,
    "method_title": methodTitle,
    "method_description": methodDescription,
    "settings": settings?.toJson(),
    "_links": links?.toJson(),
  };
}

class Links {
  Links({
    this.self,
    this.collection,
    this.describes,
  });

  List<Collection>? self;
  List<Collection>? collection;
  List<Collection>? describes;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    self: json["self"] != null ? List<Collection>.from(json["self"].map((x) => Collection.fromJson(x))) : [],
    collection: json["collection"] != null ? List<Collection>.from(json["collection"].map((x) => Collection.fromJson(x))) : [],
    describes: json["describes"] != null ? List<Collection>.from(json["describes"].map((x) => Collection.fromJson(x))) : [],
  );

  Map<String, dynamic> toJson() => {
    "self": List<dynamic>.from(self!.map((x) => x.toJson())),
    "collection": List<dynamic>.from(collection!.map((x) => x.toJson())),
    "describes": List<dynamic>.from(describes!.map((x) => x.toJson())),
  };
}

class Collection {
  Collection({
    this.href,
  });

  String? href;

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    href: json["href"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "href": href,
  };
}

class Settings {
  Settings({
    this.title,
    this.taxStatus,
    this.cost,
  });

  Cost? title;
  Cost? taxStatus;
  Cost? cost;

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    title: json["title"] != null ? Cost.fromJson(json["title"]) : null,
    taxStatus: json["tax_status"] != null ? Cost.fromJson(json["tax_status"]) : null,
    cost: json["cost"] != null ? Cost.fromJson(json["cost"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "title": title?.toJson(),
    "tax_status": taxStatus?.toJson(),
    "cost": cost?.toJson(),
  };
}

class Cost {
  Cost({
    this.id,
    this.label,
    this.description,
    this.type,
    this.value,
    this.costDefault,
    this.tip,
    this.placeholder,
    this.options,
  });

  String? id;
  String? label;
  String? description;
  String? type;
  String? value;
  String? costDefault;
  String? tip;
  String? placeholder;
  Options? options;

  factory Cost.fromJson(Map<String, dynamic> json) => Cost(
    id: json["id"]?.toString(),
    label: json["label"]?.toString(),
    description: json["description"]?.toString(),
    type: json["type"]?.toString(),
    value: json["value"]?.toString(),
    costDefault: json["default"]?.toString(),
    tip: json["tip"]?.toString(),
    placeholder: json["placeholder"]?.toString(),
    options: json["options"] == null ? null : Options.fromJson(json["options"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "label": label,
    "description": description,
    "type": type,
    "value": value,
    "default": costDefault,
    "tip": tip,
    "placeholder": placeholder,
    "options": options == null ? null : options!.toJson(),
  };
}

class Options {
  Options({
    this.taxable,
    this.none,
  });

  String? taxable;
  String? none;

  factory Options.fromJson(Map<String, dynamic> json) => Options(
    taxable: json["taxable"],
    none: json["none"],
  );

  Map<String, dynamic> toJson() => {
    "taxable": taxable,
    "none": none,
  };
}


// import 'dart:convert';
//
// List<ModelShippingMethod> modelShippingMethodFromJson(String str) => List<ModelShippingMethod>.from(json.decode(str).map((x) => ModelShippingMethod.fromJson(x)));
//
// String modelShippingMethodToJson(List<ModelShippingMethod> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
//
// class ModelShippingMethod {
//   ModelShippingMethod({
//     this.id,
//     this.title,
//     this.description,
//     this.links,
//   });
//
//   String? id;
//   String? title;
//   String? description;
//   Links? links;
//
//   factory ModelShippingMethod.fromJson(Map<String, dynamic> json) => ModelShippingMethod(
//     id: json["id"],
//     title: json["title"],
//     description: json["description"],
//     links: Links.fromJson(json["_links"]),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "title": title,
//     "description": description,
//     "_links": links!.toJson(),
//   };
// }
//
// class Links {
//   Links({
//     this.self,
//     this.collection,
//   });
//
//   List<Collection>? self;
//   List<Collection>? collection;
//
//   factory Links.fromJson(Map<String, dynamic> json) => Links(
//     self: List<Collection>.from(json["self"].map((x) => Collection.fromJson(x))),
//     collection: List<Collection>.from(json["collection"].map((x) => Collection.fromJson(x))),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "self": List<dynamic>.from(self!.map((x) => x.toJson())),
//     "collection": List<dynamic>.from(collection!.map((x) => x.toJson())),
//   };
// }
//
// class Collection {
//   Collection({
//     this.href,
//   });
//
//   String? href;
//
//   factory Collection.fromJson(Map<String, dynamic> json) => Collection(
//     href: json["href"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "href": href,
//   };
// }
