import 'package:flutter/material.dart';

class Task {
  final int? id;
  final String name;
  final int isDone;
  final String? date;
  final String? startTime;
  final String? endTime;
  final int notify;

  Task(
      {this.id,
      required this.name,
      this.isDone = 0,
      required this.date,
      required this.startTime,
      required this.endTime,
      this.notify = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDone': isDone,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'notify': notify
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
        id: map['id'],
        name: map['name'],
        isDone: map['isDone'],
        date: map['date'],
        startTime: map['startTime'],
        endTime: map['endTime'],
        notify: map['notify']);
  }

  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  static TimeOfDay stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
