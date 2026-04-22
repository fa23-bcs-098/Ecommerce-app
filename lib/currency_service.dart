import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _prefKey = 'selected_currency';

  // Cache exchange rates for 1 hour
  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetchTime;

  static Future<Map<String, double>> getExchangeRates() async {
    // Return cached rates if less than 1 hour old
    if (_cachedRates != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < Duration(hours: 1)) {
        return _cachedRates!;
      }
    }

    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
            (data['rates'] as Map).map((key, value) => MapEntry(key, value.toDouble()))
        );

        _cachedRates = rates;
        _lastFetchTime = DateTime.now();
        return rates;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }

    // Return default rates if API fails
    return {'USD': 1.0, 'PKR': 278.0, 'EUR': 0.92, 'GBP': 0.79, 'INR': 83.0};
  }

  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'USD';
  }

  static Future<void> setSelectedCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, currency);
  }

  static double convertPrice(double usdPrice, String fromCurrency, String toCurrency, Map<String, double> rates) {
    if (fromCurrency == toCurrency) return usdPrice;

    // Convert to USD first if not already
    double inUsd = fromCurrency == 'USD' ? usdPrice : usdPrice / (rates[fromCurrency] ?? 1.0);

    // Convert from USD to target currency
    return inUsd * (rates[toCurrency] ?? 1.0);
  }

  static String formatPrice(double price, String currency) {
    String symbol;
    switch (currency) {
      case 'USD':
        symbol = '\$';
        break;
      case 'PKR':
        symbol = 'Rs. ';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'INR':
        symbol = '₹';
        break;
      default:
        symbol = '\$';
    }

    return '$symbol${price.toStringAsFixed(2)}';
  }
}