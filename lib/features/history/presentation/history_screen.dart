import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/history/presentation/history_controller.dart';
import 'package:intl/intl.dart' as intl;
import 'package:rahban/features/history/models/trip_model.dart';
import 'package:go_router/go_router.dart';

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
    final formatter = intl.DateFormat('y/M/d HH:mm', 'fa');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تاریخچه سفرها'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Consumer<HistoryController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'خطا در دریافت اطلاعات:\n${controller.errorMessage}',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => controller.fetchTrips(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('تلاش مجدد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
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
                    Icon(Icons.history_toggle_off, size: 90, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('هیچ سفری یافت نشد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchTrips(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: controller.trips.length,
                itemBuilder: (context, index) {
                  final trip = controller.trips[index];

                  IconData statusIcon;
                  Color statusColor;
                  String statusText;

                  switch (trip.status) {
                    case 'completed':
                      statusIcon = Icons.check_circle;
                      statusColor = Colors.green.shade600;
                      statusText = 'تکمیل شده';
                      break;
                    case 'sos':
                    case 'emergency':
                      statusIcon = Icons.warning_amber_rounded;
                      statusColor = Colors.red.shade600;
                      statusText = 'اضطراری';
                      break;
                    default:
                      statusIcon = Icons.timelapse;
                      statusColor = Colors.orange.shade700;
                      statusText = 'در حال انجام';
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      title: Text(
                        'سفر #${trip.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('وضعیت: $statusText', style: TextStyle(color: statusColor)),
                          const SizedBox(height: 2),
                          Text('زمان آغاز: ${formatter.format(trip.createdAt.toLocal())}'),
                        ],
                      ),
                      onTap: () {
                        // عمل خاصی در صورت نیاز می‌توان اضافه کرد
                      },
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
