class ClientModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List? addresses;
  final List? liked;
  final List? cart;
  final List orders;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.orders,
    required this.cart,
    this.phone,
    this.addresses,
    this.liked,
  });

  factory ClientModel.fromJson(json) {
    return ClientModel(
      id: json['clientId'] as String? ?? 'No id',
      name: json['UserName'] as String? ?? 'No Name',
      email: json['Email'] as String? ?? 'No Email',
      phone: json['phone'] as String? ?? 'No Phone',
      orders: json['orders'] as List? ?? [],
      addresses: json['addresses'] as List? ?? [],
      cart: json['cart'] as List? ?? [],
      liked: json['liked'] as List? ?? [],
    );
  }
}
