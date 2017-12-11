
part of firebase_compute;


/// Represents a sequence of DataSnapshot values.
abstract class ReactiveDataSnapshot implements ReactiveValue<DataSnapshot> {

  /// Creates a ReactiveDataSnapshot from a stream of DataSnapshots.
  factory ReactiveDataSnapshot.fromStream(Stream<DataSnapshot> stream) =>
      new _ReactiveSnapshotFromStream(stream);

  /// Returns the first child of each DataSnapshot in this sequence.
  ReactiveDataSnapshot firstChild() => new ReactiveDataSnapshot.fromStream(
      asStream().map((s) {
        var r = null;
        s.forEach((ss)=>r ??= ss);
        return r;
      }));

  /// Returns the last child of each DataSnapshot in this sequence.
  ReactiveDataSnapshot lastChild() => new ReactiveDataSnapshot.fromStream(
      asStream().map((s) {
        var r = null;
        s.forEach((ss)=>r = ss);
        return r;
      }));


  /// Returns the value of each DataSnapshot in this sequence.
  JsonReactive val() => new JsonReactive.fromStream(asStream().map((s)=>s.val));

  /// Returns the value of each DataSnapshot in this sequence.
  ReactiveBool exists() => new ReactiveBool.fromStream(asStream().map((s)=>s.exists));


  ReactiveIterable<String> path() => new ReactiveIterable.fromStream(
      asStream().map<Iterable<String>>((s)=>s?.ref?.url?.pathSegments)
  );

  ReactiveString key() => new ReactiveString.fromStream(
      asStream().map((s)=>s?.key)
  );

  ReactiveIterable<String> keys() => new ReactiveIterable.fromStream(val().asStream()
      .map<Iterable<String>>((v)=>v is Map<String,dynamic> ? v.keys : const[]));

  ReactiveIterable<dynamic> values() => new ReactiveIterable.fromStream(val().asStream()
      .map<Iterable<dynamic>>((v)=>v is Map<String,dynamic> ? v.values : const[]));

}

class _ReactiveSnapshotFromStream extends _ReactiveValueFromStream<DataSnapshot> with ReactiveDataSnapshot {
  _ReactiveSnapshotFromStream(Stream<DataSnapshot> baseStream) : super(baseStream);
}



class StaticQuery extends Object with ReactiveValue<DataSnapshot>, ReactiveDataSnapshot {

  final Firebase _reference;
  final Iterable<String> _childrenToMerge;
  final QueryFilter _filter;

  StaticQuery(this._reference, [this._childrenToMerge, this._filter]);

  StaticQuery merge(Iterable<String> children) =>
    new StaticQuery(_reference, _childrenToMerge);

  StaticQuery filter(QueryFilter filter) =>
    new StaticQuery(_reference, _childrenToMerge, filter);


  List<Firebase> get referencesToMerge {
    if (_childrenToMerge==null) return [_reference];
    return _childrenToMerge.map((c)=>_reference.child(c)).toList();
  }

  List<Query> get queries => referencesToMerge.map((ref)=>new QueryImpl(ref.url, _filter)).toList();


  @override
  Stream<DataSnapshot> asStream() => (Combine.all(queries.map((q)=>q.onValue.map((e)=>e.snapshot)).toList()) as Stream<List<DataSnapshot>>)
      .map((snapshots)=>_childrenToMerge==null ? snapshots.single : new _MergedDataSnapshot(_reference,snapshots,_filter));
}


class DynamicQuery extends Object with ReactiveValue<DataSnapshot>, ReactiveDataSnapshot {
  final Firebase _firebaseRef;
  final List<ReactiveString> _path;
  final ReactiveIterable<String> _childrenToMerge;
  final ReactiveString _orderBy;
  final ReactiveString _startAt;
  final ReactiveString _endAt;
  final ReactiveInt _limitToFirst;
  final ReactiveInt _limitToLast;

  DynamicQuery(this._firebaseRef, this._path, [this._childrenToMerge,
      this._orderBy, this._startAt, this._endAt, this._limitToFirst,
      this._limitToLast]);

  DynamicQuery orderByKey() => new DynamicQuery(_firebaseRef, _path,
      _childrenToMerge, new ReactiveString.literal(".key"), _startAt, _endAt,
      _limitToFirst, _limitToLast);

