import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:turf/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Claim Your Territory',
      'lottie': 'https://assets2.lottiefiles.com/packages/lf20_6sxyjynd.json',
    },
    {
      'title': 'Compete. Dominate. Rise.',
      'lottie': 'https://assets4.lottiefiles.com/packages/lf20_tll0j4bb.json',
    },
    {
      'title': 'Earn Rewards Every Step',
      'lottie': 'https://assets6.lottiefiles.com/packages/lf20_touohxv0.json',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Lottie.network(
                        _slides[index]['lottie']!,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.map, size: 100, color: AppTheme.primaryColor),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        _slides[index]['title']!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Skip'),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                if (_currentPage == _slides.length - 1)
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Get Started'),
                  )
                else
                  IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
