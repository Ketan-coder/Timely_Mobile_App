import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../auth/auth_service.dart' as auth_service;
import '../components/custom_snack_bar.dart';
import '../models/reminder.dart';
import 'login_screen.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Map<String, dynamic>> _reminders = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token; // Store token

  @override
  void initState() {
    super.initState();
    _initializeData();
    // _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    //   if (_token != null) {
    //     print("Here");
    //     _initializeData();
    //   }
    // });
  }

  @override
  void dispose() {
    // _updateTimer?.cancel(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await auth_service.AuthService.getToken();
    if (_token != null) {
      setState(() => _isRefreshing = true);
      await auth_service.AuthService.fetchReminders(_token!);
      await _loadReminders();
      setState(() => _isRefreshing = false);
    } else {
      print("Error: Authentication token is null");
    }
    return;
  }

  Future<void> _loadReminders() async {
    try {
      List<Reminder> reminders =
      await auth_service.AuthService.loadRemindersFromLocal();

      setState(() {
        _reminders = reminders.map((reminders) => reminders.toJson()).toList();
      });
    } catch (e) {
      print("Error loading notebooks: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    await auth_service.AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(
          dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
  }

  Future<void> _toggleCompleted(int remaindersId, String remaindersName,
      bool isCompleted) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/remainders/${remaindersId}/',
    );
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: {
        'is_completed': (!isCompleted).toString(),
      },
    );
    print(response);
    if (response.statusCode == 200) {
      if (isCompleted) {
        _initializeData();
        showAnimatedSnackBar(
            context,
            "${remaindersName} has been marked In-Complete Successfully",
            isInfo: true, isTop: true);
      } else {
        _initializeData();
        showAnimatedSnackBar(
            context, "${remaindersName} has been marked Completed Successfully",
            isSuccess: true, isTop: true);
      }
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _addReminderAPI(String reminderName, DateTime alertTime) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/remainders/',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: {
        'title': reminderName.trim(),
        'body': reminderName.trim(),
        'alert_time': alertTime.toIso8601String(),
        // Send alert_time in ISO format
      },
    );
    print(response);
    if (response.statusCode == 201) {
      _initializeData();
      showAnimatedSnackBar(
        context,
        "$reminderName Added Successfully",
        isSuccess: true,
        isTop: true,
      );
    } else {
      showAnimatedSnackBar(
        context,
        "Something went wrong!",
        isError: true,
        isTop: true,
      );
    }
  }

  Future<void> _addReminder(BuildContext context) async {
    TextEditingController reminderController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(
        Duration(hours: 2)); // Default: Now + 2 hours

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              title: const Text("Add New Reminder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reminderController,
                    decoration: InputDecoration(labelText: "Eg. Call John"),
                  ),
                  SizedBox(height: 10),
                  // Date Picker Button
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
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
                    child: Text(
                      "Pick Alert Time: ${selectedDateTime.toLocal()}",
                      style: TextStyle(color: Theme
                          .of(context)
                          .colorScheme
                          .primary, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // ❌ Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String reminder = reminderController.text.trim();
                    if (reminder.isNotEmpty) {
                      await _addReminderAPI(reminder, selectedDateTime);
                      Navigator.of(context).pop(); // Close dialog
                    }
                  },
                  child: const Text(
                      "Add", style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReminderAPI(int reminderId, String reminderName) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/remainders/$reminderId/',
    );
    final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Token $_token', // Replace with actual token
        }
    );
    print(response);
    if (response.statusCode == 204) {
      _initializeData();
      showAnimatedSnackBar(
          context, "${reminderName} Removed!", isSuccess: true,
          isTop: true);
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _deleteReminder(BuildContext context, int reminderID,
      String reminderName) async {
    TextEditingController reminderController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              //icon: Icon(Icons.add),
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              title: const Text("Delete Reminder"),
              content: Text("Are you sure Delete $reminderName?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    await _deleteReminderAPI(reminderID, reminderName);
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text(
                      "Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editReminderAPI(String reminderUUId, String reminderName,
      DateTime alertTime) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/remainders/$reminderUUId/',
    );
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: {
        'title': reminderName.trim(),
        'body': reminderName.trim(),
        'alert_time': alertTime.toIso8601String(), // Convert to ISO format
      },
    );
    print(response);
    if (response.statusCode == 200) {
      _initializeData();
      showAnimatedSnackBar(
        context,
        "$reminderName Updated Successfully",
        isSuccess: true,
        isTop: true,
      );
    } else {
      showAnimatedSnackBar(
        context,
        "Something went wrong!",
        isError: true,
        isTop: true,
      );
    }
  }

  Future<void> _editReminder(BuildContext context,
      Map<String, dynamic> reminderData) async {
    TextEditingController reminderController = TextEditingController(
        text: reminderData['title']);
    DateTime selectedDateTime = DateTime.parse(
        reminderData['alert_time']); // Prefill DateTime

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              title: const Text("Edit Reminder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reminderController,
                    decoration: InputDecoration(labelText: "Reminder Name"),
                  ),
                  SizedBox(height: 10),
                  // Date Picker Button
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
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
                    child: Text(
                      "Pick Alert Time: ${selectedDateTime.toLocal()}",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // ❌ Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String reminder = reminderController.text.trim();
                    if (reminder.isNotEmpty) {
                      await _editReminderAPI(
                          reminderData['remainder_uuid'], reminder,
                          selectedDateTime);
                      Navigator.of(context).pop(); // Close dialog
                    }
                  },
                  child: const Text(
                      "Update", style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FloatingActionButton(
              heroTag: 'Refresh Reminders',
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              foregroundColor: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              tooltip: "Refresh Reminders",
              onPressed: () async {
                await _initializeData();
              },
              child: Icon(Icons.refresh),
            ),
          ),
          SizedBox(width: 12), // Adds spacing between buttons
          FloatingActionButton(
            heroTag: 'Add Reminder Button',
            tooltip: "Add Reminder",
            onPressed: () => _addReminder(context),
            child: Icon(Icons.add),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // setState(() {
          //   _titleOpacity = (1 - (scrollInfo.metrics.pixels / 100)).clamp(0, 1);
          // });
          return true;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              toolbarHeight: 80.0,
              flexibleSpace: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Center(
                            child: Text("Image failed to load"),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Opacity(
                      opacity: _titleOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Padding(
                          //  padding: const EdgeInsets.only(left: 1.0),
                          //  child: Icon(Icons.book,size: 40,color: Theme.of(context).colorScheme.primary),
                          // ),
                          Text(
                            "Reminders",
                            style: TextStyle(
                              color:
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primary ??
                                  Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isRefreshing)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final reminder = _reminders[index];
                  bool isCompleted = reminder['is_completed'] ?? false;
                  return ListTile(
                    textColor: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                    title: Text(reminder['title'] ?? 'Untitled',
                      style: TextStyle(color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          fontFamily: 'Sora'),),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        children: [
                          isCompleted ? SizedBox() : Icon(
                            Icons.notifications_active, size: 18, color: Theme
                              .of(context)
                              .colorScheme
                              .surface,),
                          isCompleted ? Text('Completed!', style: TextStyle(
                            fontSize: 12,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,)) : Text(
                              ' ${_formatDateTime(
                                  reminder['alert_time'])}',
                              style: TextStyle(color: Theme
                                  .of(context)
                                  .colorScheme
                                  .surface, fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: IconButton(onPressed: () async {
                      await _deleteReminder(
                          context, reminder['id'], reminder['title']);
                    }, icon: Icon(Icons.delete, color: Colors.grey,)),
                    leading: isCompleted
                        ? IconButton(
                      icon: Icon(Icons.done, color: Colors.green),
                      onPressed: () async {
                        await _toggleCompleted(reminder['id'],
                            reminder['title'], isCompleted);
                      },)
                        : IconButton(icon: Icon(Icons.check_circle),
                      onPressed: () async {
                        await _toggleCompleted(reminder['id'],
                            reminder['title'], isCompleted);
                      },),
                    onLongPress: () async {
                      _editReminder(context, _reminders[index]);
                    },
                  );
                },
                childCount: _reminders.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
