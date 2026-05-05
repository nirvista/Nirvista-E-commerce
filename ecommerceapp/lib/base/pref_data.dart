import 'package:shared_preferences/shared_preferences.dart';

class PrefData {

  static String favouriteList = "productFav";
  static const String _keyUserId = "userId";

  Future<List<String>> getFavouriteList() async {
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    List<String>? value = prefs.getStringList(favouriteList);
    return value ?? [];
  }

  setFavouriteList(List<String> sizes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(favouriteList, sizes);
  }

  Future<void> setUserId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<void> clearUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
