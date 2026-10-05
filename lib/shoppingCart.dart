import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/account/accountPreview.dart';
import 'package:firebaselearning/checkOut.dart';
import 'package:firebaselearning/homePage.dart';
import 'package:firebaselearning/likedProducts.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:firebaselearning/widgets/ClientModel.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Shoppingcart extends StatefulWidget {
  const Shoppingcart({super.key, this.showBottomNav = true});
  final bool showBottomNav;
  @override
  State<Shoppingcart> createState() => _ShoppingcartState();
}

class _ShoppingcartState extends State<Shoppingcart> {
  ClientModel? user;
  int _navIndex = 2;
  List? cartItems = [];
  Future<List<Productmodel>>? future;
  double priceTotal = 0.0;
  bool hasAddress = false;
  bool hasphone = false;

  @override
  void initState() {
    super.initState();
    loadArray();
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadArray() async {
    user = await Getsutff().fetchUser();
    cartItems = user!.cart;
    future = Getsutff().getProducts(url: 'https://fakestoreapi.com/products');
    if (user!.addresses != null && user!.addresses!.isNotEmpty) {
      hasAddress = true;
    }
    if (user!.phone != null && user!.phone!.isNotEmpty) {
      hasphone = true;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cart', style: TextStyle(fontSize: 16)),
            Text(
              cartItems!.isEmpty ? '(0 items)' : '(${cartItems!.length} items)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Productmodel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (cartItems!.isEmpty || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items in the cart'));
          } else {
            final products = snapshot.data!;
            final cartProducts =
                products
                    .where(
                      (product) => cartItems!.contains(
                        "${product.title}/@/${product.category}",
                      ),
                    )
                    .toList();
            priceTotal = 0.0;
            for (var product in cartProducts) {
              final quantity = itemCount(product);
              priceTotal += product.price * quantity;
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartProducts.length,
                    itemBuilder: (context, index) {
                      final product = cartProducts[index];
                      return Card(
                        child: SizedBox(
                          width: double.infinity,
                          height: 102,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 5),
                              CachedNetworkImage(
                                imageUrl: product.image,
                                width: 70,
                                height: 70,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Qty: ${itemCount(product)}"),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.trash,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        cartItems!.remove(
                                          "${product.title}/@/${product.category}",
                                        );
                                      });
                                      await FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                          )
                                          .update({'cart': cartItems});
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(width: 5),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                cartProducts.isEmpty
                    ? Container()
                    : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      height: 200,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Items:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  cartItems!.length.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "\$${priceTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Shipping and Handling:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "\$26.99",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price Total:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "\$${(priceTotal + 26.99).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  if (!hasAddress) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('No Shipping Address'),
                                            content: Text(
                                              'Please add a shipping address and a phone number before proceeding to checkout.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              Accountpreview(),
                                                    ),
                                                  ).then(
                                                    (_) => setState(() {
                                                      loadArray();
                                                    }),
                                                  );
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                  if (!hasphone) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('No Phone Number'),
                                            content: Text(
                                              'Please add a shipping address and a phone number before proceeding to checkout.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              Accountpreview(),
                                                    ),
                                                  ).then(
                                                    (_) => setState(() {
                                                      loadArray();
                                                    }),
                                                  );
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                  if (hasAddress && hasphone) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => Checkout(
                                              cartItems: cartItems,
                                              totalAmount: priceTotal + 26.99,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  "Checkout",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar:
          widget.showBottomNav
              ? NavigationBar(
                selectedIndex: _navIndex,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                onDestinationSelected: (index) {
                  if (index == _navIndex) return;
                  setState(() => _navIndex = index);
                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Homepage()),
                    );
                  } else if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Likedproducts(),
                      ),
                    );
                  } else if (index == 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Accountpreview(),
                      ),
                    );
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: FaIcon(FontAwesomeIcons.solidHeart, size: 16),
                    label: 'Favorites',
                  ),
                  NavigationDestination(
                    icon: FaIcon(FontAwesomeIcons.cartShopping, size: 16),
                    label: 'Cart',
                  ),
                  NavigationDestination(
                    icon: FaIcon(FontAwesomeIcons.solidUser, size: 16),
                    label: 'Account',
                  ),
                ],
              )
              : null,
    );
  }

  int itemCount(Productmodel product) {
    int count = 0;

    for (var element in cartItems!) {
      if (element == "${product.title}/@/${product.category}") {
        count++;
      }
    }
    return count;
  }
}
