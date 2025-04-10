
import 'package:flutter/material.dart';

enum SnackBarType { error, warning, info, success }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required Duration duration,
    SnackBarType type = SnackBarType.info,
  }) {
    final config = _getStyleByType(type);
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AnimatedSnackBarOverlay(
        message: message,
        config: config,
        duration: duration,
        onClose: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  static Map<String, dynamic> _getStyleByType(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return {
          'icon':              Icons.report_rounded,
          'iconColor':       Colors.white,
          'backgroundColor': Colors.red.shade700.withValues(alpha: 0.9),
          'textColor':       Colors.white,
        };
      case SnackBarType.warning:
        return {
          'icon':              Icons.warning,
          'iconColor':       Colors.black,
          'backgroundColor': Colors.amber.shade300.withValues(alpha: 0.9),
          'textColor':       Colors.black,
        };
      case SnackBarType.success:
        return {
          'icon':              Icons.check_circle,
          'iconColor':       Colors.white,
          'backgroundColor': Colors.green.shade600.withValues(alpha: 0.9),
          'textColor':       Colors.white,
        };
      case SnackBarType.info:
      default:
        return {
          'icon':              Icons.info,
          'iconColor':       Colors.white,
          'backgroundColor': Colors.blueAccent.shade700.withValues(alpha: 0.9),
          'textColor':       Colors.white,
        };
    }
  }
}

class _AnimatedSnackBarOverlay extends StatefulWidget {
  final String message;
  final Map<String, dynamic> config;
  final Duration duration;
  final VoidCallback onClose;

  const _AnimatedSnackBarOverlay({
    Key? key,
    required this.message,
    required this.config,
    required this.duration,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_AnimatedSnackBarOverlay> createState() => _AnimatedSnackBarOverlayState();
}

class _AnimatedSnackBarOverlayState extends State<_AnimatedSnackBarOverlay> {
  Offset offset = const Offset(0, 1);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        offset = const Offset(0, 0);
      });
    });

    Future.delayed(widget.duration, () {
      setState(() {
        offset = const Offset(0, 1);
      });
      Future.delayed(const Duration(milliseconds: 300), widget.onClose);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0.5,
      left: 8,
      right: 8,
      child: AnimatedSlide(
        offset: offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.config['backgroundColor'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.25 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(widget.config['icon'], color: widget.config['iconColor'], size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150), // altura interna máxima rolável
                    child: SingleChildScrollView(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.config['textColor'],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: widget.config['textColor']),
                  onPressed: () {
                    setState(() {
                      offset = const Offset(0, 1);
                    });
                    Future.delayed(const Duration(milliseconds: 300), widget.onClose);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}