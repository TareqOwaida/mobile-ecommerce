import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:firebaselearning/shoppingCart.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:firebaselearning/widgets/custom_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Detailspage extends StatefulWidget {
  Detailspage({super.key, required this.product});
  final Productmodel product;

  @override
  State<Detailspage> createState() => _DetailspageState();
}

class _DetailspageState extends State<Detailspage> {
  final GlobalKey _targetKey = GlobalKey();
  List<dynamic> cartItems = [];
  bool _isLoading = true;
  final NumberFormat _currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    loadArray();
  }

  Future<void> loadArray() async {
    try {
      final items = await Getsutff().fetchUserSpecific('cart');
      if (mounted) {
        setState(() {
          cartItems = items ?? [];
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          cartItems = [];
          _isLoading = false;
        });
      }
    }
  }

  bool checkItem() {
    return cartItems.contains(
      "${widget.product.title}/@/${widget.product.category}",
    );
  }

  int itemCount() {
    int count = 0;
    for (var element in cartItems) {
      if (element == "${widget.product.title}/@/${widget.product.category}") {
        count++;
      }
    }
    return count;
  }

  Future<void> _addItemToCart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Read the current cart first
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();

      List<dynamic> currentCart = List.from(userDoc.data()?['cart'] ?? []);

      // Add the new item to the local copy
      currentCart.add("${widget.product.title}/@/${widget.product.category}");

      // Update the entire cart array
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update(
        {'cart': currentCart},
      );

      // Update local state
      if (mounted) {
        setState(() {
          cartItems.add("${widget.product.title}/@/${widget.product.category}");
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $error'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _decrementItem() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Read the current cart first
      final userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();

      List<dynamic> currentCart = List.from(userDoc.data()?['cart'] ?? []);

      // Remove only one occurrence of the item
      final itemToRemove =
          "${widget.product.title}/@/${widget.product.category}";
      final index = currentCart.indexOf(itemToRemove);
      if (index != -1) {
        currentCart.removeAt(index);
      }

      // Update the entire cart array
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update(
        {'cart': currentCart},
      );

      if (mounted) {
        setState(() {
          final index = cartItems.indexOf(itemToRemove);
          if (index != -1) {
            cartItems.removeAt(index);
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $error'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Shoppingcart()),
              );
            },
            child: const FaIcon(FontAwesomeIcons.cartShopping),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            widget.product.title,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Scrollable.ensureVisible(
                    _targetKey.currentContext!,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  );
                },
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.star,
                      color: Colors.blueGrey,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.product.rating.rate.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    Text(
                      ' (${widget.product.rating.count})',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const FaIcon(
                  FontAwesomeIcons.shareFromSquare,
                  color: Colors.blueGrey,
                  size: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Hero(
            tag: widget.product.image,
            child: CachedNetworkImage(
              imageUrl: widget.product.image,
              fit: BoxFit.contain,
              height: 300,
              width: 300,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => Container(
                height: 300,
                width: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "${_currency.format(widget.product.price)} ",
                style: const TextStyle(
                  color: Color(0xFF74C0FC),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "(Incl. VAT)",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.product.description,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 20),
          const Text(
            "Related Products",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 100),
          SizedBox(
            height: 260,
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder(
              future: Getsutff().getProducts(
                url:
                    "https://fakestoreapi.com/products/category/${widget.product.category}",
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Productmodel> products = snapshot.data!;
                  return ListView.builder(
                    itemCount: products.length,
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      if (widget.product.title == products[index].title) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Detailspage(product: products[index]),
                                  ),
                                );
                              },
                              child: CustomCard(
                                product: products[index],
                                mainpage: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            key: _targetKey,
            child: const Text(
              "Product Reviews",
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton:
          _isLoading
              ? const CircularProgressIndicator()
              : Container(
                padding: const EdgeInsets.only(left: 30),
                height: 60,
                width: double.infinity,
                child:
                    checkItem()
                        ? FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  "Item in cart",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: _addItemToCart,
                                    icon: const FaIcon(
                                      FontAwesomeIcons.circlePlus,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(
                                    child: Text(
                                      "${itemCount()}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _decrementItem,
                                    icon: const FaIcon(
                                      FontAwesomeIcons.circleMinus,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        : FilledButton(
                          onPressed: _addItemToCart,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Add to Cart",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 10),
                              FaIcon(
                                FontAwesomeIcons.cartArrowDown,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
              ),
    );
  }
}
