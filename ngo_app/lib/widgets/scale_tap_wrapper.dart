import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper that adds a subtle scale-down animation on press to any child widget.
///
/// Wrapping list cards (e.g. _MemberCard, _DonorCard, _CategoryFolderCard) with
/// this gives the entire app a more responsive, tactile feel without requiring
/// changes inside individual card widgets.
class ScaleTapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale factor when the widget is pressed. Default is 0.98 for a subtle effect.
  final double pressedScale;

  const ScaleTapWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
  });

  @override
  State<ScaleTapWrapper> createState() => _ScaleTapWrapperState();
}

class _ScaleTapWrapperState extends State<ScaleTapWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
