import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);
  static const Color border = Color(0xFF2A2A3A);

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryGlow = Color(0x336C63FF);
  static const Color secondary = Color(0xFF00D9A3);
  static const Color secondaryGlow = Color(0x3300D9A3);
  static const Color warning = Color(0xFFFF6B35);
  static const Color warningGlow = Color(0x33FF6B35);

  static const Color contributor = Color(0xFF6C63FF);
  static const Color ngo = Color(0xFF00D9A3);
  static const Color helper = Color(0xFFFF6B35);
  static const Color admin = Color(0xFFFFD700);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF4A4A6A);

  static const Color statusPending = Color(0xFFFFB800);
  static const Color statusActive = Color(0xFF00D9A3);
  static const Color statusCompleted = Color(0xFF6C63FF);
  static const Color statusRepair = Color(0xFFFF6B35);
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 2.0,
  );
}

class AppConstants {
  static const String roleContributor = 'contributor';
  static const String roleNGO = 'ngo';
  static const String roleHelper = 'helper';
  static const String roleAdmin = 'admin';

  static const String statusPending = 'pending';
  static const String statusClassified = 'classified';
  static const String statusMatched = 'matched';
  static const String statusPickupScheduled = 'pickup_scheduled';
  static const String statusInRepair = 'in_repair';
  static const String statusRepaired = 'repaired';
  static const String statusDelivered = 'delivered';
  static const String statusCompleted = 'completed';

  static const String classUsable = 'usable';
  static const String classRepairable = 'repairable';
  static const String classUnsuitable = 'unsuitable';

  static const int pointsUpload = 10;
  static const int pointsDelivered = 50;
  static const int pointsRepaired = 75;
  static const int pointsNgoAccepted = 20;

  static const String colUsers = 'users';
  static const String colItems = 'items';
  static const String colNGOs = 'ngos';
  static const String colRepairTasks = 'repair_tasks';
  static const String colRewards = 'rewards';
  static const String colNotifications = 'notifications';
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
}
