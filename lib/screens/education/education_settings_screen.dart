import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_mode.dart';
import '../../providers/user_provider.dart';
import '../../services/education_subscription_service.dart';
import 'education_paywall_screen.dart';

class EducationSettingsScreen extends StatefulWidget {
  const EducationSettingsScreen({super.key});

  @override
  State<EducationSettingsScreen> createState() => _EducationSettingsScreenState();
}

class _EducationSettingsScreenState extends State<EducationSettingsScreen> {
  int? _selectedAge;
  String? _selectedSchoolSystem;
  String? _selectedGradeLevel;
  String? _selectedChallengeGradeLevel;
  String? _selectedExamFocus;

  @override
  void initState() {
    super.initState();
    // Access user after first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (mounted) {
        setState(() {
          _selectedAge = user?.age;
          _selectedSchoolSystem = user?.schoolSystem;
          _selectedGradeLevel = user?.gradeLevel;
          _selectedChallengeGradeLevel = user?.challengeGradeLevel ?? user?.gradeLevel;
          _selectedExamFocus = user?.examFocus ?? 'NONE';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = context.watch<EducationSubscriptionService>();
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Education Settings',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryNeon),
            onPressed: () => _saveSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Age
            _buildSectionTitle('Basic Information'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Age',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedAge,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: List.generate(13, (index) => index + 10).map((age) {
                      return DropdownMenuItem(
                        value: age,
                        child: Text('$age years old'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAge = value;
                        // Auto-suggest grade based on age
                        if (value != null) {
                          final suggestedGrade = GradeLevel.fromAge(value);
                          if (suggestedGrade != null) {
                            _selectedGradeLevel = suggestedGrade.code;
                            _selectedChallengeGradeLevel = suggestedGrade.code;
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // School System
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'School System',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSchoolSystem,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: SchoolSystem.values.map((system) {
                      return DropdownMenuItem(
                        value: system.code,
                        child: Text(system.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSchoolSystem = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Grade Level
            _buildSectionTitle('Academic Level'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Grade Level',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGradeLevel,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: GradeLevel.allGrades.map((grade) {
                      return DropdownMenuItem(
                        value: grade.code,
                        child: Text(grade.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGradeLevel = value;
                        _selectedChallengeGradeLevel ??= value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Challenge Grade Level
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Challenge Level',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Practice questions from a different grade',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedChallengeGradeLevel,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: GradeLevel.allGrades.map((grade) {
                      return DropdownMenuItem(
                        value: grade.code,
                        child: Text(grade.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChallengeGradeLevel = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Exam Focus
            _buildSectionTitle('Exam Preparation'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exam Focus',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...ExamFocus.values.map((exam) => _buildExamOption(
                    context,
                    exam,
                    subscriptionService,
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Manage Subscriptions
            if (subscriptionService.hasAnyEducationSubscription)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Subscriptions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (subscriptionService.hasSatSubscription)
                      _buildSubscriptionBadge('SAT Prep', true),
                    if (subscriptionService.hasGmatSubscription)
                      _buildSubscriptionBadge('GMAT Prep', true),
                    if (subscriptionService.hasAllAccessSubscription)
                      _buildSubscriptionBadge('All Access', true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryNeon,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppTheme.darkBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.primaryNeon, width: 2),
      ),
    );
  }

  Widget _buildExamOption(
    BuildContext context,
    ExamFocus exam,
    EducationSubscriptionService subscriptionService,
  ) {
    final isSelected = _selectedExamFocus == exam.code;
    final hasAccess = subscriptionService.canAccessExamMode(exam);
    final requiresPayment = exam.requiresSubscription && !hasAccess;

    return GestureDetector(
      onTap: () {
        if (requiresPayment) {
          // Show paywall
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EducationPaywallScreen(examFocus: exam),
            ),
          );
        } else {
          setState(() {
            _selectedExamFocus = exam.code;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNeon.withOpacity(0.1) : AppTheme.darkBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : Colors.white10,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryNeon : Colors.white30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exam.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (requiresPayment)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '\$6/mo',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (exam.requiresSubscription)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(String name, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: active ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: active ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    
    // Validate required fields
    if (_selectedAge == null || _selectedGradeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update user
    final updatedUser = userProvider.user?.copyWith(
      age: _selectedAge,
      schoolSystem: _selectedSchoolSystem,
      gradeLevel: _selectedGradeLevel,
      challengeGradeLevel: _selectedChallengeGradeLevel,
      examFocus: _selectedExamFocus,
      educationModeEnabled: true,
    );

    if (updatedUser != null) {
      userProvider.setUser(updatedUser);
      
      // Track analytics
      // ignore: avoid_print
      print('📊 Analytics: education_settings_saved');
      // ignore: avoid_print
      print('   Grade: $_selectedGradeLevel');
      // ignore: avoid_print
      print('   Exam: $_selectedExamFocus');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Education settings saved! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }
}

