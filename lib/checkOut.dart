import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:firebaselearning/homePage.dart';
import 'package:firebaselearning/widgets/ClientModel.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Checkout extends StatefulWidget {
  final List? cartItems;
  final double? totalAmount;
  const Checkout({super.key, this.cartItems, this.totalAmount});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  Future<List<Productmodel>>? future;
  ClientModel? user;
  Map<String, dynamic>? selectedAddress;
  String? selectedPaymentMethod;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loadUserDeatails();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  loadUserDeatails() async {
    user = await Getsutff().fetchUser();
    if (user?.addresses != null) {
      try {
        selectedAddress = user!.addresses!.firstWhere(
          (addr) => addr['selected'] == true,
        );
      } catch (e) {
        selectedAddress = null;
      }
    }
    setState(() {});
  }

  double getTotalAmount() {
    double baseAmount = widget.totalAmount ?? 0;
    if (selectedPaymentMethod == 'cash') {
      return baseAmount + 12.0;
    }
    return baseAmount;
  }

  void _handlePaymentMethodChange(String? method) {
    setState(() {
      selectedPaymentMethod = method;
    });
  }

  @override
  Widget build(BuildContext context) {
    int itemCount(Productmodel product) {
      int count = 0;
      for (var element in widget.cartItems!) {
        if (element == "${product.title}/@/${product.category}") {
          count++;
        }
      }
      return count;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Confirmation'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Productmodel>>(
        future: Getsutff().getProducts(
          url: 'https://fakestoreapi.com/products',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          List<Productmodel> products = snapshot.data!;
          List<Productmodel> cartProducts =
              products
                  .where(
                    (product) => widget.cartItems!.contains(
                      "${product.title}/@/${product.category}",
                    ),
                  )
                  .toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: cartProducts.length,
                  itemBuilder: (context, index) {
                    final product = cartProducts[index];
                    int count = itemCount(product);
                    return SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Card(
                        child: Row(
                          children: [
                            SizedBox(width: 5),
                            CachedNetworkImage(
                              imageUrl: product.image,
                              height: 70,
                              width: 70,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Text('Qty'), Text('$count')],
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                PaymentMethodCheckbox(
                  value: 'cash',
                  groupValue: selectedPaymentMethod,
                  onChanged: _handlePaymentMethodChange,
                  text: const Text(
                    "Cash On Delivery (+ \$12)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 20),
                PaymentMethodCheckbox(
                  value: 'card',
                  groupValue: selectedPaymentMethod,
                  onChanged: _handlePaymentMethodChange,
                  text: const Text(
                    "Credit/Debit Card",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                // Card Details Form (only shown when credit/debit card is selected)
                if (selectedPaymentMethod == 'card') ...[
                  SizedBox(height: 20),
                  _buildCardDetailsForm(),
                ],

                const SizedBox(height: 20),
                userDetails(
                  "Subtotal:",
                  "\$${(widget.totalAmount ?? 0).toStringAsFixed(2)}",
                ),
                if (selectedPaymentMethod == 'cash') ...[
                  userDetails("Cod Fee:", "\$12.00"),
                ],
                userDetails(
                  "Total Amount:",
                  "\$${getTotalAmount().toStringAsFixed(2)}",
                ),
                const SizedBox(height: 20),
                userDetails("Contact: ", "${user?.name}, ${user?.phone}"),

                const SizedBox(height: 20),
                userDetails(
                  "Shipping to: ",
                  "${selectedAddress != null ? selectedAddress!['Label'] : 'No address selected'}, ${selectedAddress != null ? selectedAddress!['State'] : ''}, ${selectedAddress != null ? selectedAddress!['Street Address'] : ''} ",
                ),
                const SizedBox(height: 20),
                userDetails("Delivery duration: ", "2-4 business days"),

                SizedBox(height: 130),
              ],
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: SlideAction(
          alignment: Alignment.bottomCenter,
          height: 60,
          sliderRotate: false,
          borderRadius: 16,
          innerColor: const Color.fromARGB(255, 255, 255, 255),
          outerColor: Theme.of(context).colorScheme.primary,
          textStyle: TextStyle(color: Colors.white),
          text: 'Slide to Confirm',
          onSubmit: () async {
            if (selectedPaymentMethod == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a payment method!'),
                ),
              );
              return;
            }

            if (selectedPaymentMethod == 'card') {
              if (!_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all card details correctly!'),
                  ),
                );
                return;
              }
            }

            final user = FirebaseAuth.instance.currentUser;
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user?.uid)
                .update({
                  'cart': [],
                  'orders': FieldValue.arrayUnion([
                    {
                      'items': widget.cartItems,
                      'totalAmount': getTotalAmount().toStringAsFixed(2),
                      'paymentMethod': selectedPaymentMethod,
                      'timestamp': DateTime.now(),
                      'shippingaddress': selectedAddress,
                    },
                  ]),
                });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Homepage()),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order done successfully!')),
            );
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCardDetailsForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Card Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Card Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card holder name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  if (value.length < 16) {
                    return 'Card number must be 16 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter expiry date';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter CVV';
                        }
                        if (value.length < 3) {
                          return 'CVV must be 3 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  userDetails(String text1, String text2) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text1,
              style: const TextStyle(fontSize: 18),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: Text(
              text2,
              style: const TextStyle(fontSize: 18),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodCheckbox extends StatelessWidget {
  final String value;
  final String? groupValue;
  final Function(String?)? onChanged;
  final Text? text;

  const PaymentMethodCheckbox({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            text ?? Text(""),
          ],
        ),
      ),
    );
  }
}
