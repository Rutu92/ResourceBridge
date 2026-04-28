import 'package:flutter/material.dart';
import '../../models/resource_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../widgets/item_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.admin,
              labelColor: AppColors.admin,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'All Items'),
                Tab(text: 'Repairs'),
                Tab(text: 'Overview'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllItems(),
                  _buildRepairItems(),
                  _buildOverview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.admin.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: AppColors.admin, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADMIN PANEL', style: AppTextStyles.label),
              Text('ShadowForge Control',
                  style: AppTextStyles.headingLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamPendingResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.admin),
          );
        }

        final items = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (_, i) => ItemCard(
            item: items[i],
            trailing: Row(
              children: [
                _buildAdminAction(
                  'Approve',
                  AppColors.secondary,
                  () => _firestoreService.updateResourceStatus(
                    resourceId: items[i].id,
                    status: AppConstants.statusMatched,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildAdminAction(
                  'Flag',
                  AppColors.warning,
                  () => _firestoreService.updateResourceStatus(
                    resourceId: items[i].id,
                    status: 'flagged',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamPendingResources(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? [])
            .where((i) => i.isRepairable)
            .toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text('No repair items pending',
                    style: AppTextStyles.headingMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (_, i) => ItemCard(item: items[i]),
        );
      },
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLATFORM OVERVIEW', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          _buildOverviewCard(
            '📦',
            'Total Donations',
            'Items donated via platform',
            AppColors.contributor,
          ),
          _buildOverviewCard(
            '🏢',
            'Active NGOs',
            'Organizations receiving items',
            AppColors.ngo,
          ),
          _buildOverviewCard(
            '🔧',
            'Repair Tasks',
            'Items routed for repair',
            AppColors.helper,
          ),
          _buildOverviewCard(
            '✅',
            'Completed Flows',
            'Successfully delivered items',
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
      String emoji, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingMedium),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAction(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(color: color)),
      ),
    );
  }
}