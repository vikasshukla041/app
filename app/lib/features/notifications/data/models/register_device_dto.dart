/// Data Transfer Object for POST /api/user/register-device.
class RegisterDeviceDto {
  const RegisterDeviceDto({
    required this.fcmToken,
    required this.deviceId,
    required this.platform,
    required this.deviceName,
  });

  final String fcmToken;
  final String deviceId;
  final String platform;
  final String deviceName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fcmToken': fcmToken,
    'deviceId': deviceId,
    'platform': platform,
    'deviceName': deviceName,
  };
}
