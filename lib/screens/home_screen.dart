import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'contributor/contributor_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.contributor.withOpacity(0.15),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floating: true,
            pinned: true,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.menu, color: AppColors.contributor),
                const SizedBox(width: 12),
                const Text(
                  'Resource Bridge',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBvFWZCVRsl5QsNByFzdNhmVSdT6YvnEloOyjW6Ty79NzMQTkjGS82Lw8qeJSAu2EdrvMM0UYfZwNxVS0_XR8CYRhZ9DpYrtG94lXdFxPoh4in5KYaboH7tyLsyHvZjEhBb1r11_urdtUSiIPMOFndbLsZGqMfLvhpgkASEjpXOWwHDQqUdm6ZJwWc0MBkLbAZyVCAsglMn_1VdIbW7B678Z_J_Joq779jNziwd_Sj7xMR8O2NIz5AtdPmE1VQ1WelO3HHrS1RVlug',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Hero Header
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.contributor, AppColors.ngo],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Turn items into\nopportunity 💚',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Impact Goals (SDG Badges)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSDGBadge('SDG 8', AppColors.ngo),
                      _buildSDGBadge('SDG 12', AppColors.contributor),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Main Donate CTA Card
                  _DonateCTA(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContributorDashboard()),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // How it Works
                  const Text(
                    'How it works',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Vertical Timeline
                  Stack(
                    children: [
                      Positioned(
                        left: 27,
                        top: 16,
                        bottom: 16,
                        child: CustomPaint(
                          painter: _DottedLinePainter(
                            color: const Color(0xFF494455).withOpacity(0.4),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          _buildTimelineStep(
                            '1',
                            'Take photo',
                            'Capture your donation item clearly',
                            AppColors.contributor,
                            AppColors.contributor.withOpacity(0.4),
                            Colors.white,
                          ),
                          const SizedBox(height: 40),
                          _buildTimelineStep(
                            '2',
                            'AI classifies',
                            'Our AI automatically labels your item',
                            AppColors.ngo,
                            AppColors.ngo.withOpacity(0.4),
                            const Color(0xFF00382F),
                          ),
                          const SizedBox(height: 40),
                          _buildTimelineStep(
                            '3',
                            'NGO/Helper receives',
                            'Direct matching with local needs',
                            AppColors.helper,
                            AppColors.helper.withOpacity(0.4),
                            const Color(0xFF4C2700),
                          ),
                          const SizedBox(height: 40),
                          _buildTimelineStep(
                            '4',
                            'Earn rewards',
                            'Get social impact points for every gift',
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                            Colors.white,
                            isBordered: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 128),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSDGBadge(String text, Color dotColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xE6FFFFFF),
                  letterSpacing: 0.88,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String num,
    String title,
    String subtitle,
    Color color,
    Color shadowColor,
    Color textColor, {
    bool isBordered = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 13),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: shadowColor != Colors.transparent
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: isBordered
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          num,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      num,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFCAC3D8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double dashHeight = 2;
    double dashSpace = 6;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonateCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _DonateCTA({required this.onTap});

  @override
  State<_DonateCTA> createState() => _DonateCTAState();
}

class _DonateCTAState extends State<_DonateCTA> {
  bool _isPressed = false;
  bool _isHovered = false;

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
          transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.contributor.withOpacity(0.15),
                blurRadius: 15,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.contributor,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.contributor.withOpacity(0.6),
                            blurRadius: 15,
                            offset: const Offset(4, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Donate an Item',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Empower your community today',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFFCAC3D8),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.contributor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.contributor.withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism,
                                color: AppColors.contributor,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            SizedBox(
                              width: 3 * 20 + 12.0,
                              height: 32,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: _buildAvatar(
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDvbLplU6UV61N9VTStC20XWpxH6U05ZeRa7kbcyHVsKlgzhFuJRDwmOgHLBQmbNwvUOvCcENXEXea0zw0DNwRpb1Zv-AsnF-6kKS9KFZAaKruiL9Rt5_ITOw4f8zLp6psKgnDVtCGeVeod031IMar0-iV8_HD2SHLF0uRa3P0xS1hqps_6hCPv0I0n6Nn732xHf2TrACd472bhAjitjBV4DLNMh5h_ONL9zdJWSUKhsXvyd92V3L_v9P-AQY1FyLZpwa_gBOEsMAs'),
                                  ),
                                  Positioned(
                                    left: 20,
                                    child: _buildAvatar(
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDYNjF0yv7-lFOPGq8FMIlbuRYuv9c_EgiUyjttsuKBECuT9BprbkJHilI1Rr_5t3i5c_qWb_oTYObPPaGvASH1C8jRqQlBbQq9fF4DWxcJN4PXOqLdIsg8lj8ZOtqv2-IumCHPXV01lKweVHreSPSvUkSohEzxlTFVCbVHlEwrjUiBIWkLLcoPaqRdkRycerHfkddvAcEE2GqmYjBAO5wE2a0FAEQcNwWg7mS2m7QfKqtR5hvG_Oq2-sjXyV9UqMbpiPP2EASJ7-g'),
                                  ),
                                  Positioned(
                                    left: 40,
                                    child: _buildAvatar(
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDwFnm38Mz4uojrnk8xK3ik0JP2DwQ-G20QjLbOH8U-7-nmfRmfHoXg9mwBJPRXjI7gV_eQJ7NqOcX82RUg8f-LHYz3W9tuXsqgTQpb_uuYd9ETwKmIIcCQsysTSzuZKKH2xqB1BuMBXvzBdR-Jqs9eU1xQGkGsyfOakOjY2BQueRHu92DAYqQg1H4yBffMcxTNSBhSYe0aL4yrTknamUK13itR_Bfg_JJyno-dR_vG8fDLP3DlgjblYcb0kBTJg2ohi3djbF3Su5M'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              '+12 NGOs active now',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.88,
                                color: AppColors.ngo,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}