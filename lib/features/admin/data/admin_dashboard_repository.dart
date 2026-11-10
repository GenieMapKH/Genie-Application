import 'package:dio/dio.dart';
import 'admin_record.dart';
import 'admin_service_health.dart';
import 'admin_rotation_status.dart';
import 'admin_income.dart';

class AdminDashboardData {
  final DateTime generatedAt;
  final int totalUsers;
  final int activeUsers;
  final int newUsers7d;
  final int openReports;
  final int totalListings;
  final int activeListings;
  final int newListings7d;
  final int leads7d;
  final int activeSubscriptions;
  final int pendingPayments;
  final int successfulPayments7d;
  final double volumeUsd7d;
  final bool paymentsSimulated;
  final Map<String, int> subscriptionsByTier;
  final AdminIncome? income;

  const AdminDashboardData({
    required this.generatedAt,
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers7d,
    required this.openReports,
    required this.totalListings,
    required this.activeListings,
    required this.newListings7d,
    required this.leads7d,
    required this.activeSubscriptions,
    required this.pendingPayments,
    required this.successfulPayments7d,
    required this.volumeUsd7d,
    required this.paymentsSimulated,
    required this.subscriptionsByTier,
    this.income,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>;
    final listings = json['listings'] as Map<String, dynamic>;
    final payments = json['payments'] as Map<String, dynamic>;
    return AdminDashboardData(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalUsers: users['total'] as int,
      activeUsers: users['active'] as int,
      newUsers7d: users['newLast7Days'] as int,
      openReports: json['openReports'] as int,
      totalListings: listings['total'] as int,
      activeListings: listings['active'] as int,
      newListings7d: listings['newLast7Days'] as int,
      leads7d: listings['leadsLast7Days'] as int,
      activeSubscriptions: payments['activeSubscriptions'] as int,
      pendingPayments: payments['pendingTransactions'] as int,
      successfulPayments7d: payments['successfulTransactions7d'] as int,
      volumeUsd7d: (payments['volumeUsd7d'] as num).toDouble(),
      paymentsSimulated: payments['simulated'] as bool,
      income: payments['income'] == null
          ? null
          : AdminIncome.fromJson(payments['income'] as Map<String, dynamic>),
      subscriptionsByTier:
          (payments['subscriptionsByTier'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          ),
    );
  }
}

class AdminDashboardRepository {
  final Dio dio;
  const AdminDashboardRepository(this.dio);

  Future<AdminRotationStatus> rotations() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/dashboard/rotations',
    );
    return AdminRotationStatus.fromJson(response.data!);
  }

  Future<AdminDashboardData> load() async {
    final response = await dio.get<Map<String, dynamic>>('/admin/dashboard');
    return AdminDashboardData.fromJson(response.data!);
  }

  Future<AdminRecordsPage> records(
    String section, {
    int offset = 0,
    String? tier,
    String? query,
    String? purpose,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/dashboard/records',
      queryParameters: {
        'section': section,
        'offset': offset,
        'tier': ?tier,
        'q': ?query,
        'purpose': ?purpose,
      },
    );
    final data = response.data!;
    return (
      items: (data['items'] as List)
          .map((item) => AdminRecord(item as Map<String, dynamic>))
          .toList(),
      nextOffset: data['nextOffset'] as int?,
    );
  }

  Future<AdminSystemHealth> health() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/dashboard/health',
    );
    return AdminSystemHealth.fromJson(response.data!);
  }
}
