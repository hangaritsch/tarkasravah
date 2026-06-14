class Grantha {
  final String id;
  final String title;
  final String englishTitle;
  final String author;
  final String description;
  final int sutraCount;

  Grantha({
    required this.id,
    required this.title,
    required this.englishTitle,
    required this.author,
    required this.description,
    required this.sutraCount,
  });

  factory Grantha.fromJson(Map<String, dynamic> json) {
    return Grantha(
      id: json['id'] as String,
      title: json['title'] as String,
      englishTitle: json['english_title'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      sutraCount: json['sutra_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'english_title': englishTitle,
      'author': author,
      'description': description,
      'sutra_count': sutraCount,
    };
  }
}
