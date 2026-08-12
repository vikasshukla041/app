import 'package:dio/dio.dart';

import '../../../../core/network/api_service.dart';
import '../models/register_device_dto.dart';

class NotificationService {
  NotificationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<void> registerDevice(RegisterDeviceDto dto) async {
    final Response<dynamic> response = await _apiService.registerDevice(
      payload: dto.toJson(),
    );

    if (response.data case {'success': true}) {
      return;
    }

    throw const FormatException('Device registration was not acknowledged');
  }
}
