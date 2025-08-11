import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://apigestortareas-production.up.railway.app'; // se puede usar en simulador o dispositivo de eso depende la url

  Future<List<dynamic>> getTasks() async {
    final res = await http.get(Uri.parse('$baseUrl/tasks'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al obtener tareas');
    }
  }
}
