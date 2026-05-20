import 'package:json_annotation/json_annotation.dart';
import 'package:food_run/models/category.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  final String? image;

  const CategoryDto({
    required this.id,
    required this.name,
    this.image,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);

  Category toEntity() => Category(
        id: id,
        name: name,
        image: image,
      );

  factory CategoryDto.fromEntity(Category entity) => CategoryDto(
        id: entity.id,
        name: entity.name,
        image: entity.image,
      );
}
