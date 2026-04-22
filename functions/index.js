const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure your email service (Gmail example)
// IMPORTANT: Use App Password, not your regular Gmail password
// Generate App Password: https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'shopeasy.notification@gmail.com', // Replace with your Gmail
    pass: 'uxhz ownt iylt ddud'      // Replace with Gmail App Password
  }
});

// Function 1: Send Order Confirmation Email
exports.sendOrderConfirmationEmail = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    
    // Only send email for new orders (status: pending)
    if (order.status !== 'pending') return null;
    
    const customerEmail = order.customerEmail;
    if (!customerEmail) {
      console.log('No customer email found');
      return null;
    }

    const mailOptions = {
      from: 'ShopEasy <shopeasy.notification@gmail.com>',
      to: customerEmail,
      subject: '🎉 Order Confirmation - ShopEasy',
      html: `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; }
    .order-box { background: #f0f0f0; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #667eea; }
    .total { font-size: 24px; color: #667eea; font-weight: bold; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Order Confirmed!</h1>
      <p>Thank you for shopping with ShopEasy</p>
    </div>
    
    <div class="content">
      <p>Hi <strong>${order.customerName}</strong>,</p>
      <p>Your order has been received and is being processed.</p>
      
      <div class="order-box">
        <h3>📦 Order Details</h3>
        <p><strong>Order ID:</strong> ${orderId}</p>
        <p><strong>Tracking ID:</strong> ${order.trackingId}</p>
        <p><strong>Product:</strong> ${order.productName}</p>
        <p><strong>Quantity:</strong> ${order.quantity}</p>
        <p><strong>Price:</strong> ${order.price}</p>
      </div>
      
      <div class="order-box">
        <h3>📍 Delivery Address</h3>
        <p><strong>${order.customerName}</strong></p>
        <p>${order.customerAddress}</p>
        <p>Phone: ${order.customerPhone}</p>
      </div>
      
      <div class="footer">
        <p>Questions? Contact us at support@shopeasy.com</p>
        <p>© 2025 ShopEasy. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
      `
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('✅ Order confirmation email sent to:', customerEmail);
      return null;
    } catch (error) {
      console.error('❌ Error sending order email:', error);
      return null;
    }
  });

// Function 2: Send Delivery Confirmation Email
exports.sendDeliveryConfirmationEmail = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newOrder = change.after.data();
    const previousOrder = change.before.data();
    const orderId = context.params.orderId;
    
    // Only send email when status changes to 'delivered'
    if (newOrder.status === 'delivered' && previousOrder.status !== 'delivered') {
      const customerEmail = newOrder.customerEmail;
      
      if (!customerEmail) {
        console.log('No customer email found');
        return null;
      }

      const mailOptions = {
        from: 'ShopEasy <mshopeasy.notification@gmail.com>',
        to: customerEmail,
        subject: '✅ Your Order Has Been Delivered! - ShopEasy',
        html: `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; }
    .header { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; }
    .delivery-box { background: #f0f0f0; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #38ef7d; }
    .success-icon { font-size: 60px; text-align: center; margin: 20px 0; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="success-icon">📦✅</div>
      <h1>Delivered Successfully!</h1>
      <p>Your order has arrived</p>
    </div>
    
    <div class="content">
      <p>Hi <strong>${newOrder.customerName}</strong>,</p>
      <p>Great news! Your order has been successfully delivered.</p>
      
      <div class="delivery-box">
        <h3>📦 Delivery Details</h3>
        <p><strong>Order ID:</strong> ${orderId}</p>
        <p><strong>Tracking ID:</strong> ${newOrder.trackingId}</p>
        <p><strong>Product:</strong> ${newOrder.productName}</p>
        <p><strong>Quantity:</strong> ${newOrder.quantity}</p>
      </div>
      
      <div class="delivery-box">
        <h3>⭐ Rate Your Experience</h3>
        <p>We hope you love your purchase! Please rate your experience in the app.</p>
      </div>
      
      <center>
        <p style="margin: 30px 0;">Thank you for shopping with ShopEasy!</p>
      </center>
      
      <div class="footer">
        <p>Need help? Contact us at support@shopeasy.com</p>
        <p>© 2025 ShopEasy. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
        `
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log('✅ Delivery confirmation email sent to:', customerEmail);
        return null;
      } catch (error) {
        console.error('❌ Error sending delivery email:', error);
        return null;
      }
    }
    
    return null;
  });