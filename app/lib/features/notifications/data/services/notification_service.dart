import 'package:dio/dio.dart';

import '../../../../core/constants/api_constant.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/notification_failure.dart';
import '../models/register_device_dto.dart';

/// The notifications feature's only network entry point.
///
/// Turns every transport failure into a [NotificationException], so the Cubit
/// above never sees Dio.
class NotificationService {
  NotificationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<void> registerDevice(RegisterDeviceDto dto) async {
    try {
      final Response<dynamic> response = await _apiService.post(
        ApiConstants.registerDevice,
        data: dto.toJson(),
      );

      // An unacknowledged write is a failure, not a success with no body.
      if (response.data case {'success': true}) {
        return;
      }
      throw const NotificationException(
        NotificationFailureReason.registrationFailed,
      );
    } on DioException catch (e) {
      throw NotificationException(_reasonFor(e));
    }
  }

  NotificationFailureReason _reasonFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => NotificationFailureReason.network,
    _ => NotificationFailureReason.registrationFailed,
  };
}
