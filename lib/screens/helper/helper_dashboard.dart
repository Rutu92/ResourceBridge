import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/repair_task_model.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';
import '../helper/helper_chat_screen.dart';
import '../helper/helper_chat_screen.dart';

class HelperDashboard extends StatefulWidget {
  const HelperDashboard({super.key});

  @override
  State<HelperDashboard> createState() => _HelperDashboardState();
}

class _HelperDashboardState extends State<HelperDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  late final String _helperId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _helperId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_helper';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Accept task ───────────────────────────────────────────────────────────

  Future<void> _acceptTask(RepairTaskModel task) async {
    final updated = task.copyWith(
      helperId: _helperId,
      status: 'assigned',
      assignedAt: DateTime.now(),
    );
    await _firestoreService.updateRepairTask(updated);

    await _firestoreService.updateResourceStatus(
      resourceId: task.itemId,
      status: AppConstants.statusInRepair,
      assignedHelperId: _helperId,
      updatedBy: _helperId,
      note: 'Helper accepted repair task — repair in progress',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task accepted!'),
        backgroundColor: AppColors.helper,
      ),
    );
  }

  // ── Mark complete ─────────────────────────────────────────────────────────

  Future<void> _markComplete(RepairTaskModel task) async {
    final updated = task.copyWith(
      status: AppConstants.statusCompleted,
      completedAt: DateTime.now(),
    );
    await _firestoreService.updateRepairTask(updated);

    await _firestoreService.updateResourceStatus(
      resourceId: task.itemId,
      status: AppConstants.statusRepaired,
      updatedBy: _helperId,
      note: 'Repair completed by helper',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Repair completed! +${AppConstants.pointsRepaired} points earned.'),
        backgroundColor: AppColors.secondary,
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
                  BoxShadow(color: AppColors.helper.withOpacity(0.05), blurRadius: 20),
                ],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.helper.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello, Helper',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.helper),
                ),
                const Text(
                  'Helper Profile',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<RepairTaskModel>>(
            stream: _firestoreService.streamRepairTasksByHelper(_helperId),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.helper,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '$count TASKS',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFFDAE2FD)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.helper,
              labelColor: AppColors.helper,
              unselectedLabelColor: const Color(0xFF948EA1),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Available Tasks'),
                Tab(text: 'My Tasks'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTasks(),
                _buildMyTasks(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Available Tasks ───────────────────────────────────────────────────────

  Widget _buildAvailableTasks() {
    return StreamBuilder<List<RepairTaskModel>>(
      stream: _firestoreService.streamPendingRepairTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.helper));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_outlined, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                const Text('No repair tasks available', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD))),
                const Text('Check back soon!', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF948EA1))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _buildTaskCard(tasks[i], showAccept: true),
        );
      },
    );
  }

  // ── My Tasks ──────────────────────────────────────────────────────────────

  Widget _buildMyTasks() {
    return StreamBuilder<List<RepairTaskModel>>(
      stream: _firestoreService.streamRepairTasksByHelper(_helperId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.helper));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                const Text('No tasks assigned yet', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDAE2FD))),
                const Text('Accept a task from Available Tasks', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF948EA1))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _buildTaskCard(tasks[i], showAccept: false),
        );
      },
    );
  }

  // ── Task Card ─────────────────────────────────────────────────────────────

  Widget _buildTaskCard(RepairTaskModel task, {required bool showAccept}) {
    final isCompleted = task.isCompleted;

    // Title = item name only. Fallback to 'Repair Task' if somehow empty.
    final cardTitle = task.itemName.isNotEmpty ? task.itemName : 'Repair Task';
    final repairDetail = task.description.isNotEmpty ? task.description : 'No additional details provided.';
    
    // Format Case ID from original logic
    final caseId = '#REF-${task.itemId.length > 6 ? task.itemId.substring(0, 6).toUpperCase() : task.itemId.toUpperCase()}';

    if (showAccept) {
      // ──────────────────────────────────────────────────────────────────
      // Available Tasks Card (Orange Glow Style)
      // ──────────────────────────────────────────────────────────────────
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(color: AppColors.helper.withOpacity(0.15), blurRadius: 20),
          ],
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
                        cardTitle,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5), height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF71717A)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Case ID: $caseId',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: Color(0xFFA1A1AA)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.helper.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.helper.withOpacity(0.2)),
                  ),
                  child: Text(
                    'EST. ₹${task.estimatedCost}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.helper),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              repairDetail,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFA1A1AA)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A3D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.helper),
                      const SizedBox(width: 8),
                      Text(
                        task.status.toUpperCase(),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFD4D4D8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _acceptTask(task),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.helper, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ACCEPT TASK', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.helper, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      );
    } else {
      if (isCompleted) {
        // ──────────────────────────────────────────────────────────────────
        // Completed Task Card
        // ──────────────────────────────────────────────────────────────────
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REPAIR COMPLETED',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: AppColors.secondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cardTitle,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFDAE2FD), decoration: TextDecoration.lineThrough, decorationColor: Color(0xFF52525B)),
                        ),
                        const SizedBox(height: 4),
                        Text('Case ID: $caseId', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFA1A1AA))),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.secondary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Completed', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFD4D4D8))),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // ──────────────────────────────────────────────────────────────────
        // My Tasks Card: In Progress
        // ──────────────────────────────────────────────────────────────────
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.helper.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: AppColors.helper.withOpacity(0.15), blurRadius: 20),
            ],
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.helper.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'IN REPAIR',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: AppColors.helper),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cardTitle,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFDAE2FD)),
                        ),
                        const SizedBox(height: 4),
                        Text('Case ID: $caseId', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFA1A1AA))),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.helper.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop, color: AppColors.helper, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('ASSIGNED', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF71717A))),
                      Text('IN REPAIR', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.helper)),
                      Text('REPAIRED', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF71717A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3449), // surface-container-highest
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.helper,
                              borderRadius: BorderRadius.circular(9999),
                              boxShadow: [
                                BoxShadow(color: AppColors.helper.withOpacity(0.6), blurRadius: 12),
                              ],
                            ),
                          ),
                        ),
                        const Expanded(flex: 1, child: SizedBox()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.helper),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Active Repair Task', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFD4D4D8))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HelperChatScreen(task: task),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF222A3D),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_bubble, color: AppColors.helper, size: 18),
                    label: const Text('Chat with NGO', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDAE2FD))),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _markComplete(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.helper,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Mark Complete', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }
  }
}