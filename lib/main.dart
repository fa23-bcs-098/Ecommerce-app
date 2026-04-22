import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'email_service.dart';
import 'order_tracking_map_screen.dart';
import 'location_service.dart';
import 'currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShopEasy',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: UserTypeSelectionScreen(),
    );
  }
}

PageRouteBuilder<dynamic> customPageRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: Offset(0.0, 0.3), end: Offset.zero)
            .animate(animation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
  );
}

// ============ MODELS ============
class Product {
  final String name;
  final String price;
  final String oldPrice;
  final String imageUrl;
  final double rating;
  final String category;

  Product({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.imageUrl,
    required this.rating,
    required this.category,
  });
}

class CartItem {
  final String productName;
  final String price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.productName,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}

class PaymentMethod {
  final String type; // 'cash' or 'card'
  final String? cardHolderName;
  final String? cardNumber;
  final String? expiryDate;
  final String? cvv;

  PaymentMethod({
    required this.type,
    this.cardHolderName,
    this.cardNumber,
    this.expiryDate,
    this.cvv,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
    };
  }
}

class SellerProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final String category;
  final List<String> images;
  final List<String> sizes;
  final int stock;
  final String sellerId;
  final DateTime createdAt;
  final double discountPercentage; // ADD THIS
  final bool isTrending; // ADD THIS

  SellerProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.sizes,
    required this.stock,
    required this.sellerId,
    required this.createdAt,
    this.discountPercentage = 0.0, // ADD THIS
    this.isTrending = false, // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'sizes': sizes,
      'stock': stock,
      'sellerId': sellerId,
      'createdAt': createdAt.toIso8601String(),
      'discountPercentage': discountPercentage, // ADD THIS
      'isTrending': isTrending, // ADD THIS
    };
  }

  factory SellerProduct.fromMap(Map<String, dynamic> map, String id) {
    return SellerProduct(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? '',
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      stock: map['stock'] ?? 0,
      sellerId: map['sellerId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(), // ADD THIS
      isTrending: map['isTrending'] ?? false, // ADD THIS
    );
  }
}

class LimitedOffer {
  final String id;
  final String productId;
  final String sellerId;
  final DateTime startDate;
  final DateTime endDate;
  final double discountPercentage;
  final bool isActive;

  LimitedOffer({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
    required this.discountPercentage,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sellerId': sellerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'discountPercentage': discountPercentage,
      'isActive': isActive,
    };
  }

  factory LimitedOffer.fromMap(Map<String, dynamic> map, String id) {
    return LimitedOffer(
      id: id,
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : DateTime.now(),
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class Order {
  final String id;
  final String productName;
  final String productImage;
  final String price;
  final int quantity;
  final String customerName;
  final String customerAddress;
  final String status;
  final DateTime orderDate;

  final double? customerLat;
  final double? customerLng;
  final double? deliveryPersonLat;
  final double? deliveryPersonLng;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final double? rating;

  Order({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.customerName,
    required this.customerAddress,
    required this.status,
    required this.orderDate,
    this.customerLat,
    this.customerLng,
    this.deliveryPersonLat,
    this.deliveryPersonLng,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    this.rating,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'rating': rating,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: map['price'] ?? '',
      quantity: map['quantity'] ?? 0,
      customerName: map['customerName'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      status: map['status'] ?? 'pending',
      orderDate: map['orderDate'] != null
          ? DateTime.parse(map['orderDate'])
          : DateTime.now(),
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
    );
  }
}

// Add this widget class after the Order class

class CurrencySelector extends StatefulWidget {
  final Function(String) onCurrencyChanged;

  CurrencySelector({required this.onCurrencyChanged});

  @override
  _CurrencySelectorState createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  String _selectedCurrency = 'USD';

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'Rs.'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedCurrency();
  }

  Future<void> _loadSelectedCurrency() async {
    String currency = await CurrencyService.getSelectedCurrency();
    setState(() {
      _selectedCurrency = currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_exchange, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              _selectedCurrency,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) {
        return _currencies.map((currency) {
          bool isSelected = currency['code'] == _selectedCurrency;
          return PopupMenuItem<String>(
            value: currency['code'],
            child: Row(
              children: [
                Text(
                  currency['symbol']!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency['code']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black,
                        ),
                      ),
                      Text(
                        currency['name']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.deepPurple, size: 20),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (String currency) async {
        await CurrencyService.setSelectedCurrency(currency);
        setState(() {
          _selectedCurrency = currency;
        });
        widget.onCurrencyChanged(currency);
      },
    );
  }
}

class WishlistItem {
  final String productId;
  final String productName;
  final String price;
  final String imageUrl;
  final String category;
  final DateTime addedAt;

  WishlistItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map, String id) {
    return WishlistItem(
      productId: id,
      productName: map['productName'] ?? '',
      price: map['price'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'])
          : DateTime.now(),
    );
  }
}

// ============ USER TYPE SELECTION ============
class UserTypeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace the Container with Icon in UserTypeSelectionScreen
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Welcome to ShopEasy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Choose how you want to continue",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 50),
                  _buildUserTypeCard(
                    context,
                    icon: Icons.shopping_bag,
                    title: "Continue as Customer",
                    subtitle: "Browse and shop products",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        customPageRoute(SignupScreen(userType: 'customer')),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  _buildUserTypeCard(
                    context,
                    icon: Icons.store,
                    title: "Continue as Seller",
                    subtitle: "Sell your products",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        customPageRoute(SellerTypeSelectionScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        customPageRoute(LoginScreen()),
                      );
                    },
                    child: Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ============ SELLER TYPE SELECTION ============
class SellerTypeSelectionScreen extends StatefulWidget {
  @override
  _SellerTypeSelectionScreenState createState() =>
      _SellerTypeSelectionScreenState();
}

class _SellerTypeSelectionScreenState extends State<SellerTypeSelectionScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("CHOOSE SELLER TYPE",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  "Select Your Seller Type",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Choose the type that best describes you",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 40),
                _buildSellerTypeOption(
                  "Individual Seller",
                  "Sell as an individual",
                  Icons.person,
                ),
                SizedBox(height: 15),
                _buildSellerTypeOption(
                  "Company Seller",
                  "Sell as a registered company",
                  Icons.business,
                ),
                SizedBox(height: 15),
                _buildSellerTypeOption(
                  "Global Seller",
                  "Sell internationally",
                  Icons.public,
                ),
                Spacer(),
                if (selectedType != null)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          customPageRoute(
                            SellerSignupScreen(sellerType: selectedType!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        "Continue",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerTypeOption(String title, String subtitle, IconData icon) {
    bool isSelected = selectedType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = title;
        });
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.deepPurple, size: 30),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.deepPurple, size: 28)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 28),
          ],
        ),
      ),
    );
  }
}

// ============ SELLER SIGNUP SCREEN ============
class SellerSignupScreen extends StatefulWidget {
  final String sellerType;

  SellerSignupScreen({required this.sellerType});

  @override
  _SellerSignupScreenState createState() => _SellerSignupScreenState();
}

class _SellerSignupScreenState extends State<SellerSignupScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _cityController = TextEditingController();

  final _storeAddressController = TextEditingController();
  final _storeCityController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _shopNameController.text.isEmpty ||
        _cityController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please accept terms & conditions")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Check if shop name is unique
      QuerySnapshot shopCheck = await _firestore
          .collection('sellers')
          .where('shopName', isEqualTo: _shopNameController.text.trim())
          .get();

      if (shopCheck.docs.isNotEmpty) {
        throw Exception("Shop name already exists. Please choose another.");
      }

      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('sellers').doc(userCredential.user!.uid).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'city': _cityController.text.trim(),
        'storeAddress': _storeAddressController.text.trim(), // ADD THIS
        'storeCity': _storeCityController.text.trim(),
        'sellerType': widget.sellerType,
        'userType': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        customPageRoute(LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Seller account created! Please login."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SELLER SIGNUP",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                SizedBox(height: 20),
                // Replace the Container with Icon in SignupScreen
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Become a Seller",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.sellerType,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 25),
                _buildTextField("Full Name", Icons.person, _nameController),
                _buildTextField("Email", Icons.email, _emailController),
                _buildTextField("Mobile Number", Icons.phone, _mobileController,
                    keyboardType: TextInputType.phone),
                _buildTextField("Shop Name", Icons.store, _shopNameController),
                _buildTextField("City", Icons.location_city, _cityController),
                _buildPasswordField("Password", _passwordController),
                _buildTextField("Store Address", Icons.store, _storeAddressController),
                SizedBox(height: 15),
                _buildTextField("Store City", Icons.location_city, _storeCityController),
                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (val) {
                          setState(() {
                            _agreedToTerms = val ?? false;
                          });
                        },
                        fillColor: MaterialStateProperty.all(Colors.white),
                        checkColor: Colors.deepPurple,
                      ),
                      Expanded(
                        child: Text(
                          "I agree to the terms & conditions",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          customPageRoute(LoginScreen()),
                        );
                      },
                      child: Text("Login",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Remove the _buildBackground method and update _buildTextField to not have horizontal padding


  Widget _buildTextField(String label, IconData icon,
      TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============ CUSTOMER SIGNUP SCREEN ============
class SignupScreen extends StatefulWidget {
  final String userType;

  SignupScreen({this.userType = 'customer'});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'addresses': [_addressController.text.trim()],
        'email': _emailController.text.trim(),
        'userType': widget.userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        customPageRoute(LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Account created successfully! Please login."),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'weak-password') {
        message = 'Password is too weak (min 6 characters)';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SIGN UP",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBackground(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 60),
              // Replace the Container with Icon in SellerSignupScreen
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sign up to get started!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 25),
              _buildTextField("Name", Icons.person, _nameController),
              _buildTextField("Phone Number", Icons.phone, _phoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField("Address", Icons.home, _addressController),
              _buildTextField("Email", Icons.email, _emailController),
              _buildPasswordField("Password", _passwordController),
              SizedBox(height: 25),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            customPageRoute(LoginScreen()),
                          );
                        },
                        child: Text("Login",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============ LOGIN SCREEN ============
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await Future.delayed(Duration(milliseconds: 500));

      if (_auth.currentUser != null) {
        String uid = _auth.currentUser!.uid;

        // Check if user is a seller
        DocumentSnapshot sellerDoc =
        await _firestore.collection('sellers').doc(uid).get();

        if (sellerDoc.exists) {
          // Navigate to Seller Dashboard
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            customPageRoute(SellerDashboardScreen()),
          );
          return;
        }

        // Customer user
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          customPageRoute(DashboardScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Successful!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // In LoginScreen
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter your email")),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text("Sending OTP..."),
            ],
          ),
        ),
      ),
    );

