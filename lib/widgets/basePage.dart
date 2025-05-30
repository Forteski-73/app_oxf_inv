import 'package:flutter/material.dart';
import 'package:app_oxf_inv/widgets/footer.dart';
import 'package:app_oxf_inv/widgets/customAppBar.dart';

class BasePage extends StatefulWidget {
  final Widget body;
  final String title;
  final String subtitle;
  final Widget? floatingButtons;

  const BasePage({
    super.key,
    required this.body,
    required this.title,
    required this.subtitle,
    this.floatingButtons,
  });

  @override
  State<BasePage> createState() => _BasePageState();

  /// Método estático para exibir o diálogo de confirmação
  static Future<bool> confirmAlert(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Cancelar
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // SIM
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SIM',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class _BasePageState extends State<BasePage> with TickerProviderStateMixin {
  bool _mostrarFloatingButtons = true;

  void _handleSwipe(DragUpdateDetails details) {
    if (details.delta.dy < -5 && !_mostrarFloatingButtons) {
      setState(() => _mostrarFloatingButtons = true);
    } else if (details.delta.dy > 5 && _mostrarFloatingButtons) {
      setState(() => _mostrarFloatingButtons = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title.isNotEmpty ? widget.title : "Aplicativo de Consulta de Estrutura de Produtos. ACEP",
        subtitle: widget.subtitle,
      ),
      body: Stack(
        children: [
          // Conteúdo do corpo que ficará atrás dos botões
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: widget.body,
            ),
          ),
          
          // Botões flutuantes, logo acima do Footer
          if (widget.floatingButtons != null)
            Positioned(
              bottom: 0,
              left: 2,
              right: 2,
              child: GestureDetector(
                onVerticalDragUpdate: _handleSwipe,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  offset: _mostrarFloatingButtons
                      ? Offset.zero
                      : const Offset(0, 1), // move para baixo quando oculto
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _mostrarFloatingButtons ? 1.0 : 0.0,
                    child: Container(
                      //color: Colors.black.withAlpha((0.15 * 255).round()),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: widget.floatingButtons!,
                    ),
                  ),
                ),
              ),
            ),
            
          // Ícone de seta aparece só quando os botões estão escondidos
          if (!_mostrarFloatingButtons) //widget.floatingButtons != null && 
            Positioned(
              bottom: 0,
              left: 2,
              right: 2,
              child: GestureDetector(
                onVerticalDragUpdate: _handleSwipe, // Permite o arrasto
                onTap: () {
                  setState(() {
                    _mostrarFloatingButtons = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 35,
                  color: Colors.black.withAlpha((0.15 * 255).round()),
                  child: const Center(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 38,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:app_oxf_inv/widgets/footer.dart';
import 'package:app_oxf_inv/widgets/customAppBar.dart';
import 'package:app_oxf_inv/styles/btnStyles.dart';

class BasePage extends StatelessWidget {
  final Widget body;
  final String title;
  final String subtitle;
  final Widget? floatingButtons; 

  const BasePage({
    super.key,
    required this.body,
    required this.title,
    required this.subtitle,
    this.floatingButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title, subtitle: subtitle),
      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: body,
          ),

          if (floatingButtons != null)
            Positioned(
              bottom: 50,
              left: 16,
              right: 16,
              child: floatingButtons!,
            ),

        ],
      ),

      bottomNavigationBar: const Footer(),

    );
  }
}
*/