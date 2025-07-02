import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../main.dart' show DuotoneThemeExtension;

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final bool showStreak;
  final Widget? streakWidget;
  
  const ModernAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.height = 56.0,
    this.showStreak = false,
    this.streakWidget,
  });
  
  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneExt?.isDuotoneTheme == true;
    final brightness = Theme.of(context).brightness;
    
    // Determine colors
    final backgroundColor = isDuotone
        ? duotoneExt!.duotoneColor1!.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8);
        
    final foregroundColor = isDuotone
        ? duotoneExt!.duotoneColor2!
        : Theme.of(context).colorScheme.onSurface;
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
      ),
    );
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isDuotone 
                ? duotoneExt!.duotoneColor2 
                : Theme.of(context).colorScheme.primary)!
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: height + MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: foregroundColor.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    if (title != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showStreak && streakWidget != null) ...[
                      streakWidget!,
                      const SizedBox(width: 12),
                    ],
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}