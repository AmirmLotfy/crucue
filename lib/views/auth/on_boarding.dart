import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/logic/cache_helper.dart';
import 'package:crucue/views/auth/login_or_register.dart';

import '../../core/design/app_button.dart';
import '../../core/branding/crucue_brand_logo.dart';
import '../../core/logic/helper_methods.dart';
import '../../core/theme.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  int _currentPage = 0;
  final _pageController = PageController();

  static const _pages = [
    _OnboardingPage(
      emoji: '💛',
      title: 'You\'re not alone\nin this.',
      description:
          'Caring for someone you love is one of the most important things you\'ll do. Crucue is here to help you do it with more confidence and calm.',
      lightColor: Color(0xffFFF0E6),
      darkColor: Color(0x1FFF4F00),
    ),
    _OnboardingPage(
      emoji: '🗺️',
      title: 'A plan for\nevery moment.',
      description:
          'Log a challenge, and Crucue creates a personal support plan — with clear steps, calming strategies, and a suggested message to your loved one.',
      lightColor: Color(0xffE8F5E9),
      darkColor: Color(0x1F4CAF50),
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: 'Private.\nJust for you.',
      description:
          'Your care notes are yours alone. Crucue keeps everything private and encrypted — never shared, never sold.',
      lightColor: Color(0xffE3F2FD),
      darkColor: Color(0x1F2196F3),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToApp() async {
    await CacheHelper.setNotFirstTime();
    navigateTo(const LoginOrRegisterView());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CrucueBrandLogo(
                    forDarkBackground: isDark,
                    maxHeight: 36.h,
                    maxWidth: 160.w,
                    alignment: Alignment.centerLeft,
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _goToApp,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _PageContent(page: _pages[i]),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: 6.h,
                    width: _currentPage == i ? 24.w : 6.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: _currentPage == i
                          ? AppTheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      bottomNavigationBar: AppButton(
        text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
        type: ButtonType.bottomNav,
        onPress: () async {
          if (_currentPage == _pages.length - 1) {
            await _goToApp();
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 120.h,
              height: 120.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: page.colorFor(Theme.of(context).brightness),
                shape: BoxShape.circle,
              ),
              child: Text(
                page.emoji,
                style: TextStyle(fontSize: 56.sp),
              ),
            ),
            SizedBox(height: 40.h),
            Text(
              page.title,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Text(
              page.description,
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  final Color lightColor;
  final Color darkColor;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
    required this.lightColor,
    required this.darkColor,
  });

  Color colorFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkColor : lightColor;
}
