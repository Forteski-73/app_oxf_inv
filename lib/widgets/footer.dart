import 'package:flutter/material.dart';
import 'package:app_oxf_inv/main.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Oxford Porcelanas",
            style: TextStyle(fontSize: 14),
          ),
          ValueListenableBuilder<String>(
            valueListenable: appVersion,
            builder: (context, appVersionValue, child) {
              return Text(
                'Versão $appVersionValue',
                style: const TextStyle(fontSize: 14),
              );
            },
          ),
        ],
      ),
    );
  }
}
