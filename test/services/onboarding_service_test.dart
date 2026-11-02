import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepwise_ai/services/onboarding_service.dart';

void main() {
  test('shows on the first launch', () async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingService.load();
    expect(OnboardingService.shouldShow, isTrue);
  });

  test('does not show again once completed', () async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingService.load();
    await OnboardingService.complete();
    expect(OnboardingService.shouldShow, isFalse);

    await OnboardingService.load();
    expect(OnboardingService.shouldShow, isFalse);
  });

  test('skips people who already have history', () async {
    SharedPreferences.setMockInitialValues({'sleep_history_v1': '[{}]'});
    await OnboardingService.load();
    expect(OnboardingService.shouldShow, isFalse);
  });
}
