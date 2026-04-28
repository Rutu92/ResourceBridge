import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/resource_model.dart';
import '../../utils/constants.dart';
import '../../widgets/reward_badge.dart';
import '../../services/firestore_service.dart';
import '../capture_screen.dart';
import 'chat_screen.dart';

class ContributorDashboard extends StatefulWidget {
  const ContributorDashboard({super.key});

  @override
  State<ContributorDashboard> createState() => _ContributorDashboardState();
}

class _ContributorDashboardState extends State<ContributorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
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
            StreamBuilder<List<ResourceModel>>(
              stream: _firestoreService.streamResourcesByUser(_userId),
              builder: (context, snapshot) {
                final allItems = snapshot.data ?? [];
                final acceptedItems = allItems
                    .where((i) =>
                        i.status == AppConstants.statusMatched ||
                        i.status == AppConstants.statusPickupScheduled ||
                        i.status == AppConstants.statusDelivered ||
                        i.status == AppConstants.statusCompleted)
                    .toList();
                return _buildHeader(allItems, acceptedItems);
              },
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.contributor,
              labelColor: AppColors.contributor,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Donate'),
                Tab(text: 'My Donations'),
                Tab(text: 'Accepted'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DonateTab(userId: _userId),
                  _DonationsTab(
                    userId: _userId,
                    firestoreService: _firestoreService,
                    onGoToDonate: () => _tabController.animateTo(0),
                    buildItemCard: _buildItemCard,
                  ),
                  _AcceptedTab(
                    userId: _userId,
                    firestoreService: _firestoreService,
                    buildItemCard: _buildItemCard,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Item Card — no StatusTracker ──────────────────────────────────────────

  Widget _buildItemCard(ResourceModel item, {bool isAccepted = false}) {
    final isRepair = item.aiClassification == AppConstants.classRepairable;
    final isMatched = item.matchedNgoId != null &&
        item.status != AppConstants.statusPending &&
        item.status != AppConstants.statusClassified;

    final color = isMatched
        ? AppColors.ngo
        : isRepair
            ? AppColors.warning
            : AppColors.contributor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName.isNotEmpty ? item.itemName : 'Item',
                  style: AppTextStyles.headingMedium,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.description,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Chat with NGO button — shown once item is matched
          if (isMatched) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      itemId: item.id,
                      itemName: item.itemName,
                      userId: _userId,
                      otherPartyId: item.matchedNgoId!,
                      otherPartyName: 'NGO',
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.ngo.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline,
                    size: 16, color: AppColors.ngo),
                label: Text(
                  'Chat with NGO',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.ngo),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'PENDING';
      case AppConstants.statusClassified:
        return 'CLASSIFIED';
      case AppConstants.statusMatched:
        return 'NGO ACCEPTED';
      case AppConstants.statusPickupScheduled:
        return 'PICKUP SCHEDULED';
      case AppConstants.statusInRepair:
        return 'IN REPAIR';
      case AppConstants.statusRepaired:
        return 'REPAIRED';
      case AppConstants.statusDelivered:
        return 'DELIVERED';
      case AppConstants.statusCompleted:
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      List<ResourceModel> all, List<ResourceModel> accepted) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RESOURCE BRIDGE', style: AppTextStyles.label),
                  Text('Hello, Contributor 👋',
                      style: AppTextStyles.displayMedium),
                ],
              ),
              RewardBadge(
                points: all.length * AppConstants.pointsUpload,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _statChip(Icons.upload_outlined,
                  '${all.length} donated', AppColors.contributor),
              const SizedBox(width: AppSpacing.sm),
              _statChip(Icons.handshake_outlined,
                  '${accepted.length} accepted', AppColors.ngo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Donate Tab ────────────────────────────────────────────────────────────────

class _DonateTab extends StatelessWidget {
  final String userId;
  const _DonateTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Snap to Share',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDAE2FD),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a photo of the resources you\'d like to donate to bridge the gap.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Color(0xFFCAC3D8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Central Upload Card
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaptureScreen()),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 384),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Camera Pulse Effect
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 24,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.contributor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Take a photo',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDAE2FD),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Or drag and drop files here',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFCAC3D8),
                            letterSpacing: 0.88,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A3D),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.33,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.contributor.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Information Chips
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(Icons.verified, 'Verified NGOs only', AppColors.secondary),
                _buildInfoChip(Icons.speed, 'Quick approval', AppColors.helper),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Donations Tab ──────────────────────────────────────────────────────────

