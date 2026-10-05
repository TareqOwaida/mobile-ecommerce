import 'package:firebaselearning/account/addPhoneNumber.dart';
import 'package:firebaselearning/editAddress.dart';
import 'package:firebaselearning/homePage.dart';
import 'package:firebaselearning/likedProducts.dart';
import 'package:firebaselearning/shoppingCart.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:firebaselearning/widgets/ClientModel.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Accountpreview extends StatefulWidget {
  const Accountpreview({super.key, this.showBottomNav = true});
  final bool showBottomNav;

  @override
  State<Accountpreview> createState() => _AccountpreviewState();
}

class _AccountpreviewState extends State<Accountpreview> {
  Map<String, dynamic>? selectedAddress;
  Future<ClientModel>? _userFuture;
  int _navIndex = 3;

  static const String supportEmail = 'support@GoShop.com';

  @override
  void initState() {
    super.initState();
    _userFuture = Getsutff().fetchUser();
    _loadSelectedAddress();
  }

  Future<void> _refresh() async {
    setState(() {
      _userFuture = Getsutff().fetchUser();
    });
    await _loadSelectedAddress();
  }

  Future<void> _loadSelectedAddress() async {
    try {
      final addresses = await Getsutff().fetchUserSpecific("addresses");

      if (!mounted) return;

      final picked = (addresses ?? []).cast<Map>().firstWhere(
        (a) => a['selected'] == true,
        orElse: () => {},
      );

      setState(() {
        selectedAddress =
            picked.isEmpty ? null : picked.cast<String, dynamic>();
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading selected address: $e');
      if (!mounted) return;
      setState(() => selectedAddress = null);
    }
  }

  String _short(String? text, int max) {
    final t = (text ?? '').trim();
    if (t.isEmpty) return '';
    return (t.length <= max) ? t : '${t.substring(0, max)}…';
  }

  String _formatAddressPreview(Map<String, dynamic>? addr) {
    if (addr == null) return 'No address selected';
    final label = _short(addr['Label']?.toString(), 10);
    final street = _short(addr['Street Address']?.toString(), 22);

    final parts = [label, street].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'No address selected';
    return parts.join(', ');
  }

  Future<void> _openSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
  }

  Card _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Preview'), centerTitle: true),
      body: FutureBuilder<ClientModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No user data found.'));
          }

          final user = snapshot.data!;
          final hasAddresses =
              (user.addresses != null && user.addresses!.isNotEmpty);

          final phoneText =
              (user.phone ?? '').toString().trim().isEmpty
                  ? 'No phone number'
                  : user.phone.toString();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 6),

                // Header (Avatar + Name + Email)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF263E58), Color(0xFF355C7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Phone
                _sectionCard(
                  child: ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(phoneText),
                    trailing: IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 16,
                      ),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const PhoneVerificationDialog(),
                        );

                        if (!mounted) return;

                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number added successfully!'),
                            ),
                          );
                        }
                        await _refresh();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Shipping Address
                _sectionCard(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Shipping Address'),
                    subtitle: Text(
                      hasAddresses
                          ? _formatAddressPreview(selectedAddress)
                          : 'No address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 16,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Editaddress(),
                          ),
                        );
                        if (!mounted) return;
                        await _refresh();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Support Email (opens Gmail / email app)
                _sectionCard(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Support Email'),
                    subtitle: const Text(supportEmail),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: _openSupportEmail,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  'Pull down to refresh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
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
                } else if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Likedproducts()),
                  );
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Shoppingcart()),
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
