import 'package:dio/dio.dart';
import 'admin_operations.dart';

class AdminOperationsRepository {
  final Dio dio;
  const AdminOperationsRepository(this.dio);

  Future<AdminWorkflowStatus> rotationJob() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/operations/rotation-job',
    );
    return AdminWorkflowStatus.fromJson(response.data!);
  }

  Future<void> forceRotation() async {
    await dio.post<void>(
      '/admin/operations/rotation-job',
      data: {'reason': 'Admin requested force rotation'},
    );
  }

  Future<AdminLogPage> logs(String dataset, {String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/operations/logs',
      queryParameters: {'dataset': dataset, 'cursor': ?cursor},
    );
    return AdminLogPage.fromJson(response.data!);
  }

  Future<AdminDeploymentStatus> deployments() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/operations/deployments',
    );
    return AdminDeploymentStatus.fromJson(response.data!);
  }

  Future<void> rollback(AdminServiceDeployments service, String reason) async {
    await dio.post<void>(
      '/admin/operations/deployments/${service.name}/rollback',
      data: {
        'reason': reason,
        'deploymentId': service.previous!.id,
        'expectedLatestId': service.latest!.id,
      },
    );
  }
}
