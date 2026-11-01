/// Shared collection equalities.
///
/// Value types here are hand-written rather than generated, so every `==` that
/// compares a collection reaches for one of these instead of rolling its own
/// loop. Keeping them in one file is what stops two value types disagreeing
/// about what equality means.
library;

import 'package:collection/collection.dart';

/// Order-sensitive list equality.
const ListEquality<Object?> listEq = ListEquality<Object?>();

/// Order-insensitive set equality.
const SetEquality<Object?> setEq = SetEquality<Object?>();

/// Key/value map equality.
const MapEquality<Object?, Object?> mapEq = MapEquality<Object?, Object?>();

/// Structural equality through nested collections.
const DeepCollectionEquality deepEq = DeepCollectionEquality();
