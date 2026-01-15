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
  String? _selectedAgeRange; // Age range like "10-12", "12-15", etc.
  int? _selectedAge; // Calculated representative age from range
  String? _selectedEducationLevel; // 'HIGH_SCHOOL' or 'UNIVERSITY'
  String? _selectedSchoolSystem;
  String? _selectedGradeLevel;
  String? _selectedChallengeGradeLevel;
  String? _selectedExamFocus;
  String? _selectedDegree; // For university students
  
  // Age ranges as specified
  static const List<Map<String, dynamic>> _ageRanges = [
    {'range': '10-12', 'min': 10, 'max': 12, 'representative': 11},
    {'range': '12-15', 'min': 12, 'max': 15, 'representative': 13},
    {'range': '15-18', 'min': 15, 'max': 18, 'representative': 16},
    {'range': '18-21', 'min': 18, 'max': 21, 'representative': 19},
    {'range': '21-25', 'min': 21, 'max': 25, 'representative': 23},
    {'range': '25-30', 'min': 25, 'max': 30, 'representative': 27},
    {'range': '30-35', 'min': 30, 'max': 35, 'representative': 32},
    {'range': '35+', 'min': 35, 'max': 100, 'representative': 40},
  ];
  
  // Convert age range to representative age for calculations
  int? _getAgeFromRange(String? range) {
    if (range == null) return null;
    try {
      final ageRange = _ageRanges.firstWhere(
        (ar) => ar['range'] == range,
      );
      return ageRange['representative'] as int;
    } catch (e) {
      return null;
    }
  }
  
  // Convert existing age to age range (for loading saved data)
  String? _getRangeFromAge(int? age) {
    if (age == null) return null;
    for (final range in _ageRanges) {
      final min = range['min'] as int;
      final max = range['max'] as int;
      if (age >= min && age <= max) {
        return range['range'] as String;
      }
    }
    return '35+'; // Default for ages above 35
  }
  
  // Get available grades based on selected school system
  List<GradeLevel> get _availableGrades {
    if (_selectedSchoolSystem == null) {
      return GradeLevel.generalGrades;
    }
    return GradeLevel.getGradesForSystem(_selectedSchoolSystem!);
  }
  
  // Check if user is 18 or older (should choose high school vs university)
  bool get _shouldShowEducationLevelSelection {
    if (_selectedAge == null) return false;
    return _selectedAge! >= 18;
  }
  
  // Check if in university
  bool get _isUniversityStudent {
    return _selectedEducationLevel == 'UNIVERSITY';
  }
  
  // Check if should show grade selection (high school students)
  bool get _shouldShowGradeSelection {
    if (_selectedAge == null) return false;
    if (_selectedAge! < 18) return true; // Under 18, always show grades
    return _selectedEducationLevel == 'HIGH_SCHOOL'; // 18+, only if high school selected
  }

  @override
  void initState() {
    super.initState();
    // Access user after first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (mounted) {
        setState(() {
          // Convert saved age to age range
          _selectedAge = user?.age;
          _selectedAgeRange = _getRangeFromAge(user?.age);
          _selectedSchoolSystem = user?.schoolSystem;
          _selectedGradeLevel = user?.gradeLevel;
          _selectedChallengeGradeLevel = user?.challengeGradeLevel ?? user?.gradeLevel;
          _selectedExamFocus = user?.examFocus ?? 'NONE';
          _selectedEducationLevel = user?.educationModeEnabled == true && user?.age != null && user!.age! >= 18
              ? (user.gradeLevel != null ? 'HIGH_SCHOOL' : 'UNIVERSITY')
              : null;
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
                  DropdownButtonFormField<String>(
                    value: _selectedAgeRange,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    hint: const Text(
                      'Select age range',
                      style: TextStyle(color: Colors.white54),
                    ),
                    items: _ageRanges.map((ageRange) {
                      final range = ageRange['range'] as String;
                      return DropdownMenuItem(
                        value: range,
                        child: Text(range == '35+' ? '35+ years' : '$range years'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgeRange = value;
                        _selectedAge = _getAgeFromRange(value);
                        
                        // Auto-handle education level for different ages
                        if (_selectedAge != null) {
                          if (_selectedAge! < 18) {
                            // Under 18, clear education level (not needed)
                            _selectedEducationLevel = null;
                          }
                          
                          // Auto-suggest grade based on age and school system
                          final systemCode = _selectedSchoolSystem ?? 'GENERAL';
                          final suggestedGrade = GradeLevel.fromAge(_selectedAge!, systemCode);
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
            
            // Education Level Selection (for users 18+)
            if (_shouldShowEducationLevelSelection) ...[
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Education Level',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEducationLevel,
                      decoration: _inputDecoration(),
                      dropdownColor: AppTheme.darkCard,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: 'HIGH_SCHOOL',
                          child: Text('High School'),
                        ),
                        DropdownMenuItem(
                          value: 'UNIVERSITY',
                          child: Text('University'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEducationLevel = value;
                          // Reset selections when switching
                          if (value == 'UNIVERSITY') {
                            _selectedGradeLevel = null;
                            _selectedChallengeGradeLevel = null;
                            _selectedDegree = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // School System (only for high school students)
            if (_shouldShowGradeSelection) ...[
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
                        
                        // Reset grade selections and auto-suggest based on age
                        if (value != null && _selectedAge != null) {
                          final suggestedGrade = GradeLevel.fromAge(_selectedAge!, value);
                          if (suggestedGrade != null) {
                            _selectedGradeLevel = suggestedGrade.code;
                            _selectedChallengeGradeLevel = suggestedGrade.code;
                          } else {
                            // Default to first grade of the new system
                            final grades = GradeLevel.getGradesForSystem(value);
                            if (grades.isNotEmpty) {
                              _selectedGradeLevel = grades.first.code;
                              _selectedChallengeGradeLevel = grades.first.code;
                            }
                          }
                        } else if (value != null) {
                          // No age set, just use first grade
                          final grades = GradeLevel.getGradesForSystem(value);
                          if (grades.isNotEmpty) {
                            _selectedGradeLevel = grades.first.code;
                            _selectedChallengeGradeLevel = grades.first.code;
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            ],
            
            const SizedBox(height: 24),
            
            // Grade Level (for high school students)
            if (_shouldShowGradeSelection) ...[
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
                    value: _availableGrades.any((g) => g.code == _selectedGradeLevel)
                        ? _selectedGradeLevel
                        : null,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: _availableGrades.map((grade) {
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
                    value: _availableGrades.any((g) => g.code == _selectedChallengeGradeLevel)
                        ? _selectedChallengeGradeLevel
                        : null,
                    decoration: _inputDecoration(),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    items: _availableGrades.map((grade) {
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
            ], // Close the spread operator for grade-level fields
            
            // University Degree Selection (for university students)
            if (_isUniversityStudent) ...[
              _buildSectionTitle('Academic Level'),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Degree Program',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.primaryNeon),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: AppTheme.primaryNeon,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDegree,
                      decoration: _inputDecoration(),
                      dropdownColor: AppTheme.darkCard,
                      style: const TextStyle(color: Colors.white60),
                      items: const [
                        DropdownMenuItem(
                          value: 'ENGINEERING',
                          child: Text('Engineering'),
                        ),
                        DropdownMenuItem(
                          value: 'BUSINESS',
                          child: Text('Business Administration'),
                        ),
                        DropdownMenuItem(
                          value: 'COMPUTER_SCIENCE',
                          child: Text('Computer Science'),
                        ),
                        DropdownMenuItem(
                          value: 'MEDICINE',
                          child: Text('Medicine'),
                        ),
                        DropdownMenuItem(
                          value: 'LAW',
                          child: Text('Law'),
                        ),
                        DropdownMenuItem(
                          value: 'ARTS',
                          child: Text('Arts & Humanities'),
                        ),
                        DropdownMenuItem(
                          value: 'SCIENCES',
                          child: Text('Natural Sciences'),
                        ),
                        DropdownMenuItem(
                          value: 'OTHER',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: null, // Disabled - coming soon
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'University-specific content is being developed. Use Exam Preparation below for now.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
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
    
    // Age restrictions
    final meetsAgeRequirement = _meetsAgeRequirementForExam(exam);
    final isDisabled = !meetsAgeRequirement;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : () {
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
            if (isDisabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getAgeRequirementText(exam),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (requiresPayment)
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
    ),
    );
  }

  bool _meetsAgeRequirementForExam(ExamFocus exam) {
    if (_selectedAge == null) return false;
    
    switch (exam) {
      case ExamFocus.sat:
        return _selectedAge! >= 15; // SAT: 15+ years
      case ExamFocus.gmat:
        return _selectedAge! >= 18; // GMAT: 18+ years
      case ExamFocus.none:
        return true;
    }
  }

  String _getAgeRequirementText(ExamFocus exam) {
    switch (exam) {
      case ExamFocus.sat:
        return '15+ only';
      case ExamFocus.gmat:
        return '18+ only';
      case ExamFocus.none:
        return '';
    }
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
    if (_selectedAgeRange == null || _selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your age range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For users 18+, require education level selection
    if (_shouldShowEducationLevelSelection && _selectedEducationLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your education level (High School or University)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Require grade selection only for high school students
    if (_shouldShowGradeSelection && _selectedGradeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your grade level'),
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
      await userProvider.saveUserData(); // Persist education settings
      
      // Track analytics
      // ignore: avoid_print
      print('📊 Analytics: education_settings_saved');
      // ignore: avoid_print
      print('   Age Range: $_selectedAgeRange (Age: $_selectedAge)');
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

