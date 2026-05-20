import 'package:json_annotation/json_annotation.dart';
import 'package:food_run/models/product.dart';

part 'product_dto.g.dart';

@JsonSerializable()
class ProductDto {
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  final String? description;
  final int? price;
  final String? image;
  final String? thumbnail;
  @JsonKey(defaultValue: 0.0)
  final double energy;
  final int? weight;
  @JsonKey(name: 'weight_measure')
  final String? weightMeasure;
  @JsonKey(defaultValue: 0.0)
  final double fat;
  @JsonKey(defaultValue: 0.0)
  final double proteins;
  @JsonKey(defaultValue: 0.0)
  final double carbohydrates;
  @JsonKey(name: 'is_popular', defaultValue: false)
  final bool isPopular;
  @JsonKey(defaultValue: [])
  final List<TagDto> tags;
  @JsonKey(name: 'group_mods', defaultValue: [])
  final List<GroupModDto> groupMods;
  @JsonKey(name: 'min_price_with_group_mods')
  final int? minPriceWithGroupMods;
  final int? balance;

  const ProductDto({
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

  factory ProductDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);

  Product toEntity() => Product(
        id: id,
        name: name,
        description: description,
        price: price,
        image: image,
        thumbnail: thumbnail,
        energy: energy,
        weight: weight,
        weightMeasure: weightMeasure,
        fat: fat,
        proteins: proteins,
        carbohydrates: carbohydrates,
        isPopular: isPopular,
        tags: tags.map((e) => e.toEntity()).toList(),
        groupMods: groupMods.map((e) => e.toEntity()).toList(),
        minPriceWithGroupMods: minPriceWithGroupMods,
        balance: balance,
      );

  factory ProductDto.fromEntity(Product entity) => ProductDto(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        image: entity.image,
        thumbnail: entity.thumbnail,
        energy: entity.energy,
        weight: entity.weight,
        weightMeasure: entity.weightMeasure,
        fat: entity.fat,
        proteins: entity.proteins,
        carbohydrates: entity.carbohydrates,
        isPopular: entity.isPopular,
        tags: entity.tags.map((e) => TagDto.fromEntity(e)).toList(),
        groupMods: entity.groupMods.map((e) => GroupModDto.fromEntity(e)).toList(),
        minPriceWithGroupMods: entity.minPriceWithGroupMods,
        balance: entity.balance,
      );
}

@JsonSerializable()
class TagDto {
  final int id;
  final String? name;
  final String? image;

  const TagDto({
    required this.id,
    this.name,
    this.image,
  });

  factory TagDto.fromJson(Map<String, dynamic> json) =>
      _$TagDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TagDtoToJson(this);

  Tag toEntity() => Tag(
        id: id,
        name: name,
        image: image,
      );

  factory TagDto.fromEntity(Tag entity) => TagDto(
        id: entity.id,
        name: entity.name,
        image: entity.image,
      );
}

@JsonSerializable()
class GroupModDto {
  final int id;
  final String? name;
  final bool? required;
  @JsonKey(name: 'min_quantity')
  final int? minQuantity;
  @JsonKey(name: 'max_quantity')
  final int? maxQuantity;
  @JsonKey(defaultValue: [])
  final List<GroupModItemDto> items;

  const GroupModDto({
    required this.id,
    this.name,
    this.required,
    this.minQuantity,
    this.maxQuantity,
    required this.items,
  });

  factory GroupModDto.fromJson(Map<String, dynamic> json) =>
      _$GroupModDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModDtoToJson(this);

  GroupMod toEntity() => GroupMod(
        id: id,
        name: name,
        required: required,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
        items: items.map((e) => e.toEntity()).toList(),
      );

  factory GroupModDto.fromEntity(GroupMod entity) => GroupModDto(
        id: entity.id,
        name: entity.name,
        required: entity.required,
        minQuantity: entity.minQuantity,
        maxQuantity: entity.maxQuantity,
        items: entity.items.map((e) => GroupModItemDto.fromEntity(e)).toList(),
      );
}

@JsonSerializable()
class GroupModItemDto {
  final int id;
  final String? name;
  final double? price;
  final String? image;

  const GroupModItemDto({
    required this.id,
    this.name,
    this.price,
    this.image,
  });

  factory GroupModItemDto.fromJson(Map<String, dynamic> json) =>
      _$GroupModItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModItemDtoToJson(this);

  GroupModItem toEntity() => GroupModItem(
        id: id,
        name: name,
        price: price,
        image: image,
      );

  factory GroupModItemDto.fromEntity(GroupModItem entity) => GroupModItemDto(
        id: entity.id,
        name: entity.name,
        price: entity.price,
        image: entity.image,
      );
}
