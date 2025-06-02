import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/DataService.dart';
import '../Theme/AppTheme.dart';
import '../Cards/InternshipApplicationCard.dart';
import '../Cards/AssessmentResultCard.dart';
import '../Cards/ATSResultCard.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({Key? key, required this.text, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}



// Modern Student History Page
class StudentHistoryPage extends StatefulWidget {
  const StudentHistoryPage({Key? key}) : super(key: key);

  @override
  _StudentHistoryPageState createState() => _StudentHistoryPageState();
}

class _StudentHistoryPageState extends State<StudentHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String userId;
  late StudentHistoryService _historyService;

  List<InternshipApplication> _applications = [];
  List<AssessmentResult> _assessments = [];
  List<ATSResult> _atsResults = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Get current user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle not logged in state
      setState(() {
        _isLoading = false;
      });
      return;
    }

    userId = user.uid;
    _historyService = StudentHistoryService(userId: userId);
    await _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final applications = await _historyService.getInternshipApplications();
      final assessments = await _historyService.getAssessmentResults();
      final atsResults = await _historyService.getATSResults();

      setState(() {
        _applications = applications;
        _assessments = assessments;
        _atsResults = atsResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching student history data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Student History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Internships'),
            Tab(text: 'Assessments'),
            Tab(text: 'ATS Analysis'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildInternshipTab(),
          _buildAssessmentTab(),
          _buildATSTab(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipTab() {
    if (_applications.isEmpty) {
      return _buildEmptyState(
        'No internship applications found',
        Icons.work_off,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          return InternshipApplicationCard(
            application: _applications[index],
          );
        },
      ),
    );
  }

  Widget _buildAssessmentTab() {
    if (_assessments.isEmpty) {
      return _buildEmptyState(
        'No assessment results found',
        Icons.assessment_outlined,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: _assessments.length,
        itemBuilder: (context, index) {
          return AssessmentResultCard(
            result: _assessments[index],
          );
        },
      ),
    );
  }

  Widget _buildATSTab() {
    if (_atsResults.isEmpty) {
      return _buildEmptyState(
        'No ATS analysis results found',
        Icons.description_outlined,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: _atsResults.length,
        itemBuilder: (context, index) {
          return ATSResultCard(
            result: _atsResults[index],
          );
        },
      ),
    );
  }
}