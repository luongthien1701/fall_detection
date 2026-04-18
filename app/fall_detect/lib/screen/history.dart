import 'package:fall_detect/model/history.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  DateTime? selectedDate;
  String formatTime(DateTime time) {
    return DateFormat('HH:mm dd/MM/yyyy').format(time);
  }
  void pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final historyList = context.watch<DeviceProvider>().history;
    final filteredHistory = selectedDate == null
        ? historyList
        : historyList.where((history) {
            return history.time.year == selectedDate!.year &&
                history.time.month == selectedDate!.month &&
                history.time.day == selectedDate!.day;
          }).toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Lịch sử sự kiện',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: pickDate, icon: Icon(Icons.calendar_month)),
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF7FBCFF)),
        child: ListView.builder(
          padding: EdgeInsets.only(top: 20),
          itemCount: filteredHistory.length,
          itemBuilder: (context, index) {
            final history = filteredHistory[index];

            return Container(
              height: 150,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Thời gian: ${formatTime(history.time)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            );
          },
        ),
      ),
    );
  }
}
