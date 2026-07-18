import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  static const _slides = [
    _Slide(
      gradient: AppColors.heroGradient,
      icon: Icons.groups_2_rounded,
      title: 'Discover Your Tribe',
      subtitle: 'Explore all clubs at KIET — from coding and robotics to music and entrepreneurship. Find where you belong.',
    ),
    _Slide(
      gradient: LinearGradient(colors: [Color(0xFF0E7490), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      icon: Icons.calendar_today_rounded,
      title: 'Never Miss an Event',
      subtitle: 'Get notified about workshops, hackathons, seminars and fests happening on campus. Register in one tap.',
    ),
    _Slide(
      gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      icon: Icons.diversity_3_rounded,
      title: 'Find Your Team',
      subtitle: 'Looking for a hackathon teammate? Post a Team Up request and connect with the right people instantly.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      if (_current < _slides.length - 1) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: _finish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Center(child: Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('Next', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                            ),
                          ),
                        ),
                      ] else
                        Expanded(
                          child: GestureDetector(
                            onTap: _finish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)],
                              ),
                              child: const Center(
                                child: Text("Let's Go 🚀",
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: slide.gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 180),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 48),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _Slide({required this.gradient, required this.icon, required this.title, required this.subtitle});
}