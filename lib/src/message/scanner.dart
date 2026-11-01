/// Validates an ICU pattern and reports what it needs.
///
/// Formatting itself is delegated to `intl`'s `MessageFormat`, which handles
/// plural and select selection, `#`, `offset:` and ICU apostrophe quoting, and
/// is verified correct for Czech and Arabic. What it does not do is fail
/// usefully: a malformed pattern raises an `AssertionError` (stripped in
/// release), an unknown argument renders `Undefined parameter - name`, and
/// `{d, date, yMMMd}` is silently read as a placeholder *named*
/// `d, date, yMMMd`. This scanner runs first so none of those reach a user.
///
/// It also collects the placeholder names, which the formatter needs in order
/// to locale-format numeric and date arguments -- `intl` formats `#` inside a
/// plural but leaves a bare `{n}` as `toString`.
library;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../ids.dart';

const Set<String> _pluralKeywords = <String>{
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
};

/// Argument types ICU defines that this package deliberately does not accept.
const Map<String, String> _rejectedTypes = <String, String>{
  'selectordinal':
      'intl resolves selectordinal with cardinal rules, which renders "2th" '
      'in English. Rather than ship that silently, this package rejects it. '
      'Select the ordinal form in Dart and pass the result as a string.',
  'date': 'Format the value in Dart and pass the result as a string argument.',
  'time': 'Format the value in Dart and pass the result as a string argument.',
  'number':
      'Numeric arguments are already locale-formatted; drop the argument type.',
  'duration':
      'Format the value in Dart and pass the result as a string argument.',
  'spellout':
      'Format the value in Dart and pass the result as a string argument.',
  'ordinal':
      'Format the value in Dart and pass the result as a string argument.',
};

final RegExp _identifier = RegExp(r'''^[^\s{}#,'"]+$''');
final RegExp _explicitValue = RegExp(r'^=\d+$');

/// What a scan learned about a pattern.
@immutable
final class PatternInfo {
  /// Creates pattern information.
  const PatternInfo({required this.placeholders, required this.counts});

  /// Every argument the pattern can substitute or branch on.
  ///
  /// A host can assert in its own tests that the arguments it passes match what
  /// the content asks for, rather than discovering `{userName}` on screen.
  final Set<ArgName> placeholders;

  /// Arguments used as a plural count.
  ///
  /// These must reach `intl` as numbers rather than pre-formatted strings, or
  /// category selection and `#` both break.
  final Set<ArgName> counts;

  /// Whether the pattern is a plain string with nothing to substitute.
  ///
  /// The common case by far, and worth knowing: it can skip `MessageFormat`
  /// entirely and be returned as-is.
  bool get isPlain => placeholders.isEmpty;
}

/// Validates [pattern], throwing [MessagePatternException] if it cannot be used.
PatternInfo scanPattern(String pattern) {
  final Set<ArgName> placeholders = <ArgName>{};
  final Set<ArgName> counts = <ArgName>{};
  _scanBody(pattern, 0, pattern.length, placeholders, counts);
  return PatternInfo(
    placeholders: Set<ArgName>.unmodifiable(placeholders),
    counts: Set<ArgName>.unmodifiable(counts),
  );
}

void _scanBody(
  String src,
  int from,
  int to,
  Set<ArgName> placeholders,
  Set<ArgName> counts,
) {
  int i = from;
  while (i < to) {
    final String c = src[i];
    if (c == "'") {
      i = _skipQuote(src, i, to);
      continue;
    }
    if (c == '}') {
      throw MessagePatternException(
        src,
        i,
        'Unmatched "}" at offset $i. Escape a literal brace as \'}\'.',
      );
    }
    if (c == '{') {
      final int close = _matchingBrace(src, i, to);
      _scanBlock(src, i + 1, close, placeholders, counts);
      i = close + 1;
      continue;
    }
    i++;
  }
}

void _scanBlock(
  String src,
  int from,
  int to,
  Set<ArgName> placeholders,
  Set<ArgName> counts,
) {
  final int comma = _findTopLevel(src, from, to, ',');
  final (int nameStart, int nameEnd) = _trimmed(
    src,
    from,
    comma < 0 ? to : comma,
  );
  final String name = src.substring(nameStart, nameEnd);

  if (name.isEmpty || !_identifier.hasMatch(name)) {
    throw MessagePatternException(
      src,
      from,
      'Expected an argument name at offset $from, found "$name". Names may not '
      'contain whitespace, braces, commas or quotes.',
    );
  }
  placeholders.add(ArgName(name));

  if (comma < 0) {
    return;
  }

  final int typeComma = _findTopLevel(src, comma + 1, to, ',');
  final (int typeStart, int typeEnd) = _trimmed(
    src,
    comma + 1,
    typeComma < 0 ? to : typeComma,
  );
  final String type = src.substring(typeStart, typeEnd);

  final String? rejection = _rejectedTypes[type];
  if (rejection != null) {
    throw MessagePatternException(
      src,
      typeStart,
      'Argument type "$type" is not supported at offset $typeStart. '
      '$rejection',
    );
  }
  if (type != 'plural' && type != 'select') {
    throw MessagePatternException(
      src,
      typeStart,
      'Unknown argument type "$type" at offset $typeStart. This package '
      'supports "plural" and "select". Note that intl would have read the '
      'whole of "${src.substring(from, to)}" as an argument name instead of '
      'reporting this.',
    );
  }
  if (typeComma < 0) {
    throw MessagePatternException(
      src,
      typeStart,
      '"$type" at offset $typeStart has no options. Expected branches such as '
      'one{...} other{...}.',
    );
  }

  final bool isPlural = type == 'plural';
  if (isPlural) {
    counts.add(ArgName(name));
  }
  _scanOptions(src, typeComma + 1, to, isPlural, name, placeholders, counts);
}

