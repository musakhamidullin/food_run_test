import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.url, required this.orderId});

  final String url;
  final int orderId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PaymentScreen')),
    );
  }
}
