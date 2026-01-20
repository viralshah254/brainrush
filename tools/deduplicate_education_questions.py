#!/usr/bin/env python3
"""
Smart deduplication script for education_questions.json
Removes all duplicate and near-duplicate questions intelligently.
"""

import json
import re
from collections import defaultdict
from typing import List, Dict, Any

def normalize_text(text: str) -> str:
    """Normalize question text by removing ID patterns and extra formatting."""
    if not text:
        return ""
    
    # Remove patterns like "(ID: 123)", "[Q123]", "(ID: 123)?", etc.
    text = re.sub(r'\(ID:\s*\d+\)\??', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\[Q\d+\]\??', '', text)
    text = re.sub(r'\(id:\s*\d+\)\??', '', text, flags=re.IGNORECASE)
    
    # Remove trailing question marks and whitespace
    text = re.sub(r'\?+$', '', text)
    text = text.strip()
    
    # Normalize whitespace
    text = re.sub(r'\s+', ' ', text)
    
    return text.lower()

def normalize_core(text: str) -> str:
    """Normalize to core question text (removes common suffixes and normalizes variations)."""
    normalized = normalize_text(text)
    
    # Remove common suffixes FIRST (before normalizing question words)
    # This ensures "Choose the best answer" is removed regardless of case
    suffixes = [
        r'choose the best answer\.?',
        r'choose the correct answer\.?',
        r'select the best answer\.?',
        r'select the correct answer\.?',
        r'pick the best answer\.?',
        r'pick the correct answer\.?',
        r'choose one\.?',
        r'select one\.?',
    ]
    
    for suffix_pattern in suffixes:
        normalized = re.sub(suffix_pattern + r'$', '', normalized, flags=re.IGNORECASE).strip()
    
    # Remove trailing punctuation after suffix removal
    normalized = re.sub(r'[.,;:]+$', '', normalized).strip()
    
    # Normalize question variations - be more aggressive
    # "What is..." vs "Which is..." vs "Which of the following is..."
    normalized = re.sub(r'^(what|which|who|where|when|why|how)\s+is\s+', r'what is ', normalized)
    normalized = re.sub(r'^(what|which|who|where|when|why|how)\s+are\s+', r'what are ', normalized)
    normalized = re.sub(r'which of the following is', 'what is', normalized)
    normalized = re.sub(r'which of the following are', 'what are', normalized)
    normalized = re.sub(r'^which\s+', 'what ', normalized)  # "Which X" -> "What X"
    
    # Final cleanup - remove any trailing question marks
    normalized = re.sub(r'\?+$', '', normalized).strip()
    
    return normalized

def clean_question_text(text: str) -> str:
    """Clean question text by removing ID patterns and normalizing."""
    if not text:
        return ""
    
    # Remove ID patterns
    text = re.sub(r'\(ID:\s*\d+\)\??', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\[Q\d+\]\??', '', text)
    text = re.sub(r'\(id:\s*\d+\)\??', '', text, flags=re.IGNORECASE)
    
    # Remove trailing question marks (keep only one)
    text = re.sub(r'\?+$', '?', text)
    
    # Normalize whitespace
    text = re.sub(r'\s+', ' ', text)
    
    return text.strip()

def score_question(question: Dict[str, Any]) -> float:
    """Score a question to determine which duplicate to keep (higher is better)."""
    score = 0.0
    
    text = question.get('text', '')
    
    # Prefer questions without ID patterns
    if not re.search(r'\(ID:\s*\d+\)|\[Q\d+\]', text, re.IGNORECASE):
        score += 10.0
    
    # Prefer questions with complete metadata
    if question.get('explanation'):
        score += 5.0
    if question.get('options') and len(question.get('options', [])) >= 4:
        score += 3.0
    if question.get('topic'):
        score += 2.0
    if question.get('standards'):
        score += 2.0
    
    # Prefer questions with cleaner text (no "Choose the best answer" suffix)
    if not re.search(r'choose the (best|correct) answer', text.lower()):
        score += 1.0
    
    # Prefer questions with proper capitalization
    if text and text[0].isupper():
        score += 0.5
    
    return score

def deduplicate_questions(questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Remove duplicates and near-duplicates, keeping the best version of each."""
    print(f'📚 Processing {len(questions)} questions...')
    
    # Group by normalized core text
    core_groups = defaultdict(list)
    for i, q in enumerate(questions):
        text = q.get('text', '')
        core = normalize_core(text)
        if core:
            core_groups[core].append((i, q))
    
    print(f'📊 Found {len(core_groups)} unique core questions')
    print(f'   Total duplicates: {sum(len(v) for v in core_groups.values() if len(v) > 1)}')
    
    # Keep only the best question from each group
    unique_questions = []
    removed_count = 0
    
    for core, group in core_groups.items():
        if len(group) == 1:
            # No duplicates, keep as is
            _, q = group[0]
            # Clean the text
            q['text'] = clean_question_text(q.get('text', ''))
            unique_questions.append(q)
        else:
            # Multiple duplicates - keep the best one
            scored = [(score_question(q), idx, q) for idx, q in group]
            scored.sort(reverse=True)  # Sort by score descending
            
            # Keep the best question
            _, best_idx, best_q = scored[0]
            best_q['text'] = clean_question_text(best_q.get('text', ''))
            unique_questions.append(best_q)
            
            removed_count += len(group) - 1
    
    print(f'\n✅ Deduplication complete!')
    print(f'   Original: {len(questions)} questions')
    print(f'   Unique: {len(unique_questions)} questions')
    print(f'   Removed: {removed_count} duplicates')
    print(f'   Reduction: {removed_count/len(questions)*100:.1f}%')
    
    return unique_questions

def main():
    print('🔍 Smart Deduplication of education_questions.json')
    print('=' * 60)
    
    # Load questions
    input_file = 'assets/questions/education_questions.json'
    output_file = 'assets/questions/education_questions.json'
    backup_file = 'assets/questions/education_questions.json.backup_dedup'
    
    print(f'\n📖 Loading {input_file}...')
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            questions = json.load(f)
        print(f'✅ Loaded {len(questions)} questions')
    except Exception as e:
        print(f'❌ Error loading file: {e}')
        return
    
    # Create backup
    print(f'\n💾 Creating backup: {backup_file}...')
    try:
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(questions, f, indent=2, ensure_ascii=False)
        print(f'✅ Backup created')
    except Exception as e:
        print(f'⚠️  Warning: Could not create backup: {e}')
    
    # Deduplicate
    print(f'\n🔧 Deduplicating questions...')
    unique_questions = deduplicate_questions(questions)
    
    # Save deduplicated questions
    print(f'\n💾 Saving deduplicated questions to {output_file}...')
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(unique_questions, f, indent=2, ensure_ascii=False)
        print(f'✅ Saved {len(unique_questions)} unique questions')
    except Exception as e:
        print(f'❌ Error saving file: {e}')
        import traceback
        traceback.print_exc()
        return
    
    # Final pass: Remove any remaining duplicates by exact normalized text match
    print(f'\n🔧 Final pass: Removing any remaining duplicates...')
    seen_cores = {}
    final_questions = []
    removed_final = 0
    
    # Sort by score descending to keep best questions
    scored_questions = [(score_question(q), q) for q in unique_questions]
    scored_questions.sort(key=lambda x: x[0], reverse=True)  # Sort by score only
    
    for score, q in scored_questions:
        text = q.get('text', '')
        core = normalize_core(text)
        
        if not core:
            final_questions.append(q)
            continue
        
        if core not in seen_cores:
            seen_cores[core] = q
            final_questions.append(q)
        else:
            # Duplicate found - skip (we already have the best one since sorted by score)
            removed_final += 1
    
    unique_questions = final_questions
    
    if removed_final > 0:
        print(f'   Removed {removed_final} additional duplicates in final pass')
    
    # Verify no duplicates remain
    print(f'\n🔍 Verifying no duplicates remain...')
    core_groups = defaultdict(list)
    for q in unique_questions:
        text = q.get('text', '')
        core = normalize_core(text)
        if core:
            core_groups[core].append(q.get('id'))
    
    remaining_duplicates = {k: v for k, v in core_groups.items() if len(v) > 1}
    if remaining_duplicates:
        print(f'⚠️  Warning: Found {len(remaining_duplicates)} groups still with duplicates!')
        for core, ids in list(remaining_duplicates.items())[:5]:
            print(f'   "{core[:60]}...": {len(ids)} duplicates')
    else:
        print(f'✅ Verification passed: No duplicates found!')
    
    print(f'\n✅ Deduplication complete!')
    print(f'   Final count: {len(unique_questions)} unique questions')

if __name__ == '__main__':
    main()

