part of firebase_compute;

/// Represents a sequence of values.
///
/// Subclasses that specialize on the generic value type, can implement methods
/// that act on each value in the sequence and return the result as a
/// ReactiveValue.
abstract class ReactiveValue<T> {

  /// Creates a reactive value from another reactive value or a literal.
  factory ReactiveValue.from(/*T or Stream<T>*/ v) => v is ReactiveValue<T> ? v : new ReactiveValue<T>.literal(v);

  /// Creates a reactive value from a stream of values.
  factory ReactiveValue.fromStream(Stream<T> stream) => new _ReactiveValueFromStream(stream);

  /// Creates a reactive value from a literal.
  factory ReactiveValue.literal(T v) => new ReactiveValue.fromStream(new Stream.fromIterable([v]));

  /// Creates a reactive value by executing the computation function on the
  /// values.
  factory ReactiveValue.computed(Iterable values, Function computation) =>
      new ReactiveValue.fromStream(
          Combine.all(values.map((v)=>new ReactiveValue.from(v).asStream()).toList())
              .map((l)=>Function.apply(computation,l)));

  /// Returns the sequence of values as a stream.
  Stream<T> asStream();

  /// Combines with another (reactive) value, returning a reactive list.
  ReactiveIterable combine(other) => new ReactiveIterable.fromStream(
      Combine.all([asStream(), new ReactiveValue.from(other).asStream()]));

  /// Checks for equality with another (reactive) value, returning a reactive bool.
  ReactiveBool equals(other) => new ReactiveValue<bool>.computed([this,other],(a,b)=>a==b).toReactiveBool();

  /// Converts this reactive value to a ReactiveBool.
  ///
  /// Will throw an error when one of the values is not a bool.
  ReactiveBool toReactiveBool() => new ReactiveBool.fromStream(asStream() as Stream<bool>);

  /// Converts this reactive value to a ReactiveNumber.
  ///
  /// Will throw an error when one of the values is not a num.
  ReactiveNumber toReactiveNumber() => new ReactiveNumber.fromStream(asStream() as Stream<num>);

  /// Converts this reactive value to a ReactiveString.
  ///
  /// Will throw an error when one of the values is not a String.
  ReactiveString toReactiveString() => new ReactiveString.fromStream(asStream() as Stream<String>);

  /// Converts this reactive value to a ReactiveInt.
  ///
  /// Will throw an error when one of the values is not an int.
  ReactiveInt toReactiveInt() => new ReactiveInt.fromStream(asStream() as Stream<int>);

  /// Converts this reactive value to a ReactiveDouble.
  ///
  /// Will throw an error when one of the values is not a double.
  ReactiveDouble toReactiveDouble() => new ReactiveDouble.fromStream(asStream() as Stream<double>);

  /// Converts this reactive value to a ReactiveIterable.
  ///
  /// Will throw an error when one of the values is not an iterable.
  ReactiveIterable<S> toReactiveIterable<S>() => new ReactiveIterable.fromStream(asStream() as Stream<Iterable<S>>);

}


/// Mixin for reactive value types where the value type supports compare operations.
abstract class CompareOperable<T> implements ReactiveValue<T> {
  ReactiveBool operator>=(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : Comparable.compare(a,b)>=0).toReactiveBool();
  ReactiveBool operator<=(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : Comparable.compare(a,b)<=0).toReactiveBool();
  ReactiveBool operator>(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : Comparable.compare(a,b)>0).toReactiveBool();
  ReactiveBool operator<(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : Comparable.compare(a,b)<0).toReactiveBool();
}

/// Mixin for reactive value types where the value type supports mathematical operations.
abstract class MathOperable<T> implements ReactiveValue<T> {
  ReactiveValue operator+(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a+b);
  ReactiveValue operator-(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a-b);
  ReactiveValue operator*(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a*b);
  ReactiveValue operator/(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a/b);
  ReactiveValue operator~/(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a~/b);
}

class ReactiveBool extends _ReactiveValueFromStream<bool> {
  ReactiveBool.fromStream(Stream<bool> stream) : super(stream);
  factory ReactiveBool.literal(bool v) => new ReactiveBool.fromStream(new Stream.fromIterable([v]));

  ReactiveBool not() => new ReactiveValue.computed([this],(v)=>v==null ? null : !(v as bool)).toReactiveBool();
  ReactiveBool and(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a&&b).toReactiveBool();
  ReactiveBool or(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a||b).toReactiveBool();
}

class ReactiveNumber<T extends num> extends _ReactiveValueFromStream<T> with CompareOperable<T>, MathOperable<T> {
  ReactiveNumber.fromStream(Stream<T> stream) : super(stream);
  factory ReactiveNumber.literal(T v) => new ReactiveNumber.fromStream(new Stream.fromIterable([v]));
}

class ReactiveInt extends ReactiveNumber<int> {
  ReactiveInt.fromStream(Stream<int> stream) : super.fromStream(stream);
  factory ReactiveInt.literal(int v) => new ReactiveInt.fromStream(new Stream.fromIterable([v]));
}

class ReactiveDouble extends ReactiveNumber<double> {
  ReactiveDouble.fromStream(Stream<double> stream) : super.fromStream(stream);
  factory ReactiveDouble.literal(double v) => new ReactiveDouble.fromStream(new Stream.fromIterable([v]));
}

