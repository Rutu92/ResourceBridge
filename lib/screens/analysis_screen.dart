import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../utils/constants.dart';
import 'results_screen.dart';
import '../services/blur_detection_service.dart';

class AnalysisScreen extends StatefulWidget {
  final File imageFile;
  final String voiceNote;

  const AnalysisScreen({
    super.key,
    required this.imageFile,
    required this.voiceNote,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _statusText = 'Sending to Gemini AI...';
  Map<String, dynamic>? _result;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _analyze();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    // ── STEP 0: Local blur check before any API call ──────────────────────
    final blurry = await BlurDetectionService.isBlurry(widget.imageFile);
    if (blurry) {
      if (!mounted) return;
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.blur_on, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text(
                'Blurry Image',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your photo is too blurry to analyse. Please retake it in good lighting and hold the camera steady.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF948EA1),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF370096), size: 18),
              label: const Text(
                'Retake Photo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF370096),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
      return;
    }
    

    // ── Blur check passed — proceed with Gemini ───────────────────────────
    final statusMessages = [
      'Sending to Gemini AI...',
      'Analysing image...',
      'Classifying item condition...',
      'Determining repair needs...',
      'Preparing results...',
    ];

    int msgIndex = 0;
    final ticker = Stream.periodic(const Duration(milliseconds: 800))
        .listen((_) {
      if (mounted && msgIndex < statusMessages.length - 1) {
        setState(() => _statusText = statusMessages[++msgIndex]);
      }
    });

    try {
      final gemini = GeminiService();
      final result = await gemini.classifyItem(
        imageFile: widget.imageFile,
        description: widget.voiceNote,
      );

      ticker.cancel();

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      ticker.cancel();
      if (mounted) {
        setState(() {
          _statusText = 'Analysis failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Analysis',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD_mfqoeMQpog1HyOgnc2_JVRnRezgu7eT4L1qMaE4IntHTj4Yxsc6NYtUzpMFIrnunCaOFQ5iMQBVkP63yrKNSurWd74_MzE1X3pk7zxByGgpaoilJXDCKo2htbNLVArSzxcNTcL1uApLP4mdP7KipJrQX9scwx-rHwHxBnuzXQkmblFTYnvXDBnuhF_L88i-MECHLZs21bV2obNCLb04ys2_1R6A18wZsRk5N41p88K_H4l-dlXm9qhhpUXAg2EkkbSIrjUbIkdw'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildResult(),
      bottomNavigationBar: _isLoading || _result == null ? null : _buildBottomAction(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: _pulseAnim.value,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 24 * _pulseAnim.value,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology_outlined,
                      color: AppColors.primary, size: 44),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Gemini is thinking...', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _statusText,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    final delay = i * 0.2;
                    final v = ((_pulseController.value - delay) % 1.0).abs();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3 + v * 0.7),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.warning, size: 48),
            const SizedBox(height: 24),
            const Text('Analysis failed', style: TextStyle(
              fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 12),
            Text(_statusText,
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 16, color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final isRepairable = _result!['classification'] == AppConstants.classRepairable;
    final inputWarning = (_result!['inputWarning'] ?? '').toString().trim();
    final descriptionWarning = (_result!['descriptionWarning'] ?? '').toString().trim();
    final summary = (_result!['summary'] ?? '').toString().trim();
    final voiceDisplay = widget.voiceNote.length > 40
        ? '${widget.voiceNote.substring(0, 40)}...'
        : widget.voiceNote;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Analysis Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRepairable
                    ? AppColors.warning.withOpacity(0.2)
                    : AppColors.secondary.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(widget.imageFile, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.background.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isRepairable
                              ? AppColors.warning.withOpacity(0.2)
                              : AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRepairable
                                ? AppColors.warning.withOpacity(0.3)
                                : AppColors.secondary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          isRepairable ? 'REPAIR REQUIRED' : 'READY TO DONATE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isRepairable ? AppColors.warning : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Input Validation Warnings ──────────────────────────────────────
          if (inputWarning.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      inputWarning,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (descriptionWarning.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      descriptionWarning,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Gemini Understood Section ──────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Gemini Understood',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDAE2FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                _buildUnderstoodRow('Item', (_result!['itemName'] ?? '-').toString()),
                Container(height: 1, color: Colors.white.withOpacity(0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
                _buildUnderstoodRow('Your Input', voiceDisplay),
                Container(height: 1, color: Colors.white.withOpacity(0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
                _buildUnderstoodRow('Condition', (_result!['condition'] ?? '-').toString()),
                Container(height: 1, color: Colors.white.withOpacity(0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Classification',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.88,
                        color: Color(0xFFCAC3D8),
                      ),
                    ),
                    Text(
                      (_result!['classification'] ?? 'usable').toString().toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isRepairable ? AppColors.warning : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  Container(height: 1, color: Colors.white.withOpacity(0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Summary',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.88,
                          color: Color(0xFFCAC3D8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          summary,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFDAE2FD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Next Steps Timeline
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Next Steps',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDAE2FD),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildNextSteps(isRepairable),
        ],
      ),
    );
  }

  Widget _buildUnderstoodRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: Color(0xFFCAC3D8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDAE2FD),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(bool isRepairable) {
    final steps = isRepairable
        ? [
            ('NGO reviews and accepts', 'Verification of your donation request'),
            ('Repair helper assigned', 'Local technician will be matched'),
            ('Item repaired and delivered', 'Refurbishment process and shipping'),
            ('You earn reward points', 'Impact credits added to your profile'),
          ]
        : [
            ('Matched with nearest NGO', 'Analysis routes to closest facility'),
            ('Pickup scheduled', 'Logistics coordination begins'),
            ('Delivered to community', 'Item reaches final recipient'),
            ('You earn reward points', 'Impact credits added to your profile'),
          ];

    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 8,
            bottom: 8,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: steps.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 16),
                      width: isFirst ? 16 : 12,
                      height: isFirst ? 16 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst ? AppColors.primary : const Color(0xFF2D3449),
                        border: isFirst
                            ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 4)
                            : Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.$1,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDAE2FD),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.$2,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.88,
                              color: Color(0xFFCAC3D8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => ResultsScreen(
                    imageFile: widget.imageFile,
                    analysisResult: _result!,
                    voiceNote: widget.voiceNote,
                  ),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
              child: const Text(
                'Proceed to Submit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF370096),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'POWERED BY GEMINI AI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.88,
              color: const Color(0xFFCAC3D8).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}