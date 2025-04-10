import 'package:flutter/material.dart';

class ButtonStyles {

  static ButtonStyle blackButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            final baseColor = Colors.cyanAccent;
            return baseColor.withValues(
              red: baseColor.r.toDouble(),
              green: baseColor.g.toDouble(),
              blue: baseColor.b.toDouble(),
              alpha: (255 * 0.4).toDouble(),
            );
          }
          return null;
        },
      ),
    );
  }

  static ButtonStyle outlinedBlackButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide.none,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            final baseColor = Colors.cyanAccent;
            return baseColor.withValues(
              red: baseColor.r.toDouble(),
              green: baseColor.g.toDouble(),
              blue: baseColor.b.toDouble(),
              alpha: (255 * 0.4).toDouble(),
            );
          }
          return null;
        },
      ),
    );
  }


  /*static ButtonStyle processButton(int _tamanho) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            final baseColor = Colors.cyanAccent;
            return baseColor.withValues(
              red: baseColor.r.toDouble(),
              green: baseColor.g.toDouble(),
              blue: baseColor.b.toDouble(),
              alpha: (255 * 0.4).toDouble(),
            );
          }
          return null;
        },
      ),
    );
  }*/

  static ButtonStyle processButton(BuildContext context, int _tamanho) {
    double largura = MediaQuery.of(context).size.width;

    if (_tamanho == 2) {
      largura *= 0.5;
    } else if (_tamanho == 3) {
      largura *= 0.25;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      minimumSize: Size(largura, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            final baseColor = Colors.cyanAccent;
            return baseColor.withValues(
              red: baseColor.r.toDouble(),
              green: baseColor.g.toDouble(),
              blue: baseColor.b.toDouble(),
              alpha: (255 * 0.4).toDouble(),
            );
          }
          return null;
        },
      ),
    );
  }

}
