import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

void main() {
  test('defaults to falling back on English', () {
    expect(const FallbackPolicy().tail, <LocaleTag>[const LocaleTag('en')]);
    expect(const FallbackPolicy().useAnyAvailable, isFalse);
  });

  test('none falls back on nothing', () {
    expect(FallbackPolicy.none.tail, isEmpty);
  });

  test('equality is by value, so a const policy compares equal', () {
    expect(const FallbackPolicy(), const FallbackPolicy());
    expect(const FallbackPolicy().hashCode, const FallbackPolicy().hashCode);
    expect(
      const FallbackPolicy(tail: <LocaleTag>[LocaleTag('de')]),
      isNot(const FallbackPolicy()),
    );
  });
}
