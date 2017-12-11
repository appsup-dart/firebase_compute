// Copyright (c) 2017, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library firebase_compute;

import 'package:firebase_dart/firebase_dart.dart';
import 'package:firebase_dart/src/treestructureddata.dart';
import 'package:firebase_dart/src/firebase_impl.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

part 'src/query.dart';
part 'src/value.dart';
part 'src/reactive.dart';

final _logger = new Logger('firebase-compute');





class _MergedDataSnapshot implements DataSnapshot {

  final Firebase _parentRef;
  final FilteredMap<Name,DataSnapshot> _children;

  _MergedDataSnapshot(this._parentRef, Iterable<DataSnapshot> _snapshots, QueryFilter _filter) :
    _children = new FilteredMap(new Filter(
      ordering: new Ordering<Name,DataSnapshot>.byMappedValue((DataSnapshot s) {
        var data = s is DataSnapshotImpl ? s.treeStructuredData : new TreeStructuredData.fromJson(s.exportVal());
        return _filter.ordering.mapValue(data);
      }),
      limit: _filter.limit, reversed: _filter.reversed,
      validInterval: _filter.validInterval
    )) {
    for (var s in _snapshots) {
      s.forEach((ss)=>_children[new Name(ss.key)] = ss);
    }
  }



  @override
  DataSnapshot child(String c) => _children[new Name(c)] ??
    new DataSnapshotImpl(ref.child(c),null);

  @override
  bool get exists => _children.isNotEmpty;

  @override
  exportVal() {
    var e = {};
    for (var s in _children.keys) {
      e[s.toString()] = _children[s].exportVal();
    }
    return e;
  }

  @override
  void forEach(cb(DataSnapshot snapshot)) => _children.values.forEach(cb);

  @override
  bool hasChild(String path) {
    var p = Name.parsePath(path);
    var c = _children[p.first];
    if (c==null) return false;
    if (p.length==1) return true;
    return c.hasChild(p.skip(1).join("/"));
  }

  @override
  bool get hasChildren => _children.isNotEmpty;

  @override
  String get key => "[]";

  @override
  int get numChildren => _children.length;

  @override
  get priority => null;

  @override
  Firebase get ref => _parentRef.child(key);

  @override
  get val {
    if (!hasChildren) return null;
    var e = {};
    for (var s in _children.keys) {
      e[s.toString()] = _children[s].val;
    }
    return e;
  }
}
