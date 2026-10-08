import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const TaskAlertApp());
}

class TaskAlertApp extends StatelessWidget {
  const TaskAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Alert App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TaskHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  String title;
  String description;
  String deadline;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'deadline': deadline,
        'isCompleted': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        description: json['description'],
        deadline: json['deadline'],
        isCompleted: json['isCompleted'],
      );
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Menyimpan data tugas ke memori lokal HP
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> taskListString =
        _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('saved_tasks', taskListString);
  }

  // Memuat data tugas yang tersimpan
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? taskListString = prefs.getStringList('saved_tasks');
    if (taskListString != null) {
      setState(() {
        _tasks = taskListString
            .map((taskStr) => Task.fromJson(jsonDecode(taskStr)))
            .toList();
      });
    }
  }

  // Menambah Task Baru
  void _addNewTask(String title, String desc, String deadline) {
    setState(() {
      _tasks.add(Task(title: title, description: desc, deadline: deadline));
    });
    _saveTasks();
  }

  // Menghapus Task
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  // Toggle status selesai
  void _toggleTaskStatus(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    _saveTasks();
  }

  // Form Pop-up untuk tambah tugas
  void _showAddTaskModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tambah Tugas Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Tugas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Deadline: ${DateFormat('dd MMM yyyy, HH:mm').format(selectedDate)}',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    String formattedDeadline =
                        DateFormat('dd MMM yyyy, HH:mm').format(selectedDate);
                    _addNewTask(
                      titleController.text,
                      descController.text,
                      formattedDeadline,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan Tugas'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Task & Alert'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Text(
                'Belum ada tugas. Yuk buat tugas pertamamu!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (bool? value) {
                        _toggleTaskStatus(index);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description.isNotEmpty)
                          Text(task.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.alarm, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              task.deadline,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => _deleteTask(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskModal,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
