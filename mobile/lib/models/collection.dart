class Collection {
  final int id;
  final String gid;
  final String name;
  final String slug;
  final String? image;

  Collection({
    required this.id,
    required this.gid,
    required this.name,
    required this.slug,
    this.image,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int,
      gid: json['gid'] as String? ?? '',
      name: json['name'] as String,
      slug: json['slug'] as String,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gid': gid,
      'name': name,
      'slug': slug,
      'image': image,
    };
  }
}
