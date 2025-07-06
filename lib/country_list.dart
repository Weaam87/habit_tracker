import 'dart:convert';

import 'package:http/http.dart' as http;

/// Default list used when the API request fails.
const List<String> fallbackCountries = [
  'United States',
  'Canada',
  'United Kingdom',
  'Australia',
  'Germany',
  'France',
  'India',
  'Japan',
  'Brazil',
  'South Africa',
];

/// Fetches country names from the REST Countries API.
Future<List<String>> fetchCountryList() async {
  final uri = Uri.parse('https://restcountries.com/v3.1/all?fields=name');
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List<dynamic>;
    final names = data
        .map((country) => country['name'])
        .whereType<Map>()
        .map((name) => name['common'] as String)
        .toList();
    names.sort();
    return names;
  } else {
    throw Exception('Failed to load countries');
  }
}

/// Returns the fetched list or [fallbackCountries] on error.
Future<List<String>> getCountries() async {
  try {
    return await fetchCountryList();
  } catch (_) {
    return fallbackCountries;
  }
}
