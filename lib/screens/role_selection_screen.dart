import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';
import '../utils/router.dart';
import 'home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, String role) {
    if (role == AppConstants.roleContributor) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
    final dummyUser = UserModel(
      id: 'guest_$role',
      name: 'Guest ${role[0].toUpperCase()}${role.substring(1)}',
      email: '',
      phone: '',
      role: role,
      location: 'Unknown',
      latitude: 0.0,
      longitude: 0.0,
      createdAt: DateTime.now(),
    );
    AppRouter.navigateToDashboard(context, dummyUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1A1B3A),
              Color(0xFF0B1326),
            ],
            stops: [0.0, 0.6],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.2,
              left: -MediaQuery.of(context).size.width * 0.1,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCDBDFF).withOpacity(0.10),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -MediaQuery.of(context).size.width * 0.1,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF44DDC1).withOpacity(0.05),
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Section
                      const Padding(
                        padding: EdgeInsets.only(bottom: 48.0),
                        child: Column(
                          children: [
                            Text(
                              'RESOURCE BRIDGE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                height: 16 / 11,
                                letterSpacing: 11 * 0.2,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFCAC3D8),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Who are you?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                height: 40 / 32,
                                letterSpacing: -32 * 0.02,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDAE2FD),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Role Cards Container
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          children: [
                            _RoleOption(
                              icon: Icons.inventory_2,
                              title: 'User',
                              subtitle: 'Donate items and earn rewards',
                              color: const Color(0xFFCDBDFF),
                              shadowColor: const Color(0xFF7C4DFF),
                              onTap: () => _selectRole(context, AppConstants.roleContributor),
                            ),
                            const SizedBox(height: 24.0),
                            _RoleOption(
                              icon: Icons.handshake,
                              title: 'NGO',
                              subtitle: 'Receive and manage donated items',
                              color: const Color(0xFF44DDC1),
                              shadowColor: const Color(0xFF44DDC1),
                              onTap: () => _selectRole(context, AppConstants.roleNGO),
                            ),
                            const SizedBox(height: 24.0),
                            _RoleOption(
                              icon: Icons.build,
                              title: 'Helper',
                              subtitle: 'Accept and complete repair tasks',
                              color: const Color(0xFFFFB778),
                              shadowColor: const Color(0xFFFFB778),
                              onTap: () => _selectRole(context, AppConstants.roleHelper),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_RoleOption> createState() => _RoleOptionState();
}

class _RoleOptionState extends State<_RoleOption> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          transformAlignment: Alignment.center,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.color.withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Shimmer-border effect
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 2.0,
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: SweepGradient(
                                  center: Alignment.center,
                                  startAngle: 0.0,
                                  endAngle: 3.141592653589793 * 2,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x0DFFFFFF),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.15, 0.3, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.only(right: 16.0),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.icon, color: widget.color, size: 32),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 24,
                                      height: 32 / 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFDAE2FD),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFCAC3D8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: _isHovered ? widget.color : const Color(0xFFCAC3D8),
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: _isHovered ? widget.color : const Color(0xFFCAC3D8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}