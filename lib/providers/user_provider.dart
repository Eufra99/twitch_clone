import 'package:flutter/foundation.dart';
import 'package:twitch_clone/models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(email: '', username: '', uid: '');

  User get user => _user;

  setUser(User user) {
    _user = user;
    notifyListeners();
  }
}
