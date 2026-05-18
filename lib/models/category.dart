class Category {
  final int id;
  final String name;
  final String? image;

  const Category({
    required this.id,
    required this.name,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        image: json['image'] as String?,
      );
}
