import 'package:flutter/material.dart';
import 'package:shift_cover/organisation_services_page.dart';

class ShiftRequirement {
  TimeOfDay startTime;
  TimeOfDay endTime;
  Map<String, int> minimums; // role => count

  ShiftRequirement({
    required this.startTime,
    required this.endTime,
    Map<String, int>? minimums,
  }) : minimums = minimums ?? {};
}
