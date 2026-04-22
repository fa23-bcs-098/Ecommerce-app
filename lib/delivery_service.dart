import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simulated delivery platforms (since real APIs require business accounts)
  static const List<Map<String, dynamic>> deliveryPartners = [
    {
      'name': 'TCS Express',
      'estimatedDays': '2-3 days',
      'cost': 200,
      'tracking': true,
    },
    {
      'name': 'Leopard Courier',
      'estimatedDays': '1-2 days',
      'cost': 250,
      'tracking': true,
    },
    {
      'name': 'M&P Express',
      'estimatedDays': '3-4 days',
      'cost': 150,
      'tracking': false,
    },
  ];

  // Create delivery request
  static Future<String?> createDeliveryRequest({
    required String orderId,
    required String deliveryPartner,
    required String pickupAddress,
    required String deliveryAddress,
    required String customerPhone,
    required String sellerPhone,
  }) async {
    try {
      // Generate tracking number
      String trackingNumber = 'DEL${DateTime.now().millisecondsSinceEpoch}';

      // Store delivery info
      await _firestore.collection('deliveries').doc(orderId).set({
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'deliveryPartner': deliveryPartner,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'customerPhone': customerPhone,
        'sellerPhone': sellerPhone,
        'status': 'pending_pickup',
        'createdAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          {
            'status': 'pending_pickup',
            'timestamp': DateTime.now().toIso8601String(),
            'description': 'Delivery request created',
          }
        ],
      });

      // Update order with tracking info
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryTrackingNumber': trackingNumber,
        'deliveryPartner': deliveryPartner,
        'deliveryStatus': 'pending_pickup',
      });

      return trackingNumber;
    } catch (e) {
      print('Error creating delivery request: $e');
      return null;
    }
  }

  // Update delivery status
  static Future<void> updateDeliveryStatus({
    required String orderId,
    required String status,
    String? description,
  }) async {
    try {
      Map<String, dynamic> statusEntry = {
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'description': description ?? _getStatusDescription(status),
      };

      await _firestore.collection('deliveries').doc(orderId).update({
        'status': status,
        'statusHistory': FieldValue.arrayUnion([statusEntry]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('orders').doc(orderId).update({
        'deliveryStatus': status,
      });
    } catch (e) {
      print('Error updating delivery status: $e');
    }
  }

  static String _getStatusDescription(String status) {
    switch (status) {
      case 'pending_pickup':
        return 'Waiting for pickup';
      case 'picked_up':
        return 'Package picked up by courier';
      case 'in_transit':
        return 'Package in transit';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Package delivered';
      case 'failed':
        return 'Delivery attempt failed';
      default:
        return 'Status updated';
    }
  }

  // Calculate delivery cost based on distance
  static double calculateDeliveryCost(double distanceKm, String partner) {
    var partnerData = deliveryPartners.firstWhere(
          (p) => p['name'] == partner,
      orElse: () => deliveryPartners[0],
    );

    double baseCost = (partnerData['cost'] as int).toDouble();

    // Add extra cost for longer distances
    if (distanceKm > 50) {
      baseCost += (distanceKm - 50) * 3;
    }

    return baseCost;
  }
}