import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/repair_task_model.dart';
import '../screens/home_screen.dart';
import '../screens/contributor/contributor_dashboard.dart';
import '../screens/ngo/ngo_dashboard.dart';
import '../screens/helper/helper_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/helper/helper_chat_screen.dart';
import '../screens/ngo/ngo_helper_chat_screen.dart';
import '../utils/constants.dart';

class AppRouter {
  static const String home = '/';
  static const String contributorDashboard = '/contributor';
  static const String ngoDashboard = '/ngo';
  static const String helperDashboard = '/helper';
  static const String adminDashboard = '/admin';
  static const String helperChat = '/helper-chat';
  static const String ngoHelperChat = '/ngo-helper-chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case contributorDashboard:
        return MaterialPageRoute(
            builder: (_) => const ContributorDashboard());

      case ngoDashboard:
        return MaterialPageRoute(builder: (_) => const NGODashboard());

      case helperDashboard:
        return MaterialPageRoute(builder: (_) => const HelperDashboard());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case helperChat:
        final task = settings.arguments as RepairTaskModel;
        return _slideRoute(HelperChatScreen(task: task));

      case ngoHelperChat:
        final task = settings.arguments as RepairTaskModel;
        return _slideRoute(NgoHelperChatScreen(task: task));

      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  /// Navigates to the role dashboard while keeping RoleSelectionScreen
  /// at the bottom of the stack, so back-press returns to it instead
  /// of quitting the app.
  static void navigateToDashboard(BuildContext context, UserModel user) {
    String route;
    switch (user.role) {
      case AppConstants.roleNGO:
        route = ngoDashboard;
        break;
      case AppConstants.roleHelper:
        route = helperDashboard;
        break;
      case AppConstants.roleAdmin:
        route = adminDashboard;
        break;
      default:
        route = contributorDashboard;
    }
    // pushNamed instead of pushNamedAndRemoveUntil — preserves the
    // RoleSelectionScreen beneath so back-press works correctly.
    Navigator.pushNamed(context, route);
  }

  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(context, _slideRoute(screen));
  }

  static PageRouteBuilder<T> _slideRoute<T>(Widget screen) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => screen,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}