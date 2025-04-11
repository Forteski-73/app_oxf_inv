import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Oxford Porcelanas",
            style: TextStyle(fontSize: 14),
          ),
          Text(
            "Versão: 1.0",
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
