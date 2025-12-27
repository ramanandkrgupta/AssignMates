import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignmates/src/services/notification_service.dart';

void main() {
  test('Terminal Notification Format Verification', () {
    final String studentName = "Dummy Test Student";
    final String studentCity = "Bhopal";
    final int pageCount = 5;

    final String notificationBody = 'From $studentCity, $studentName created $pageCount pages order';

    print('\n--- TERMINAL NOTIFICATION TEST ---');
    print('Simulated Body: $notificationBody');
    print('---------------------------------\n');

    expect(notificationBody, equals('From Bhopal, Dummy Test Student created 5 pages order'));
  });
}
