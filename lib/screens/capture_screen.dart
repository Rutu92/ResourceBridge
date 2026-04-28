import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/gemini_service.dart';
import 'analysis_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _selectedImage;
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isProceeding = false;

  // Translation preview state
  String? _translatedDesc;
  bool _isTranslating = false;
  bool _showTranslationTab = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  String? _detectedLanguage;

  Future<void> _previewTranslation() async {
    final text = _descController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isTranslating = true;
      _showTranslationTab = true;
      _translatedDesc = null;
      _detectedLanguage = null;
    });
    final result = await _translateToEnglish(text);
    final isAlreadyEnglish = result.trim() == text.trim();
    if (mounted) {
      setState(() {
        _translatedDesc = result;
        _isTranslating = false;
        _detectedLanguage = isAlreadyEnglish ? 'English' : null;
      });
    }
  }

Future<String> _translateToEnglish(String text) async {
  try {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    debugPrint('API KEY: $apiKey');
    if (apiKey.isEmpty) return text;
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    final response = await model.generateContent([
      Content.text(
        'You are a translator. Your only job is to translate the user\'s text into English.\n'
        'Rules:\n'
        '- Detect the language of the input text.\n'
        '- If the text is NOT in English, translate it fully and accurately to English.\n'
        '- If the text IS already in English, return it exactly as-is.\n'
        '- Output ONLY the final English text. No explanations, no labels, no quotes.\n\n'
        'Text to translate:\n$text',
      )
    ]);
    final translated = response.text?.trim() ?? '';
    return translated.isEmpty ? text : translated;
  } catch (e) {
    debugPrint('Translation error: $e');
    return 'ERROR: $e';
  }
}
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file != null) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Add Photo', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            _sheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              subtitle: 'Use your camera',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _sheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              subtitle: 'Pick an existing photo',
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // TO:
Future<void> _proceed() async {
    if (_selectedImage == null) {
      _showSnack('Please add a photo of the item first.');
      return;
    }

    final desc = _descController.text.trim();
    final wordCount = desc.isEmpty
        ? 0
        : desc.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    if (desc.isEmpty) {
      _showSnack('Please describe the item.');
      return;
    }

    if (wordCount > 50) {
      _showDescriptionWarningDialog(
        'Your description is too long (over 500 words). Please keep it brief and focused on the item.',
        true,
      );
      return;
    }

    if (wordCount < 4) {
      _showDescriptionWarningDialog(
        'Your description is too vague. Try describing the item specifically — what it is, its condition, and any damage.',
        false,
      );
      return;
    }

   setState(() => _isProceeding = true);
    final translatedDesc = await _translateToEnglish(desc);
    if (!mounted) return;
    setState(() => _isProceeding = false);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AnalysisScreen(
          imageFile: _selectedImage!,
          voiceNote: translatedDesc,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showDescriptionWarningDialog(String message, bool isTooLong) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A26),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isTooLong ? Icons.text_decrease : Icons.help_outline,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTooLong ? 'Description Too Long' : 'Description Too Vague',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF948EA1),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF370096), size: 18),
            label: const Text(
              'Rewrite Description',
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
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
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
                border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1))),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donate Item',
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
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDyFxufFFbDsQZh8QgrUFx1GbTpsBLD_N4VbaYkFOcehFdmJR1UO04Vf5K232Siuw8kTRPOuMmXFZUFEp4SCupcCnQuHLZToFu6biLYD98BOqmIFO-KUq5qHaIcMnXETBCGUKf-2qB8dVb5xcVH4ZDcA0oKw6D3NGJAXO3UWRhRl0pJxy28P0yWPqbCV3CmsAaAqAS2m2M8LBbdeVYFFPxixnYkz0tl2Ke13dPhc3Q2JcCHQ6hzeKEusAZkxiNY2W1GnPs-gzP9Ufg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Capture Item',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDAE2FD),
                  ),
                ),
                Text(
                  'STEP 1 OF 2',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.88,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image Area
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to add photo',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG up to 10MB',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description Input
            const Text(
              'Describe the Item',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDAE2FD),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You can write in English, Hindi (हिंदी), Marathi (मराठी), Tamil (தமிழ்), Telugu (తెలుగు), Kannada (ಕನ್ನಡ), Bengali (বাংলা), Gujarati (ગુજરાતી), German, French, Spanish, Arabic, or any language — we\'ll translate it automatically.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                height: 1.5,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFFDAE2FD),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Wooden chair with a broken leg...',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF060E20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF494455)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF494455)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.contributor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {
                    _showTranslationTab = false;
                    _translatedDesc = null;
                    _detectedLanguage = null;
                  }),
                ),
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Icon(
                    Icons.edit_note,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Translate to English preview ───────────────────────────
            if (_descController.text.trim().isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isTranslating ? null : _previewTranslation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _showTranslationTab
                              ? AppColors.primary.withOpacity(0.15)
                              : const Color(0xFF060E20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _showTranslationTab
                                ? AppColors.primary.withOpacity(0.5)
                                : const Color(0xFF494455),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isTranslating)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary),
                              )
                            else
                              Icon(
                                Icons.translate,
                                size: 16,
                                color: _showTranslationTab
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.6),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              'Translated Description to English',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _showTranslationTab
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.6),
                              ),
                            ),
                            if (_showTranslationTab && !_isTranslating) ...[
                              const Spacer(),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.primary.withOpacity(0.8),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showTranslationTab) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: _isTranslating
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Translating...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.language,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'English Translation',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: AppColors.primary
                                        .withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _translatedDesc ??
                                  _descController.text.trim(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFFDAE2FD),
                              ),
                            ),
                            if (_translatedDesc != null &&
                                _detectedLanguage == 'English') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 13,
                                      color:
                                          Colors.white.withOpacity(0.4)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Already in English — no changes made.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedImage != null &&
                        _descController.text.trim().isNotEmpty &&
                        !_isProceeding)
                    ? _proceed
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: _isProceeding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF370096)),
                      )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analyse with AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF370096),
                      ),
                  
                    ),

                    SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF370096),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bolt,
                  size: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                const Text(
                  'POWERED BY GEMINI AI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Color(0xFFB0B8D0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}