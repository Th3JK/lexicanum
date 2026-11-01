/// Decoding polymorphic content, including types this package never saw.
library;

import '../errors.dart';
import '../internal/json.dart';
import 'built_in_objects.dart';
import 'content_object.dart';

/// Builds one content object from its JSON.
typedef ContentDecoder = ContentObject Function(Json json, String path);

/// Type names this package ships and will not let a host redefine.
const Set<String> reservedContentTypes = <String>{
  'text',
  'image',
  'audio',
  'video',
  'speech',
};

/// Maps a `type` field to a decoder.
///
/// The mechanism that lets a repository hand back `List<ContentObject>` without
/// knowing what is in it. Modelled on interrogator's `QuestionTypeRegistry`,
/// including its refusal to let a host quietly replace a built-in type -- a
/// silent override would make the same JSON mean different things depending on
/// import order.
final class ContentRegistry {
  /// Creates a registry with the built-in types already present.
  ContentRegistry()
    : _decoders = <String, ContentDecoder>{...builtInContentDecoders};

  /// Creates a registry with no built-in types at all.
  ///
  /// For a host that wants its own vocabulary and nothing else.
  ContentRegistry.empty() : _decoders = <String, ContentDecoder>{};

  final Map<String, ContentDecoder> _decoders;

  /// The type names this registry can decode.
  Set<String> get types => Set<String>.unmodifiable(_decoders.keys);

  /// Registers [decoder] for [type].
  ///
  /// Throws if [type] is reserved or already registered, rather than
  /// overwriting: a registration that silently replaced another would be a bug
  /// that only appeared once two packages were used together.
  void register(String type, ContentDecoder decoder) {
    if (reservedContentTypes.contains(type) &&
        builtInContentDecoders.containsKey(type) &&
        _decoders[type] == builtInContentDecoders[type]) {
      throw ArgumentError.value(
        type,
        'type',
        'is reserved by this package. Choose another name, or start from '
            'ContentRegistry.empty() if you mean to define your own vocabulary.',
      );
    }
    if (_decoders.containsKey(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'is already registered. Each type name may have one decoder.',
      );
    }
    _decoders[type] = decoder;
  }

  /// Decodes one content object.
  ContentObject decode(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    final Object? type = object['type'];
    if (type is! String) {
      throw LexicanumFormatException(
        '$path.type',
        '$path: content needs a "type" field naming a registered type, found '
            '${type.runtimeType}.',
      );
    }
    final ContentDecoder? decoder = _decoders[type];
    if (decoder == null) {
      final List<String> known = _decoders.keys.toList()..sort();
      throw LexicanumFormatException(
        '$path.type',
        '$path: no decoder for content type "$type". Registered: '
            '${known.isEmpty ? 'none' : known.join(', ')}. Register one with '
            'ContentRegistry.register("$type", ...).',
      );
    }
    return decoder(object, path);
  }

  /// Decodes a list of content objects, reporting the index that failed.
  List<ContentObject> decodeAll(Object? json, [String path = r'$']) {
    final List<Object?> list = requireList(json, path);
    return <ContentObject>[
      for (final (int index, Object? item) in list.indexed)
        decode(item, '$path[$index]'),
    ];
  }
}
