import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/services/firebase_bootstrap.dart';

void main() {
  test('chỉ nhận diện lỗi Firebase thiếu default options', () {
    expect(
      FirebaseBootstrap.isMissingDefaultOptionsError(
        PlatformException(
          code: 'Exception',
          message: 'Failed to load FirebaseOptions from resource',
        ),
      ),
      isTrue,
    );
    expect(
      FirebaseBootstrap.isMissingDefaultOptionsError(
        PlatformException(code: 'network-error', message: 'Request failed'),
      ),
      isFalse,
    );
    expect(
      FirebaseBootstrap.isMissingDefaultOptionsError(StateError('other')),
      isFalse,
    );
  });
}
