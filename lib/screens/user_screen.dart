import 'package:flutter/material.dart';
import 'package:rest_api/services/user_service.dart' show UserService;
import '../models/user_model.dart';

class CrudHomePage extends StatefulWidget {
  const CrudHomePage({super.key});

  @override
  State<CrudHomePage> createState() => _CrudHomePageState();
}

class _CrudHomePageState extends State<CrudHomePage> {
  final UserService _userService = UserService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  User? _editingUser;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _userService.fetchUsers();
      setState(() {
        _users = users;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _saveUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnackbar('Name and email cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_editingUser == null) {
        final newUser = await _userService.addUser(name, email);
        setState(() => _users.add(newUser));
        _showSnackbar('User added successfully!');
      } else {
        final updatedUser = await _userService.updateUser(_editingUser!.id, name, email);
        setState(() {
          final index = _users.indexWhere((user) => user.id == updatedUser.id);
          if (index != -1) {
            _users[index] = updatedUser;
          }
        });
        _showSnackbar('User updated successfully!');
      }
      _clearForm();
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _startEditing(User user) {
    setState(() {
      _editingUser = user;
      _nameController.text = user.name;
      _emailController.text = user.email;
    });
  }

  void _deleteUser(int id) async {
    setState(() => _isLoading = true);
    try {
      await _userService.deleteUser(id);
      setState(() {
        _users.removeWhere((user) => user.id == id);
        if (_editingUser?.id == id) {
          _clearForm();
        }
      });
      _showSnackbar('User deleted successfully!');
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _clearForm() {
    setState(() {
      _editingUser = null;
      _nameController.clear();
      _emailController.clear();
      FocusScope.of(context).unfocus(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          if (_editingUser != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearForm,
              tooltip: 'Cancel Edit',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveUser,
            child: Text(_editingUser == null ? 'Add User' : 'Update User'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('No users found. Add one above!'));
    }
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (_, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: ListTile(
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _startEditing(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteUser(user.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
