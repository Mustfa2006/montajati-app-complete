import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import 'statistics_page.dart';
import 'top_products_page.dart';

class StatisticsWithTabsPage extends StatefulWidget {
  const StatisticsWithTabsPage({super.key});

  @override
  State<StatisticsWithTabsPage> createState() => _StatisticsWithTabsPageState();
}

class _StatisticsWithTabsPageState extends State<StatisticsWithTabsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            StatisticsPage(
              isInsideTabView: true,
              currentTabIndex: _currentIndex,
              onTabChanged: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            TopProductsPage(
              isInsideTabView: true,
              currentTabIndex: _currentIndex,
              onTabChanged: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
