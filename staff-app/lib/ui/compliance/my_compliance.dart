import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/compliance_service.dart';
import 'package:staff_app/models/compliance_flag.dart';
import 'package:staff_app/models/compliance_score.dart';
import 'package:staff_app/models/teaching_moment.dart';

class MyComplianceScreen extends StatefulWidget {
  @override
  _MyComplianceScreenState createState() => _MyComplianceScreenState();
}

class _MyComplianceScreenState extends State<MyComplianceScreen> {
  late ComplianceService _complianceService;
  late Stream<List<ComplianceFlag>> _flagsStream;
  late Stream<List<ComplianceScore>> _scoresStream;
  late Stream<List<TeachingMoment>> _teachingMomentsStream;

  @override
  void initState() {
    super.initState();
    _complianceService = Provider.of<ComplianceService>(context, listen: false);
    // Get current user ID from auth service
    final userId = 'current_user_id'; // This should come from auth service
    _flagsStream = _complianceService.getComplianceFlagsByCarer(userId);
    _scoresStream = _complianceService.getComplianceScoresByCarer(userId);
    _teachingMomentsStream = _complianceService.getTeachingMomentsByUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Compliance'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Issues'),
              Tab(text: 'Learning'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildIssuesTab(),
            _buildLearningTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Compliance Score
          _buildComplianceScoreCard(),
          SizedBox(height: 16),
          
          // Recent Issues
          _buildRecentIssuesSection(),
          SizedBox(height: 16),
          
          // Learning Progress
          _buildLearningProgressSection(),
          SizedBox(height: 16),
          
          // Improvement Suggestions
          _buildImprovementSuggestionsSection(),
        ],
      ),
    );
  }

  Widget _buildComplianceScoreCard() {
    return StreamBuilder<List<ComplianceScore>>(
      stream: _scoresStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error loading compliance score');
        }

        final scores = snapshot.data ?? [];
        final latestScore = scores.isNotEmpty ? scores.first : null;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Current Compliance Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                if (latestScore != null)
                  Column(
                    children: [
                      Text('${latestScore.overallScore ?? 0}%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _getScoreColor(latestScore.overallScore ?? 0))),
                      SizedBox(height: 8),
                      _buildScoreBreakdown(latestScore),
                    ],
                  )
                else
                  Text('No score available yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildScoreBreakdown(ComplianceScore score) {
    return Column(
      children: [
        _buildScoreRow('Duration', score.durationCompliance ?? 0, Colors.blue),
        _buildScoreRow('Documentation', score.documentationCompliance ?? 0, Colors.green),
        _buildScoreRow('Medication', score.medicationCompliance ?? 0, Colors.orange),
        _buildScoreRow('Incident Reporting', score.incidentReportingCompliance ?? 0, Colors.purple),
      ],
    );
  }

  Widget _buildScoreRow(String label, double score, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${score.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIssuesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Compliance Issues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 16),
            StreamBuilder<List<ComplianceFlag>>(
              stream: _flagsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error loading issues');
                }

                final flags = snapshot.data ?? [];
                final recentFlags = flags.take(3).toList();

                if (recentFlags.isEmpty) {
                  return Column(
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 8),
                      Text('No recent issues!', style: TextStyle(color: Colors.green)),
                    ],
                  );
                }

                return Column(
                  children: recentFlags.map((flag) => _buildIssueCard(flag)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(ComplianceFlag flag) {
    Color severityColor = Colors.green;
    IconData severityIcon = Icons.check_circle;
    
    switch (flag.severity) {
      case 'CRITICAL':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'WARNING':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'INFO':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(flag.ruleName, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(flag.severity, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(flag.message, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 8),
            if (flag.regulationReference != null)
              Text('Regulation: ${flag.regulationReference}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (flag.suggestedAction != null)
              Text('Suggested Action: ${flag.suggestedAction}', style: TextStyle(fontSize: 12, color: Colors.blue)),
            SizedBox(height: 8),
            Text('Date: ${flag.createdAt.toString()}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgressSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Learning Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 16),
            StreamBuilder<List<TeachingMoment>>(
              stream: _teachingMomentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error loading learning progress');
                }

                final moments = snapshot.data ?? [];
                final totalMoments = moments.length;
                final completedMoments = moments.where((m) => m.quizPassed == true).length;
                final pendingMoments = totalMoments - completedMoments;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('$completedMoments / $totalMoments', style: TextStyle(fontSize: 24, color: Colors.green)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('$pendingMoments', style: TextStyle(fontSize: 24, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (pendingMoments > 0)
                      Text('Complete pending learning moments to improve your compliance score'),
                    SizedBox(height: 16),
                    if (pendingMoments > 0)
                      _buildPendingMomentsList(moments.where((m) => m.quizPassed != true).toList()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMomentsList(List<TeachingMoment> pendingMoments) {
    return Column(
      children: pendingMoments.map((moment) => Card(
        margin: EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(moment.title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(moment.content, style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (moment.videoUrl != null)
                Text('Video available', style: TextStyle(color: Colors.blue)),
              if (moment.policyUrl != null)
                Text('Policy document available', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildImprovementSuggestionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Improvement Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: _complianceService.getComplianceInsights(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error loading suggestions');
                }

                final insights = snapshot.data;
                if (insights == null || insights['recommendations'] == null) {
                  return Text('No specific suggestions at this time. Keep up the good work!');
                }

                final recommendations = insights['recommendations'] as List<dynamic>;
                
                return Column(
                  children: recommendations.map((rec) => Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(rec['recommendation'] ?? ''),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesTab() {
    return StreamBuilder<List<ComplianceFlag>>(
      stream: _flagsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error loading issues');
        }

        final flags = snapshot.data ?? [];

        if (flags.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No compliance issues!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Keep up the excellent work!'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: flags.length,
          itemBuilder: (context, index) => _buildIssueCard(flags[index]),
        );
      },
    );
  }

  Widget _buildLearningTab() {
    return StreamBuilder<List<TeachingMoment>>(
      stream: _teachingMomentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error loading learning content');
        }

        final moments = snapshot.data ?? [];

        if (moments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text('No learning content assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Your supervisor will assign learning content as needed'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: moments.length,
          itemBuilder: (context, index) => _buildLearningCard(moments[index]),
        );
      },
    );
  }

  Widget _buildLearningCard(TeachingMoment moment) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(moment.title, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (moment.quizPassed == true)
                  Icon(Icons.check_circle, color: Colors.green)
                else
                  Icon(Icons.pending_actions, color: Colors.orange),
              ],
            ),
            SizedBox(height: 8),
            Text(moment.content, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 8),
            if (moment.videoUrl != null)
              _buildLearningAction('Watch Video', moment.videoUrl!),
            if (moment.policyUrl != null)
              _buildLearningAction('Read Policy', moment.policyUrl!),
            if (moment.quizRequired)
              _buildQuizButton(moment),
            SizedBox(height: 8),
            Text('Assigned: ${moment.createdAt.toString()}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningAction(String label, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: Colors.blue))),
          Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildQuizButton(TeachingMoment moment) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to quiz screen
          // This would need to be implemented
        },
        child: Text(moment.quizPassed == true ? 'Quiz Completed' : 'Take Quiz'),
        style: ElevatedButton.styleFrom(
          backgroundColor: moment.quizPassed == true ? Colors.green : Colors.blue,
        ),
      ),
    );
  }
}