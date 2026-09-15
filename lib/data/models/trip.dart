// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/foundation.dart';

/// Командировка: период времени, к которому привязываются служебные траты.
@immutable
class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.destination = '',
    this.note = '',
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    title: json['title'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    destination: json['destination'] as String? ?? '',
    note: json['note'] as String? ?? '',
  );

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// Место назначения (город, организация).
  final String destination;
  final String note;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'destination': destination,
    'note': note,
  };

  Trip copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    String? note,
  }) => Trip(
    id: id,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    destination: destination ?? this.destination,
    note: note ?? this.note,
  );

  /// Продолжительность командировки в днях (включая первый и последний день).
  int get days => endDate.difference(startDate).inDays.abs() + 1;

  /// Попадает ли дата в период командировки.
  bool containsDate(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    final DateTime from = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final DateTime to = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  @override
  bool operator ==(Object other) =>
      other is Trip &&
      other.id == id &&
      other.title == title &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.destination == destination &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, title, startDate, endDate, destination, note);
}
