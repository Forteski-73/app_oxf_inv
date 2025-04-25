import 'package:flutter/material.dart';

class CustomButton {

  static ButtonStyle defaultButton() {
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


  static Widget processButton(
    BuildContext context,
    String texto,
    int tamanho,
    IconData? icone,
    VoidCallback? onPressed,
    Color? cor,
    {
      Widget? childCustom, // Novo parâmetro opcional
    }) 
    {
    double largura = MediaQuery.of(context).size.width;
    String textoFormatado = texto;

    // Definir largura com base no tamanho
    if (tamanho == 2) {
      largura *= 0.5;
    } else if (tamanho == 3) {
      largura *= 0.25;
      final int limiteCaracteres = icone != null ? 4 : 6;
      textoFormatado = texto.length > limiteCaracteres ? '${texto.substring(0, limiteCaracteres)}' : texto;
    }

    // Estilo base do botão
    final ButtonStyle estilo = defaultButton().copyWith(
      minimumSize: WidgetStateProperty.all(Size(largura, 50)),
      backgroundColor: cor != null ? WidgetStateProperty.all(cor) : null,
    );

    return ElevatedButton(
      style: estilo,
      onPressed: onPressed,
      child: childCustom ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(icone, color: Colors.white, size: 28),
                const SizedBox(width: 5),
              ],
              Text(
                textoFormatado,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
    );
  }


/*
  static Widget processButton(
    BuildContext context,
    String texto,
    int tamanho,
    IconData? icone,
    VoidCallback onPressed,
    Color? cor, // Alterando para Colors? como parâmetro
  ) {
    double largura = MediaQuery.of(context).size.width;
    String textoFormatado = texto;

    cor ??= Colors.blue;

    if (tamanho == 2) {
      largura *= 0.5;
    } else if (tamanho == 3) {
      largura *= 0.25;
      final int limiteCaracteres = icone != null ? 4 : 6;
      textoFormatado = texto.length > limiteCaracteres ? '${texto.substring(0, limiteCaracteres)}' : texto;
    }

    final ButtonStyle estilo = ElevatedButton.styleFrom(
      backgroundColor: cor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
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

    return ElevatedButton(
      style: estilo,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, color: Colors.white, size: 28),
            const SizedBox(width: 5),
          ],
          Text(
            textoFormatado,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
*/
}