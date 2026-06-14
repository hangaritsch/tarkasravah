class Sutra {
  final int id;
  final String sutraNumber;
  final String title;
  final String sanskrit;
  final String englishMeaning;
  final String kannadaMeaning;
  final String audio;

  Sutra({
    required this.id,
    required this.sutraNumber,
    required this.title,
    required this.sanskrit,
    required this.englishMeaning,
    required this.kannadaMeaning,
    required this.audio,
  });

  factory Sutra.fromJson(Map<String, dynamic> json) {
    return Sutra(
      id: json['id'] as int,
      sutraNumber: json['sutra_number'] as String,
      title: json['title'] as String,
      sanskrit: json['sanskrit'] as String,
      englishMeaning: json['english_meaning'] as String,
      kannadaMeaning: json['kannada_meaning'] as String,
      audio: json['audio'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sutra_number': sutraNumber,
      'title': title,
      'sanskrit': sanskrit,
      'english_meaning': englishMeaning,
      'kannada_meaning': kannadaMeaning,
      'audio': audio,
    };
  }
}
