import 'package:flutter/material';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;



  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "School Life,\nOrganized.",
      description: "Tired of looking at messy schedules? Schedly converts your registration forms into beautiful, custom-styled planners.",
      imagePath: "assets/onboarding_1.png",
    ),
    OnboardingPageData(
      title: "Snap & Extract",
      description: "Upload a screenshot of your registration certificate, student portal schedule, or text list. Schedly parses it instantly.",
      imagePath: "assets/onboarding_2.png",
    ),
    OnboardingPageData(
      title: "Let's Get Started",
      description: "Create your personalized schedule in seconds. Let's go!",
      imagePath: "assets/onboarding_3.png",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Arrow
                  _currentIndex > 0
                      ? IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      : const SizedBox(width: 48),

                  // Skip Button
                  _currentIndex < 2
                      ? TextButton(
                          onPressed: () => _navigateToLogin(context),
                          child: const Text(
                            "Skip",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : const SizedBox(width: 48),
                ],
              ),
            ),

            // Onboarding Slides (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Illustration
                        Center(
                          child: Container(
                            height: 220,
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Image.asset(
                              page.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Title
                        Text(
                          page.title,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          page.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.6,
                          ),
                        ),

                        // Feature highlights on Slide 3
                        if (index == 2) ...[
                          const SizedBox(height: 24),
                          _buildFeatureItem(
                            Icons.camera_alt_rounded,
                            "Snap & Parse",
                            "Take a photo of your schedule and we'll extract it automatically.",
                            const [Colors.black, Colors.black],
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            Icons.palette_rounded,
                            "Custom Themes",
                            "Personalize your planner with beautiful styles and colors.",
                            const [Colors.black, Colors.black],
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            Icons.download_rounded,
                            "Export Anywhere",
                            "Download as image or PDF and share with your classmates.",
                            const [Colors.black, Colors.black],
                            isDark,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators (only on Slide 1 & 2)
                  if (_currentIndex < 2) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentIndex == index ? 18 : 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Next / Continue Pill Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _navigateToLogin(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _currentIndex == 2 ? "Continue" : "Next",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, List<Color> gradientColors, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
