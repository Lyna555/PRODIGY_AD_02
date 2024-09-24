import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'models/model_task.dart';
import 'helpers/helper_task.dart';
import 'helpers/helper.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Task> tasks = [];
  final TaskHelper _taskHelper = TaskHelper();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _initializeNotifications();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission() ??
        false) {
      debugPrint('Permission granted');
    } else {
      debugPrint('Permission denied');
    }
  }

  Future<void> _scheduleNotification(Task task) async {
    if (task.notify == 1 && task.startTime != null && task.date != null) {
      TimeOfDay startTime = Task.stringToTimeOfDay(task.startTime!);
      DateTime taskDate = DateTime.parse(task.date!);

      DateTime notificationTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        startTime.hour,
        startTime.minute,
      );

      notificationTime = notificationTime.subtract(const Duration(hours: 1));

      DateTime now = DateTime.now();

      if (notificationTime.isBefore(now)) {
        notificationTime = notificationTime.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        'To Do List',
        'Your task "${task.name}" is starting soon!',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  Future<void> _initializeDatabase() async {
    await DatabaseHelper().database;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    List<Task> loadedTasks = await _taskHelper.getTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  Future<void> _deleteTask(int index) async {
    await _taskHelper.deleteTask(tasks[index].id!);
    _loadTasks();
  }

  Future<void> _toggleCheckbox(int index, bool? value) async {
    Task updatedTask = Task(
        id: tasks[index].id,
        name: tasks[index].name,
        isDone: value! ? 1 : 0,
        date: tasks[index].date,
        startTime: tasks[index].startTime,
        endTime: tasks[index].endTime,
        notify: tasks[index].notify);

    await _taskHelper.updateTask(updatedTask);
    setState(() {
      tasks.removeAt(index);
      tasks.insert(tasks.length, updatedTask);
    });
  }

  Future<void> _showAddTaskForm() async {
    TextEditingController nameController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool notifyUser = false;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${selectedDate?.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(startTime == null
                    ? 'Start Time'
                    : 'Start Time: ${startTime?.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(endTime == null
                    ? 'End Time'
                    : 'End Time: ${endTime?.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      endTime = pickedTime;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Notify me'),
                value: notifyUser,
                onChanged: (value) {
                  setState(() {
                    notifyUser = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    Task newTask = Task(
                        name: nameController.text,
                        isDone: 0,
                        date: selectedDate!.toIso8601String(),
                        startTime: Task.timeOfDayToString(startTime!),
                        endTime: Task.timeOfDayToString(endTime!),
                        notify: 0);
                    await _taskHelper.createTask(newTask);
                    await _scheduleNotification(newTask);
                    _loadTasks();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Task'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditTaskForm(int index) async {
    Task taskToEdit = tasks[index];

    TextEditingController nameController =
        TextEditingController(text: taskToEdit.name);

    DateTime selectedDate =
        DateTime.parse(taskToEdit.date ?? DateTime.now().toIso8601String());
    TimeOfDay startTime = Task.stringToTimeOfDay(taskToEdit.startTime ?? '');
    TimeOfDay endTime = Task.stringToTimeOfDay(taskToEdit.endTime ?? '');
    bool notifyUser = taskToEdit.notify == 1;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(
                    'Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Start Time: ${startTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime;
                    });
                  }
                },
              ),
              ListTile(
                title: Text('End Time: ${endTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      endTime = pickedTime;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Notify me'),
                value: notifyUser,
                onChanged: (value) {
                  setState(() {
                    notifyUser = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    Task updatedTask = Task(
                      id: taskToEdit.id,
                      name: nameController.text,
                      isDone: taskToEdit.isDone,
                      date: selectedDate.toIso8601String(),
                      // Save the updated date
                      startTime: Task.timeOfDayToString(startTime),
                      endTime: Task.timeOfDayToString(endTime),
                      notify: notifyUser ? 1 : 0,
                    );
                    await _taskHelper.updateTask(updatedTask);
                    await _scheduleNotification(updatedTask);
                    _loadTasks();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update Task'),
              ),
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
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            TextEditingController controller =
                TextEditingController(text: tasks[index].name);

            String formattedStartTime =
                tasks[index].startTime ?? 'No Start Time';
            String formattedEndTime = tasks[index].endTime ?? 'No End Time';
            String formattedDate = tasks[index].date != null
                ? DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(tasks[index].date!))
                : 'Today';

            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );

            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tasks[index].name,
                            style: TextStyle(
                              fontSize: 20.0,
                              color: tasks[index].isDone == 1
                                  ? Colors.black26
                                  : Colors.black,
                              decoration: tasks[index].isDone == 1
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$formattedStartTime - $formattedEndTime',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _showEditTaskForm(index),
                            icon: const Icon(Icons.edit),
                            color: Colors.blue[800],
                          ),
                          IconButton(
                            onPressed: () => _deleteTask(index),
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                          ),
                        ],
                      ))
                ],
              ),
              value: tasks[index].isDone == 1,
              onChanged: (value) => _toggleCheckbox(index, value),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
