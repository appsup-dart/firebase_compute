# firebase_compute

[![Build Status](https://travis-ci.org/appsup-dart/firebase_compute.svg?branch=master)](https://travis-ci.org/appsup-dart/firebase_compute)

Library for doing reactive computations with firebase.




## Usage

A simple, yet powerful usage example!

Given a Firebase instance containing events in a calendar, the following code will print the next appointment.


    import 'package:firebase_compute/firebase_compute.dart';
    import 'package:firebase_dart/firebase_dart.dart';
    import 'dart:async';
    
    main() async {
      var ref = new Firebase("https://my-project.firebaseio.com");
    
      var data = new DynamicReference(ref); // create a reactive version of a firebase reference
    
      data
          .child("calendar").child("events")    // reference the subtree at /calendar/events
          .orderByChild("startTime").limitToFirst(1) // order by child startTime and limit to first result
          .startAt(new ReactiveDateTime.now().toIso8601String())  // start at the current time
          .firstChild() // move to the first child
          .val()
          .asStream().forEach((v)=>print("your next appointment is at ${v["startTime"]}: ${v["description"]}"));
    
      ref.child("calendar").child("events").push({
        "startTime": new DateTime.now().add(new Duration(hours: 4)).toIso8601String(),
        "description": "hairdresser"
      });  // will print "your next appointment is at ... : hairdresser"
    
      await new Future.delayed(new Duration(seconds: 2));
    
      ref.child("calendar").child("events").push({
        "startTime": new DateTime.now().add(new Duration(seconds: 10)).toIso8601String(),
        "description": "doctor"
      });  // will print "your next appointment is at ... : doctor"
    
      // after 10 seconds will print "your next appointment is at ... : hairdresser"
    
    
    
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/appsup-dart/firebase_compute/issues