class _DonationsTab extends StatelessWidget {
  final String userId;
  final FirestoreService firestoreService;
  final VoidCallback onGoToDonate;
  final Widget Function(ResourceModel, {bool isAccepted}) buildItemCard;

  const _DonationsTab({
    required this.userId,
    required this.firestoreService,
    required this.onGoToDonate,
    required this.buildItemCard,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ResourceModel>>(
      stream: firestoreService.streamResourcesByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism,
                        color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Nothing donated yet',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Go to the Donate tab to get started.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFCAC3D8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: onGoToDonate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('Donate an Item',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: items.length,
          itemBuilder: (_, i) => _DonationItemCard(item: items[i]),
        );
      },
    );
  }
}

class _DonationItemCard extends StatelessWidget {
  final ResourceModel item;

  const _DonationItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText = item.status.toUpperCase();
    IconData statusIcon = Icons.schedule;
    
    if (item.status == AppConstants.statusPending || item.status == AppConstants.statusClassified) {
      statusColor = AppColors.warning; 
    } else if (item.status == AppConstants.statusMatched) {
      statusColor = AppColors.ngo;
      statusIcon = Icons.handshake;
    } else {
      statusColor = AppColors.primary;
      statusIcon = Icons.verified;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64, 
                height: 64, 
                decoration: BoxDecoration(
                  color: const Color(0xFF222A3D),
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl.isNotEmpty 
                    ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                    : null,
                ),
                child: item.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.white54) : null,
              ),
              const SizedBox(width: 16), 
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName.isNotEmpty ? item.itemName : 'Unknown Item',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDAE2FD),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description.isNotEmpty ? item.description : 'No description',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFFCAC3D8), 
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          item.status == AppConstants.statusMatched ? 'Matched with NGO' : 'Listed recently',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: statusColor,
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
    );
  }
}

// ── Accepted Tab ──────────────────────────────────────────────────────────────

class _AcceptedTab extends StatelessWidget {
  final String userId;
  final FirestoreService firestoreService;
  final Widget Function(ResourceModel, {bool isAccepted}) buildItemCard;

  const _AcceptedTab({
    required this.userId,
    required this.firestoreService,
    required this.buildItemCard,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ResourceModel>>(
      stream: firestoreService.streamResourcesByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data ?? [];
        final acceptedItems = allItems
            .where((i) =>
                i.status == AppConstants.statusMatched ||
                i.status == AppConstants.statusPickupScheduled ||
                i.status == AppConstants.statusDelivered ||
                i.status == AppConstants.statusCompleted)
            .toList();

        if (acceptedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No accepted items yet',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'NGOs will accept your donations here',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFCAC3D8)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: acceptedItems.length,
          itemBuilder: (_, i) => _AcceptedItemCard(item: acceptedItems[i], userId: userId),
        );
      },
    );
  }
}

class _AcceptedItemCard extends StatelessWidget {
  final ResourceModel item;
  final String userId;

  const _AcceptedItemCard({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: AppColors.ngo.withOpacity(0.2)), 
        boxShadow: [
          BoxShadow(
            color: AppColors.ngo.withOpacity(0.15), 
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ngo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.ngo.withOpacity(0.3)),
                ),
                child: const Text(
                  'NGO ACCEPTED',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ngo,
                  ),
                ),
              ),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80, 
                    height: 80, 
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3449), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      image: item.imageUrl.isNotEmpty 
                        ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                        : null,
                    ),
                    child: item.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.white54) : null,
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName.isNotEmpty ? item.itemName : 'Accepted Item',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDAE2FD),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.corporate_fare, size: 14, color: Color(0xFFCAC3D8)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'NGO Partner', 
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFFCAC3D8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Color(0xFFCAC3D8)),
                            SizedBox(width: 4),
                            Text(
                              'Location arranged',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFFCAC3D8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (item.matchedNgoId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            itemId: item.id,
                            itemName: item.itemName,
                            userId: userId,
                            otherPartyId: item.matchedNgoId!,
                            otherPartyName: 'NGO',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ngo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.chat, color: Color(0xFF00382F), size: 18), 
                  label: const Text(
                    'Chat with NGO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00382F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}