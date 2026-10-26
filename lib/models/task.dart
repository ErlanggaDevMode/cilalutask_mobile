import 'employee.dart';
import '../core/utils/data_parser.dart';

enum PriorityType {
  high('Prioritas Tinggi'),
  medium('Prioritas Sedang'),
  low('Prioritas Rendah');

  final String label;
  const PriorityType(this.label);

  static PriorityType fromString(String value) {
    switch (value) {
      case 'Prioritas Tinggi':
        return PriorityType.high;
      case 'Prioritas Rendah':
        return PriorityType.low;
      case 'Prioritas Sedang':
      default:
        return PriorityType.medium;
    }
  }
}

enum TaskStatus {
  notStarted('Belum Dimulai'),
  inProgress('Dalam Proses'),
  completed('Selesai');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'Belum Dimulai':
        return TaskStatus.notStarted;
      case 'Selesai':
        return TaskStatus.completed;
      case 'Dalam Proses':
      default:
        return TaskStatus.inProgress;
    }
  }
}

class Subtask {
  final String id;
  final String title;
  final bool completed;

  const Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Subtask copyWith({String? id, String? title, bool? completed}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'completed': completed};
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String division;
  final PriorityType priority;
  final TaskStatus status;
  final String deadlineLabel;
  final bool isUrgentDeadline;
  final bool isToday;
  final List<Subtask> subtasks;
  final Assignee assignee;
  final int progressPercent;
  final String? updatedAt;
  final bool needsReview;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.division,
    required this.priority,
    required this.status,
    required this.deadlineLabel,
    this.isUrgentDeadline = false,
    this.isToday = false,
    required this.subtasks,
    required this.assignee,
    required this.progressPercent,
    this.updatedAt,
    this.needsReview = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? division,
    PriorityType? priority,
    TaskStatus? status,
    String? deadlineLabel,
    bool? isUrgentDeadline,
    bool? isToday,
    List<Subtask>? subtasks,
    Assignee? assignee,
    int? progressPercent,
    String? updatedAt,
    bool? needsReview,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      division: division ?? this.division,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      isUrgentDeadline: isUrgentDeadline ?? this.isUrgentDeadline,
      isToday: isToday ?? this.isToday,
      subtasks: subtasks ?? this.subtasks,
      assignee: assignee ?? this.assignee,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedAt: updatedAt ?? this.updatedAt,
      needsReview: needsReview ?? this.needsReview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'division': division,
      'priority': priority.label,
      'status': status.label,
      'deadlineLabel': deadlineLabel,
      'isUrgentDeadline': isUrgentDeadline,
      'isToday': isToday,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'assignee': assignee.toMap(),
      'progressPercent': progressPercent,
      'updatedAt': updatedAt,
      'needsReview': needsReview,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      division: map['division'] as String? ?? '',
      priority: PriorityType.fromString(map['priority'] as String? ?? ''),
      status: TaskStatus.fromString(map['status'] as String? ?? ''),
      deadlineLabel: map['deadlineLabel'] as String? ?? '',
      isUrgentDeadline: map['isUrgentDeadline'] as bool? ?? false,
      isToday: map['isToday'] as bool? ?? false,
      subtasks: DataParser.parseList<Subtask>(
        map['subtasks'],
        (s) => Subtask.fromMap(s),
      ),
      assignee: map['assignee'] != null
          ? Assignee.fromMap(DataParser.parseMap(map['assignee']))
          : const Assignee(
              id: 'emp-unknown',
              name: 'Staff',
              shortName: 'Staff',
              avatar: '',
              division: 'Umum',
              role: 'Karyawan',
            ),
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] as String?,
      needsReview: map['needsReview'] as bool? ?? false,
    );
  }
}
