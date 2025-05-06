import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: ExpandableNestedCards()));

class ExpandableNestedCards extends StatefulWidget {
  @override
  _ExpandableNestedCardsState createState() => _ExpandableNestedCardsState();
}

class _ExpandableNestedCardsState extends State<ExpandableNestedCards> with TickerProviderStateMixin {
  List<bool> _expanded = List.generate(5, (_) => false);
  List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (_) => AnimationController(vsync: this, duration: Duration(milliseconds: 300)),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleExpand(int index) {
    setState(() {
      _expanded[index] = !_expanded[index];
      if (_expanded[index]) {
        _controllers[index].forward();
      } else {
        _controllers[index].reverse();
      }
    });
  }

  Widget _buildChildCard(String title, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          color: Colors.blue.shade50,
          child: ListTile(
            title: Text(title),
            leading: Icon(Icons.subdirectory_arrow_right),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cards com Filhos Animados")),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _expanded.length,
        itemBuilder: (context, index) {
          final animation = CurvedAnimation(
            parent: _controllers[index],
            curve: Curves.easeInOut,
          );

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  ListTile(
                    title: Text('Item ${index + 1}'),
                    trailing: Icon(
                      _expanded[index] ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () => _toggleExpand(index),
                  ),
                  if (_expanded[index])
                    Column(
                      children: List.generate(
                        3,
                        (childIndex) => _buildChildCard('Detalhe ${childIndex + 1}', animation),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
