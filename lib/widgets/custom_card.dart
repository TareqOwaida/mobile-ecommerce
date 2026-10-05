import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/detailsPage.dart';
import 'package:firebaselearning/widgets/getSutff.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class CustomCard extends StatefulWidget {
  CustomCard({super.key, required this.product, required this.mainpage});
  Productmodel product;
  bool mainpage;
  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  Color? color = Colors.grey;
  bool liked = false;
  final NumberFormat _currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    _initColor();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initColor() async {
    try {
      liked = await isliked(widget.product);
      color = liked ? Colors.red : Colors.grey;
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing color: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Detailspage(product: widget.product)),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: widget.product.image,
                    child: SizedBox(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.product.image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined),
                            SizedBox(height: 4),
                            Text('Image unavailable', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.solidStar,
                    color: Color(0xFFFFC53D),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.product.rating.rate} (${widget.product.rating.count})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currency.format(widget.product.price),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      if (liked) {
                        color = Colors.grey;
                        if (mounted) {
                          setState(() {
                            liked = false;
                          });
                        }
                        try {
                          await deleteField(widget.product);
                        } catch (e) {
                          print('Error removing item: $e');
                        }
                      } else {
                        color = Colors.red;
                        if (mounted) {
                          setState(() {
                            liked = true;
                          });
                        }
                        try {
                          await addItemToArray(widget.product.title);
                        } catch (e) {
                          print('Error adding item: $e');
                        }
                      }
                      FirebaseAuth.instance.currentUser!.reload();
                    },
                    icon: FaIcon(FontAwesomeIcons.solidHeart, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> isliked(Productmodel product) async {
  var likedList = await Getsutff().fetchUserSpecific("liked");

  if (likedList == null || likedList.isEmpty) {
    return false;
  } else {
    for (var i = 0; i < likedList.length; i++) {
      if (likedList[i] == product.title) {
        return true;
      }
    }
    return false;
  }
}

CollectionReference users = FirebaseFirestore.instance.collection('Users');

Future<void> deleteField(Productmodel product) {
  return users
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .update({
        'liked': FieldValue.arrayRemove([product.title]),
      })
      .catchError((error) => print("Failed to delete user's property: $error"));
}

Future<void> addItemToArray(String newItem) {
  return users
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .update({
        'liked': FieldValue.arrayUnion([newItem]),
      })
      .catchError((error) => print("Failed to add item: $error"));
}
