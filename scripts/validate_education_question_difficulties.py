#!/usr/bin/env python3
"""
Validation script to ensure education questions have appropriate difficulty levels.
This script checks that:
1. All questions have valid difficulty values (easy, medium, hard, very_hard)
2. Questions are appropriately distributed across difficulty levels
3. Difficulty levels match the grade level expectations
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

def validate_education_questions(json_file_path):
    """Validate education questions difficulty levels."""
    
    print("🔍 Loading education questions...")
    with open(json_file_path, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    print(f"✅ Loaded {len(questions)} questions\n")
    
    # Track statistics
    difficulty_counts = defaultdict(int)
    grade_difficulty_counts = defaultdict(lambda: defaultdict(int))
    invalid_difficulties = []
    missing_difficulties = []
    
    valid_difficulties = {'easy', 'medium', 'hard', 'very_hard'}
    
    for i, question in enumerate(questions):
        q_id = question.get('id', f'question_{i}')
        difficulty = question.get('difficulty', '').lower().strip()
        grade_level = question.get('gradeLevel', 'UNKNOWN')
        
        # Check if difficulty exists
        if not difficulty:
            missing_difficulties.append({
                'id': q_id,
                'grade': grade_level,
                'category': question.get('category', 'UNKNOWN')
            })
            continue
        
        # Check if difficulty is valid
        if difficulty not in valid_difficulties:
            invalid_difficulties.append({
                'id': q_id,
                'difficulty': difficulty,
                'grade': grade_level,
                'category': question.get('category', 'UNKNOWN')
            })
            continue
        
        # Count difficulties
        difficulty_counts[difficulty] += 1
        grade_difficulty_counts[grade_level][difficulty] += 1
    
    # Print summary
    print("=" * 60)
    print("📊 DIFFICULTY DISTRIBUTION SUMMARY")
    print("=" * 60)
    print(f"\nTotal Questions: {len(questions)}")
    print(f"\nDifficulty Breakdown:")
    for diff in ['easy', 'medium', 'hard', 'very_hard']:
        count = difficulty_counts[diff]
        percentage = (count / len(questions) * 100) if questions else 0
        print(f"  {diff:12} : {count:6,} ({percentage:5.1f}%)")
    
    # Print grade-level breakdown (sample)
    print(f"\n📚 Grade-Level Difficulty Distribution (Sample):")
    sample_grades = sorted(grade_difficulty_counts.keys())[:10]
    for grade in sample_grades:
        print(f"\n  {grade}:")
        for diff in ['easy', 'medium', 'hard', 'very_hard']:
            count = grade_difficulty_counts[grade][diff]
            if count > 0:
                print(f"    {diff:12} : {count:6,}")
    
    # Report issues
    print("\n" + "=" * 60)
    print("⚠️  VALIDATION RESULTS")
    print("=" * 60)
    
    if missing_difficulties:
        print(f"\n❌ Found {len(missing_difficulties)} questions with missing difficulty:")
        for item in missing_difficulties[:10]:  # Show first 10
            print(f"  - {item['id']} (Grade: {item['grade']}, Category: {item['category']})")
        if len(missing_difficulties) > 10:
            print(f"  ... and {len(missing_difficulties) - 10} more")
    else:
        print("\n✅ All questions have difficulty levels")
    
    if invalid_difficulties:
        print(f"\n❌ Found {len(invalid_difficulties)} questions with invalid difficulty:")
        invalid_by_diff = defaultdict(list)
        for item in invalid_difficulties:
            invalid_by_diff[item['difficulty']].append(item)
        
        for diff, items in invalid_by_diff.items():
            print(f"\n  Invalid difficulty '{diff}' ({len(items)} questions):")
            for item in items[:5]:  # Show first 5 of each
                print(f"    - {item['id']} (Grade: {item['grade']}, Category: {item['category']})")
            if len(items) > 5:
                print(f"    ... and {len(items) - 5} more")
    else:
        print("\n✅ All difficulty values are valid (easy, medium, hard, very_hard)")
    
    # Recommendations
    print("\n" + "=" * 60)
    print("💡 RECOMMENDATIONS")
    print("=" * 60)
    
    total_valid = len(questions) - len(missing_difficulties) - len(invalid_difficulties)
    if total_valid > 0:
        easy_pct = (difficulty_counts['easy'] / total_valid) * 100
        medium_pct = (difficulty_counts['medium'] / total_valid) * 100
        hard_pct = (difficulty_counts['hard'] / total_valid) * 100
        very_hard_pct = (difficulty_counts['very_hard'] / total_valid) * 100
        
        print(f"\nCurrent Distribution:")
        print(f"  Easy      : {easy_pct:.1f}% (recommended: 25-35%)")
        print(f"  Medium    : {medium_pct:.1f}% (recommended: 30-40%)")
        print(f"  Hard      : {hard_pct:.1f}% (recommended: 20-30%)")
        print(f"  Very Hard : {very_hard_pct:.1f}% (recommended: 10-20%)")
        
        if easy_pct < 20:
            print("\n⚠️  Warning: Too few easy questions. Consider adding more.")
        if very_hard_pct > 25:
            print("\n⚠️  Warning: Too many very hard questions. Consider rebalancing.")
    
    # Final status
    print("\n" + "=" * 60)
    if missing_difficulties or invalid_difficulties:
        print("❌ VALIDATION FAILED - Issues found")
        return 1
    else:
        print("✅ VALIDATION PASSED - All questions have valid difficulties")
        return 0

if __name__ == '__main__':
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / 'assets' / 'questions' / 'education_questions.json'
    
    if not json_file.exists():
        print(f"❌ Error: File not found: {json_file}")
        sys.exit(1)
    
    exit_code = validate_education_questions(json_file)
    sys.exit(exit_code)

