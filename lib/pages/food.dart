import 'package:flutter/material.dart';

class FoodDialog extends StatefulWidget {
  const FoodDialog({super.key});

  @override
  State<FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<FoodDialog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 300,
          height: 300,
          color: Colors.red,
          child: const Center(
            child: Text(
              'Food Dialog',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
