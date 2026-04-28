import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/resource_model.dart';
import '../../models/repair_task_model.dart';
import '../../utils/constants.dart';
import '../../widgets/item_card.dart';
import '../../widgets/status_tracker.dart';
import '../../services/firestore_service.dart';
import '../../services/repair_chat_service.dart';
import '../contributor/ngo_chat_screen.dart';
import 'ngo_helper_chat_screen.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  late final String _ngoId;

  final Set<String> _repairRequested = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ngoId = FirebaseAuth.instance.currentUser?.uid ?? 'ngo_guest';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Accept item ───────────────────────────────────────────────────────────

  Future<void> _acceptItem(ResourceModel item) async {
    await _firestoreService.updateResourceStatus(
      resourceId: item.id,
      status: AppConstants.statusMatched,
      matchedNgoId: _ngoId,
      updatedBy: _ngoId,
      note: 'NGO accepted the item',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item accepted! Chat is now open with the contributor.'),
        backgroundColor: AppColors.secondary,
      ),
    );
    _tabController.animateTo(1);
  }

  // ── Request repair ────────────────────────────────────────────────────────

  Future<void> _requestRepair(ResourceModel item) async {
    final estimatedCost = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RepairRequestSheet(item: item),
    );

    if (estimatedCost == null || !mounted) return;

    final task = RepairTaskModel(
      id: '',
      itemId: item.id,
      itemName: item.itemName.isNotEmpty ? item.itemName : 'Item',
      contributorId: item.userId,
      ngoId: _ngoId,
      repairType: item.repairType.isNotEmpty ? item.repairType : 'General',
      description: item.repairDescription.isNotEmpty
          ? item.repairDescription
          : item.description,
      status: AppConstants.statusPending,
      estimatedCost: estimatedCost,
      createdAt: DateTime.now(),
    );

    await _firestoreService.createRepairTask(task);

    if (!mounted) return;

    setState(() => _repairRequested.add(item.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Repair request sent to helpers!'),
        backgroundColor: AppColors.helper,
      ),
    );
  }

  // ── Open chat ─────────────────────────────────────────────────────────────

  Future<void> _openChat(ResourceModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NgoChatScreen(item: item, ngoId: _ngoId),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F).withOpacity(0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.12))),
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withOpacity(0.05), blurRadius: 20),
                ],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.account_circle, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'NGO Dashboard',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF948EA1)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: const Color(0xFF948EA1),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Available Items'),
                Tab(text: 'Accepted'),
                Tab(text: 'Under Repair'),
                Tab(text: 'Received'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableItems(),
                _buildAcceptedItems(),
                _buildUnderRepairItems(),
                _buildReceivedItems(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Available Items Tab ───────────────────────────────────────────────────

  Widget _buildAvailableItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamPendingResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        final items = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Available Supplies',
              style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD)),
            ),
            const SizedBox(height: 4),
            Text(
              items.isEmpty ? 'No items available yet' : 'Found ${items.length} items ready for collection',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFF494455)),
            ),
            const SizedBox(height: 24),
            ...items.map((item) => _buildAvailableCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildAvailableCard(ResourceModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  child: Text(
                    item.condition.isNotEmpty ? item.condition.toUpperCase() : 'USABLE',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.itemName.isNotEmpty ? item.itemName : 'Item',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFDAE2FD)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF948EA1)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location.isNotEmpty ? item.location : 'Location unknown',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF948EA1)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: AppColors.secondary.withOpacity(0.15), blurRadius: 15),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _acceptItem(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BEA4), // secondary-container
                foregroundColor: const Color(0xFF00463B), // on-secondary-container
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                elevation: 0,
              ),
              child: const Text('Accept', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Accepted Items Tab ────────────────────────────────────────────────────

  Widget _buildAcceptedItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamNGOAcceptedItems(_ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        final items = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Accepted Items',
              style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reviewing your current commitments',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFF948EA1)),
            ),
            const SizedBox(height: 24),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No accepted items yet', style: TextStyle(color: Color(0xFF948EA1))),
                ),
              )
            else
              ...items.map((item) => _buildAcceptedCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildAcceptedCard(ResourceModel item) {
    final isRepair = item.aiClassification == AppConstants.classRepairable;
    final color = isRepair ? AppColors.warning : AppColors.secondary;
    final repairAlreadyRequested = item.repairTaskId != null || _repairRequested.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isRepair ? Icons.build : Icons.broken_image, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : 'Item',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD)),
                    ),
                    const SizedBox(height: 4),
                    Text('Batch ID: #${item.id.substring(0, min(6, item.id.length))}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF948EA1))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.88, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFlowStep(true, 'Uploaded', color),
                _buildFlowLine(true, color),
                _buildFlowStep(true, 'Classified', color),
                _buildFlowLine(true, color),
                _buildFlowStep(true, 'Accepted', color),
                _buildFlowLine(false, color),
                _buildFlowStep(false, 'Repair', color),
                _buildFlowLine(false, color),
                _buildFlowStep(false, 'Done', color),
                _buildFlowLine(false, color),
                _buildFlowStep(false, 'Delivered', color),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRepair && !repairAlreadyRequested)
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: const Color(0xFFAA5F00).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _requestRepair(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAA5F00), // tertiary-container
                      foregroundColor: const Color(0xFFFFF6F2), // on-tertiary-container
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.build),
                    label: const Text('Request Repair', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (isRepair && !repairAlreadyRequested) const SizedBox(height: 12),
              if (!isRepair)
                ElevatedButton.icon(
                  onPressed: () => _firestoreService.updateResourceStatus(
                    resourceId: item.id,
                    status: AppConstants.statusCompleted,
                    updatedBy: _ngoId,
                    note: 'NGO marked as received',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: const Color(0xFF00382F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Mark as Received', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              if (!isRepair) const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openChat(item),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Contributor', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Under Repair Tab ──────────────────────────────────────────────────────

  Widget _buildUnderRepairItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamNGOItems(_ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        final all = snapshot.data ?? [];
        final items = all.where((r) => r.status == AppConstants.statusInRepair).toList();
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ACTIVE MAINTENANCE',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: AppColors.secondary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Under Repair',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '${items.length} ITEMS',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF948EA1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No items under repair', style: TextStyle(color: Color(0xFF948EA1))),
                ),
              )
            else
              ...items.map((item) => _buildUnderRepairCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildUnderRepairCard(ResourceModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : 'Item',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Color(0xFF948EA1)),
                        const SizedBox(width: 4),
                        Text('Helper Assigned', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF948EA1))),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _openChat(item),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Chat', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFlowStep(true, 'Uploaded', AppColors.secondary),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Classified', AppColors.secondary),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Accepted', AppColors.secondary),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStepAnimated(true, 'Repairing', AppColors.secondary),
                _buildFlowLine(false, AppColors.secondary),
                _buildFlowStep(false, 'Done', AppColors.secondary),
                _buildFlowLine(false, AppColors.secondary),
                _buildFlowStep(false, 'Delivered', AppColors.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Received Items Tab ────────────────────────────────────────────────────

  Widget _buildReceivedItems() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _firestoreService.streamNGOItems(_ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        final all = snapshot.data ?? [];
        final items = all.where((r) => r.status == AppConstants.statusRepaired || r.status == AppConstants.statusCompleted).toList();
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Received',
              style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Inventory flow finalized for ${items.length} items',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFFA1A1AA)),
            ),
            const SizedBox(height: 24),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No received items yet', style: TextStyle(color: Color(0xFFA1A1AA))),
                ),
              )
            else
              ...items.map((item) => _buildReceivedCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildReceivedCard(ResourceModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : 'Item',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: #${item.id.substring(0, min(6, item.id.length))}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF71717A))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                ),
                child: const Text(
                  'DELIVERED',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.88, color: AppColors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFlowStep(true, 'Uploaded', AppColors.secondary, small: true),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Classified', AppColors.secondary, small: true),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Accepted', AppColors.secondary, small: true),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Repair', AppColors.secondary, small: true),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Repaired', AppColors.secondary, small: true),
                _buildFlowLine(true, AppColors.secondary),
                _buildFlowStep(true, 'Delivered', AppColors.secondary, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildFlowStep(bool active, String label, Color color, {bool small = false}) {
    final size = small ? 24.0 : 24.0;
    return Container(
      width: 50,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active ? color : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
            ),
            child: active
                ? const Icon(Icons.check, size: 14, color: Color(0xFF00382F))
                : const Icon(Icons.circle, size: 8, color: Colors.transparent),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: active ? color : const Color(0xFF948EA1),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStepAnimated(bool active, String label, Color color) {
    return Container(
      width: 50,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowLine(bool active, Color color) {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: active ? color : Colors.white.withOpacity(0.1),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusMatched: return 'ACCEPTED';
      case AppConstants.statusPickupScheduled: return 'PICKUP SCHEDULED';
      case AppConstants.statusInRepair: return 'IN REPAIR';
      case AppConstants.statusRepaired: return 'REPAIRED';
      case AppConstants.statusDelivered: return 'DELIVERED';
      case AppConstants.statusCompleted: return 'COMPLETED';
      default: return status.toUpperCase();
    }
  }
}

// ── Repair Request Bottom Sheet ───────────────────────────────────────────────

class _RepairRequestSheet extends StatefulWidget {
  final ResourceModel item;
  const _RepairRequestSheet({required this.item});

  @override
  State<_RepairRequestSheet> createState() => _RepairRequestSheetState();
}

class _RepairRequestSheetState extends State<_RepairRequestSheet> {
  final _costController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _costController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060E20), // surface-container-lowest
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40, offset: Offset(0, -10))],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Repair', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD))),
                  Text('Estimate restoration for ${widget.item.itemName}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF948EA1))),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFFDAE2FD)),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Repair Cost (INR)', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFF948EA1))),
          const SizedBox(height: 8),
          TextField(
            controller: _costController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFDAE2FD)),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.secondary),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: const Color(0xFF171F33), // surface-container
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12, width: 2)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12, width: 2)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary, width: 2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Repair Details', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFF948EA1))),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFDAE2FD)),
            decoration: InputDecoration(
              hintText: 'Describe the damage and required parts...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: const Color(0xFF171F33), // surface-container
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12, width: 2)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12, width: 2)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary, width: 2)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.2), blurRadius: 30)],
            ),
            child: ElevatedButton(
              onPressed: () {
                final cost = _costController.text.trim();
                Navigator.pop(context, cost.isEmpty ? '0' : cost);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: const Color(0xFF00382F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SUBMIT REQUEST', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}