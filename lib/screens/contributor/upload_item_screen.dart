import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/resource_model.dart';
import '../../services/auth_service.dart';
import '../../services/blur_detection_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../services/reward_service.dart';
import '../../utils/constants.dart';

class UploadItemScreen extends StatefulWidget {
  const UploadItemScreen({super.key});

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  final _geminiService = GeminiService();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _rewardService = RewardService();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();
  final _descriptionFocusNode = FocusNode();

  File? _imageFile;
  Map<String, dynamic>? _classification;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String _step = 'capture';

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _classification = null;
        _step = 'capture';
      });
    }
  }

  Future<String> _imageToBase64() async {
    if (_imageFile == null) return '';
    try {
      final bytes = await _imageFile!.readAsBytes();
      if (bytes.length > 700 * 1024) {
        _showSnack('Image is too large. Please retake with lower quality.');
        return '';
      }
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _analyzeItem() async {
    if (_imageFile == null) {
      print('🚨 _analyzeItem called, desc: "${_descriptionController.text}"');
      _showSnack('Please capture or upload an image first.');
      return;
    }

    // ── Check description BEFORE anything else ──
    final desc = _descriptionController.text.trim();
    final words = desc.isEmpty
        ? <String>[]
        : desc.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;

    if (wordCount > 500) {
      _showDescriptionWarningDialog(
        'Your description is too long (over 500 words). Please keep it brief and focused on the item.',
        true,
      );
      return;
    }

    if (wordCount > 0 && wordCount < 4) {
      _showDescriptionWarningDialog(
        'Your description is too vague. Try describing the item specifically — what it is, its condition, and any damage.',
        false,
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _step = 'analyzing';
    });

    try {
      final blurry = await BlurDetectionService.isBlurry(_imageFile!);

      if (blurry) {
        if (!mounted) return;
        setState(() => _step = 'capture');
        _showImageQualityDialog('blurry');
        return;
      }

      final result = await _geminiService.classifyItem(
        imageFile: _imageFile!,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      final imageQuality =
          (result['imageQuality'] ?? 'good').toString().toLowerCase();
      if (imageQuality == 'notitem') {
        setState(() => _step = 'capture');
        _showImageQualityDialog('notitem');
        return;
      }

      setState(() {
        _classification = result;
        _step = 'review';
      });
    } catch (e, stack) {
      print('❌ ERROR: $e');
      print('❌ STACK: $stack');
      if (!mounted) return;
      _showSnack('AI analysis failed. Please try again.');
      setState(() => _step = 'capture');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
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
            onPressed: () {
              Navigator.pop(dialogContext);
              _focusDescriptionField();
            },
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

  void _focusDescriptionField() {
    _scrollController.animateTo(
      260,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) FocusScope.of(context).requestFocus(_descriptionFocusNode);
    });
  }

  void _showImageQualityDialog(String reason) {
    final isBlurry = reason == 'blurry';
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
              isBlurry ? Icons.blur_on : Icons.hide_image_outlined,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isBlurry ? 'Blurry Image' : 'Invalid Image',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          isBlurry
              ? 'Your photo is too blurry to analyse. Please retake it in good lighting and hold the camera steady.'
              : 'This does not appear to be a donate-able item. Please photograph the actual item you wish to donate.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF948EA1),
          ),
        ),
        actions: [
          if (isBlurry)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _pickImage(ImageSource.camera);
              },
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Dismiss',
              style: TextStyle(
                  fontFamily: 'Inter', color: Color(0xFF948EA1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitItem() async {
    if (_classification == null) return;

    setState(() {
      _isSaving = true;
      _step = 'saving';
    });

    try {
      await _firestoreService.signInAnonymously();
      final uid = _firestoreService.userId;
      final imageBase64 = await _imageToBase64();

      final item = ResourceModel(
        id: '',
        userId: uid,
        imageUrl: imageBase64,
        description: _descriptionController.text,
        itemName: _classification!['itemName'] ?? '',
        category: _classification!['category'] ?? '',
        condition: _classification!['condition'] ?? 'fair',
        aiClassification:
            _classification!['classification'] ?? AppConstants.classUsable,
        repairType: _classification!['repairType'] ?? 'none',
        repairDescription: _classification!['repairDescription'] ?? '',
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : 'Location not set',
        latitude: 0.0,
        longitude: 0.0,
        status: AppConstants.statusClassified,
        createdAt: DateTime.now(),
      );

      final savedId = await _firestoreService.saveResource(item);

      try {
        await _rewardService.awardUploadPoints(uid, savedId);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _step = 'done');
    } catch (e) {
      debugPrint('❌ SUBMIT ERROR: $e');
      if (!mounted) return;
      _showSnack('Failed to submit item. Please try again.');
      setState(() => _step = 'review');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surfaceElevated,
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
          'Submit Donation',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step == 'done')
              _buildSuccessView()
            else ...[
              _buildImageSection(),
              const SizedBox(height: AppSpacing.md),
              _buildDescriptionSection(),
              const SizedBox(height: AppSpacing.md),
              _buildAiInfoCard(),
              const SizedBox(height: AppSpacing.md),
              _buildLocationSection(),
              const SizedBox(height: AppSpacing.lg),
              if (_step == 'analyzing') _buildAnalyzingState(),
              if (_classification != null && _step == 'review') ...[
                _buildClassificationResult(),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ITEM PHOTO',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: Color(0xFF948EA1),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImageSourceDialog(),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _imageFile != null
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.12),
                width: _imageFile != null ? 2 : 1,
              ),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_imageFile!, fit: BoxFit.cover),
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
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.primary, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to add photo',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Camera or Gallery',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
          ),
        ),
        if (_imageFile != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined,
                    size: 16, color: AppColors.primary),
                label: const Text('Retake',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.primary)),
              ),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined,
                    size: 16, color: AppColors.secondary),
                label: const Text('Gallery',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.secondary)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Photo',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Camera',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.secondary),
              title: const Text('Gallery',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Colors.white)),
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

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESCRIPTION',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: Color(0xFF948EA1),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFFDAE2FD)),
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Describe the item, its condition, and why you\'re donating it...',
            hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF060E20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF494455)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF494455)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PICKUP LOCATION',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: Color(0xFF948EA1),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFFDAE2FD)),
          decoration: InputDecoration(
            hintText: 'Enter your address or area...',
            hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(Icons.location_on_outlined,
                color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF060E20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF494455)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF494455)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Analyzing Item...',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Classifying condition and routing',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationResult() {
    final c = _classification!;
    final isRepairable = c['classification'] == AppConstants.classRepairable;
    final accentColor = isRepairable ? AppColors.warning : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRepairable)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: accentColor, width: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.build, color: accentColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repair Required',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const Text(
                        'Will be routed to a repair helper first',
                        style: TextStyle(
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
          ),
        const Text(
          'ITEM DETAILS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: Color(0xFF948EA1),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              _buildDetailRow('Item', c['itemName'] ?? ''),
              Container(height: 1, color: Colors.white.withOpacity(0.05)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Condition',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFCAC3D8))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        (c['condition'] ?? '').toString().toUpperCase(),
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (isRepairable) ...[
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repair Needed',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFCAC3D8))),
                      const SizedBox(height: 4),
                      Text(c['repairDescription'] ?? '',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFFDAE2FD))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -16,
                top: -16,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.warning.withOpacity(0.1),
                          blurRadius: 40),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.warning.withOpacity(0.2),
                            blurRadius: 15),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: AppColors.warning, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You\'ll earn rewards',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  '+${AppConstants.pointsUpload} pts for upload',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.warning)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('+75 pts on delivery',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.secondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFCAC3D8))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFFDAE2FD))),
        ],
      ),
    );
  }

  Widget _buildAiInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Classification',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gemini AI will automatically classify your item and suggest the best recycling or donation centers nearby based on the photo and description.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF948EA1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_classification == null) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isAnalyzing ? null : _analyzeItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.psychology_outlined,
              color: Color(0xFF370096)),
          label: const Text(
            'Analyze with AI',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF370096)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _submitItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.2),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF370096)),
              )
            : const Icon(Icons.build, color: Color(0xFF370096)),
        label: Text(
          _isSaving ? 'Submitting...' : 'Submit for Repair & Donation',
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF370096)),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.secondary, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Donation Submitted!',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Your item has been classified and will be matched with the best NGO.',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '+${AppConstants.pointsUpload} reward points earned!',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Dashboard',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF370096))),
            ),
          ],
        ),
      ),
    );
  }
}