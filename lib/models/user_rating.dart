class UserRating {
  final int? id;
  final int recipeId;
  final int rating;
  final DateTime ratedAt;

  const UserRating({
    this.id,
    required this.recipeId,
    required this.rating,
    required this.ratedAt,
  });

  factory UserRating.fromMap(Map<String, dynamic> map) {
    return UserRating(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      rating: map['rating'] as int,
      ratedAt: DateTime.parse(map['rated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'rating': rating,
      'rated_at': ratedAt.toIso8601String(),
    };
  }
}

class Collection {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Collection({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SearchHistory {
  final int? id;
  final int recipeId;
  final String title;
  final String imageUrl;
  final DateTime viewedAt;

  const SearchHistory({
    this.id,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.viewedAt,
  });

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      title: map['title'] as String,
      imageUrl: map['image_url'] as String? ?? '',
      viewedAt: DateTime.parse(map['viewed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'title': title,
      'image_url': imageUrl,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }
}
