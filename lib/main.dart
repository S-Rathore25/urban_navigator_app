import 'package:flutter/material.dart';
import 'package:urban_navigator_osm_app/screens/navigator_screen.dart'; // सुनिश्चित करें कि यह पथ सही है

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Urban Navigator (OSM)',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey,
          elevation: 1,
          centerTitle: true,
        ),
      ),
      home: NavigatorScreen(),
    );
  }
}
