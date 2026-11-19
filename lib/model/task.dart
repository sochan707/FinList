
import 'package:flutter/material.dart';
import 'dateOnly.dart';
import 'subTask.dart';

enum TaskPriority {low, medium, high,}

class Task {
  final String id;
  final String title;
  final DateOnly workDay;

  final bool isCompleted;
  final bool isTopPriority;
  final bool rewardGranted;

  final List<SubTask> subTasks;

  final DateOnly? dueDate;
  final TimeOfDay? dueTime;
  final TimeOfDay? plannedTime;
  final DateTime? reminderAt;

  final String? notes;
  final String? groupId;
  final String? goalId;
  final int? goalOrder;

  final TaskPriority? priority;

  Task({
    required this.id,
    required this.title,
    required this.workDay,
    this.isCompleted = false,
    this.isTopPriority = false,
    this.rewardGranted = false,
    List<SubTask>? subTasks,
    this.dueDate,
    this.dueTime,
    this.plannedTime,
    this.reminderAt,
    this.notes,
    this.groupId,
    this.goalId,
    this.goalOrder,
    this.priority,
  }) : subTasks = subTasks ?? [];
}