  DynamicQuery orderByValue() => new DynamicQuery(_firebaseRef, _path,
      _childrenToMerge, new ReactiveString.literal(".value"), _startAt, _endAt,
      _limitToFirst, _limitToLast);

  DynamicQuery orderByPriority() => new DynamicQuery(_firebaseRef, _path,
      _childrenToMerge, new ReactiveString.literal(".priority"), _startAt,
      _endAt, _limitToFirst, _limitToLast);

  DynamicQuery orderByChild(/*String or ReactiveValue<String>*/child) =>
      new DynamicQuery(_firebaseRef, _path,_childrenToMerge,
          new ReactiveValue.from(child).toReactiveString(), _startAt, _endAt,
          _limitToFirst, _limitToLast);

  DynamicQuery startAt(/*String or ReactiveValue<String>*/v) =>
      new DynamicQuery(_firebaseRef, _path, _childrenToMerge, _orderBy,
          new ReactiveValue.from(v).toReactiveString(), _endAt, _limitToFirst,
          _limitToLast);

  DynamicQuery endAt(/*String or ReactiveValue<String>*/v) =>
      new DynamicQuery(_firebaseRef, _path, _childrenToMerge, _orderBy,
          _startAt, new ReactiveValue.from(v).toReactiveString(), _limitToFirst,
          _limitToLast);

  DynamicQuery limitToFirst(/*int or ReactiveValue<int>*/v) =>
      new DynamicQuery(_firebaseRef, _path, _childrenToMerge, _orderBy,
          _startAt, _endAt, new ReactiveValue.from(v).toReactiveInt(),
          _limitToLast);

  DynamicQuery limitToLast(/*int or ReactiveValue<int>*/v) =>
      new DynamicQuery(_firebaseRef, _path, _childrenToMerge, _orderBy,
          _startAt, _endAt, _limitToFirst,
          new ReactiveValue.from(v).toReactiveInt());

  ReactiveValue<Firebase> _toFirebaseRef() => new ReactiveValue.fromStream(
      new ReactiveList.combine(_path).asStream().map((l) {
        var ref = _firebaseRef;
        for (var i=0;i<l.length;i++) {
          if (_path[i]==null) ref = ref.parent;
          else ref = ref.child(l[i]);
        }
        return ref;
      }));

  ReactiveValue<QueryFilter> _toFilter() => new ReactiveValue.fromStream(
      new ReactiveList.combine(<ReactiveValue>[_orderBy, _startAt, _endAt,
      _limitToFirst, _limitToLast]).asStream().map((l) {
        var orderBy = l[0];
        var startAt = l[1];
        var endAt = l[2];
        var limitToFirst = l[3];
        var limitToLast = l[4];

        return new QueryFilter()
            .copyWith(
            orderBy: orderBy,
            startAtValue: startAt,
            endAtValue: endAt,
            limit: limitToFirst==null ? limitToLast : limitToFirst,
            reverse: limitToLast!=null);
      }));

  @override
  Stream<DataSnapshot> asStream() => new ReactiveList.combine(
      <ReactiveValue>[_toFirebaseRef(), _childrenToMerge, _toFilter()])
      .asStream()
      .map((l)=>new StaticQuery(l[0],l[1],l[2]).asStream())
      .transform<DataSnapshot>(new ConcatAndStopListening<DataSnapshot>());

}

class DynamicReference extends DynamicQuery {


  DynamicReference(Firebase firebaseRef, [List<ReactiveString> path = const[]]) : super(firebaseRef, path);

  DynamicReference child(/*String or ReactiveValue<String>*/childPath) =>
      new DynamicReference(_firebaseRef, new List.from(_path)
        ..add(new ReactiveValue.from(childPath).toReactiveString()));

  DynamicReference parent() =>
      new DynamicReference(_firebaseRef, new List.from(_path)..add(null));

  DynamicReference root() =>
      new DynamicReference(_firebaseRef.root, const []);


  DynamicQuery merge(/*Iterable<String> or ReactiveValue<Iterable<String>>*/children) =>
      new DynamicQuery(_firebaseRef, _path, new ReactiveValue.from(children).toReactiveIterable<String>());
}

