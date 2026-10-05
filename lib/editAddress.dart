import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Editaddress extends StatefulWidget {
  const Editaddress({super.key});

  @override
  State<Editaddress> createState() => _EditaddressState();
}

class _EditaddressState extends State<Editaddress> {
  static const List<String> _supportedStates = [
    'Cairo',
    'AlMansoura',
    'Alexandria',
  ];

  String? state;
  final _dialogFormKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final TextEditingController stAddressController = TextEditingController();
  final TextEditingController buildingController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController aptController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController additionalDirectionsController =
      TextEditingController();

  @override
  void dispose() {
    stAddressController.dispose();
    buildingController.dispose();
    floorController.dispose();
    aptController.dispose();
    labelController.dispose();
    additionalDirectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Edit Address'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            /// LIST
            Expanded(
              child: FutureBuilder(
                future: Getsutff().fetchUserSpecific('addresses'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  } else if (!snapshot.hasData ||
                      (snapshot.data as List).isEmpty) {
                    return const Center(
                      child: Text(
                        'No addresses found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  List addresses = snapshot.data!;

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      final isSelected = address['selected'] == true;

                      return _AddressCard(
                        isSelected: isSelected,
                        label: address['Label'] ?? 'No Label',
                        addressLine:
                            '${address['State'] ?? ''}, ${address['Street Address'] ?? ''}',
                        details:
                            'Building: ${address['Building'] ?? ''} • Floor: ${address['Floor Number'] ?? ''} • Apt: ${address['Apartment Number'] ?? ''}',
                        directions:
                            'Directions: ${address['Additional Directions'] ?? ''}',
                        onTap: () => _selectAddress(addresses, index),
                        onEdit: () => _openEditDialog(addresses, index),
                        onDelete: () => _deleteAddress(addresses, index),
                      );
                    },
                  );
                },
              ),
            ),

            /// ADD BUTTON
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, 10, w * 0.05, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E252C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.locationDot, size: 16),
                  label: const Text(
                    "Add new address",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _openAddDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _sanitizeState(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return _supportedStates.contains(trimmed) ? trimmed : null;
  }

  Future<void> _selectAddress(List addresses, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List updatedAddresses =
        addresses.map((addr) {
          return {...addr, 'selected': false};
        }).toList();

    updatedAddresses[index]['selected'] = true;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'addresses': updatedAddresses,
    });

    if (mounted) setState(() {});
  }

  void _clearInputs() {
    stAddressController.clear();
    buildingController.clear();
    floorController.clear();
    aptController.clear();
    labelController.clear();
    additionalDirectionsController.clear();
    state = null;
    _autovalidateMode = AutovalidateMode.disabled;
  }

  void _openAddDialog() {
    _clearInputs();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14181E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: _inputData(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final isValid = _dialogFormKey.currentState?.validate() ?? false;
                if (!isValid) {
                  setState(() {
                    _autovalidateMode = AutovalidateMode.always;
                  });
                  return;
                }
                await addAddress();

                if (mounted) {
                  setState(_clearInputs);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditDialog(List addresses, int index) {
    final address = addresses[index];

    setState(() {
      labelController.text = (address['Label'] ?? '').toString();
      state = _sanitizeState((address['State'] ?? '').toString());
      stAddressController.text = (address['Street Address'] ?? '').toString();
      buildingController.text = (address['Building'] ?? '').toString();
      floorController.text = (address['Floor Number'] ?? '').toString();
      aptController.text = (address['Apartment Number'] ?? '').toString();
      additionalDirectionsController.text =
          (address['Additional Directions'] ?? '').toString();
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14181E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: _inputData(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final isValid = _dialogFormKey.currentState?.validate() ?? false;
                if (!isValid) {
                  setState(() {
                    _autovalidateMode = AutovalidateMode.always;
                  });
                  return;
                }
                await _updateAddress(addresses, index);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> addAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update(
        {
          'addresses': FieldValue.arrayUnion([
            {
              'State': state,
              'Street Address': stAddressController.text.trim(),
              'Building': buildingController.text.trim(),
              'Floor Number': floorController.text.trim(),
              'Apartment Number': aptController.text.trim(),
              'Additional Directions':
                  additionalDirectionsController.text.trim(),
              'Label': labelController.text.trim(),
              'selected': false,
            },
          ]),
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add address: $error'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateAddress(List addresses, int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedAddresses = List<Map<String, dynamic>>.from(
        addresses.map((e) => Map<String, dynamic>.from(e)),
      );

      final wasSelected = updatedAddresses[index]['selected'] == true;

      updatedAddresses[index] = {
        'State': state,
        'Street Address': stAddressController.text.trim(),
        'Building': buildingController.text.trim(),
        'Floor Number': floorController.text.trim(),
        'Apartment Number': aptController.text.trim(),
        'Additional Directions': additionalDirectionsController.text.trim(),
        'Label': labelController.text.trim(),
        'selected': wasSelected,
      };

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'addresses': updatedAddresses,
      });

      if (mounted) {
        setState(_clearInputs);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update address: $error'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(List addresses, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14181E),
          title: const Text(
            'Delete Address',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this address?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedAddresses = List<Map<String, dynamic>>.from(
        addresses.map((e) => Map<String, dynamic>.from(e)),
      );

      final removedWasSelected = updatedAddresses[index]['selected'] == true;
      updatedAddresses.removeAt(index);

      if (removedWasSelected && updatedAddresses.isNotEmpty) {
        updatedAddresses[0]['selected'] = true;
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'addresses': updatedAddresses,
      });

      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete address: $error'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _inputData() {
    InputDecoration deco(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0F1115),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
      );
    }

    String? requiredValidator(String? value, String fieldName) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    }

    return SingleChildScrollView(
      child: Form(
        key: _dialogFormKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: labelController,
              style: const TextStyle(color: Colors.white),
              decoration: deco('Label (Home, Work...)'),
              validator: (value) => requiredValidator(value, 'Label'),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _sanitizeState(state),
              dropdownColor: const Color(0xFF14181E),
              style: const TextStyle(color: Colors.white),
              decoration: deco("Select State"),
              items: _supportedStates
                  .map(
                    (city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => state = value),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'State is required' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: stAddressController,
              style: const TextStyle(color: Colors.white),
              decoration: deco('Street Address'),
              validator: (value) => requiredValidator(value, 'Street Address'),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: buildingController,
              style: const TextStyle(color: Colors.white),
              decoration: deco('Building Name/Number'),
              validator: (value) => requiredValidator(value, 'Building'),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: floorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Floor'),
                    validator: (value) => requiredValidator(value, 'Floor'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: aptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Apartment'),
                    validator: (value) => requiredValidator(value, 'Apartment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: additionalDirectionsController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: deco('Additional Directions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final bool isSelected;
  final String label;
  final String addressLine;
  final String details;
  final String directions;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.isSelected,
    required this.label,
    required this.addressLine,
    required this.details,
    required this.directions,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E252C) : const Color(0xFF14181E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white24 : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isSelected)
                  const FaIcon(
                    FontAwesomeIcons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.penToSquare,
                    size: 15,
                    color: Colors.white70,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit address',
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.trash,
                    size: 15,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete address',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              addressLine,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              details,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              directions,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
