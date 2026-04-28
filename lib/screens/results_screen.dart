import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resource_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/status_tracker.dart';
import 'contributor/contributor_dashboard.dart';

class ResultsScreen extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> analysisResult;
  final String voiceNote;

  const ResultsScreen({
    super.key,
    required this.imageFile,
    required this.analysisResult,
    required this.voiceNote,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isSaving = false;
  final _firestoreService = FirestoreService();

  bool get _isRepairable =>
      widget.analysisResult['classification'] == AppConstants.classRepairable;

  Color get _accentColor =>
      _isRepairable ? AppColors.warning : AppColors.secondary;

  Future<void> _saveAndSubmit() async {
    setState(() => _isSaving = true);

    try {
      // Ensure user is signed in (anonymous auth as fallback)
      await _firestoreService.signInAnonymously();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      final result = widget.analysisResult;

      final resource = ResourceModel(
        id: '', // Firestore will assign the real id
        userId: uid,
        imageUrl: widget.imageFile.path,
        description: widget.voiceNote,
        itemName: result['itemName'] ?? result['materialType'] ?? 'Unknown Item',
        category: result['category'] ?? 'other',
        condition: result['condition'] ?? 'fair',
        aiClassification:
            result['classification'] ?? AppConstants.classUsable,
        repairType: result['repairType'] ?? 'none',
        repairDescription: result['repairDescription'] ?? '',
        location: 'Your Location',
        latitude: 0.0,
        longitude: 0.0,
        status: AppConstants.statusClassified,
        createdAt: DateTime.now(),
        voiceNote: widget.voiceNote,
        materialType: result['itemName'] ?? '',
        quantity: '1 unit',
        estimatedValue: 0,
      );

      // Save to Firestore — this also writes the first tracking entry
      await _firestoreService.saveResource(resource);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ContributorDashboard(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: ${e.toString()}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.analysisResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Submit Donation', style: AppTextStyles.headingLarge),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _buildReviewView(result),
    );
  }

  Widget _buildReviewView(Map<String, dynamic> result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerdictBanner(),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.file(
              widget.imageFile,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('ITEM DETAILS', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailsCard(result),
          const SizedBox(height: AppSpacing.md),

          _buildRewardPreview(),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                disabledBackgroundColor: AppColors.border,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(
                      _isRepairable
                          ? Icons.build_outlined
                          : Icons.volunteer_activism,
                      color: Colors.black,
                      size: 20,
                    ),
              label: Text(
                _isSaving
                    ? 'Submitting...'
                    : _isRepairable
                        ? 'Submit for Repair & Donation'
                        : 'List for Donation',
                style: AppTextStyles.headingMedium
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildVerdictBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _isRepairable
                  ? Icons.build_outlined
                  : Icons.check_circle_outline,
              color: _accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRepairable ? 'Repair Required' : 'Ready to Donate',
                style: AppTextStyles.headingMedium
                    .copyWith(color: _accentColor),
              ),
              Text(
                _isRepairable
                    ? 'Will be routed to a repair helper first'
                    : 'Will be matched directly to an NGO',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Map<String, dynamic> result) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _detailRow(
              'Item', result['itemName'] ?? result['materialType'] ?? '-'),
          _divider(),
          _detailRow('Condition', result['condition'] ?? '-'),
          if (_isRepairable) ...[
            _divider(),
            _detailRow('Repair Needed', result['repairDescription'] ?? '-'),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _routeStep(
            icon: Icons.psychology_outlined,
            label: 'AI Classified',
            detail: _isRepairable ? 'Needs repair' : 'Usable',
            color: AppColors.primary,
            isDone: true,
          ),
          _routeArrow(),
          _routeStep(
            icon: _isRepairable
                ? Icons.build_outlined
                : Icons.handshake_outlined,
            label: _isRepairable ? 'Repair Helper' : 'NGO Match',
            detail: _isRepairable
                ? '${widget.analysisResult['repairType'] ?? 'Technician'} needed'
                : 'Nearest accepting NGO',
            color: _isRepairable ? AppColors.helper : AppColors.ngo,
            isDone: false,
          ),
          _routeArrow(),
          _routeStep(
            icon: Icons.volunteer_activism_outlined,
            label: 'NGO Delivery',
            detail: 'Community receives item',
            color: AppColors.secondary,
            isDone: false,
          ),
        ],
      ),
    );
  }

  Widget _routeStep({
    required IconData icon,
    required String label,
    required String detail,
    required Color color,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? color : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: isDone ? Colors.white : color),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            Text(detail, style: AppTextStyles.caption),
          ],
        ),
        const Spacer(),
        if (isDone)
          const Icon(Icons.check_circle,
              color: AppColors.secondary, size: 18),
      ],
    );
  }

  Widget _routeArrow() {
    return Padding(
      padding: const EdgeInsets.only(left: 17, top: 2, bottom: 2),
      child: Container(width: 2, height: 18, color: AppColors.border),
    );
  }

  Widget _buildRewardPreview() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You'll earn rewards",
                  style: AppTextStyles.headingMedium),
              Text(
                '+${AppConstants.pointsUpload} pts for upload · +${_isRepairable ? AppConstants.pointsRepaired : AppConstants.pointsDelivered} pts on delivery',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.border);
}