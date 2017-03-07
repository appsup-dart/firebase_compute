
part of firebase_compute;


class JsonReactive extends _ReactiveValueFromStream with CompareOperable {
  JsonReactive.fromStream(Stream stream) : super(stream.distinct((a,b)=>const DeepCollectionEquality().equals(a,b)));

  factory JsonReactive.computed(Iterable values, Function computation) =>
      new JsonReactive.fromStream(
          Combine.all(values.map((v)=>new ReactiveValue.from(v).asStream()).toList())
              .map((l)=>Function.apply(computation,l)));

  JsonReactive operator+(other) => new JsonReactive.computed([this, other],(a,b)=>a==null||b==null ? null : a+b);
  JsonReactive operator-(other) => new JsonReactive.computed([this, other],(a,b)=>a==null||b==null ? null : a-b);
  JsonReactive operator*(other) => new JsonReactive.computed([this, other],(a,b)=>a==null||b==null ? null : a*b);
  JsonReactive operator/(other) => new JsonReactive.computed([this, other],(a,b)=>a==null||b==null ? null : a/b);
  JsonReactive operator~/(other) => new JsonReactive.computed([this, other],(a,b)=>a==null||b==null ? null : a~/b);

  ReactiveBool not() => new ReactiveValue.computed([this],(v)=>v==null ? null : !(v as bool)).toReactiveBool();
  ReactiveBool and(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a&&b).toReactiveBool();
  ReactiveBool or(other) => new ReactiveValue.computed([this, other],(a,b)=>a==null||b==null ? null : a||b).toReactiveBool();

}