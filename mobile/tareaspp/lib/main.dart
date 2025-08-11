import 'package:flutter/material.dart';
import 'package:tareaspp/tareas.dart';
import 'inicio.dart';
import 'registro.dart'; // por convención el nombre del archivo en minúsculas

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      initialRoute: '/login', // empieza desde la pantalla de inicio
      routes: {
        '/login': (context) => const Inicio(),
        '/register': (context) => const Registro(),
        '/welcome': (context) => const Tareas(),
      },
    );
  }
}

