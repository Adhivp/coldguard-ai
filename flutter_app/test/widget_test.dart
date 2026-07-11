import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:code_card_ai/core/di/injection_container.dart' as di;

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    await di.init();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('Dependency Injection initialization check', () {
    expect(GetIt.instance.isRegistered<Dio>(), isTrue);
    expect(GetIt.instance.isRegistered<Connectivity>(), isTrue);
  });
}