    try {
      // Send OTP via email
      String? otp = await EmailService.sendPasswordResetOTP(
        _emailController.text.trim(),
        "User",
      );

      Navigator.pop(context); // Close loading dialog

      if (otp != null) {
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          customPageRoute(
            OTPVerificationScreen(
              email: _emailController.text.trim(),
              correctOTP: otp,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send OTP. Please check your email and try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOTPDialog(String correctOTP) {
    final _otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter OTP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "We've sent a 6-digit code to ${_emailController.text}",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: "Enter OTP",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _otpController.dispose();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_otpController.text == correctOTP) {
                Navigator.pop(context);
                // Send Firebase password reset email
                try {
                  await _auth.sendPasswordResetEmail(
                      email: _emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Password reset email sent! Check your inbox."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Invalid OTP. Please try again."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              _otpController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: Text("Verify"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("LOGIN",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              customPageRoute(UserTypeSelectionScreen()),
            );
          },
        ),
      ),
      body: _buildBackground(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 80),
              // Replace the Container with Icon in LoginScreen
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Welcome Back!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Login to continue shopping",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 35),
              _buildTextField("Email", Icons.email, _emailController),
              _buildPasswordField("Password", _passwordController),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            customPageRoute(UserTypeSelectionScreen()),
                          );
                        },
                        child: Text("Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============ OTP VERIFICATION SCREEN ============
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String correctOTP;

  OTPVerificationScreen({required this.email, required this.correctOTP});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerifying = false;
  bool _otpVerified = false;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _verifyOTP() {
    if (_otpController.text.trim() == widget.correctOTP) {
      setState(() {
        _otpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("OTP verified! Enter your new password"),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text("Invalid OTP. Please try again."),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords don't match")),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: widget.email);

      if (!mounted) return;

      // Show success and navigate to login
      Navigator.pushReplacement(
        context,
        customPageRoute(LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent! Check your inbox."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _otpVerified ? "RESET PASSWORD" : "VERIFY OTP",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBackground(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 80),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _otpVerified ? Icons.lock_reset : Icons.verified_user,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              Text(
                _otpVerified ? "Create New Password" : "Enter OTP Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _otpVerified
                      ? "Choose a strong password"
                      : "We've sent a 6-digit code to\n${widget.email}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 35),

              if (!_otpVerified) ...[
                // OTP Input
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        letterSpacing: 10,
                      ),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              if (_otpVerified) ...[
                // New Password Fields
                _buildPasswordField(
                  "New Password",
                  _newPasswordController,
                  _obscureNewPassword,
                      () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                SizedBox(height: 15),
                _buildPasswordField(
                  "Confirm Password",
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                      () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isVerifying
                        ? CircularProgressIndicator(color: Colors.deepPurple)
                        : Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscure,
      VoidCallback onToggle,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


// ============ SELLER DASHBOARD ============
// ============ SELLER DASHBOARD ============
class SellerDashboardScreen extends StatefulWidget {
  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  String sellerName = "Seller";
  String shopName = "";
  String sellerType = "";
  int totalProducts = 0;
  double totalSales = 0.0;
  int totalOrders = 0;
  double averageRating = 0.0;
  int pendingShipments = 0;
  int lowStockProducts = 0;
  Map<String, int> _productStocks = {};
  Map<String, String> _productIds = {};

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};
  bool _loadingRates = false;

  String _orderFilter = 'all';

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
    _loadDashboardStats();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    setState(() {});
  }

  // ADD THIS NEW METHOD HERE:
  Future<void> _reloadAllData() async {
    await _loadCurrencyData();
    setState(() {});
  }

  String _convertAndFormatPrice(String priceStr) {
    if (_exchangeRates.isEmpty) return priceStr;

    // Parse the USD price from string (remove $ and any commas)
    double usdPrice = double.tryParse(priceStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0;

    double convertedPrice = CurrencyService.convertPrice(usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  String _convertAndFormatPriceFromDouble(double usdPrice) {
    if (_exchangeRates.isEmpty) return '\$${usdPrice.toStringAsFixed(2)}';

    double convertedPrice = CurrencyService.convertPrice(usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  Future<void> _loadSellerData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot sellerData =
        await _firestore.collection('sellers').doc(user.uid).get();
        if (sellerData.exists && mounted) {
          setState(() {
            sellerName = sellerData['fullName'] ?? 'Seller';
            shopName = sellerData['shopName'] ?? '';
            sellerType = sellerData['sellerType'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading seller data: $e');
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Load products count
      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      // Load orders
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      double sales = 0.0;
      int delivered = 0;
      int pending = 0;

      for (var doc in ordersSnapshot.docs) {
        String status = doc['status'] ?? 'pending';
        String priceStr = doc['price']?.toString().replaceAll('\$', '').replaceAll(',', '') ?? '0';
        double price = double.tryParse(priceStr) ?? 0;
        int qty = doc['quantity'] ?? 1;

        // CHANGED: Count all delivered orders for sales
        if (status == 'delivered') {
          sales += (price * qty);
          delivered++;
        }

        // CHANGED: Count pending AND processing orders
        if (status == 'pending' || status == 'processing') {
          pending++;
        }
      }

      // Get average rating
      double totalRating = 0.0;
      int ratingCount = 0;

      for (var productDoc in productsSnapshot.docs) {
        String productId = productDoc.id;

        QuerySnapshot reviewsSnapshot = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          totalRating += (reviewDoc['rating'] as num).toDouble();
          ratingCount++;
        }
      }

      double avgRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

      // Count low stock products
      int lowStock = 0;
      for (var doc in productsSnapshot.docs) {
        int stock = doc['stock'] ?? 0;
        if (stock < 10) lowStock++;
      }

      if (mounted) {
        setState(() {
          totalProducts = productsSnapshot.docs.length;
          totalSales = sales;
          totalOrders = ordersSnapshot.docs.length; // CHANGED: Shows all orders
          pendingShipments = pending; // CHANGED: Shows pending + processing
          lowStockProducts = lowStock;
          averageRating = avgRating;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        customPageRoute(UserTypeSelectionScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged out successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Seller Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // ADD CURRENCY SELECTOR
          CurrencySelector(
            onCurrencyChanged: (currency) async {
              await _reloadAllData();  // CHANGED from: await _loadCurrencyData(); setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                customPageRoute(CustomerOrdersScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildProductsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-length header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 30, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          sellerName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shopName.isNotEmpty) ...[
                          SizedBox(height: 5),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.store, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  shopName,
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.store, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sales Overview",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showSalesDetails(context),
                        child: _buildStatCard(
                          "Total Sales",
                          _convertAndFormatPriceFromDouble(totalSales),
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showOrdersDetails(context),
                        child: _buildStatCard(
                          "Pending Orders",
                          "$pendingShipments",
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showProductsDetails(context),
                        child: _buildStatCard(
                          "Products",
                          "$totalProducts",
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showRatingsDetails(context),
                        child: _buildStatCard(
                          "Rating",
                          "${averageRating.toStringAsFixed(1)} ⭐",
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),
                Text(
                  "Pending Tasks",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                _buildTaskCard(
                  "Orders to Ship",
                  "$pendingShipments orders waiting",
                  Icons.local_shipping,
                  Colors.red,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                  },
                ),
                _buildTaskCard(
                  "Low Stock Alert",
                  "$lowStockProducts products low on stock",
                  Icons.warning,
                  Colors.orange,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
                _buildTaskCard(
                  "Add New Product",
                  "Expand your inventory",
                  Icons.add_box,
                  Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      customPageRoute(AddProductScreen()),
                    ).then((_) {
                      _loadDashboardStats();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
      String title, String subtitle, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Center(child: Text("Please login"));
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Products",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        customPageRoute(AddProductScreen()),
                      ).then((_) {
                        _loadDashboardStats();
                        setState(() {});
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text("Add Product"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      customPageRoute(LimitedTimeOfferScreen()),
                    ).then((_) {
                      _loadDashboardStats();
                      setState(() {});
                    });
                  },
                  icon: Icon(Icons.schedule, size: 20),
                  label: Text("Limited Time Offers"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('products')
                .where('sellerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red.shade300),
                      SizedBox(height: 20),
                      Text(
                        "Error loading products",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 80, color: Colors.grey.shade300),
                      SizedBox(height: 20),
                      Text(
                        "No Products Yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Add your first product to get started!",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            customPageRoute(AddProductScreen()),
                          ).then((_) {
                            _loadDashboardStats();
                          });
                        },
                        icon: Icon(Icons.add),
                        label: Text("Add Product"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var product = snapshot.data!.docs[index];
                  return _buildProductItem(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(DocumentSnapshot product) {
    List<String> images = List<String>.from(product['images'] ?? []);
    String imageUrl = images.isNotEmpty ? images[0] : '';
    int stock = product['stock'] ?? 0;
    bool lowStock = stock < 10;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade400),
                );
              },
            )
                : Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade200,
              child: Icon(Icons.image, color: Colors.grey.shade400),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Product',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    product['category'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product['price'] ?? '\$0',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lowStock
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Stock: $stock",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: lowStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Edit"),
                  ],
                ),
                value: 'edit',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Delete"),
                  ],
                ),
                value: 'delete',
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                // Navigate to edit product screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(
                      productId: product.id,
                      productData: product.data() as Map<String, dynamic>,
                    ),
                  ),
                );

                if (result == true) {
                  _loadDashboardStats();
                  setState(() {});
                }
              } else if (value == 'delete') {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Delete Product"),
                    content: Text(
                        "Are you sure you want to delete this product?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _firestore
                      .collection('products')
                      .doc(product.id)
                      .delete();
                  _loadDashboardStats();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Product deleted")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Center(child: Text("Please login"));
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Orders",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _orderFilter,
                items: [
                  DropdownMenuItem(value: 'all', child: Text("All Orders")),
                  DropdownMenuItem(value: 'pending', child: Text("Pending")),
                  DropdownMenuItem(value: 'processing', child: Text("Processing")),
                  DropdownMenuItem(value: 'shipped', child: Text("Shipped")),
                  DropdownMenuItem(value: 'delivered', child: Text("Delivered")),
                ],
                onChanged: (value) {
                  setState(() {
                    _orderFilter = value ?? 'all';
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('orders')
                .where('sellerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red.shade300),
                      SizedBox(height: 20),
                      Text(
                        "Error loading orders",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 80, color: Colors.grey.shade300),
                      SizedBox(height: 20),
                      Text(
                        "No Orders Yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Orders will appear here",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              // Filter and sort orders
              List<DocumentSnapshot> orders = snapshot.data!.docs.toList();

              // Apply filter
              if (_orderFilter != 'all') {
                orders = orders.where((doc) {
                  String status = doc['status'] ?? 'pending';
                  return status == _orderFilter;
                }).toList();
              }

              // Sort by date
              orders.sort((a, b) {
                DateTime dateA = a['orderDate'] != null
                    ? (a['orderDate'] is Timestamp
                    ? (a['orderDate'] as Timestamp).toDate()
                    : DateTime.parse(a['orderDate']))
                    : DateTime.now();
                DateTime dateB = b['orderDate'] != null
                    ? (b['orderDate'] is Timestamp
                    ? (b['orderDate'] as Timestamp).toDate()
                    : DateTime.parse(b['orderDate']))
                    : DateTime.now();
                return dateB.compareTo(dateA);
              });

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off,
                          size: 60, color: Colors.grey.shade300),
                      SizedBox(height: 15),
                      Text(
                        "No ${_orderFilter} orders",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var order = orders[index];
                  return _buildOrderItem(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildOrderItem(DocumentSnapshot order) {
    String status = order['status'] ?? 'pending';
    Color statusColor;

    switch (status) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          customPageRoute(OrderDetailScreen(orderId: order.id)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${order.id.substring(0, 8)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order['productImage'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['productName'] ?? 'Product',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Qty: ${order['quantity']} • ${order['price']}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 5),
                  Text(
                    order['customerName'] ?? 'Customer',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 5),
                  Text(
                    _formatDate(order['orderDate']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dateTime = date is String ? DateTime.parse(date) : date.toDate();
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Analytics & Reports",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildAnalyticsCard(
              "Sales Overview",
              "Track your overall performance",
              Icons.trending_up,
              Colors.green,
              [
                _buildMetricRow("Total Sales (GMV)", "\$${totalSales.toStringAsFixed(2)}"),
                _buildMetricRow("Total Orders", "$totalOrders"),
                _buildMetricRow("Avg Order Value", totalOrders > 0
                    ? "\$${(totalSales / totalOrders).toStringAsFixed(2)}"
                    : "\$0"),
                _buildMetricRow("Return Rate", "0%"),
              ],
            ),
            SizedBox(height: 15),
            _buildAnalyticsCard(
              "Product Performance",
              "Best and worst-performing products",
              Icons.inventory_2,
              Colors.blue,
              [
                _buildMetricRow("Total Products", "$totalProducts"),
                _buildMetricRow("Low Stock Items", "$lowStockProducts"),
                _buildMetricRow("Out of Stock", "0"),
                _buildMetricRow("Average Rating", "${averageRating.toStringAsFixed(1)} ⭐"),
              ],
            ),
            SizedBox(height: 15),
            _buildAnalyticsCard(
              "Traffic Insights",
              "Visitor and conversion data",
              Icons.people,
              Colors.purple,
              [
                _buildMetricRow("Product Views", "Coming Soon"),
                _buildMetricRow("Add-to-Cart Rate", "Coming Soon"),
                _buildMetricRow("Conversion Rate", "Coming Soon"),
                _buildMetricRow("Device Split", "Coming Soon"),
              ],
            ),
            SizedBox(height: 15),
            _buildAnalyticsCard(
              "Financial Reports",
              "Payment and commission details",
              Icons.account_balance_wallet,
              Colors.orange,
              [
                _buildMetricRow("Total Earnings", "\$${totalSales.toStringAsFixed(2)}"),
                _buildMetricRow("Platform Commission", "Coming Soon"),
                _buildMetricRow("Pending Balance", "Coming Soon"),
                _buildMetricRow("Refunds", "\$0"),
              ],
            ),
            SizedBox(height: 15),
            _buildAnalyticsCard(
              "Customer Insights",
              "Information about your buyers",
              Icons.groups,
              Colors.teal,
              [
                _buildMetricRow("Total Customers", "Coming Soon"),
                _buildMetricRow("Repeat Customers", "Coming Soon"),
                _buildMetricRow("Customer Satisfaction", "Coming Soon"),
                _buildMetricRow("Reviews Count", "Coming Soon"),
              ],
            ),
            SizedBox(height: 15),
            _buildAnalyticsCard(
              "Performance Metrics",
              "Your seller score",
              Icons.speed,
              Colors.red,
              [
                _buildMetricRow("On-Time Shipment", "100%"),
                _buildMetricRow("Cancellation Rate", "0%"),
                _buildMetricRow("Response Rate", "Coming Soon"),
                _buildMetricRow("Seller Rating", "${averageRating.toStringAsFixed(1)}/5.0"),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showSalesDetails(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot ordersSnapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'delivered')
        .get();

    List<Map<String, dynamic>> salesData = [];
    for (var doc in ordersSnapshot.docs) {
      String priceStr = doc['price']?.toString().replaceAll('\$', '').replaceAll(',', '') ?? '0';
      double price = double.tryParse(priceStr) ?? 0;
      int qty = doc['quantity'] ?? 1;
      double total = price * qty;

      salesData.add({
        'productName': doc['productName'],
        'quantity': qty,
        'price': price,
        'total': total,
        'date': doc['orderDate'],
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sales Details'),
        content: Container(
          width: double.maxFinite,
          child: salesData.isEmpty
              ? Text('No sales yet')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: salesData.length,
            itemBuilder: (context, index) {
              var sale = salesData[index];
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(sale['productName']),
                  subtitle: Text('Qty: ${sale['quantity']} • \$${sale['price'].toStringAsFixed(2)} each'),
                  trailing: Text(
                    '\$${sale['total'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrdersDetails(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot ordersSnapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .get();

    Map<String, int> statusCounts = {
      'pending': 0,
      'processing': 0,
      'shipped': 0,
      'delivered': 0,
    };

    for (var doc in ordersSnapshot.docs) {
      String status = doc['status'] ?? 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Orders Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusRow('Pending', statusCounts['pending']!, Colors.orange),
            _buildStatusRow('Processing', statusCounts['processing']!, Colors.blue),
            _buildStatusRow('Shipped', statusCounts['shipped']!, Colors.purple),
            _buildStatusRow('Delivered', statusCounts['delivered']!, Colors.green),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Orders',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$totalOrders',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
              Text(label),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showProductsDetails(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot productsSnapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    Map<String, int> categoryCount = {};
    int inStock = 0;
    int outOfStock = 0;

    for (var doc in productsSnapshot.docs) {
      String category = doc['category'] ?? 'Other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;

      int stock = doc['stock'] ?? 0;
      if (stock > 0) {
        inStock++;
      } else {
        outOfStock++;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Products Overview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            _buildStatusRow('In Stock', inStock, Colors.green),
            _buildStatusRow('Out of Stock', outOfStock, Colors.red),
            Divider(height: 24),
            Text(
              'By Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            ...categoryCount.entries.map((entry) =>
                _buildStatusRow(entry.key, entry.value, Colors.deepPurple)
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRatingsDetails(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot productsSnapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    List<Map<String, dynamic>> productRatings = [];

    for (var productDoc in productsSnapshot.docs) {
      String productId = productDoc.id;
      String productName = productDoc['name'];

      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var reviewDoc in reviewsSnapshot.docs) {
          totalRating += (reviewDoc['rating'] as num).toDouble();
        }
        double avgRating = totalRating / reviewsSnapshot.docs.length;

        productRatings.add({
          'name': productName,
          'rating': avgRating,
          'count': reviewsSnapshot.docs.length,
        });
      }
    }

    productRatings.sort((a, b) => b['rating'].compareTo(a['rating']));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Ratings'),
        content: Container(
          width: double.maxFinite,
          child: productRatings.isEmpty
              ? Text('No reviews yet')
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 40),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        Text(
                          '${averageRating.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Average Rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: productRatings.length,
                  itemBuilder: (context, index) {
                    var product = productRatings[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          product['name'],
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text('${product['count']} reviews'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              product['rating'].toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String subtitle, IconData icon,
      Color color, List<Widget> metrics) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...metrics,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CHECKOUT SCREEN ============
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalPrice;

  CheckoutScreen({required this.cartItems, required this.totalPrice});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String selectedAddress = "";
  List<String> userAddresses = [];
  String userName = "";
  String userEmail = "";
  String userPhone = "";
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  // ADD THESE TWO LINES:
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};

  // Payment related variables
  String? selectedPaymentMethod;
  final _cardHolderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrencyData(); // ADD THIS
  }

  @override
  void dispose() {
    _cardHolderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ADD THIS METHOD
  Future<void> _loadCurrencyData() async {
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    setState(() {});
  }

// ADD THIS METHOD
  String _convertAndFormatPrice(String priceStr) {
    if (_exchangeRates.isEmpty) return priceStr;

    double usdPrice = double.tryParse(priceStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0;
    double convertedPrice = CurrencyService.convertPrice(usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }


  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userData =
      await _firestore.collection('users').doc(user.uid).get();

      if (userData.exists && mounted) {
        setState(() {
          userName = userData['name'] ?? 'Customer';
          userPhone = userData['phone'] ?? '';
          userEmail = userData['email'] ?? user.email ?? '';
          userAddresses = List<String>.from(userData['addresses'] ?? []);
          selectedAddress = userAddresses.isNotEmpty ? userAddresses[0] : '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a delivery address")),
      );
      return;
    }

    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    // Validate card details if card payment is selected
    if (selectedPaymentMethod == 'card') {
      if (_cardHolderNameController.text.isEmpty ||
          _cardNumberController.text.isEmpty ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all card details")),
        );
        return;
      }

      // Validate card number (should be 16 digits)
      if (_cardNumberController.text.replaceAll(' ', '').length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid card number")),
        );
        return;
      }

      // Validate CVV (should be 3 digits)
      if (_cvvController.text.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid CVV code")),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      Position? customerPosition =
      await LocationService.getCoordinatesFromAddress(selectedAddress);

      for (var item in widget.cartItems) {
        QuerySnapshot productQuery = await _firestore
            .collection('products')
            .where('name', isEqualTo: item.productName)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          var product = productQuery.docs.first;
          String trackingId = 'TRK${DateTime.now().millisecondsSinceEpoch}';

          Map<String, dynamic> orderData = {
            'trackingId': trackingId,
            'productName': item.productName,
            'productImage': item.imageUrl,
            'price': item.price,
            'quantity': item.quantity,
            'customerName': userName,
            'customerAddress': selectedAddress,
            'customerPhone': userPhone,
            'customerEmail': userEmail,
            'customerId': user.uid,
            'sellerId': product['sellerId'],
            'status': 'pending',
            'orderDate': FieldValue.serverTimestamp(),
            'estimatedDelivery':
            DateTime.now().add(Duration(days: 7)).toIso8601String(),
            'paymentMethod': selectedPaymentMethod,
            'paymentStatus': selectedPaymentMethod == 'cash' ? 'pending' : 'paid',
          };

          // Add masked card details if card payment
          if (selectedPaymentMethod == 'card') {
            String cardNumber = _cardNumberController.text.replaceAll(' ', '');
            String maskedCard = '**** **** **** ${cardNumber.substring(12)}';
            orderData['cardLastFour'] = cardNumber.substring(12);
            orderData['maskedCardNumber'] = maskedCard;
          }

          String priceStr = item.price.replaceAll('\$', '').replaceAll(',', '');
          double price = double.tryParse(priceStr) ?? 0;
          double itemTotal = price * item.quantity;

          await EmailService.sendOrderConfirmation(
            email: userEmail,
            customerName: userName,
            trackingId: trackingId,
            productName: item.productName,
            quantity: item.quantity.toString(),
            price: item.price,
            totalAmount: '\$${itemTotal.toStringAsFixed(2)}',
            deliveryAddress: selectedAddress,
            customerPhone: userPhone,
          );

          if (customerPosition != null) {
            orderData['customerLat'] = customerPosition.latitude;
            orderData['customerLng'] = customerPosition.longitude;
          }

          await _firestore.collection('orders').add(orderData);

          int currentStock = product['stock'] ?? 0;
          int newStock = currentStock - item.quantity;
          if (newStock >= 0) {
            await _firestore
                .collection('products')
                .doc(product.id)
                .update({'stock': newStock});
          }

          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(item.productName)
              .delete();
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        customPageRoute(OrderSuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error placing order: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isPlacingOrder = false);
    }
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += value[i];
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          CurrencySelector(
            onCurrencyChanged: (currency) {
              // Prices will update automatically via StreamBuilder if needed
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Text(
                "Order Summary",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Inside the Order Summary container
                    ...widget.cartItems.map((item) {
                      String priceStr = item.price.replaceAll('\$', '').replaceAll(',', '');
                      double price = double.tryParse(priceStr) ?? 0;
                      double itemTotal = price * item.quantity;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.image),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Qty: ${item.quantity}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _convertAndFormatPrice('\$${itemTotal.toStringAsFixed(2)}'), // CHANGED
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _convertAndFormatPrice('\$${widget.totalPrice.toStringAsFixed(2)}'), // CHANGED
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25),

              // Delivery Address
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Delivery Address",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        customPageRoute(EditProfileScreen()),
                      ).then((_) => _loadUserData());
                    },
                    child: Text("+ Add New"),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (userAddresses.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.location_off,
                          size: 40, color: Colors.orange),
                      SizedBox(height: 10),
                      Text(
                        "No address found",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Please add a delivery address",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            customPageRoute(EditProfileScreen()),
                          ).then((_) => _loadUserData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: Text("Add Address"),
                      ),
                    ],
                  ),
                )
              else
                ...userAddresses.map((address) {
                  bool isSelected = selectedAddress == address;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAddress = address;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (userPhone.isNotEmpty) ...[
                                  SizedBox(height: 5),
                                  Text(
                                    "Phone: $userPhone",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              SizedBox(height: 25),

              // Payment Method Section
              Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),

              // Cash on Delivery Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentMethod = 'cash';
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selectedPaymentMethod == 'cash'
                          ? Colors.deepPurple
                          : Colors.grey.shade300,
                      width: selectedPaymentMethod == 'cash' ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedPaymentMethod == 'cash'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedPaymentMethod == 'cash'
                            ? Colors.deepPurple
                            : Colors.grey,
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.money, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cash on Delivery",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Pay when you receive",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Card Payment Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentMethod = 'card';
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selectedPaymentMethod == 'card'
                          ? Colors.deepPurple
                          : Colors.grey.shade300,
                      width: selectedPaymentMethod == 'card' ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedPaymentMethod == 'card'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedPaymentMethod == 'card'
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.credit_card,
                              color: Colors.blue, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Credit/Debit Card",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Pay securely with your card",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (selectedPaymentMethod == 'card') ...[
                        SizedBox(height: 20),
                        Divider(),
                        SizedBox(height: 15),
                        // Card Holder Name
                        TextField(
                          controller: _cardHolderNameController,
                          decoration: InputDecoration(
                            labelText: "Card Holder Name",
                            prefixIcon: Icon(Icons.person_outline,
                                color: Colors.deepPurple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.deepPurple, width: 2),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: 15),
                        // Card Number
                        TextField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                          decoration: InputDecoration(
                            labelText: "Card Number",
                            prefixIcon: Icon(Icons.credit_card,
                                color: Colors.deepPurple),
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.deepPurple, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            String formatted = _formatCardNumber(value);
                            _cardNumberController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          },
                        ),
                        SizedBox(height: 15),
                        // Expiry Date and CVV
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryDateController,
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                decoration: InputDecoration(
                                  labelText: "MM/YY",
                                  hintText: "12/25",
                                  prefixIcon: Icon(Icons.calendar_today,
                                      color: Colors.deepPurple),
                                  counterText: "",
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.deepPurple,
                                        width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.length == 2 &&
                                      !value.contains('/')) {
                                    _expiryDateController.text =
                                        value + '/';
                                    _expiryDateController.selection =
                                        TextSelection.collapsed(
                                            offset: 3);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "CVV",
                                  hintText: "123",
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: Colors.deepPurple),
                                  counterText: "",
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.deepPurple,
                                        width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Place Order Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Place Order - ${_convertAndFormatPrice('\$${widget.totalPrice.toStringAsFixed(2)}')}", // CHANGED
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ ORDER SUCCESS SCREEN ============
class OrderSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Order Placed Successfully!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                "Your order has been placed and is being processed.\nYou can track your order status in My Orders.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      customPageRoute(CustomerOrdersScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "View My Orders",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    customPageRoute(DashboardScreen()),
                        (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  side: BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Continue Shopping",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ CUSTOMER ORDERS SCREEN ============
class CustomerOrdersScreen extends StatefulWidget {
  @override
  _CustomerOrdersScreenState createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('customerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading orders"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 20),
                  Text(
                    "No Orders Yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort orders by date
          List<DocumentSnapshot> orders = snapshot.data!.docs.toList();
          orders.sort((a, b) {
            DateTime dateA = (a['orderDate'] as Timestamp).toDate();
            DateTime dateB = (b['orderDate'] as Timestamp).toDate();
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot order) {
    String status = order['status'] ?? 'pending';
    String trackingId = order['trackingId'] ?? 'N/A';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.settings;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          customPageRoute(OrderTrackingScreen(orderId: order.id)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, size: 18, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        trackingId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 5),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order['productImage'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['productName'] ?? 'Product',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Qty: ${order['quantity']}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          order['price'] ?? '\$0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Divider(height: 1),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      SizedBox(width: 5),
                      Text(
                        _formatDate(order['orderDate']),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Text(
                    "View Details →",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dateTime = (date as Timestamp).toDate();
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return 'N/A';
    }
  }
}

// ============ ORDER TRACKING SCREEN ============
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  OrderTrackingScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Track Order",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Order not found"));
          }

          var order = snapshot.data!;
          String status = order['status'] ?? 'pending';
          String trackingId = order['trackingId'] ?? 'N/A';
          // Check if rating exists in reviews collection instead
          Future<double?> _getOrderRating() async {
            try {
              QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('orderId', isEqualTo: orderId)
                  .limit(1)
                  .get();

              if (reviewSnapshot.docs.isNotEmpty) {
                return (reviewSnapshot.docs.first['rating'] as num).toDouble();
              }
              return null;
            } catch (e) {
              return null;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping, size: 60, color: Colors.white),
                      SizedBox(height: 15),
                      Text(
                        "Tracking ID",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 5),
                      Text(
                        trackingId,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Product Details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order['productImage'] ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: Icon(Icons.image),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['productName'] ?? 'Product',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Quantity: ${order['quantity']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                order['price'] ?? '\$0',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),

                // Order Status Timeline
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Status",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTimelineItem(
                        "Order Placed",
                        "Your order has been placed",
                        true,
                        status != 'pending',
                        Icons.shopping_cart,
                      ),
                      _buildTimelineItem(
                        "Processing",
                        "Seller is preparing your order",
                        status == 'processing' || status == 'shipped' || status == 'delivered',
                        status == 'shipped' || status == 'delivered',
                        Icons.settings,
                      ),
                      _buildTimelineItem(
                        "Shipped",
                        "Your order is on the way",
                        status == 'shipped' || status == 'delivered',
                        status == 'delivered',
                        Icons.local_shipping,
                      ),
                      _buildTimelineItem(
                        "Delivered",
                        "Order delivered successfully",
                        status == 'delivered',
                        false,
                        Icons.check_circle,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),

                // Delivery Address
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivery Address",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (order['status'] == 'shipped' || order['status'] == 'processing')
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (order['customerLat'] != null &&
                                      order['customerLng'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderTrackingMapScreen(
                                          orderId: orderId,
                                          isSeller: false,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Location tracking not available for this order'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.map, size: 24),
                                label: Text(
                                  'Track on Map',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 30),
                        // Replace the existing rating check with FutureBuilder
                        if (order['status'] == 'delivered')
                          FutureBuilder<double?>(
                            future: _getOrderRating(),
                            builder: (context, ratingSnapshot) {
                              bool hasRating = ratingSnapshot.hasData && ratingSnapshot.data != null;

                              if (hasRating) {
                                return SizedBox.shrink(); // Already rated
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      QuerySnapshot productQuery = await FirebaseFirestore.instance
                                          .collection('products')
                                          .where('name', isEqualTo: order['productName'])
                                          .limit(1)
                                          .get();

                                      if (productQuery.docs.isNotEmpty) {
                                        String productId = productQuery.docs.first.id;
                                        await _showReviewDialog(context, orderId, productId, order['productName']);
                                      }
                                    },
                                    icon: Icon(Icons.star, size: 20),
                                    label: Text('Rate & Review Product'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        SizedBox(height: 30),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: Colors.deepPurple, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['customerName'] ?? 'Customer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    order['customerAddress'] ?? 'No address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (order['customerPhone'] != null) ...[
                                    SizedBox(height: 5),
                                    Text(
                                      order['customerPhone'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, String orderId, String productId, String productName) async {
    final _commentController = TextEditingController();
    double rating = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate & Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Rate this product:'),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: rating > 0
                    ? () async {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    DocumentSnapshot userData = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    await FirebaseFirestore.instance.collection('reviews').add({
                      'orderId': orderId,
                      'productId': productId,
                      'customerId': user.uid,
                      'customerName': userData['name'] ?? 'Customer',
                      'rating': rating,
                      'comment': _commentController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'rating': rating});

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for your review!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildTimelineItem(
      String title,
      String subtitle,
      bool isActive,
      bool isCompleted,
      IconData icon, {
        bool isLast = false,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.deepPurple
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? Colors.deepPurple
                    : Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isActive ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============ ADD PRODUCT SCREEN ============
class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}



// ============ EDIT PRODUCT SCREEN ============
class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditProductScreen({required this.productId, required this.productData});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _discountController = TextEditingController();

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};

  String selectedCategory = "Electronics";
  List<String> selectedSizes = [];
  List<String> existingImages = [];
  bool _isLoading = false;
  bool _isTrending = false;

  final List<String> categories = [
    "Electronics",
    "Fashion",
    "Sports",
    "Beauty",
    "Home",
    "Books"
  ];

  final List<String> availableSizes = ["XS", "S", "M", "L", "XL", "XXL"];

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCurrencyData();
    _loadProductData();
  }

  Future<void> _loadCurrencyData() async {
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    if (mounted) {
      setState(() {});
    }
  }

  void _loadProductData() {
    _nameController.text = widget.productData['name'] ?? '';
    _descriptionController.text = widget.productData['description'] ?? '';

    // CONVERT USD PRICE TO SELECTED CURRENCY FOR DISPLAY
    String priceStr = widget.productData['price'].toString().replaceAll('\$', '');
    double usdPrice = double.tryParse(priceStr) ?? 0;
    double displayPrice = CurrencyService.convertPrice(
        usdPrice,
        'USD',
        _selectedCurrency,
        _exchangeRates
    );
    _priceController.text = displayPrice.toStringAsFixed(2);

    _stockController.text = widget.productData['stock'].toString();

    double discount = (widget.productData['discountPercentage'] ?? 0.0).toDouble();
    _discountController.text = discount > 0 ? discount.toString() : '';

    selectedCategory = widget.productData['category'] ?? 'Electronics';
    selectedSizes = List<String>.from(widget.productData['sizes'] ?? []);
    existingImages = List<String>.from(widget.productData['images'] ?? []);
    _isTrending = widget.productData['isTrending'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product must have at least one image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

// CONVERT PRICE BACK TO USD BEFORE SAVING
      double enteredPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      double priceInUSD = CurrencyService.convertPrice(
          enteredPrice,
          _selectedCurrency,
          'USD',
          _exchangeRates
      );

      // If marking as trending, remove trending from other products
      if (_isTrending && !(widget.productData['isTrending'] ?? false)) {
        QuerySnapshot existingTrending = await _firestore
            .collection('products')
            .where('sellerId', isEqualTo: widget.productData['sellerId'])
            .where('isTrending', isEqualTo: true)
            .get();

        for (var doc in existingTrending.docs) {
          if (doc.id != widget.productId) {
            await _firestore.collection('products').doc(doc.id).update({
              'isTrending': false,
            });
          }
        }
      }

      await _firestore.collection('products').doc(widget.productId).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': '\$${priceInUSD.toStringAsFixed(2)}',
        'category': selectedCategory,
        'images': existingImages,
        'sizes': selectedSizes,
        'stock': int.parse(_stockController.text.trim()),
        'discountPercentage': discount,
        'isTrending': _isTrending,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Edit Product",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product Images",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              if (existingImages.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: existingImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 120,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            existingImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 25),

              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price Currency",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.currency_exchange, color: Colors.deepPurple),
                      ),
                      items: [
                        DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                        DropdownMenuItem(value: 'PKR', child: Text('Pakistani Rupee (Rs.)')),
                        DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('British Pound (£)')),
                        DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (₹)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Enter price in ${_selectedCurrency}. It will be stored in USD.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              _buildTextField("Product Name", _nameController),
              SizedBox(height: 15),
              _buildTextField("Description", _descriptionController,
                  maxLines: 4),
              SizedBox(height: 15),
              _buildTextField("Price in ${CurrencyService.formatPrice(0, _selectedCurrency).replaceAll('0.00', '')} (without symbol)", _priceController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 15),
              _buildTextField("Stock Quantity", _stockController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 15),
              _buildTextField("Discount % (Optional)", _discountController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Mark as Trending",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Show this product in trending section (1 per seller)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isTrending,
                      onChanged: (value) {
                        setState(() {
                          _isTrending = value;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Available Sizes (Optional)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: availableSizes.map((size) {
                  bool isSelected = selectedSizes.contains(size);
                  return FilterChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSizes.add(size);
                        } else {
                          selectedSizes.remove(size);
                        }
                      });
                    },
                    selectedColor: Colors.deepPurple.withOpacity(0.3),
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Update Product",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _discountController = TextEditingController(); // ADD THIS

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};

  String selectedCategory = "Electronics";
  List<String> selectedSizes = [];
  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];
  bool _isLoading = false;
  bool _isTrending = false; // ADD THIS
  bool _useUrlInput = false; // ADD THIS
  final _imageUrlController = TextEditingController(); // ADD THIS
  List<String> urlImages = []; // ADD THIS

  final List<String> categories = [
    "Electronics",
    "Fashion",
    "Sports",
    "Beauty",
    "Home",
    "Books"
  ];

  final List<String> availableSizes = ["XS", "S", "M", "L", "XL", "XXL"];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrencyData();

  }

  Future<void> _loadCurrencyData() async {
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    _imageUrlController.dispose(); // ADD THIS
    super.dispose();
  }

  // Pick single image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

// Pick multiple images
  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking images: $e")),
      );
    }
  }

// Upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> urls = [];

    if (selectedImages.isEmpty) {
      return urls;
    }

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        Reference ref = _storage
            .ref()
            .child('product_images')
            .child(_auth.currentUser!.uid)
            .child(fileName);

        // Upload file
        UploadTask uploadTask = ref.putFile(selectedImages[i]);

        // Wait for upload to complete
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

        // Get download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);

        print("✅ Uploaded image ${i + 1}: $downloadUrl");
      }

      print("✅ All images uploaded successfully. Total: ${urls.length}");
      return urls;
    } catch (e) {
      print("❌ Error uploading images: $e");
      throw Exception("Failed to upload images: $e");
    }
  }

// Remove selected image
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // Check if at least one image is provided (either URL or device)
    if (selectedImages.isEmpty && urlImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      List<String> imageUrls = [];

      // If using device images, upload them to Firebase Storage
      if (!_useUrlInput && selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        if (imageUrls.isEmpty) {
          throw Exception("Failed to upload images");
        }
      }
      // If using URL images, use them directly
      else if (_useUrlInput && urlImages.isNotEmpty) {
        imageUrls = urlImages;
      }
      // If somehow neither has images (shouldn't happen due to validation above)
      else {
        throw Exception("No images provided");
      }

      // Get seller info
      DocumentSnapshot sellerDoc =
      await _firestore.collection('sellers').doc(user.uid).get();
      String shopName = sellerDoc['shopName'] ?? '';

      // Check if seller already has a trending product
      if (_isTrending) {
        QuerySnapshot existingTrending = await _firestore
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .where('isTrending', isEqualTo: true)
            .get();

        // Remove trending status from previous product
        for (var doc in existingTrending.docs) {
          await _firestore.collection('products').doc(doc.id).update({
            'isTrending': false,
          });
        }
      }

      double discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

// CONVERT PRICE TO USD BEFORE SAVING
      double enteredPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      double priceInUSD = CurrencyService.convertPrice(
          enteredPrice,
          _selectedCurrency,
          'USD',
          _exchangeRates
      );

      // Save product to Firestore
      await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': '\$${priceInUSD.toStringAsFixed(2)}',
        'category': selectedCategory,
        'images': imageUrls,
        'sizes': selectedSizes,
        'stock': int.parse(_stockController.text.trim()),
        'sellerId': user.uid,
        'shopName': shopName,
        'rating': 0.0,
        'reviews': 0,
        'discountPercentage': discount,
        'isTrending': _isTrending,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Add New Product",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product Images *",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

// Toggle between URL and Device Upload
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _useUrlInput = false;
                        });
                      },
                      icon: Icon(Icons.phone_android),
                      label: Text("From Device"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_useUrlInput ? Colors.deepPurple : Colors.grey.shade300,
                        foregroundColor: !_useUrlInput ? Colors.white : Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _useUrlInput = true;
                        });
                      },
                      icon: Icon(Icons.link),
                      label: Text("From URL"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _useUrlInput ? Colors.deepPurple : Colors.grey.shade300,
                        foregroundColor: _useUrlInput ? Colors.white : Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

// URL Input Section
              if (_useUrlInput) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: "Image URL",
                          hintText: "https://example.com/image.jpg",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_imageUrlController.text.isNotEmpty) {
                          setState(() {
                            urlImages.add(_imageUrlController.text.trim());
                            _imageUrlController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(16),
                      ),
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],

// Display URL images
              if (_useUrlInput && urlImages.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: urlImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                urlImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: Colors.red),
                                        Text("Invalid URL", style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 15,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  urlImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

// Display device images
              if (!_useUrlInput && selectedImages.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 15,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              SizedBox(height: 10),

// Image picker buttons (only show when device mode)
              if (!_useUrlInput)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text("Add Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickMultipleImages,
                        icon: Icon(Icons.photo_library),
                        label: Text("Add Multiple"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 25),

              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price Currency",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.currency_exchange, color: Colors.deepPurple),
                      ),
                      items: [
                        DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                        DropdownMenuItem(value: 'PKR', child: Text('Pakistani Rupee (Rs.)')),
                        DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('British Pound (£)')),
                        DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (₹)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Enter price in ${_selectedCurrency}. It will be stored in USD.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              _buildTextField("Product Name", _nameController),
              SizedBox(height: 15),
              _buildTextField("Description", _descriptionController,
                  maxLines: 4),
              SizedBox(height: 15),
              _buildTextField("Price in ${CurrencyService.formatPrice(0, _selectedCurrency).replaceAll('0.00', '')} (without symbol)", _priceController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 15),
              _buildTextField("Stock Quantity", _stockController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 20),
              _buildTextField("Discount % (Optional)", _discountController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Mark as Trending",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Show this product in trending section (1 per seller)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isTrending,
                      onChanged: (value) {
                        setState(() {
                          _isTrending = value;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Available Sizes (Optional)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: availableSizes.map((size) {
                  bool isSelected = selectedSizes.contains(size);
                  return FilterChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSizes.add(size);
                        } else {
                          selectedSizes.remove(size);
                        }
                      });
                    },
                    selectedColor: Colors.deepPurple.withOpacity(0.3),
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Add Product",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}

// ============ LIMITED TIME OFFER SCREEN ============
class LimitedTimeOfferScreen extends StatefulWidget {
  @override
  _LimitedTimeOfferScreenState createState() => _LimitedTimeOfferScreenState();
}

class _LimitedTimeOfferScreenState extends State<LimitedTimeOfferScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, bool> selectedProducts = {};
  Map<String, double> productDiscounts = {};
  Map<String, int> productOfferDays = {};
  int globalSelectedDays = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        title: Text(
          "Limited Time Offers",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Default Offer Duration",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  children: [1, 3, 7, 14, 30].map((days) {
                    bool isSelected = globalSelectedDays == days;
                    return ChoiceChip(
                      label: Text("$days ${days == 1 ? 'Day' : 'Days'}"),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          globalSelectedDays = days;
                        });
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                Text(
                  "You can customize duration for each product individually",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('sellerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 80, color: Colors.red.shade300),
                        SizedBox(height: 20),
                        Text(
                          "Error loading products",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 20),
                        Text(
                          "No Products Available",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter products with stock > 0 in Dart instead of Firestore
                List<DocumentSnapshot> productsWithStock = snapshot.data!.docs
                    .where((doc) {
                  int stock = doc['stock'] ?? 0;
                  return stock > 0;
                })
                    .toList();

                if (productsWithStock.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 20),
                        Text(
                          "No Products in Stock",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Add stock to your products to create offers",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(15),
                  itemCount: productsWithStock.length,
                  itemBuilder: (context, index) {
                    var product = productsWithStock[index];
                    String productId = product.id;
                    bool isSelected = selectedProducts[productId] ?? false;
                    double discount = productDiscounts[productId] ?? 10.0;
                    int offerDays =
                        productOfferDays[productId] ?? globalSelectedDays;

                    List<String> images =
                    List<String>.from(product['images'] ?? []);
                    String imageUrl = images.isNotEmpty ? images[0] : '';

                    return Container(
                      margin: EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                          isSelected ? Colors.orange : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(15)),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image,
                                          color: Colors.grey.shade400),
                                    );
                                  },
                                )
                                    : Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.image,
                                      color: Colors.grey.shade400),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Product',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        product['price'] ?? '\$0',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Stock: ${product['stock']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    selectedProducts[productId] =
                                        value ?? false;
                                    if (value == true &&
                                        !productOfferDays
                                            .containsKey(productId)) {
                                      productOfferDays[productId] =
                                          globalSelectedDays;
                                    }
                                  });
                                },
                                activeColor: Colors.orange,
                              ),
                            ],
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Discount: ${discount.toInt()}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "Duration: $offerDays ${offerDays == 1 ? 'day' : 'days'}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: discount,
                                    min: 5,
                                    max: 90,
                                    divisions: 17,
                                    label: "${discount.toInt()}%",
                                    activeColor: Colors.orange,
                                    onChanged: (value) {
                                      setState(() {
                                        productDiscounts[productId] = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Offer Duration:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [1, 3, 7, 14, 30].map((days) {
                                      bool isDaySelected = offerDays == days;
                                      return ChoiceChip(
                                        label: Text(
                                            "$days ${days == 1 ? 'Day' : 'Days'}"),
                                        selected: isDaySelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            productOfferDays[productId] = days;
                                          });
                                        },
                                        selectedColor: Colors.orange,
                                        labelStyle: TextStyle(
                                          color: isDaySelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "${selectedProducts.values.where((v) => v).length} products selected",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedProducts.values.where((v) => v).isEmpty ||
                        _isLoading
                        ? null
                        : _applyOffers,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Apply Offers",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyOffers() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();

      WriteBatch batch = _firestore.batch();

      for (var entry in selectedProducts.entries) {
        if (entry.value) {
          String productId = entry.key;
          double discount = productDiscounts[productId] ?? 10.0;
          int offerDays = productOfferDays[productId] ?? globalSelectedDays;
          DateTime endDate = now.add(Duration(days: offerDays));

          // Update product with discount
          DocumentReference productRef =
          _firestore.collection('products').doc(productId);
          batch.update(productRef, {
            'discountPercentage': discount,
            'offerEndDate': endDate.toIso8601String(),
            'offerStartDate': now.toIso8601String(),
          });

          // Create offer record
          DocumentReference offerRef =
          _firestore.collection('limitedOffers').doc();
          batch.set(offerRef, {
            'productId': productId,
            'sellerId': user.uid,
            'startDate': now.toIso8601String(),
            'endDate': endDate.toIso8601String(),
            'discountPercentage': discount,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Offers applied successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error applying offers: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ============ ORDER DETAIL SCREEN ============
class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  OrderDetailScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Order not found"));
          }

          var order = snapshot.data!;
          String status = order['status'] ?? 'pending';

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${orderId.substring(0, 8)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                order['productImage'] ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.image),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['productName'] ?? 'Product',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Quantity: ${order['quantity']}",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    order['price'] ?? '\$0',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Customer Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildInfoRow(
                            Icons.person, "Name", order['customerName'] ?? 'N/A'),
                        SizedBox(height: 10),
                        _buildInfoRow(Icons.location_on, "Address",
                            order['customerAddress'] ?? 'N/A'),
                        SizedBox(height: 10),
                        _buildInfoRow(Icons.phone, "Phone",
                            order['customerPhone'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildStatusOption(
                            context, orderId, "pending", "Pending", status),
                        _buildStatusOption(context, orderId, "processing",
                            "Processing", status),
                        _buildStatusOption(
                            context, orderId, "shipped", "Shipped", status),
                        _buildStatusOption(
                            context, orderId, "delivered", "Delivered", status),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  // ADD SELLER TRACKING BUTTON HERE
                  if (status == 'shipped' || status == 'processing')
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    status == 'shipped'
                                        ? 'Enable live tracking to share your location with customer'
                                        : 'Mark as shipped to enable live tracking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (status != 'shipped') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please mark order as shipped first'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderTrackingMapScreen(
                                      orderId: orderId,
                                      isSeller: true,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.navigation, size: 24),
                              label: Text(
                                status == 'shipped'
                                    ? 'Start Live Tracking'
                                    : 'View Delivery Location',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: status == 'shipped'
                                    ? Colors.green
                                    : Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(BuildContext context, String orderId,
      String statusValue, String statusLabel, String currentStatus) {
    bool isSelected = currentStatus == statusValue;
    bool isPastStatus = _isStatusPast(statusValue, currentStatus);

    // Status descriptions
    Map<String, String> statusDescriptions = {
      'pending': 'Order received, waiting for seller confirmation',
      'processing': 'Seller is preparing your product',
      'shipped': 'Product is on the way to you',
      'delivered': 'Product delivered successfully',
    };

    return GestureDetector(
      onTap: () async {
        if (!isSelected) {
          try {
            // Prepare update data
            Map<String, dynamic> updateData = {
              'status': statusValue,
            };

            // Add status history entry
            Map<String, dynamic> historyEntry = {
              'status': statusValue,
              'timestamp': DateTime.now().toIso8601String(), // Changed from FieldValue.serverTimestamp()
              'description': statusDescriptions[statusValue] ?? 'Status updated',
            };

            // Update order with new status and history
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .update(updateData);

            // Add to status history array
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .update({
              'statusHistory': FieldValue.arrayUnion([historyEntry]),
              'lastUpdated': DateTime.now().toIso8601String(), // Add last updated timestamp
            });

            // Send delivery confirmation email if status is delivered
            if (statusValue == 'delivered') {
              DocumentSnapshot orderDoc = await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .get();

              if (orderDoc.exists) {
                var order = orderDoc.data() as Map<String, dynamic>;

                await EmailService.sendDeliveryConfirmation(
                  email: order['customerEmail'] ?? '',
                  customerName: order['customerName'] ?? 'Customer',
                  trackingId: order['trackingId'] ?? 'N/A',
                  productName: order['productName'] ?? 'Product',
                  quantity: order['quantity'].toString(),
                  price: order['price'] ?? '\$0',
                  deliveryDate: DateTime.now().toString().split(' ')[0],
                );
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Order status updated to $statusLabel"),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('❌ Error updating status: $e'); // Debug print
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error updating status: ${e.toString()}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.1)
              : isPastStatus
              ? Colors.green.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple
                : isPastStatus
                ? Colors.green
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPastStatus
                  ? Icons.check_circle
                  : isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Colors.deepPurple
                  : isPastStatus
                  ? Colors.green
                  : Colors.grey.shade400,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.deepPurple
                          : isPastStatus
                          ? Colors.green
                          : Colors.black87,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: 4),
                    Text(
                      statusDescriptions[statusValue] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStatusPast(String statusValue, String currentStatus) {
    List<String> statusOrder = ['pending', 'processing', 'shipped', 'delivered'];
    int currentIndex = statusOrder.indexOf(currentStatus);
    int statusIndex = statusOrder.indexOf(statusValue);
    return statusIndex < currentIndex;
  }
}

// ============ CART SCREEN ============
class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<CartItem> cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      if (mounted) {
        setState(() {
          cartItems = cartSnapshot.docs.map((doc) {
            return CartItem(
              productName: doc['productName'],
              price: doc['price'],
              imageUrl: doc['imageUrl'],
              quantity: doc['quantity'],
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> wishlistProductIds = [];

  Future<void> _loadWishlist() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot wishlistSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      if (mounted) {
        setState(() {
          wishlistProductIds = wishlistSnapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _toggleWishlist(String productId, String productName, String price, String imageUrl, String category, {int? stock}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      return;
    }

    // CHECK IF PRODUCT IS OUT OF STOCK
    bool isOutOfStock = stock != null && stock == 0;
    if (!isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text("Only out of stock items can be added to wishlist"),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      DocumentReference wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId);

      DocumentSnapshot wishlistDoc = await wishlistRef.get();

      if (wishlistDoc.exists) {
        await wishlistRef.delete();
        setState(() {
          wishlistProductIds.remove(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from wishlist"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await wishlistRef.set({
          'productId': productId,
          'productName': productName,
          'price': price,
          'imageUrl': imageUrl,
          'category': category,
          'addedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          wishlistProductIds.add(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Added to wishlist! We'll notify you when it's back in stock."),
                ),
              ],
            ),
            backgroundColor: Colors.pink,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  Future<void> _removeFromCart(CartItem item) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.productName)
          .delete();

      setState(() {
        cartItems.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${item.productName} removed from cart")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing item")),
      );
    }
  }

  Future<void> _updateQuantity(CartItem item, int change) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    int newQuantity = item.quantity + change;
    if (newQuantity < 1) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item.productName)
          .update({'quantity': newQuantity});

      setState(() {
        item.quantity = newQuantity;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating quantity")),
      );
    }
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems) {
      String priceStr = item.price.replaceAll('\$', '').replaceAll(',', '');
      double price = double.tryParse(priceStr) ?? 0;
      total += price * item.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 100, color: Colors.grey.shade300),
            SizedBox(height: 20),
            Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Add items to get started",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(15),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(cartItems[index]);
              },
            ),
          ),
          // ADD THIS CONTAINER BACK
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${getTotalPrice().toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (cartItems.isEmpty) return;
                      Navigator.push(
                        context,
                        customPageRoute(
                          CheckoutScreen(
                            cartItems: cartItems,
                            totalPrice: getTotalPrice(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Checkout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
            child: Image.network(
              item.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade400),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.price,
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 18),
                              onPressed: () => _updateQuantity(item, -1),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                item.quantity.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 18),
                              onPressed: () => _updateQuantity(item, 1),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeFromCart(item),
          ),
        ],
      ),
    );
  }
}

// ============ DASHBOARD SCREEN ============
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String userName = "User";
  String userEmail = "";
  String userPhone = "";
  List<String> userAddresses = [];
  String searchQuery = "";
  String selectedCategory = "";
  bool _isLoadingUserData = true;

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};
  bool _loadingRates = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();

  List<CartItem> cartItems = [];

  // All products database
  List<Product> allProducts = [];
  bool _isLoadingProducts = true;

  Map<String, int> _productStocks = {};
  Map<String, String> _productIds = {};
  List<String> wishlistProductIds = [];

  @override
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCartItems();
    _loadProductsFromFirestore();
    _loadWishlist();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    setState(() => _loadingRates = true);
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    setState(() => _loadingRates = false);
  }

// ADD this helper method
  String _convertAndFormatPrice(String priceStr) {
    if (_exchangeRates.isEmpty) return priceStr;

    // Parse the USD price from string (remove $ and any commas)
    double usdPrice = double.tryParse(
        priceStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0;

    double convertedPrice = CurrencyService.convertPrice(
        usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  String _convertAndFormatPriceFromDouble(double usdPrice) {
    if (_exchangeRates.isEmpty) return '\$${usdPrice.toStringAsFixed(2)}';

    double convertedPrice = CurrencyService.convertPrice(
        usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  Future<void> _loadWishlist() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot wishlistSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      if (mounted) {
        setState(() {
          wishlistProductIds =
              wishlistSnapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _toggleWishlist(String productId, String productName,
      String price, String imageUrl, String category, {int? stock}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      return;
    }

    // CHECK IF PRODUCT IS OUT OF STOCK
    bool isOutOfStock = stock != null && stock == 0;
    if (!isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text("Only out of stock items can be added to wishlist"),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      DocumentReference wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId);

      DocumentSnapshot wishlistDoc = await wishlistRef.get();

      if (wishlistDoc.exists) {
        // Remove from wishlist
        await wishlistRef.delete();
        setState(() {
          wishlistProductIds.remove(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from wishlist"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Add to wishlist
        await wishlistRef.set({
          'productId': productId,
          'productName': productName,
          'price': price,
          'imageUrl': imageUrl,
          'category': category,
          'addedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          wishlistProductIds.add(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                    "Added to wishlist! We'll notify you when it's back in stock."),
              ],
            ),
            backgroundColor: Colors.pink,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData =
        await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          if (mounted) {
            setState(() {
              userName = userData['name'] ?? 'User';
              userEmail = userData['email'] ?? user.email ?? '';
              userPhone = userData['phone'] ?? '';
              userAddresses = List<String>.from(userData['addresses'] ?? []);
              _isLoadingUserData = false;
            });
          }
        } else {
          // User document doesn't exist - create it
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'User',
            'email': user.email ?? '',
            'phone': '',
            'addresses': [],
            'userType': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() {
              userName = user.displayName ?? 'User';
              userEmail = user.email ?? '';
              _isLoadingUserData = false;
            });
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (mounted) {
          setState(() {
            userName = user.displayName ?? 'User';
            userEmail = user.email ?? '';
            _isLoadingUserData = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  Future<void> _addToCart(Product product) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      return;
    }

    try {
      // Reference to the cart document
      DocumentReference cartRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(product.name);

      // Check if item already exists
      DocumentSnapshot cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Item exists, increment quantity
        int currentQty = cartDoc['quantity'] ?? 1;
        await cartRef.update({
          'quantity': currentQty + 1,
        });
      } else {
        // New item, add to cart
        await cartRef.set({
          'productName': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'quantity': 1,
          'category': product.category,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // Reload cart items to update count
      await _loadCartItems();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${product.name} added to cart!",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text("Failed to add to cart: ${e.toString()}"),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _loadCartItems() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      if (mounted) {
        setState(() {
          cartItems = cartSnapshot.docs.map((doc) {
            return CartItem(
              productName: doc['productName'],
              price: doc['price'],
              imageUrl: doc['imageUrl'],
              quantity: doc['quantity'],
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  int get cartItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _loadProductsFromFirestore() async {
    try {
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .get(); // Remove stock filter here

      List<Product> loadedProducts = [];
      Map<String, int> productStocks = {};
      Map<String, String> productIds = {};

      for (var doc in productSnapshot.docs) {
        List<String> images = List<String>.from(doc['images'] ?? []);
        String imageUrl = images.isNotEmpty ? images[0] : '';

        String priceStr = doc['price'].toString().replaceAll('\$', '');
        double originalPrice = double.tryParse(priceStr) ?? 0;

        double discountPercent = (doc['discountPercentage'] ?? 0.0).toDouble();

        String displayPrice;
        String oldPrice;

        if (discountPercent > 0) {
          double discountedPrice = originalPrice * (1 - discountPercent / 100);
          displayPrice = '\$${discountedPrice.toStringAsFixed(2)}';
          oldPrice = '\$${originalPrice.toStringAsFixed(2)}';
        } else {
          displayPrice = '\$${originalPrice.toStringAsFixed(2)}';
          oldPrice = '\$${(originalPrice * 1.4).toStringAsFixed(2)}';
        }

        String productName = doc['name'] ?? 'Product';
        int stock = doc['stock'] ?? 0;

        productStocks[productName] = stock;
        productIds[productName] = doc.id;

        loadedProducts.add(Product(
          name: productName,
          price: displayPrice,
          oldPrice: oldPrice,
          imageUrl: imageUrl,
          rating: (doc['rating'] ?? 0.0).toDouble(),
          category: doc['category'] ?? 'Electronics',
        ));
      }

      if (mounted) {
        setState(() {
          allProducts = loadedProducts;
          _productStocks = productStocks; // Add this state variable
          _productIds = productIds; // Add this state variable
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        customPageRoute(UserTypeSelectionScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged out successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  List<Product> getFilteredProducts() {
    List<Product> filtered = allProducts;

    if (selectedCategory.isNotEmpty) {
      filtered = filtered.where((p) => p.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }


  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      searchQuery = "";
      _searchController.clear();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = "";
      searchQuery = "";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "ShopEasy",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white
              ),
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          CurrencySelector(
            onCurrencyChanged: (currency) async {
              await _loadCurrencyData();
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                customPageRoute(CustomerOrdersScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    customPageRoute(CartScreen()),
                  ).then((_) => _loadCartItems());
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      cartItemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 4),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index != 0) {
                _clearFilters();
              }
            });
          },
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Stores',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Trending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildOffersTab();
      case 2:
        return _buildStoresTab(); // NEW
      case 3:
        return _buildTrendingTab(); // CHANGED FROM case 2
      case 4:
        return _buildProfileTab(); // CHANGED FROM case 3
      default:
        return _buildHomeTab();
    }
  }

  // HOME TAB
  Widget _buildHomeTab() {
    List<Product> displayProducts = getFilteredProducts();


    bool hasFilters = selectedCategory.isNotEmpty || searchQuery.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Search
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello,",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          _isLoadingUserData
                              ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Loading...",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : Text(
                            userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search for products...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.deepPurple),
                      onPressed: () {
                        setState(() {
                          searchQuery = "";
                          _searchController.clear();
                        });
                      },
                    )
                        : Icon(Icons.filter_list, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Active Filter Indicator
          if (hasFilters)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    selectedCategory.isNotEmpty
                        ? "Category: $selectedCategory"
                        : "Search: \"$searchQuery\"",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Clear",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.close,
                              size: 14, color: Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasFilters) SizedBox(height: 15),

          // Categories Section
          if (!hasFilters) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "See All",
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Container(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryCard(
                      "Electronics", "📱", Colors.blue.shade400),
                  _buildCategoryCard("Fashion", "👗", Colors.pink.shade400),
                  _buildCategoryCard("Sports", "⚽", Colors.green.shade400),
                  _buildCategoryCard("Beauty", "💄", Colors.purple.shade400),
                  _buildCategoryCard("Home", "🏠", Colors.orange.shade400),
                  _buildCategoryCard("Books", "📚", Colors.teal.shade400),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Flash Sale Banner
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.deepOrange.shade800
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "LIMITED TIME OFFER",
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Flash Sale! 🔥",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Up to 50% OFF on selected items",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepOrange,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text("Shop Now",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
          ],

          // Products Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasFilters
                      ? "Results (${displayProducts.length})"
                      : "Featured Products",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!hasFilters)
                  Text(
                    "See All",
                    style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          SizedBox(height: 15),

          // Products Grid
          if (displayProducts.isEmpty)
            Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off,
                        size: 80, color: Colors.grey.shade300),
                    SizedBox(height: 20),
                    Text(
                      "No products found",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Try searching with different keywords",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.70,
                ),
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                  Product product = displayProducts[index];
                  int stock = _productStocks[product.name] ?? 0;
                  String productId = _productIds[product.name] ?? '';
                  return _buildProductCard(
                    product,
                    productId: productId,
                    stock: stock,
                  );
                },
              ),
            ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String emoji, Color color) {
    return GestureDetector(
      onTap: () => _onCategorySelected(title),
      child: Container(
        width: 95,
        margin: EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedCategory == title ? color : color.withOpacity(0.2),
            width: selectedCategory == title ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selectedCategory == title ? color : Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, {String? productId, int? stock}) {
    bool isOutOfStock = stock != null && stock == 0;
    bool isInWishlist = productId != null && wishlistProductIds.contains(productId);

    double currentPrice = double.tryParse(product.price.replaceAll('\$', '')) ?? 0;
    double oldPriceValue = double.tryParse(product.oldPrice.replaceAll('\$', '')) ?? 0;
    int discountPercent = 0;

    if (oldPriceValue > currentPrice && currentPrice > 0) {
      discountPercent = (((oldPriceValue - currentPrice) / oldPriceValue) * 100).round();
    }

    return GestureDetector(
      onTap: () {
        if (productId != null) {
          Navigator.push(
            context,
            customPageRoute(ProductDetailScreen(productId: productId)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    product.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                      );
                    },
                  ),
                ),
                if (productId != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _toggleWishlist(
                          productId,
                          product.name,
                          product.price,
                          product.imageUrl,
                          product.category,
                          stock: stock,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.pink : (isOutOfStock ? Colors.deepPurple : Colors.grey.shade400),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          if (productId != null)
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('reviews')
                                  .where('productId', isEqualTo: productId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                double avgRating = 0;
                                int reviewCount = 0;

                                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                  reviewCount = snapshot.data!.docs.length;
                                  double totalRating = 0;
                                  for (var doc in snapshot.data!.docs) {
                                    totalRating += (doc['rating'] as num).toDouble();
                                  }
                                  avgRating = totalRating / reviewCount;
                                }

                                return Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 10),
                                    SizedBox(width: 2),
                                    Text(
                                      avgRating > 0 ? avgRating.toStringAsFixed(1) : '0.0',
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      ' ($reviewCount)',
                                      style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
                                    ),
                                  ],
                                );
                              },
                            ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _loadingRates ? product.price : _convertAndFormatPrice(product.price),
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (discountPercent > 0) ...[
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _loadingRates ? product.oldPrice : _convertAndFormatPrice(product.oldPrice),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: isOutOfStock ? null : () async {
                        await _addToCart(product);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade300 : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock ? Icons.block : Icons.shopping_cart,
                              color: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isOutOfStock ? "Out of Stock" : "Add to Cart",
                                style: TextStyle(
                                  color: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OFFERS TAB
  Widget _buildOffersTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade700],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Exclusive Offers",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Limited time deals just for you!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 15),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('limitedOffers')
                      .where('isActive', isEqualTo: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, offerSnapshot) {
                    if (offerSnapshot.hasData &&
                        offerSnapshot.data!.docs.isNotEmpty) {
                      var offer = offerSnapshot.data!.docs.first;
                      DateTime endDate = DateTime.parse(offer['endDate']);
                      Duration remaining = endDate.difference(DateTime.now());

                      if (remaining.isNegative) return SizedBox.shrink();

                      int days = remaining.inDays;
                      int hours = remaining.inHours % 24;
                      int minutes = remaining.inMinutes % 60;

                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              days > 0
                                  ? "Ends in $days days $hours hrs"
                                  : "Ends in $hours hrs $minutes mins",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ));
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 80, color: Colors.red.shade300),
                        SizedBox(height: 20),
                        Text(
                          "Error loading offers",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.shade600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 20),
                        Text(
                          "No offers available",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter products with discounts
              List<DocumentSnapshot> offerProducts = snapshot.data!.docs.where((
                  doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                double discount = (data['discountPercentage'] ?? 0.0)
                    .toDouble();
                return discount > 0;
              }).toList();

              if (offerProducts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 20),
                        Text(
                          "No offers available",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Sellers haven't added any limited time offers yet",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: offerProducts.map((doc) {
                    try {
                      Map<String, dynamic> data = doc.data() as Map<
                          String,
                          dynamic>;

                      List<String> images = List<String>.from(
                          data['images'] ?? []);
                      String imageUrl = images.isNotEmpty ? images[0] : '';

                      String priceStr = data['price'].toString().replaceAll(
                          '\$', '');
                      double originalPrice = double.tryParse(priceStr) ?? 0;
                      double discountPercent = (data['discountPercentage'] ??
                          0.0).toDouble();

                      double discountedPrice = originalPrice * (1 -
                          discountPercent / 100);
                      String displayPrice = '\$${discountedPrice
                          .toStringAsFixed(2)}';
                      String oldPrice = '\$${originalPrice.toStringAsFixed(2)}';

                      int stock = data['stock'] ?? 0;
                      String productId = doc.id;

                      Product product = Product(
                        name: data['name'] ?? 'Product',
                        price: displayPrice,
                        oldPrice: oldPrice,
                        imageUrl: imageUrl,
                        rating: (data['rating'] ?? 0.0).toDouble(),
                        category: data['category'] ?? 'Electronics',
                      );

                      return _buildOfferCard(
                        data['name'] ?? 'Product',
                        displayPrice,
                        oldPrice,
                        "Save ${discountPercent.toInt()}%",
                        imageUrl,
                        Colors.deepPurple,
                        product,
                        productId: productId,
                        stock: stock,
                      );
                    } catch (e) {
                      print('Error building offer card: $e');
                      return SizedBox.shrink();
                    }
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // STORES TAB
  Widget _buildStoresTab() {
    final _storeSearchController = TextEditingController();
    String storeSearchQuery = "";

    return StatefulBuilder(
      builder: (context, setStoreState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.white, size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Seller Stores",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Browse products from different sellers",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    // Search Bar
                    TextField(
                      controller: _storeSearchController,
                      onChanged: (value) {
                        setStoreState(() {
                          storeSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search stores...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                            Icons.search, color: Colors.deepPurple),
                        suffixIcon: storeSearchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.deepPurple),
                          onPressed: () {
                            setStoreState(() {
                              storeSearchQuery = "";
                              _storeSearchController.clear();
                            });
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('sellers').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(),
                        ));
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 80, color: Colors.red.shade300),
                            SizedBox(height: 20),
                            Text(
                              "Error loading stores",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.store_outlined,
                                size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 20),
                            Text(
                              "No stores available",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter stores by search query
                  List<DocumentSnapshot> filteredStores = snapshot.data!.docs
                      .where((doc) {
                    if (storeSearchQuery.isEmpty) return true;
                    String shopName = (doc['shopName'] ?? '').toLowerCase();
                    String city = (doc['city'] ?? '').toLowerCase();
                    String sellerType = (doc['sellerType'] ?? '').toLowerCase();
                    String query = storeSearchQuery.toLowerCase();
                    return shopName.contains(query) ||
                        city.contains(query) ||
                        sellerType.contains(query);
                  }).toList();

                  if (filteredStores.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off,
                                size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 20),
                            Text(
                              "No stores found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Try searching with different keywords",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(15),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) {
                        var seller = filteredStores[index];
                        return _buildStoreCard(seller);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreCard(DocumentSnapshot seller) {
    String shopName = seller['shopName'] ?? 'Shop';
    String sellerType = seller['sellerType'] ?? 'Individual Seller';
    String city = seller['city'] ?? 'Location';
    String sellerId = seller.id;

    // Get first letter for avatar
    String initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          customPageRoute(SellerStoreScreen(
            sellerId: sellerId,
            shopName: shopName,
          )),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    shopName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sellerType,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 12,
                          color: Colors.grey.shade600),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(String title, String price, String oldPrice,
      String discount, String imageUrl, Color color, Product product,
      {String? productId, int? stock}) {
    bool isOutOfStock = stock != null && stock == 0;
    bool isInWishlist = productId != null &&
        wishlistProductIds.contains(productId);

    return GestureDetector(
      onTap: () {
        if (productId != null) {
          Navigator.push(
            context,
            customPageRoute(ProductDetailScreen(productId: productId)),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(20)),
                      child: ColorFiltered(
                        colorFilter: isOutOfStock
                            ? ColorFilter.mode(
                            Colors.grey, BlendMode.saturation)
                            : ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                        child: Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: color.withOpacity(0.2),
                              child:
                              Icon(Icons.shopping_bag, color: color, size: 40),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!isOutOfStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            discount,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    if (isOutOfStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "OUT OF STOCK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isOutOfStock ? Colors.grey : Colors
                                      .black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (productId != null)
                              GestureDetector(
                                onTap: () {
                                  _toggleWishlist(
                                    productId,
                                    title,
                                    price,
                                    imageUrl,
                                    product.category,
                                    stock: stock,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isInWishlist ? Icons.favorite : Icons
                                        .favorite_border,
                                    color: isInWishlist ? Colors.pink : Colors
                                        .grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "4.5",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isOutOfStock
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            ),
                            Text(
                              " (120)",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isOutOfStock
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade400),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _loadingRates ? price : _convertAndFormatPrice(price),  // CHANGED
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isOutOfStock ? Colors.grey : Colors.deepPurple,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _loadingRates ? oldPrice : _convertAndFormatPrice(oldPrice),  // CHANGED
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: GestureDetector(
                onTap: isOutOfStock ? null : () => _addToCart(product),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.grey.shade300 : Colors
                        .deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOutOfStock ? Icons.block : Icons.shopping_cart,
                        color: isOutOfStock ? Colors.grey.shade600 : Colors
                            .white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isOutOfStock ? "Out of Stock" : "Add to Cart",
                        style: TextStyle(
                          color: isOutOfStock ? Colors.grey.shade600 : Colors
                              .white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // TRENDING TAB
  Widget _buildTrendingTab() {
    List<MapEntry<Product, String>> trendingProductsWithIds = [];

    for (var product in allProducts) {
      int stock = _productStocks[product.name] ?? 0;
      String productId = _productIds[product.name] ?? '';

      if (stock > 0 && productId.isNotEmpty) {
        trendingProductsWithIds.add(MapEntry(product, productId));
      }

      if (trendingProductsWithIds.length >= 8) break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade700],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Trending Now",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Most popular items this week",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(15),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.70,
            ),
            itemCount: trendingProductsWithIds.length,
            itemBuilder: (context, index) {
              Product product = trendingProductsWithIds[index].key;
              String productId = trendingProductsWithIds[index].value;
              int stock = _productStocks[product.name] ?? 0;

              return _buildTrendingCard(
                product,
                productId: productId,
                stock: stock,
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Product product, {String? productId, int? stock}) {
    bool isOutOfStock = stock != null && stock == 0;
    bool isInWishlist = productId != null && wishlistProductIds.contains(productId);

    double currentPrice = double.tryParse(product.price.replaceAll('\$', '')) ?? 0;
    double oldPriceValue = double.tryParse(product.oldPrice.replaceAll('\$', '')) ?? 0;
    int discountPercent = 0;

    if (oldPriceValue > currentPrice && currentPrice > 0) {
      discountPercent = (((oldPriceValue - currentPrice) / oldPriceValue) * 100).round();
    }

    return GestureDetector(
      onTap: () {
        if (productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Image.network(
                      product.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 130,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                ),
                if (!isOutOfStock)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "TRENDING",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "OUT OF STOCK",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                  ),
                if (discountPercent > 0 && !isOutOfStock)
                  Positioned(
                    top: 50,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                  ),
                if (productId != null && !isOutOfStock)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        _toggleWishlist(
                          productId,
                          product.name,
                          product.price,
                          product.imageUrl,
                          product.category,
                          stock: stock,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.pink : Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isOutOfStock ? Colors.grey : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isOutOfStock
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _loadingRates ? product.price : _convertAndFormatPrice(product.price),
                              style: TextStyle(
                                color: isOutOfStock ? Colors.grey : Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (discountPercent > 0) ...[
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _loadingRates ? product.oldPrice : _convertAndFormatPrice(product.oldPrice),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: isOutOfStock ? null : () async {
                        await _addToCart(product);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade300 : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock ? Icons.block : Icons.shopping_cart,
                              color: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              isOutOfStock ? "Out of Stock" : "Add to Cart",
                              style: TextStyle(
                                color: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // PROFILE TAB
  Widget _buildProfileTab() {
    User? user = _auth.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 20),
                if (user != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('orders')
                            .where('customerId', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatCard(count.toString(), "Orders");
                        },
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(user.uid)
                            .collection('wishlist')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatCard(count.toString(), "Wishlist");
                        },
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('reviews')
                            .where('customerId', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatCard(count.toString(), "Reviews");
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 15),
                _buildProfileOption(Icons.person_outline, "Edit Profile", Colors.blue, () {
                  Navigator.push(
                    context,
                    customPageRoute(EditProfileScreen()),
                  ).then((_) => _loadUserData());
                }),
                _buildProfileOption(Icons.shopping_bag_outlined, "My Orders", Colors.orange, () {
                  Navigator.push(
                    context,
                    customPageRoute(CustomerOrdersScreen()),
                  );
                }),
                _buildProfileOption(Icons.favorite_border, "Wishlist", Colors.red, () {
                  Navigator.push(
                    context,
                    customPageRoute(WishlistScreen()),
                  );
                }),
                _buildProfileOption(Icons.location_on_outlined, "Shipping Address", Colors.green, () {}),
                SizedBox(height: 20),
                Text(
                  "Support",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 15),
                _buildProfileOption(Icons.help_outline, "Help & Support", Colors.purple, () {}),
                _buildProfileOption(Icons.info_outline, "About Us", Colors.teal, () {}),
                _buildProfileOption(Icons.privacy_tip_outlined, "Privacy Policy", Colors.indigo, () {}),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "Logout",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}

// ============ EDIT PROFILE SCREEN ============
class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _newAddressController = TextEditingController();

  List<String> addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData =
        await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && mounted) {
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _emailController.text = userData['email'] ?? user.email ?? '';
            addresses = List<String>.from(userData['addresses'] ?? []);
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name and phone are required")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'addresses': addresses,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addAddress() {
    if (_newAddressController.text.isNotEmpty) {
      setState(() {
        addresses.add(_newAddressController.text.trim());
        _newAddressController.clear();
      });
    }
  }

  void _removeAddress(int index) {
    setState(() {
      addresses.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 15),
              _buildTextField("Name", Icons.person, _nameController),
              SizedBox(height: 15),
              _buildTextField(
                "Phone Number",
                Icons.phone,
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 15),
              _buildTextField(
                "Email",
                Icons.email,
                _emailController,
                enabled: false,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Addresses",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.deepPurple),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Add New Address"),
                          content: TextField(
                            controller: _newAddressController,
                            decoration: InputDecoration(
                              hintText: "Enter address",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _newAddressController.clear();
                              },
                              child: Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _addAddress();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: Text("Add"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (addresses.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "No addresses added yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...addresses.asMap().entries.map((entry) {
                  int index = entry.key;
                  String address = entry.value;
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.deepPurple),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeAddress(index),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        bool enabled = true,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}

// Add this new screen class after EditProfileScreen

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _removeFromWishlist(String productId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed from wishlist"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _checkAndNotifyRestock(String productId) async {
    try {
      DocumentSnapshot productDoc =
      await _firestore.collection('products').doc(productId).get();

      if (productDoc.exists) {
        int stock = productDoc['stock'] ?? 0;
        if (stock > 0) {
          // Product is back in stock
          return;
        }
      }
    } catch (e) {
      print('Error checking stock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "My Wishlist",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 80, color: Colors.red.shade300),
                  SizedBox(height: 20),
                  Text(
                    "Error loading wishlist",
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 20),
                  Text(
                    "Your Wishlist is Empty",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Add out-of-stock items to get notified",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var wishlistItem = snapshot.data!.docs[index];
              String productId = wishlistItem.id;
              String productName = wishlistItem['productName'] ?? 'Product';
              String price = wishlistItem['price'] ?? '\$0';
              String imageUrl = wishlistItem['imageUrl'] ?? '';
              String category = wishlistItem['category'] ?? 'Electronics';

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('products').doc(productId).get(),
                builder: (context, productSnapshot) {
                  bool isBackInStock = false;
                  int stock = 0;

                  if (productSnapshot.hasData && productSnapshot.data!.exists) {
                    stock = productSnapshot.data!['stock'] ?? 0;
                    isBackInStock = stock > 0;
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: isBackInStock
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (isBackInStock)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "BACK IN STOCK! 🎉",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(15)),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.image,
                                        color: Colors.grey.shade400),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          price,
                                          style: TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Spacer(),
                                        if (!isBackInStock)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "Out of Stock",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isBackInStock)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "Stock: $stock",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeFromWishlist(productId),
                            ),
                          ],
                        ),
                        if (isBackInStock)
                          Padding(
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to product or add to cart
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.shopping_cart, size: 18),
                                label: Text("Shop Now"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ============ SELLER STORE SCREEN ============
class SellerStoreScreen extends StatefulWidget {
  final String sellerId;
  final String shopName;

  SellerStoreScreen({required this.sellerId, required this.shopName});

  @override
  _SellerStoreScreenState createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String selectedCategory = "";
  List<CartItem> cartItems = [];
  List<String> wishlistProductIds = [];

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};
  bool _loadingRates = false;



  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    setState(() => _loadingRates = true);
    _selectedCurrency = await CurrencyService.getSelectedCurrency();
    _exchangeRates = await CurrencyService.getExchangeRates();
    setState(() => _loadingRates = false);
  }

  String _convertAndFormatPrice(String priceStr) {
    if (_exchangeRates.isEmpty) return priceStr;

    // Parse the USD price from string (remove $ and any commas)
    double usdPrice = double.tryParse(priceStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0;

    double convertedPrice = CurrencyService.convertPrice(usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  String _convertAndFormatPriceFromDouble(double usdPrice) {
    if (_exchangeRates.isEmpty) return '\$${usdPrice.toStringAsFixed(2)}';

    double convertedPrice = CurrencyService.convertPrice(usdPrice, 'USD', _selectedCurrency, _exchangeRates);
    return CurrencyService.formatPrice(convertedPrice, _selectedCurrency);
  }

  Future<void> _loadWishlist() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot wishlistSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      if (mounted) {
        setState(() {
          wishlistProductIds = wishlistSnapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _toggleWishlist(String productId, String productName, String price, String imageUrl, String category, {int? stock}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      return;
    }

    // CHECK IF PRODUCT IS OUT OF STOCK
    bool isOutOfStock = stock != null && stock == 0;
    if (!isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text("Only out of stock items can be added to wishlist"),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      DocumentReference wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId);

      DocumentSnapshot wishlistDoc = await wishlistRef.get();

      if (wishlistDoc.exists) {
        await wishlistRef.delete();
        setState(() {
          wishlistProductIds.remove(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from wishlist"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await wishlistRef.set({
          'productId': productId,
          'productName': productName,
          'price': price,
          'imageUrl': imageUrl,
          'category': category,
          'addedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          wishlistProductIds.add(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Added to wishlist! We'll notify you when it's back in stock."),
                ),
              ],
            ),
            backgroundColor: Colors.pink,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  Future<void> _loadCartItems() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      if (mounted) {
        setState(() {
          cartItems = cartSnapshot.docs.map((doc) {
            return CartItem(
              productName: doc['productName'],
              price: doc['price'],
              imageUrl: doc['imageUrl'],
              quantity: doc['quantity'],
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  int get cartItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _addToCart(Product product) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      return;
    }

    try {
      DocumentReference cartRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(product.name);

      DocumentSnapshot cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        int currentQty = cartDoc['quantity'] ?? 1;
        await cartRef.update({
          'quantity': currentQty + 1,
        });
      } else {
        await cartRef.set({
          'productName': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'quantity': 1,
          'category': product.category,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      await _loadCartItems();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${product.name} added to cart!",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add to cart"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.shopName,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, size: 26, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    customPageRoute(CartScreen()),
                  ).then((_) => _loadCartItems());
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      cartItemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 5),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('sellerId', isEqualTo: widget.sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('StreamBuilder Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  SizedBox(height: 20),
                  Text(
                    "Error loading products",
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 20),
                  Text(
                    "No Products Available",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "This store hasn't added any products yet",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Filter products with stock > 0
          List<DocumentSnapshot> allProducts = snapshot.data!.docs;
          List<DocumentSnapshot> productsInStock = allProducts.where((doc) {
            try {
              int stock = doc['stock'] ?? 0;
              return stock > 0;
            } catch (e) {
              print('Error reading stock for product ${doc.id}: $e');
              return false;
            }
          }).toList();

          // Get unique categories
          Set<String> categories = {};
          for (var doc in productsInStock) {
            try {
              String category = doc['category'] ?? 'Electronics';
              categories.add(category);
            } catch (e) {
              print('Error reading category for product ${doc.id}: $e');
            }
          }

          // Filter by selected category
          List<DocumentSnapshot> displayProducts = productsInStock;
          if (selectedCategory.isNotEmpty) {
            displayProducts = productsInStock.where((doc) {
              try {
                return doc['category'] == selectedCategory;
              } catch (e) {
                print('Error filtering product ${doc.id}: $e');
                return false;
              }
            }).toList();
          }

          return Column(
            children: [
              if (categories.length > 1) ...[
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    children: [
                      _buildCategoryChip("All", ""),
                      ...categories.map((cat) => _buildCategoryChip(cat, cat)),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: displayProducts.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off,
                          size: 60, color: Colors.grey.shade300),
                      SizedBox(height: 15),
                      Text(
                        selectedCategory.isNotEmpty
                            ? "No products in this category"
                            : "No products in stock",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                    : GridView.builder(
                  padding: EdgeInsets.all(15),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    try {
                      var doc = displayProducts[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                      String productId = doc.id;
                      int stock = data['stock'] ?? 0;

                      List<String> images = List<String>.from(data['images'] ?? []);
                      String imageUrl = images.isNotEmpty ? images[0] : '';

                      String priceStr = data['price'].toString().replaceAll('\$', '');
                      double originalPrice = double.tryParse(priceStr) ?? 0;
                      double discountPercent = (data['discountPercentage'] ?? 0.0).toDouble();

                      double discountedPrice = originalPrice * (1 - discountPercent / 100);
                      String displayPrice = '\$${discountedPrice.toStringAsFixed(2)}';
                      String oldPrice = '\$${originalPrice.toStringAsFixed(2)}';

                      Product product = Product(
                        name: data['name'] ?? 'Product',
                        price: displayPrice,
                        oldPrice: oldPrice,
                        imageUrl: imageUrl,
                        rating: (data['rating'] ?? 0.0).toDouble(),
                        category: data['category'] ?? 'Electronics',
                      );

                      return _buildProductCard(product, productId: productId, stock: stock);
                    } catch (e) {
                      print('Error building product card at index $index: $e');
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(Icons.error_outline, color: Colors.grey),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    bool isSelected = selectedCategory == value;
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = selected ? value : "";
          });
        },
        selectedColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, {String? productId, int? stock}) {
    bool isOutOfStock = stock != null && stock == 0;
    bool isInWishlist = productId != null && wishlistProductIds.contains(productId);

    double currentPrice = double.tryParse(product.price.replaceAll('\$', '')) ?? 0;
    double oldPriceValue = double.tryParse(product.oldPrice.replaceAll('\$', '')) ?? 0;
    int discountPercent = 0;

    if (oldPriceValue > currentPrice && currentPrice > 0) {
      discountPercent = (((oldPriceValue - currentPrice) / oldPriceValue) * 100).round();
    }

    return GestureDetector(
      onTap: () {
        if (productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Image.network(
                      product.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 130,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: productId != null ? () {
                      _toggleWishlist(
                        productId,
                        product.name,
                        product.price,
                        product.imageUrl,
                        product.category,
                        stock: stock,
                      );
                    } : null,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.pink : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (discountPercent > 0 && !isOutOfStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "OUT OF STOCK",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isOutOfStock ? Colors.grey : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 12),
                            SizedBox(width: 3),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isOutOfStock
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              product.price,
                              style: TextStyle(
                                color: isOutOfStock ? Colors.grey : Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (discountPercent > 0) ...[
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.oldPrice,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    InkWell(
                      onTap: isOutOfStock ? null : () async {
                        await _addToCart(product);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.grey.shade300
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.block
                                  : Icons.shopping_cart,
                              color: isOutOfStock
                                  ? Colors.grey.shade600
                                  : Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isOutOfStock ? "Out of Stock" : "Add to Cart",
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.grey.shade600
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Review {
  final String id;
  final String orderId;
  final String productId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      orderId: map['orderId'] ?? '',
      productId: map['productId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int _selectedImageIndex = 0;
  String? _selectedSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('products').doc(widget.productId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Product not found"));
          }

          var product = snapshot.data!;
          Map<String, dynamic> data = product.data() as Map<String, dynamic>;

          List<String> images = List<String>.from(data['images'] ?? []);
          List<String> sizes = List<String>.from(data['sizes'] ?? []);
          int stock = data['stock'] ?? 0;
          String priceStr = data['price'].toString().replaceAll('\$', '');
          double originalPrice = double.tryParse(priceStr) ?? 0;
          double discountPercent = (data['discountPercentage'] ?? 0.0).toDouble();
          double discountedPrice = originalPrice * (1 - discountPercent / 100);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Colors.deepPurple,
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.deepPurple),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        images.isNotEmpty ? images[_selectedImageIndex] : '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image, size: 100),
                          );
                        },
                      ),
                      if (discountPercent > 0)
                        Positioned(
                          top: 60,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${discountPercent.toInt()}% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image thumbnails
                    if (images.length > 1)
                      Container(
                        height: 80,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageIndex = index;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedImageIndex == index
                                        ? Colors.deepPurple
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Product info
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Product',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '\$${discountedPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              if (discountPercent > 0) ...[
                                SizedBox(width: 12),
                                Text(
                                  '\$${originalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              stock > 0 ? 'In Stock ($stock available)' : 'Out of Stock',
                              style: TextStyle(
                                color: stock > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Sizes
                          if (sizes.isNotEmpty) ...[
                            Text(
                              'Available Sizes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              children: sizes.map((size) {
                                bool isSelected = _selectedSize == size;
                                return ChoiceChip(
                                  label: Text(size),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSize = selected ? size : null;
                                    });
                                  },
                                  selectedColor: Colors.deepPurple,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 20),
                          ],

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            data['description'] ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 24),

                          // Reviews Section
                          _buildReviewsSection(widget.productId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildReviewsSection(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        List<Review> reviews = snapshot.data!.docs.map((doc) {
          return Review.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        double avgRating = 0;
        if (reviews.isNotEmpty) {
          avgRating = reviews.fold(0.0, (sum, review) => sum + review.rating) / reviews.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reviews.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (reviews.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewCard(review)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(
                  review.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('products').doc(widget.productId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        var product = snapshot.data!;
        Map<String, dynamic> data = product.data() as Map<String, dynamic>;

        int stock = data['stock'] ?? 0;
        bool isOutOfStock = stock == 0;

        List<String> images = List<String>.from(data['images'] ?? []);
        String priceStr = data['price'].toString().replaceAll('\$', '');
        double originalPrice = double.tryParse(priceStr) ?? 0;
        double discountPercent = (data['discountPercentage'] ?? 0.0).toDouble();
        double discountedPrice = originalPrice * (1 - discountPercent / 100);
        String displayPrice = '\$${discountedPrice.toStringAsFixed(2)}';
        String imageUrl = images.isNotEmpty ? images[0] : '';

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOutOfStock ? null : () async {
                    Product productToAdd = Product(
                      name: data['name'] ?? 'Product',
                      price: displayPrice,
                      oldPrice: data['price'] ?? '\$0',
                      imageUrl: imageUrl,
                      rating: (data['rating'] ?? 0.0).toDouble(),
                      category: data['category'] ?? 'Electronics',
                    );

                    User? user = _auth.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please login first")),
                      );
                      return;
                    }

                    try {
                      DocumentReference cartRef = _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('cart')
                          .doc(productToAdd.name);

                      DocumentSnapshot cartDoc = await cartRef.get();

                      if (cartDoc.exists) {
                        int currentQty = cartDoc['quantity'] ?? 1;
                        await cartRef.update({'quantity': currentQty + 1});
                      } else {
                        await cartRef.set({
                          'productName': productToAdd.name,
                          'price': productToAdd.price,
                          'imageUrl': productToAdd.imageUrl,
                          'quantity': 1,
                          'category': productToAdd.category,
                          'addedAt': FieldValue.serverTimestamp(),
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text("${productToAdd.name} added to cart!"),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to add to cart"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(isOutOfStock ? Icons.block : Icons.shopping_cart),
                  label: Text(isOutOfStock ? 'Out of Stock' : 'Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutOfStock ? Colors.grey : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}