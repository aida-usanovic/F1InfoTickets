import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/ticket.dart';

/// Customer cart kept on the server; shared by the cart badge and the cart/checkout screens.
class CartState extends ChangeNotifier {
  final _api = ApiClient.instance;

  Cart _cart = Cart.empty;
  Cart get cart => _cart;
  int get count => _cart.totalQuantity;

  Future<void> load() async {
    _cart = Cart.fromJson(await _api.get('Cart'));
    notifyListeners();
  }

  Future<void> add(int raceTicketCategoryId, int quantity) async {
    _cart = Cart.fromJson(await _api.post('Cart/items', body: {'raceTicketCategoryID': raceTicketCategoryId, 'quantity': quantity}));
    notifyListeners();
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    _cart = Cart.fromJson(await _api.put('Cart/items/$cartItemId', body: {'quantity': quantity}));
    notifyListeners();
  }

  Future<void> remove(int cartItemId) async {
    _cart = Cart.fromJson(await _api.delete('Cart/items/$cartItemId'));
    notifyListeners();
  }

  void reset() {
    _cart = Cart.empty;
    notifyListeners();
  }
}
