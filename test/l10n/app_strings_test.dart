import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/l10n/app_strings.dart';

void main() {
  tearDown(() => AppLanguage.notifier.value = 'en');

  test('the no-factor message does not claim there is no risk', () {
    const raw = 'No major risk factors found';
    for (final language in ['en', 'th']) {
      AppLanguage.notifier.value = language;
      final text = S.current.factor(raw);
      expect(text, isNot(raw));
      expect(text.toLowerCase(), isNot(contains('risk')));
      expect(text, isNot(contains('เสี่ยง')));
    }
  });

  test('backend factors are translated, and unknown text is kept', () {
    AppLanguage.notifier.value = 'th';
    expect(S.current.factor('High stress level'), 'ความเครียดสูง');
    expect(S.current.factor('Something new'), 'Something new');
  });
}
