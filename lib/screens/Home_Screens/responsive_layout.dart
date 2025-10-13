import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileview;
  final Widget tabletview;
  final Widget desktopview;

  ResponsiveLayout({
    required this.mobileview,
    required this.tabletview,
    required this.desktopview,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < maxMobilewidth) {
          return mobileview;
        } else if (constraints.maxWidth < maxTabletwidth) {
          return mobileview;
        } else {
          return desktopview;
        }
      },
    );
  }
}
