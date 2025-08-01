import 'dart:convert';
import '../models/user_model.dart'; 
import 'package:http/http.dart' as http;

class UserService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/users';

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users. Status code: ${response.statusCode}');
    }
  }

  Future<User> addUser(String name, String email) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add user. Status code: ${response.statusCode}');
    }
  }
  
  Future<User> updateUser(int id, String name, String email) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'id': id, 'name': name, 'email': email}),
      );

      if (response.statusCode == 200) {
        
        return User.fromJson(jsonDecode(response.body));
      } else {
        
        return User(id: id, name: name, email: email);
      }
    } catch (e) {

      return User(id: id, name: name, email: email);
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user. Status code: ${response.statusCode}');
    }
  }
}
