import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tareaspp/inicio.dart';

const String baseUrl = 'https://apigestortareas-production.up.railway.app';

void showMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class Tareas extends StatelessWidget {
  const Tareas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestor de Tareas',
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const TaskList(),
        '/login': (context) => const Inicio(),
       
      },
    );
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  bool completed; // Nuevo

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.completed = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        completed: json['completed'] ?? false, 
      );
}


class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<Task> tasks = [];
  bool isLoading = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token == null) {
      if (mounted) showMessage(context, 'No se encontró el token. Inicia sesión');// solo funciona si el usuario tiene el token activo de lo contrario debe iniciar sesion 
      return;
    }
    await fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final List jsonList = jsonDecode(res.body);
        setState(() {
          tasks = jsonList.map((e) => Task.fromJson(e)).toList();
        });
      } else {
        if (mounted) showMessage(context, 'Error al cargar: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Error de conexión: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> deleteTask(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          tasks.removeWhere((t) => t.id == id);
        });
        showMessage(context, 'Tarea eliminada');
      } else {
        if (mounted) showMessage(context, 'Error al eliminar: ${res.body}');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Error: $e');
    }
  }

  void goToForm({Task? task}) async {
    if (token == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskForm(task: task, token: token!),
      ),
    );
    if (updated == true) fetchTasks();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Elimina el token
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login'); }
  }

  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('No hay tareas'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return ListTile(
  leading: Checkbox(
    value: task.completed,
    activeColor: Colors.green,
    onChanged: (value) {
      setState(() {
        task.completed = value ?? false;
      });
    },
  ),
  title: Text(
    task.title,
    style: TextStyle(
      color: task.completed ? Colors.green : Colors.black, 
      decoration:
          task.completed ? TextDecoration.lineThrough : TextDecoration.none,
    ),
  ),
  subtitle: task.description.isNotEmpty
      ? Text(
          task.description,
          style: TextStyle(
            color: task.completed ? Colors.green : Colors.black54,
            decoration:
                task.completed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        )
      : null,
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => goToForm(task: task),
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Eliminar esta tarea?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                  if (mounted) {
                    deleteTask(task.id);
                  }
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskForm extends StatefulWidget {
  final Task? task;
  final String token;

  const TaskForm({Key? key, this.task, required this.token}) : super(key: key);

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleCtrl.text = widget.task!.title;
      descCtrl.text = widget.task!.description;
    }
  }

  Future<void> saveTask() async {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (title.isEmpty) {
      showMessage(context, 'El título es obligatorio');
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = widget.task == null
          ? Uri.parse('$baseUrl/tasks')
          : Uri.parse('$baseUrl/tasks/${widget.task!.id}');

      final res = widget.task == null
          ? await http.post(uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              },
              body: jsonEncode({'title': title, 'description': description}),
            )
          : await http.patch(uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              },
              body: jsonEncode({'title': title, 'description': description}),
            );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          showMessage(
              context, widget.task == null ? 'Tarea creada' : 'Tarea actualizada');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) showMessage(context, 'Error: ${res.body}');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tarea' : 'Nueva Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Descripción (opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : saveTask,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
