import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class CreateOrganisationPage extends StatefulWidget {
  const CreateOrganisationPage({super.key});

  @override
  _CreateOrganisationPageState createState() => _CreateOrganisationPageState();
}

class _CreateOrganisationPageState extends State<CreateOrganisationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Roles: dynamic list of role names
  List<String> _roles = [];

  // Shifts: dynamic list of ShiftRequirement objects
  List<ShiftRequirement> _shifts = [];

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialTime,
    void Function(TimeOfDay) onTimePicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimePicked(picked);
    }
  }

  Future<void> _createOrganisation() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation: Ensure at least one role and one shift
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one role')),
      );
      return;
    }
    if (_shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one shift')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final name = _nameController.text.trim();

      // Convert shifts to map to save in Firestore
      final shiftMaps = _shifts.map((shift) {
        return {
          'startTime':
              '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}',
          'endTime':
              '${shift.endTime.hour.toString().padLeft(2, '0')}:${shift.endTime.minute.toString().padLeft(2, '0')}',
          'minimums': shift.minimums,
        };
      }).toList();

      final orgRef = await FirebaseFirestore.instance
          .collection('organisations')
          .add({
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
            'managers': [user.uid],
            'employees': [],
            'roles': _roles,
            'shiftRequirements': shiftMaps,
          });

      // Update user document to add organisation ID and role manager
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await userRef.set({
        'organisationIds': FieldValue.arrayUnion([orgRef.id]),
        'role': 'manager',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Organisation "$name" created!')));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create organisation: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _addRole() {
    setState(() {
      _roles.add('');
    });
  }

  void _removeRole(int index) {
    setState(() {
      _roles.removeAt(index);
      // Also remove min counts for removed role in all shifts
      for (var shift in _shifts) {
        shift.minimums.remove(_roles[index]);
      }
    });
  }

  void _addShift() {
    setState(() {
      _shifts.add(
        ShiftRequirement(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          minimums: {for (var role in _roles) role: 0},
        ),
      );
    });
  }

  void _removeShift(int index) {
    setState(() {
      _shifts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Organisation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Organisation Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Organisation Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Roles Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Roles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _addRole,
                    child: const Text('Add Role'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ..._roles.asMap().entries.map((entry) {
                final i = entry.key;
                final role = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: role,
                          decoration: InputDecoration(
                            labelText: 'Role ${i + 1}',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Role name cannot be empty';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              _roles[i] = val;
                              // Update minimums keys in shifts if needed
                              for (var shift in _shifts) {
                                if (!shift.minimums.containsKey(val)) {
                                  shift.minimums[val] = 0;
                                }
                                // Remove old keys that no longer exist
                                final toRemove = shift.minimums.keys
                                    .where((k) => !_roles.contains(k))
                                    .toList();
                                for (var oldKey in toRemove) {
                                  shift.minimums.remove(oldKey);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final removedRole = _roles[i];
                            _roles.removeAt(i);
                            for (var shift in _shifts) {
                              shift.minimums.remove(removedRole);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Shifts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shifts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _roles.isEmpty ? null : _addShift,
                    child: const Text('Add Shift'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (_shifts.isEmpty)
                const Text('Add at least one shift to proceed.'),

              ..._shifts.asMap().entries.map((entry) {
                final i = entry.key;
                final shift = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Start Time
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(
                                  context,
                                  shift.startTime,
                                  (picked) {
                                    setState(() {
                                      shift.startTime = picked;
                                      if (_compareTime(
                                            shift.endTime,
                                            shift.startTime,
                                          ) <=
                                          0) {
                                        // ensure endTime after startTime
                                        shift.endTime = TimeOfDay(
                                          hour: (picked.hour + 1) % 24,
                                          minute: picked.minute,
                                        );
                                      }
                                    });
                                  },
                                ),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Time',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    shift.startTime.format(context),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // End Time
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(context, shift.endTime, (
                                  picked,
                                ) {
                                  setState(() {
                                    if (_compareTime(picked, shift.startTime) >
                                        0) {
                                      shift.endTime = picked;
                                    }
                                  });
                                }),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Time',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    shift.endTime.format(context),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeShift(i),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Minimum staff per role:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        ..._roles.map((role) {
                          final currentCount = shift.minimums[role] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(role)),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: currentCount.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty)
                                        return null;
                                      final numVal = int.tryParse(value);
                                      if (numVal == null || numVal < 0) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                    onChanged: (val) {
                                      final numVal = int.tryParse(val) ?? 0;
                                      shift.minimums[role] = numVal;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createOrganisation,
                      child: const Text('Create Organisation'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to compare two TimeOfDay objects.
  /// Returns <0 if t1 < t2, 0 if equal, >0 if t1 > t2
  int _compareTime(TimeOfDay t1, TimeOfDay t2) {
    if (t1.hour != t2.hour) return t1.hour - t2.hour;
    return t1.minute - t2.minute;
  }
}
