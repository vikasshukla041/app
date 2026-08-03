import 'package:activotrade_app/core/security/biometric_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication localAuth;
  late BiometricService service;

  setUp(() {
    localAuth = MockLocalAuthentication();
    service = BiometricService(localAuth: localAuth);
  });

  void stubDevice({
    bool supported = true,
    bool canCheck = true,
    List<BiometricType> enrolled = const <BiometricType>[
      BiometricType.fingerprint,
    ],
  }) {
    when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => supported);
    when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => canCheck);
    when(
      () => localAuth.getAvailableBiometrics(),
    ).thenAnswer((_) async => enrolled);
  }

  group('isAvailable', () {
    test('true when supported, capable and something is enrolled', () async {
      stubDevice();

      expect(await service.isAvailable(), isTrue);
    });

    test('false when the device is not supported', () async {
      stubDevice(supported: false);

      expect(await service.isAvailable(), isFalse);
    });

    test('false when hardware exists but nothing is enrolled', () async {
      stubDevice(enrolled: const <BiometricType>[]);

      expect(await service.isAvailable(), isFalse);
    });
  });

  group('authenticate', () {
    void stubAuthenticate(Future<bool> Function() result) {
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(
            named: 'persistAcrossBackgrounding',
          ),
        ),
      ).thenAnswer((_) => result());
    }

    test('success when the prompt reports a match', () async {
      stubAuthenticate(() async => true);

      expect(
        await service.authenticate(reason: 'reason'),
        BiometricResult.success,
      );
    });

    test('cancelled when the prompt reports no match', () async {
      stubAuthenticate(() async => false);

      expect(
        await service.authenticate(reason: 'reason'),
        BiometricResult.cancelled,
      );
    });

    test('lockedOut when the OS reports a biometric lockout', () async {
      stubAuthenticate(
        () async => throw const LocalAuthException(
          code: LocalAuthExceptionCode.biometricLockout,
        ),
      );

      expect(
        await service.authenticate(reason: 'reason'),
        BiometricResult.lockedOut,
      );
    });

    test('unavailable when no hardware is present', () async {
      stubAuthenticate(
        () async => throw const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricHardware,
        ),
      );

      expect(
        await service.authenticate(reason: 'reason'),
        BiometricResult.unavailable,
      );
    });
  });
}
