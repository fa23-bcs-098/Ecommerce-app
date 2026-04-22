import 'package:emailjs/emailjs.dart' as emailjs;
import 'dart:math';

class EmailService {
  // ⚠️ REPLACE THESE WITH YOUR ACTUAL VALUES
  static const String _serviceId = 'service_95x0njg';
  static const String _publicKey = 'gKr55noTO_tR3qHry';
  static const String _universalTemplateId = 'template_av7mm1s'; // Only ONE template needed!

  // Generate OTP
  static String generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Base method to send email
  static Future<bool> _sendEmail(Map<String, dynamic> params) async {
    try {
      await emailjs.send(
        _serviceId,
        _universalTemplateId,
        params,
        emailjs.Options(
          publicKey: _publicKey,
        ),
      );
      return true;
    } catch (e) {
      print('❌ Email sending failed: $e');
      return false;
    }
  }

  static Future<String?> sendPasswordResetOTP(String email, String userName) async {
    String otp = generateOTP();

    bool success = await _sendEmail({
      'to_email': email,
      'email_subject': '🔐 Password Reset - OTP Code',
      'email_title': 'Password Reset Request',
      'email_subtitle': 'Secure verification code',
      'email_icon': '🔐',
      'header_class': 'warning',
      'customer_name': userName,
      'main_message': 'We received a request to reset your password. Use the OTP code below to proceed:',
      'show_otp': 'yes',
      'otp_code': otp,
      'show_tracking': 'no',
      'tracking_id': '',
      'show_order_details': 'no',
      'product_name': '',
      'quantity': '',
      'price': '',
      'total_amount': '',
      'order_status': '',
      'status_class': '',
      'show_address': 'no',
      'delivery_address': '',
      'customer_phone': '',
      'show_success_icon': 'no',
      'success_message': '',
      'delivery_date': '',
      'additional_message': '',
      'custom_content': '',
      'closing_message': 'If you didn\'t request this, please ignore this email and your password will remain unchanged.',
    });

    return success ? otp : null;
  }

  // 2️⃣ Send Order Confirmation Email
  static Future<bool> sendOrderConfirmation({
    required String email,
    required String customerName,
    required String trackingId,
    required String productName,
    required String quantity,
    required String price,
    required String totalAmount,
    required String deliveryAddress,
    required String customerPhone,
  }) async {
    return await _sendEmail({
      'to_email': email,
      'email_subject': '🎉 Order Confirmed - $trackingId',
      'email_title': 'Order Confirmed!',
      'email_subtitle': 'Thank you for shopping with ShopEasy',
      'email_icon': '🎉',
      'header_class': '',
      'customer_name': customerName,
      'main_message': 'Your order has been successfully placed and is being processed.',
      'show_otp': '',
      'show_tracking': 'true',
      'tracking_id': trackingId,
      'show_order_details': 'true',
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total_amount': totalAmount,
      'order_status': 'Pending',
      'status_class': 'status-pending',
      'show_address': 'true',
      'delivery_address': deliveryAddress,
      'customer_phone': customerPhone,
      'show_success_icon': '',
      'additional_message': '💡 Track your order: You can track your order status anytime in the "My Orders" section of the ShopEasy app.',
      'custom_content': '',
      'closing_message': 'We\'ll send you updates as your order progresses.',
    });
  }

  // 3️⃣ Send Delivery Confirmation Email
  static Future<bool> sendDeliveryConfirmation({
    required String email,
    required String customerName,
    required String trackingId,
    required String productName,
    required String quantity,
    required String price,
    required String deliveryDate,
  }) async {
    return await _sendEmail({
      'to_email': email,
      'email_subject': '✅ Your Order Has Been Delivered!',
      'email_title': 'Delivered Successfully!',
      'email_subtitle': 'Your package has arrived',
      'email_icon': '✅',
      'header_class': 'success',
      'customer_name': customerName,
      'main_message': 'Great news! Your order has been successfully delivered.',
      'show_otp': '',
      'show_tracking': 'true',
      'tracking_id': trackingId,
      'show_order_details': 'true',
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total_amount': price,
      'order_status': 'Delivered',
      'status_class': 'status-delivered',
      'show_address': '',
      'show_success_icon': 'true',
      'success_message': 'Package Delivered Successfully!',
      'delivery_date': deliveryDate,
      'additional_message': '⭐ Rate Your Experience: Your feedback helps us improve! Please rate your order in the app.',
      'custom_content': '',
      'closing_message': 'We hope you love your purchase! Thank you for choosing ShopEasy.',
    });
  }

  // 4️⃣ Send Restock Notification
  static Future<bool> sendRestockNotification({
    required String email,
    required String userName,
    required String productName,
    required String price,
    required int stock,
  }) async {
    return await _sendEmail({
      'to_email': email,
      'email_subject': '🎉 $productName is Back in Stock!',
      'email_title': 'Good News!',
      'email_subtitle': 'Your Wishlist Item is Available',
      'email_icon': '🎉',
      'header_class': 'success',
      'customer_name': userName,
      'main_message': 'Great news! The product you\'ve been waiting for is now back in stock:',
      'show_otp': '',
      'show_tracking': '',
      'show_order_details': 'true',
      'product_name': productName,
      'quantity': '',
      'price': price,
      'total_amount': '',
      'order_status': 'In Stock - $stock available',
      'status_class': 'status-delivered',
      'show_address': '',
      'show_success_icon': '',
      'additional_message': '⚠️ Don\'t miss out! This product might go out of stock again soon. Open the ShopEasy app to order now.',
      'custom_content': '',
      'closing_message': 'Happy shopping!',
    });
  }

  // 5️⃣ Send Custom Email (For any other purpose)
  static Future<bool> sendCustomEmail({
    required String email,
    required String customerName,
    required String subject,
    required String title,
    required String message,
    String? customHTML,
  }) async {
    return await _sendEmail({
      'to_email': email,
      'email_subject': subject,
      'email_title': title,
      'email_subtitle': '',
      'email_icon': '📧',
      'header_class': '',
      'customer_name': customerName,
      'main_message': message,
      'show_otp': '',
      'show_tracking': '',
      'show_order_details': '',
      'show_address': '',
      'show_success_icon': '',
      'additional_message': '',
      'custom_content': customHTML ?? '',
      'closing_message': 'Thank you for being a valued customer.',
    });
  }
}