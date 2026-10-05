import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/account/accountPreview.dart';
import 'package:firebaselearning/detailsPage.dart';
import 'package:firebaselearning/homePage.dart';
import 'package:firebaselearning/shoppingCart.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Likedproducts extends StatefulWidget {
  const Likedproducts({super.key, this.showBottomNav = true});
  final bool showBottomNav;

  @override
  State<Likedproducts> createState() => _LikedproductsState();
}

class _LikedproductsState extends State<Likedproducts> {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'Users',
  );
  int _navIndex = 1;
  List<dynamic> likedProducts = [];
  Future<List<Productmodel>>? future;
  List<Productmodel> fullyLikeProducts = [];

  loadliked() async {
    fullyLikeProducts.clear();
    likedProducts = await Getsutff().fetchUserSpecific('liked');
    future = Getsutff().getProducts(url: 'https://fakestoreapi.com/products');
    for (var product in await future!) {
      if (likedProducts.contains(product.title)) {
        fullyLikeProducts.add(product);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liked Products')),
      body: Container(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder(
          future: loadliked(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                itemCount: fullyLikeProducts.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Detailspage(
                                product: fullyLikeProducts[index],
                              ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: Card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: fullyLikeProducts[index].image,
                              height: 70,
                              width: 70,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fullyLikeProducts[index].title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () {
                                setState(() {
                                  deleteField(fullyLikeProducts[index]);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
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
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Shoppingcart()),
                  );
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Accountpreview()),
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

  Future<void> deleteField(Productmodel product) {
    return users
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
          'liked': FieldValue.arrayRemove([product.title]),
        })
        .catchError(
          (error) => print("Failed to delete user's property: $error"),
        );
  }
}
