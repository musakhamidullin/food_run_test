class Product {
  final int id;
  final String name;
  final String? description;
  final int? price;
  final String? image;
  final String? thumbnail;
  final double energy;
  final int? weight;
  final String? weightMeasure;
  final double fat;
  final double proteins;
  final double carbohydrates;
  final bool isPopular;
  final List<Tag> tags;
  final List<GroupMod> groupMods;
  final int? minPriceWithGroupMods;
  int? balance;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.image,
    this.thumbnail,
    required this.energy,
    this.weight,
    this.weightMeasure,
    required this.fat,
    required this.proteins,
    required this.carbohydrates,
    required this.isPopular,
    required this.tags,
    required this.groupMods,
    this.minPriceWithGroupMods,
    this.balance,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toInt(),
        image: json['image'] as String?,
        thumbnail: json['thumbnail'] as String?,
        energy: (json['energy'] as num?)?.toDouble() ?? 0.0,
        weight: (json['weight'] as num?)?.toInt(),
        weightMeasure: json['weight_measure'] as String?,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        proteins: (json['proteins'] as num?)?.toDouble() ?? 0.0,
        carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
        isPopular: json['is_popular'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList(),
        groupMods: (json['group_mods'] as List<dynamic>? ?? [])
            .map((e) => GroupMod.fromJson(e as Map<String, dynamic>))
            .toList(),
        minPriceWithGroupMods: json['min_price_with_group_mods'] as int?,
        balance: json['balance'] as int?,
      );
}

class Tag {
  final int id;
  final String? name;
  final String? image;

  const Tag({required this.id, this.name, this.image});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as int,
        name: json['name'] as String?,
        image: json['image'] as String?,
      );
}

class GroupMod {
  final int id;
  final String? name;
  final bool? required;
  final int? minQuantity;
  final int? maxQuantity;
  final List<GroupModItem> items;

  const GroupMod({
    required this.id,
    this.name,
    this.required,
    this.minQuantity,
    this.maxQuantity,
    required this.items,
  });

  factory GroupMod.fromJson(Map<String, dynamic> json) => GroupMod(
        id: json['id'] as int,
        name: json['name'] as String?,
        required: json['required'] as bool?,
        minQuantity: json['min_quantity'] as int?,
        maxQuantity: json['max_quantity'] as int?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => GroupModItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GroupModItem {
  final int id;
  final String? name;
  final double? price;
  final String? image;

  const GroupModItem({
    required this.id,
    this.name,
    this.price,
    this.image,
  });

  factory GroupModItem.fromJson(Map<String, dynamic> json) => GroupModItem(
        id: json['id'] as int,
        name: json['name'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
      };
}
