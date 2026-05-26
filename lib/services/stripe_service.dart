import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class StripeService {
  // Your Cloud Functions base URL
  // Replace with your actual deployed Cloud Functions URL
  static const String _functionsBaseUrl =
      'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net';

  /// Creates a Stripe PaymentIntent via Cloud Functions and confirms the payment
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String orderId,
  }) async {
    // 1. Get Firebase ID token for auth
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    // 2. Create payment intent on server
    final intentResponse = await http.post(
      Uri.parse('$_functionsBaseUrl/createPaymentIntent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'amount': (amount * 100).toInt(), // Stripe uses cents
        'currency': currency,
        'orderId': orderId,
      }),
    );

    if (intentResponse.statusCode != 200) {
      throw Exception('Failed to create payment intent');
    }

    final intentData = jsonDecode(intentResponse.body);
    final clientSecret = intentData['clientSecret'] as String;
    final paymentIntentId = intentData['paymentIntentId'] as String;

    // 3. Present payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ShopWave',
        style: ThemeMode.dark,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF6C63FF),
            background: Color(0xFF131318),
            componentBackground: Color(0xFF1C1C24),
            componentText: Color(0xFFF0EFF8),
            primaryText: Color(0xFFF0EFF8),
            secondaryText: Color(0xFF9994B8),
          ),
          shapes: PaymentSheetShape(
            borderRadius: 16,
          ),
        ),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          testEnv: true,
        ),
        applePay: const PaymentSheetApplePay(
          merchantCountryCode: 'US',
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    return paymentIntentId;
  }

  /// Add a payment method for future use
  Future<String> savePaymentMethod() async {
    final result = await Stripe.instance.createPaymentMethod(
      params: const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
    return result.id;
  }

  /// Get saved payment methods
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return [];

    final response = await http.get(
      Uri.parse('$_functionsBaseUrl/getPaymentMethods'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []);
  }
}
