import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/widgets/ClientModel.dart';
import 'package:firebaselearning/widgets/ProductModel.dart';
import 'package:http/http.dart' as http;

class Getsutff {
  Future<List<Productmodel>> getProducts({required String url}) async {
    final data = await get(url: url);

    List<Productmodel> productList = [];
    for (var item in data) {
      try {
        productList.add(Productmodel.fromJson(item));
      } catch (e) {
        print('Error parsing product: $e');
        print('Bad item: $item');
      }
    }
    return productList;
  }

Future<List<dynamic>> get({required String url}) async {
  http.Response response;
  try {
    response = await http.get(Uri.parse(url))
      .timeout(const Duration(seconds: 10));
  } on TimeoutException {
    throw Exception('Request timed out after 10 seconds');
  } on SocketException catch (e) {
    throw Exception('Network error: ${e.message}');
  }
  return jsonDecode(response.body);
}

  Future<ClientModel> fetchUser() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

    if (querySnapshot.exists) {
      return ClientModel.fromJson(querySnapshot.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  Future fetchUserSpecific(String spec) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
    var data = querySnapshot.data();

    return data![spec];
  }
}
