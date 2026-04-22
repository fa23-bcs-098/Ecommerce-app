import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final String orderId;
  final bool isSeller;

  OrderTrackingMapScreen({
    required this.orderId,
    this.isSeller = false,
  });

  @override
  _OrderTrackingMapScreenState createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _orderStream;

  LatLng? _customerLocation;
  LatLng? _deliveryPersonLocation;
  LatLng? _currentUserLocation;
  String _orderStatus = 'pending';
  String _estimatedTime = 'Calculating...';
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _orderStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      // Get order details
      DocumentSnapshot orderDoc =
      await _firestore.collection('orders').doc(widget.orderId).get();

      if (!orderDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order not found')),
          );
        }
        return;
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;

      setState(() {
        _orderStatus = orderData['status'] ?? 'pending';

        if (orderData['customerLat'] != null && orderData['customerLng'] != null) {
          _customerLocation = LatLng(
            (orderData['customerLat'] as num).toDouble(),
            (orderData['customerLng'] as num).toDouble(),
          );
        }

        if (orderData['deliveryPersonLat'] != null &&
            orderData['deliveryPersonLng'] != null) {
          _deliveryPersonLocation = LatLng(
            (orderData['deliveryPersonLat'] as num).toDouble(),
            (orderData['deliveryPersonLng'] as num).toDouble(),
          );
        }
      });

      // Listen to order updates
      _orderStream = _firestore
          .collection('orders')
          .doc(widget.orderId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _orderStatus = data['status'] ?? 'pending';

              if (data['deliveryPersonLat'] != null &&
                  data['deliveryPersonLng'] != null) {
                _deliveryPersonLocation = LatLng(
                  (data['deliveryPersonLat'] as num).toDouble(),
                  (data['deliveryPersonLng'] as num).toDouble(),
                );
              }
            });
            _updateMarkersAndRoute();
          }
        }
      });

      // If seller, track their location
      if (widget.isSeller && _orderStatus == 'shipped') {
        _startLocationTracking();
      }

      _updateMarkersAndRoute();
    } catch (e) {
      print('Error initializing tracking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tracking data')),
        );
      }
    }
  }

  void _startLocationTracking() async {
    bool hasPermission = await LocationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
          _deliveryPersonLocation = _currentUserLocation;
        });
      }

      _firestore.collection('orders').doc(widget.orderId).update({
        'deliveryPersonLat': position.latitude,
        'deliveryPersonLng': position.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      }).catchError((error) {
        print('Error updating location: $error');
      });

      _updateMarkersAndRoute();
    });
  }

  void _updateMarkersAndRoute() {
    Set<Marker> markers = {};

    if (_customerLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('customer'),
          position: _customerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: 'Customer Address',
          ),
        ),
      );
    }

    if (_deliveryPersonLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('delivery_person'),
          position: _deliveryPersonLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Delivery Person',
            snippet: _orderStatus == 'shipped' ? 'On the way' : 'Preparing',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    if (_customerLocation != null && _deliveryPersonLocation != null) {
      _calculateDistanceAndTime();
      _drawRoute();
      _animateToFitMarkers();
    }
  }

  void _calculateDistanceAndTime() {
    if (_customerLocation == null || _deliveryPersonLocation == null) return;

    double distance = LocationService.calculateDistance(
      _deliveryPersonLocation!.latitude,
      _deliveryPersonLocation!.longitude,
      _customerLocation!.latitude,
      _customerLocation!.longitude,
    );

    double estimatedMinutes = (distance / 30) * 60;

    if (mounted) {
      setState(() {
        _distance = distance;
        _estimatedTime = estimatedMinutes < 60
            ? '${estimatedMinutes.toInt()} mins'
            : '${(estimatedMinutes / 60).toStringAsFixed(1)} hours';
      });
    }
  }

  void _drawRoute() {
    if (_customerLocation == null || _deliveryPersonLocation == null) return;

    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: [_deliveryPersonLocation!, _customerLocation!],
            color: Colors.blue,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });
    }
  }

  Future<void> _animateToFitMarkers() async {
    if (_customerLocation == null || _deliveryPersonLocation == null) return;

    try {
      final GoogleMapController controller = await _controller.future;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _customerLocation!.latitude < _deliveryPersonLocation!.latitude
              ? _customerLocation!.latitude
              : _deliveryPersonLocation!.latitude,
          _customerLocation!.longitude < _deliveryPersonLocation!.longitude
              ? _customerLocation!.longitude
              : _deliveryPersonLocation!.longitude,
        ),
        northeast: LatLng(
          _customerLocation!.latitude > _deliveryPersonLocation!.latitude
              ? _customerLocation!.latitude
              : _deliveryPersonLocation!.latitude,
          _customerLocation!.longitude > _deliveryPersonLocation!.longitude
              ? _customerLocation!.longitude
              : _deliveryPersonLocation!.longitude,
        ),
      );

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } catch (e) {
      print('Error animating camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          _customerLocation == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading map...'),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _customerLocation!,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _animateToFitMarkers();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _orderStatus == 'shipped'
                                    ? 'Order on the way'
                                    : 'Preparing your order',
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
                    if (_orderStatus == 'shipped' &&
                        _deliveryPersonLocation != null) ...[
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            Icons.route,
                            '${_distance.toStringAsFixed(1)} km',
                            'Distance',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildInfoItem(
                            Icons.access_time,
                            _estimatedTime,
                            'Est. Time',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Start Tracking Button (for sellers when order is shipped)
          if (widget.isSeller &&
              _orderStatus == 'shipped' &&
              _positionStream == null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _startLocationTracking,
                icon: Icon(Icons.navigation),
                label: Text('Start Live Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_orderStatus) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_orderStatus) {
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (_orderStatus) {
      case 'pending':
        return 'Order Pending';
      case 'processing':
        return 'Processing Order';
      case 'shipped':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Unknown Status';
    }
  }
}