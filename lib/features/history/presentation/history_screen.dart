import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/history/presentation/history_controller.dart';
import 'package:intl/intl.dart' as intl;
import 'package:rahban/features/history/models/trip_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = intl.DateFormat('y/M/d H:m', 'fa');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تاریخچه سفرها')),
        body: Consumer<HistoryController>(
          builder: (context, controller, child) {
            if (controller.isLoading) return const Center(child: CircularProgressIndicator());
            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطا در دریافت اطلاعات: ${controller.errorMessage}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchTrips(),
                      child: const Text('تلاش مجدد'),
                    )
                  ],
                ),
              );
            }
            if (controller.trips.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('هیچ سفری یافت نشد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => controller.fetchTrips(),
              child: ListView.builder(
                itemCount: controller.trips.length,
                itemBuilder: (context, index) {
                  final trip = controller.trips[index];
                  IconData statusIcon;
                  Color statusColor;
                  String statusText;
                  switch (trip.status) {
                    case 'completed':
                      statusIcon = Icons.check_circle_outline;
                      statusColor = Colors.green;
                      statusText = 'تکمیل شده';
                      break;
                    case 'sos':
                    case 'emergency':
                      statusIcon = Icons.warning_amber_rounded;
                      statusColor = Colors.red;
                      statusText = 'اضطراری';
                      break;
                    default:
                      statusIcon = Icons.hourglass_empty_rounded;
                      statusColor = Colors.orange;
                      statusText = 'در حال انجام';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(statusIcon, color: statusColor, size: 40),
                      title: Text('سفر #${trip.id} - $statusText'),
                      subtitle: Text('آغاز: ${a.format(trip.createdAt.toLocal())}'),
                      onTap: () {},
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