class ReactiveString extends _ReactiveValueFromStream<String> with CompareOperable<String> {
  ReactiveString.fromStream(Stream<String> stream) : super(stream);
  factory ReactiveString.literal(String v) => new ReactiveString.fromStream(new Stream.fromIterable([v]));


}

class ReactiveIterable<T> extends _ReactiveValueFromStream<Iterable<T>> {
  ReactiveIterable.fromStream(Stream<Iterable<T>> stream) : super(stream);


  ReactiveValue<T> first() => new ReactiveValue.fromStream(asStream().map((l)=>l.isNotEmpty ? l.first : null));
  ReactiveValue<T> last() => new ReactiveValue.fromStream(asStream().map((l)=>l.isNotEmpty ? l.last : null));
  ReactiveInt length() => new ReactiveInt.fromStream(asStream().map((l)=>l.length));
  ReactiveBool isEmpty() => new ReactiveBool.fromStream(asStream().map((l)=>l.isEmpty));
  ReactiveBool isNotEmpty() => isEmpty().not();

  ReactiveString join([String separator = ""]) => new ReactiveString.fromStream(asStream().map((l)=>l?.join(separator)));

  ReactiveIterable<T> skip(int count) => new ReactiveIterable.fromStream(asStream().map((l)=>l?.skip(count)));
  ReactiveIterable<T> take(int count) => new ReactiveIterable.fromStream(asStream().map((l)=>l?.take(count)));

  ReactiveList<T> toList() => new ReactiveList.fromStream(asStream().map((l)=>l.toList()));
}

class ReactiveList<T> extends ReactiveIterable<T> {
  ReactiveList.fromStream(Stream<List<T>> stream) : super.fromStream(stream);
  ReactiveList.combine(Iterable<ReactiveValue<T>> values) : this.fromStream(
      Combine.all(values.map((l)=>l?.asStream() ?? new Stream.fromIterable(const [null])).toList())
  );

  @override
  Stream<List<T>> asStream() => super.asStream();
}

class ReactiveDateTime extends _ReactiveValueFromStream<DateTime> {

  ReactiveDateTime.fromStream(Stream<DateTime> stream) : super(stream);

  ReactiveDateTime.now({Duration interval: const Duration(seconds: 1)}) :
        this.fromStream(new Stream.periodic(interval).asBroadcastStream().map((_)=>new DateTime.now()));

  ReactiveString format(String pattern) {
    var formatter = new DateFormat(pattern);
    return new ReactiveString.fromStream(asStream().map((v)=>formatter.format(v)));
  }

  ReactiveString toIso8601String() => new ReactiveString.fromStream(asStream().map((v)=>v.toIso8601String()));

  ReactiveDateTime add(/*String or Duration*/ duration) {
    var d = duration is Duration ? duration : _parseDuration(duration);
    return new ReactiveDateTime.fromStream(asStream().map((v)=>v.add(d)));
  }
  ReactiveDateTime subtract(/*String or Duration*/ duration) {
    var d = duration is Duration ? duration : _parseDuration(duration);
    return new ReactiveDateTime.fromStream(asStream().map((v)=>v.subtract(d)));
  }

  static Duration _parseDuration(String formattedString) {
    var parts = formattedString.trim().split(new RegExp(r"\s+"));
    var v = int.parse(parts[0]);
    switch (parts[1].trim()) {
      case "days":
      case "day":
        return new Duration(days: v);
      case "hours":
      case "hour":
        return new Duration(hours: v);
      case "minutes":
      case "minute":
        return new Duration(minutes: v);
      case "seconds":
      case "second":
        return new Duration(seconds: v);
      case "milliseconds":
      case "millisecond":
        return new Duration(milliseconds: v);
      case "microseconds":
      case "microsecond":
        return new Duration(microseconds: v);
      default:
        throw new FormatException("Unable to parse duration '$formattedString'");
    }
  }
}



class ReactiveOperableValue<T> extends _ReactiveValueFromStream<T> with MathOperable<T>, CompareOperable<T> {
  ReactiveOperableValue.fromStream(Stream<T> stream) : super(stream);
  factory ReactiveOperableValue.literal(T v) => new ReactiveOperableValue.fromStream(new Stream.fromIterable([v]));
}


class _ReactiveValueFromStream<T> extends Object with ReactiveValue<T> {

  final Stream<T> _stream;

  _ReactiveValueFromStream(Stream<T> stream) : _stream = stream.distinct();

  @override
  Stream<T> asStream() => _stream;
}


class ConcatAndStopListening<T> implements StreamTransformer<Stream<T>, T> {

  StreamSubscription<Stream<T>> streamOfStreamSubcription;
  StreamSubscription<T> valueSubscription;


  @override
  Stream<T> bind(Stream<Stream<T>> stream) {
    StreamController<T> controller;
    controller = new StreamController<T>(
        onListen: () {
          streamOfStreamSubcription = stream.listen((stream) {
            valueSubscription?.cancel();
            valueSubscription = stream.listen((v) {
              controller.add(v);
            });
          });
        },
        onPause: () {
          valueSubscription.pause();
          streamOfStreamSubcription.pause();
        },
        onResume: () {
          streamOfStreamSubcription.resume();
          valueSubscription.resume();
        },
        onCancel: () {
          streamOfStreamSubcription.cancel();
          valueSubscription.cancel();
        }
    );
    return controller.stream;
  }
}
