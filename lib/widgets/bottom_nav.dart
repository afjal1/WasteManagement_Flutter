import 'package:flutter/material.dart';

import '../pages/home.dart';
import '../pages/dispose/dispose_waste.dart';
import '../pages/recycle/recycle_waste.dart';
import '../pages/decluster/decluster.dart';
import '../pages/info_center/info.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final List _routes = [
    HomePage(),
    DisposeWastePage(),
    RecycleWastePage(),
    DeclusterPage(),
    InfoPage()
  ];

  BottomNav(this.index);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      fixedColor: Colors.green,
      currentIndex: index,
      onTap: (int idx) {
        if (idx == index) return;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (BuildContext context) => _routes[idx]),
            (Route route) => false);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.delete,
            ),
            label: 'Dispose'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.sync,
            ),
            label: 'Recycle'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.zoom_out_map,
            ),
            backgroundColor: Colors.green,
            label: 'Decluster'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.info,
            ),
            label: 'Info'),
      ],
    );
  }
}
