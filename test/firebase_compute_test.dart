// Copyright (c) 2017, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:firebase_compute/firebase_compute.dart';
import 'package:firebase_dart/firebase_dart.dart';
import 'package:test/test.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'dart:io';

void main() {
  StreamSubscription logSubscription;

  Firebase mainRef;

  setUp(() async {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen(print);
    mainRef = new Firebase(Platform.environment["FIREBASE_URL"]);
    if (Platform.environment.containsKey("FIREBASE_SECRET"))
      await mainRef.authWithCustomToken(Platform.environment["FIREBASE_SECRET"]);
  });
  tearDown(() {
    logSubscription?.cancel();
  });

  group('Operations', () {
    DynamicReference data;
    Firebase ref;

    setUp(() async {
      ref = mainRef.child('cars').child('car001');
      data = new DynamicReference(ref);
    });

    test('Comparison', () async {
      await ref.child('status').child('fuel_level').set(50);
      var cond = data.child('status').child('fuel_level').val() >= 70;
      var l = cond.asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('status').child('fuel_level').set(90);
      expect(await l, [false, true]);
    });

    test('Equality', () async {
      await ref.child('status').child('fuel_level').set(50);
      var cond = data.child('status').child('fuel_level').val().equals(90);
      var l = cond.asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('status').child('fuel_level').set(90);
      expect(await l, [false, true]);
    });

    test('Math', () async {
      await ref.child('status').child('fuel_level').set(50);
      var v = ((data.child('status').child('fuel_level').val() + 5) * 2 - 3) ~/
          2 / 3;
      var l = v.asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('status').child('fuel_level').set(90);
      expect(await l, [53 / 3, 93 / 3]);
    });

    test('Logic', () async {
      await ref.child('status').child('fuel_level').set(50);
      var cond1 = data.child('status').child('fuel_level').val() > 70;
      var cond2 = data.child('status').child('fuel_level').val() < 70;
      var cond = cond1.or(cond2).not();
      var l = cond.asStream().take(3).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('status').child('fuel_level').set(70);
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('status').child('fuel_level').set(90);
      expect(await l, [false, true, false]);
    });
  });

  group('Query', () {
    DynamicReference data;
    Firebase ref;

    setUp(() async {
      ref = mainRef.child('cars');
      data = new DynamicReference(ref);

      await ref.set({
        "car001": {
          "name": "abc"
        },
        "car002": {
          "name": "def"
        },
      });
    });

    test('Order', () async {
      var l = data.orderByChild('name').keys().asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('car001').child('name').set('ghi');
      expect(await l, [["car001","car002"],["car002","car001"]]);
      await ref.child('car001').child('name').set('abc');
    });

    test('Limit', () async {
      var l = data.orderByChild('name').startAt('a').limitToFirst(1).keys().asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('car001').child('name').set('ghi');
      print((await l).runtimeType);
      print(await l);
      expect(await l, [["car001"],["car002"]]);
      await ref.child('car001').child('name').set('abc');
    });

    test('Start', () async {
      var l = data.orderByChild('name').startAt('b').limitToLast(1).keys().asStream().take(2).toList();
      await new Future.delayed(new Duration(milliseconds: 400));
      await ref.child('car001').child('name').set('ghi');
      expect(await l, [["car002"],["car001"]]);
      await ref.child('car001').child('name').set('abc');
    });


  });

  group('Value as argument', () {
    DynamicReference data;
    Firebase ref;

    setUp(() async {
      ref = mainRef.child('cars');
      data = new DynamicReference(ref);

      await ref.set({
        "car001": {
          "status": {
            "fuel_level": 50
          }
        },
        "car002": {
          "status": {
            "fuel_level": 30
          }
        },
      });
    });

    test('In child', () async {
      var cars = ["car001","car002"];
      var carsValue = new ReactiveOperableValue.fromStream(new Stream.periodic(new Duration(milliseconds: 200), (i)=>cars[i]).take(2));

      var v = data.child(carsValue).child('status').child('fuel_level').val();
      var l = v.asStream().take(2).toList();
      expect(await l, [50,30]);
    });

    test('In startAt', () async {
      var cars = ["car001","car002"];
      var carsValue = new ReactiveOperableValue.fromStream(new Stream.periodic(new Duration(milliseconds: 200), (i)=>cars[i]).take(2));

      var v = data.orderByKey().startAt(carsValue).limitToFirst(1).keys();
      var l = v.asStream().take(2).toList();
      expect(await l, [["car001"],["car002"]]);

    });

  });

  group('DateTimeValue', ()
  {
    DynamicReference data;
    Firebase ref;

    setUp(() async {
      ref = mainRef.child('cars');
      data = new DynamicReference(ref);
    });

    test('startAt now', () async {

      ref.orderByKey().limitToFirst(1).startAt("car002").onValue.listen(print);

      var now = new ReactiveDateTime.now();

      var f = new DateFormat("yyyyMMdd-HHmmss");

      await ref.child('reservations').set({
        f.format(new DateTime.now().add(new Duration(seconds: 4))): "first",

        f.format(new DateTime.now().add(new Duration(seconds: 8))): "second",

        f.format(new DateTime.now().add(new Duration(seconds: 12))): "third",

      });

      await new Future.delayed(new Duration(milliseconds: 400));

      var l = data.child('reservations').orderByKey().limitToFirst(1)
      .startAt(now.format("yyyyMMdd-HHmmss")).values().first().asStream()
      .map((v) {print("got $v");return v;}).take(2).toList();

      expect(await l, ["first","second"]);
    });
  });

  group('Merge', () {
    DynamicReference data;
    Firebase ref;

    setUp(() async {
      ref = mainRef.child('cars');
      data = new DynamicReference(ref);
      await ref.set({
        "car001": {
          "20170101": {
            "duration": 50
          }
        },
        "car002": {
          "20170102": {
            "duration": 30
          }
        },
      });
    });

    test('Merge', () async {

      var v = data.merge(["car001","car002"]).orderByKey().limitToFirst(1).keys().first();

      var l = v.asStream().take(2).map((v) {print("got $v");return v;}).toList();

      await new Future.delayed(new Duration(milliseconds: 500));
      ref.child("car001").remove();

      expect(await l, ["20170101","20170102"]);
    });
  });
}
