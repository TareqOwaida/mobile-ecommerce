import 'package:firebaselearning/account/accountPreview.dart';
import 'package:firebaselearning/homePage.dart';
import 'package:firebaselearning/likedProducts.dart';
import 'package:firebaselearning/shoppingCart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  late int _selectedIndex;
  late final List<int> _tabReloadKeys = List<int>.filled(4, 0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Homepage(
            key: ValueKey('home-${_tabReloadKeys[0]}'),
            showBottomNav: false,
          ),
          Likedproducts(
            key: ValueKey('liked-${_tabReloadKeys[1]}'),
            showBottomNav: false,
          ),
          Shoppingcart(
            key: ValueKey('cart-${_tabReloadKeys[2]}'),
            showBottomNav: false,
          ),
          Accountpreview(
            key: ValueKey('account-${_tabReloadKeys[3]}'),
            showBottomNav: false,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _tabReloadKeys[index]++;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
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
      ),
    );
  }
}
