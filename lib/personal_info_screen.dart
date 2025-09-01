import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'country_list.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<String> _countries = [];
  String _selectedCountry = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await getCountries();
    setState(() {
      _countries = countries;
      if (_selectedCountry.isEmpty && countries.isNotEmpty) {
        _selectedCountry = countries.first;
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _ageController.text = prefs.getString('age') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _selectedCountry = prefs.getString('country') ?? '';
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('country', _selectedCountry);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _countries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedCountry.isNotEmpty
                          ? _selectedCountry
                          : _countries.first,
                      decoration:
                          const InputDecoration(labelText: 'Country'),
                      isExpanded: true,
                      items: _countries
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCountry = val ?? '';
                        });
                      },
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserData,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