void _scanOptions(
  String src,
  int from,
  int to,
  bool isPlural,
  String argument,
  Set<ArgName> placeholders,
  Set<ArgName> counts,
) {
  final Set<String> seen = <String>{};
  int i = _skipWhitespace(src, from, to);

  if (isPlural && src.startsWith('offset:', i)) {
    i += 'offset:'.length;
    final int digitsStart = i;
    while (i < to && _isDigit(src[i])) {
      i++;
    }
    if (i == digitsStart) {
      throw MessagePatternException(
        src,
        digitsStart,
        'Expected a number after "offset:" at offset $digitsStart.',
      );
    }
    i = _skipWhitespace(src, i, to);
  }

  while (i < to) {
    final int keyStart = i;
    while (i < to && src[i] != '{' && !_isWhitespace(src[i])) {
      i++;
    }
    final String key = src.substring(keyStart, i);
    if (key.isEmpty) {
      throw MessagePatternException(
        src,
        keyStart,
        'Expected a branch key at offset $keyStart.',
      );
    }
    if (isPlural &&
        !_pluralKeywords.contains(key) &&
        !_explicitValue.hasMatch(key)) {
      throw MessagePatternException(
        src,
        keyStart,
        'Unknown plural branch "$key" at offset $keyStart. Expected one of '
        '${_pluralKeywords.join(", ")}, or an exact value such as "=0".',
      );
    }
    if (!seen.add(key)) {
      throw MessagePatternException(
        src,
        keyStart,
        'Branch "$key" appears twice at offset $keyStart.',
      );
    }

    i = _skipWhitespace(src, i, to);
    if (i >= to || src[i] != '{') {
      throw MessagePatternException(
        src,
        i,
        'Expected "{" after branch "$key" at offset $i.',
      );
    }
    final int close = _matchingBrace(src, i, to);
    _scanBody(src, i + 1, close, placeholders, counts);
    i = _skipWhitespace(src, close + 1, to);
  }

  if (!seen.contains('other')) {
    throw MessagePatternException(
      src,
      from,
      'The "$argument" ${isPlural ? 'plural' : 'select'} has no "other" '
      'branch. ICU requires one, and without it intl fails with an '
      'AssertionError that is stripped from release builds.',
    );
  }
}

int _matchingBrace(String src, int open, int to) {
  int depth = 0;
  int i = open;
  while (i < to) {
    final String c = src[i];
    if (c == "'") {
      i = _skipQuote(src, i, to);
      continue;
    }
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
    i++;
  }
  throw MessagePatternException(
    src,
    open,
    'Unmatched "{" at offset $open. Escape a literal brace as \'{\'.',
  );
}

/// Advances past a quoted run starting at [i], following ICU's rules.
///
/// `''` is a literal apostrophe; an apostrophe immediately before `{`, `}` or
/// `#` opens a quoted literal that runs to the next apostrophe; anything else
/// is an ordinary apostrophe. This mirrors what `intl` does, so the scanner and
/// the formatter can never disagree about where a brace is real.
int _skipQuote(String src, int i, int to) {
  if (i + 1 >= to) {
    return i + 1;
  }
  final String next = src[i + 1];
  if (next == "'") {
    return i + 2;
  }
  if (next != '{' && next != '}' && next != '#') {
    return i + 1;
  }
  // A doubled apostrophe stays an escaped apostrophe *inside* a quoted run --
  // ICU's own example is "This '{isn''t}' obvious" rendering as
  // "This {isn't} obvious" -- so scanning for the close must step over pairs.
  int j = i + 1;
  while (j < to) {
    if (src[j] == "'") {
      if (j + 1 < to && src[j + 1] == "'") {
        j += 2;
        continue;
      }
      return j + 1;
    }
    j++;
  }
  throw MessagePatternException(
    src,
    i,
    'Unterminated quoted literal starting at offset $i.',
  );
}

int _findTopLevel(String src, int from, int to, String needle) {
  int depth = 0;
  int i = from;
  while (i < to) {
    final String c = src[i];
    if (c == "'") {
      i = _skipQuote(src, i, to);
      continue;
    }
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
    } else if (depth == 0 && c == needle) {
      return i;
    }
    i++;
  }
  return -1;
}

(int, int) _trimmed(String src, int from, int to) {
  final int start = _skipWhitespace(src, from, to);
  int end = to;
  while (end > start && _isWhitespace(src[end - 1])) {
    end--;
  }
  return (start, end);
}

int _skipWhitespace(String src, int from, int to) {
  int i = from;
  while (i < to && _isWhitespace(src[i])) {
    i++;
  }
  return i;
}

bool _isWhitespace(String c) => c == ' ' || c == '\n' || c == '\t' || c == '\r';

bool _isDigit(String c) => c.codeUnitAt(0) ^ 0x30 <= 9;
