class Article {
  final String? author;
  final String title;
  final String? description;
  final String? urlToImage;
  final String? content;
  final DateTime? publishedAt;
  final String? url;

  Article({
    required this.title,
    this.author,
    this.description,
    this.urlToImage,
    this.content,
    this.publishedAt,
    this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      author: json['author'] as String?,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      urlToImage: json['urlToImage'] as String?,
      content: json['content'] as String?,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      url: json['url'] as String?,
    );
  }
}