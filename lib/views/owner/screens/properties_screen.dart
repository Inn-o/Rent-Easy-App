import 'package:flutter/material.dart';

class PropertiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F2),
      appBar: AppBar(
        title: Text('Properties'),
        backgroundColor: Color(0xFF22577A),
      ),
      body: Center(child: Text('Properties list will appear here.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFFFB3640),
        child: Icon(Icons.add),
      ),
    );
  }
}
