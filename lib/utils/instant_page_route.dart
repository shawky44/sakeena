import 'package:flutter/material.dart';

class InstantPageRoute<T> extends MaterialPageRoute<T> {
  InstantPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
