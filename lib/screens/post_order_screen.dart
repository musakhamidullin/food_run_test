import 'package:flutter/material.dart';
import 'package:food_run/models/order.dart';

class PostOrderScreen extends StatelessWidget {
  const PostOrderScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PostOrderScreen')),
    );
  }
}
