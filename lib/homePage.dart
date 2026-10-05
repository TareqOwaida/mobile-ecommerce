import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/account/accountPreview.dart';
import 'package:firebaselearning/likedProducts.dart';
import 'package:firebaselearning/shoppingCart.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:firebaselearning/authSetup/login.dart';
import 'package:firebaselearning/widgets/custom_card.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key, this.showBottomNav = true});
  final bool showBottomNav;

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String? selectedCategory = 'all';
  Future<List<Productmodel>>? future;
  int _navIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Productmodel> _allProducts = [];
  List<Productmodel> _filteredProducts = [];

  @override
  void initState() {
    try {
      future = Getsutff().getProducts(url: 'https://fakestoreapi.com/products');
    } on Exception catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Failed to load products: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    }
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Productmodel> _applySearch(List<Productmodel> list, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return list;

    return list.where((p) {
      return p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 390 ? 12.0 : 16.0;
    final crossAxisCount = size.width >= 1100
        ? 4
        : size.width >= 760
            ? 3
            : 2;
    return Scaffold(
      drawer: Drawer(
        backgroundColor: _drawerBg,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (_) {
                          final user = FirebaseAuth.instance.currentUser;
                          final name =
                              user?.displayName?.trim().isNotEmpty == true
                                  ? user!.displayName!
                                  : 'User Name';
                          final email =
                              user?.email?.trim().isNotEmpty == true
                                  ? user!.email!
                                  : 'user@email.com';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: Text(
                        'Go Shop',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // All Products
                    _drawerTile(
                      title: 'All Products',
                      icon: Icons.category_outlined,
                      selected: selectedCategory == 'all',
                      onTap: () {
                        setState(() {
                          selectedCategory = 'all';
                          future = Getsutff().getProducts(
                            url: 'https://fakestoreapi.com/products',
                          );

                          _query = '';
                          _searchController.clear();
                          _filteredProducts = _allProducts;
                        });
                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(height: 6),

                    FutureBuilder(
                      future: Getsutff().get(
                        url: "https://fakestoreapi.com/products/categories",
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final List categories = snapshot.data!;
                          return Column(
                            children: List.generate(categories.length, (index) {
                              final String category = categories[index];
                              final bool isSelected =
                                  category == selectedCategory;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _drawerTile(
                                  title: category,
                                  icon: _categoryIcon(category),
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                      future = Getsutff().getProducts(
                                        url:
                                            "https://fakestoreapi.com/products/category/$category",
                                      );

                                      _query = '';
                                      _searchController.clear();
                                      _filteredProducts = _allProducts;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            }),
                          );
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Failed to load categories',
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.9),
                              ),
                            ),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.08)),

                    _drawerTile(
                      title: 'Profile',
                      icon: Icons.person_outline,
                      selected: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Accountpreview(),
                          ),
                        );
                      },
                    ),

                    Divider(color: Colors.white.withOpacity(0.08)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (BuildContext context, bool isScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 72,
              floating: true,
              title: Text(
                'Go Shop',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(62),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    12,
                  ),
                  child: SearchBar(
                    controller: _searchController,
                    leading: const Icon(Icons.search),
                    hintText: 'Search products',
                    elevation: const WidgetStatePropertyAll(0),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _filteredProducts = _applySearch(_allProducts, _query);
                      });
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 12,
          ),
          child: FutureBuilder(
            key: ValueKey(future),
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _allProducts = snapshot.data!;
                _filteredProducts = _applySearch(_allProducts, _query);

                return GridView.builder(
                  itemCount: _filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return CustomCard(
                      product: _filteredProducts[index],
                      mainpage: true,
                    );
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? NavigationBar(
              selectedIndex: _navIndex,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              onDestinationSelected: (index) {
                if (index == _navIndex) return;
                setState(() => _navIndex = index);
                if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Likedproducts()),
                  );
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Shoppingcart()),
                  );
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Accountpreview()),
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
}

Color get _drawerBg => const Color(0xFF1C1F26);
Color get _selectedTile => const Color(0xFF34404F);
Color get _mutedText => const Color(0xFFB6BCC7);

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'electronics':
      return Icons.devices;
    case 'jewelery':
    case 'jewelry':
      return Icons.diamond_outlined;
    case "men's clothing":
      return Icons.checkroom_outlined;
    case "women's clothing":
      return Icons.checkroom_outlined;
    default:
      return Icons.category_outlined;
  }
}

Widget _drawerTile({
  required String title,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
  Color? iconColor,
  Color? textColor,
}) {
  final Color fg = selected ? Colors.white : _mutedText;
  return ListTile(
    dense: true,
    leading: Icon(icon, color: iconColor ?? fg),
    title: Text(
      title,
      style: TextStyle(
        color: textColor ?? fg,
        fontSize: 16,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    ),
    tileColor: selected ? _selectedTile : Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    onTap: onTap,
  );
}

