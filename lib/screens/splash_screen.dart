import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Splash screen displaying the Cilalutask logo in the center with a
/// single-cycle Fade-In, Hold, and Fade-Out animation (~2.5 seconds total),
/// subtle scale effect, and a time-synchronized loading indicator.
class SplashScreen extends StatefulWidget {
  /// Callback triggered when the fade-in & fade-out sequence completes.
  final VoidCallback? onCompleted;

  /// Optional target screen to navigate to automatically via pushReplacement
  /// if [onCompleted] is not used to switch state in the parent widget.
  final Widget? nextScreen;

  /// Total animation duration (defaults to 2500ms: 900ms fade-in, 800ms hold, 800ms fade-out).
  final Duration duration;

  const SplashScreen({
    super.key,
    this.onCompleted,
    this.nextScreen,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    // 2500ms breakdown:
    // - Fade In : 900ms (weight 36)
    // - Hold    : 800ms (weight 32)
    // - Fade Out: 800ms (weight 32)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 32),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 32,
      ),
    ]).animate(_controller);

    // Subtle scale effect synchronized with fade phases
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 32),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 32,
      ),
    ]).animate(_controller);

    // Loading progress synchronized from 0.0 to 1.0 across the splash duration
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener(_handleAnimationStatus);
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else if (widget.nextScreen != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen!,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final logoSize = (screenSize.shortestSide * 0.58).clamp(140.0, 260.0);
    final indicatorWidth = (logoSize * 0.72).clamp(120.0, 190.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final opacity = _opacityAnimation.value.clamp(0.0, 1.0);
                  final scale = _scaleAnimation.value;
                  final progress = _progressAnimation.value.clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Logo Cilalutask',
                            image: true,
                            child: Image.asset(
                              'cilalutask_logo.png',
                              key: const ValueKey('splash_logo_image'),
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: const Center(
                                    child: Icon(
                                      Icons.task_alt_rounded,
                                      size: 72,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: indicatorWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    key: const ValueKey(
                                      'splash_circular_indicator',
                                    ),
                                    value: progress,
                                    strokeWidth: 2.5,
                                    backgroundColor: AppColors.primaryLight,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    key: const ValueKey(
                                      'splash_loading_indicator',
                                    ),
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: AppColors.primaryLight,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
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
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
