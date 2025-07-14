import 'package:flutter/material.dart';

enum ScreenSize {
  small, // Mobile
  medium, // Tablet
  large, // Desktop
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return builder(context, ScreenSize.small);
        } else if (constraints.maxWidth < 1200) {
          return builder(context, ScreenSize.medium);
        } else {
          return builder(context, ScreenSize.large);
        }
      },
    );
  }
}

// Extension methods to check screen size
extension ScreenSizeExtension on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    if (width < 600) {
      return ScreenSize.small;
    } else if (width < 1200) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  bool get isSmallScreen => screenSize == ScreenSize.small;
  bool get isMediumScreen => screenSize == ScreenSize.medium;
  bool get isLargeScreen => screenSize == ScreenSize.large;
}
