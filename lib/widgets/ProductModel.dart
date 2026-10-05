class Productmodel {
  final String title;
  final dynamic price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  Productmodel({
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory Productmodel.fromJson(Map<String, dynamic> jsonData) {
    return Productmodel(
      title: jsonData['title'] ?? '',
      price: jsonData['price'] ?? 0,
      description: jsonData['description'] ?? '',
      category: jsonData['category'] ?? '',
      image: jsonData['image'] ?? '',
      rating: Rating.fromJson(jsonData['rating'] ?? {}),
    );
  }
}

class Rating {
  final dynamic rate;
  final int count;

  Rating({required this.count, required this.rate});

  factory Rating.fromJson(Map<String, dynamic> jsonData) {
    return Rating(
      count:
          jsonData['count'] is int
              ? jsonData['count']
              : int.tryParse(jsonData['count'].toString()) ?? 0,
      rate: jsonData['rate'],
    );
  }
}
