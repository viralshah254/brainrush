#!/usr/bin/env python3
"""
Generate UK Year 11 Math Questions
Covers GCSE/IGCSE Year 11 Mathematics syllabus topics
"""

import json
import random
import uuid
import math
from typing import List, Dict

GRADE_LEVEL = 'UK_YEAR_11'
SUBJECT = 'Math'
DIFFICULTIES = ['easy', 'medium', 'hard', 'very_hard']

def generate_quadratic_question(difficulty: str, question_num: int) -> Dict:
    """Generate quadratic equation questions"""
    if difficulty == 'easy':
        # Simple factorable quadratics: (x + a)(x + b) = 0
        a, b = random.randint(1, 10), random.randint(1, 10)
        if random.choice([True, False]):
            # x² + (a+b)x + ab = 0, solution is -a or -b
            text = f"Solve: x² + {a+b}x + {a*b} = 0"
            correct = f"-{a}" if random.choice([True, False]) else f"-{b}"
        else:
            # x² - (a+b)x + ab = 0, solution is a or b
            text = f"Solve: x² - {a+b}x + {a*b} = 0"
            correct = str(a) if random.choice([True, False]) else str(b)
    elif difficulty == 'medium':
        # Use quadratic formula
        a, b, c = random.randint(1, 5), random.randint(-10, 10), random.randint(-10, 10)
        discriminant = b**2 - 4*a*c
        if discriminant >= 0:
            x1 = (-b + math.sqrt(discriminant)) / (2*a)
            text = f"Solve: {a}x² + {b}x + {c} = 0"
            correct = f"{x1:.1f}"
        else:
            # Fallback to simple case
            a, b = 1, -5
            text = f"Solve: x² - 5x + 6 = 0"
            correct = "2 or 3"
    elif difficulty == 'hard':
        # Completing the square or harder quadratics
        a, b, c = random.randint(2, 5), random.randint(-15, 15), random.randint(-15, 15)
        discriminant = b**2 - 4*a*c
        if discriminant >= 0:
            x1 = (-b + math.sqrt(discriminant)) / (2*a)
            text = f"Solve using the quadratic formula: {a}x² + {b}x + {c} = 0"
            correct = f"{x1:.2f}"
        else:
            text = f"Solve: 2x² - 8x + 6 = 0"
            correct = "1 or 3"
    else:  # very_hard
        # Simultaneous equations with quadratics or word problems
        text = "A rectangle has length x and width y. If x + y = 10 and xy = 21, what is x?"
        correct = "7 or 3"
    
    wrong_answers = [f"{random.randint(-10, 10)}", f"{random.randint(-10, 10)}", f"{random.randint(-10, 10)}"]
    options = [correct] + wrong_answers
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_quad_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of quadratic equations for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "quadratic_equations",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

def generate_algebra_question(difficulty: str, question_num: int) -> Dict:
    """Generate algebra questions"""
    if difficulty == 'easy':
        # Simple linear equations
        a, b = random.randint(2, 10), random.randint(1, 20)
        c = a * random.randint(2, 10) + b
        x = (c - b) // a
        text = f"Solve for x: {a}x + {b} = {c}"
        correct = str(x)
    elif difficulty == 'medium':
        # Simultaneous equations
        x, y = random.randint(1, 10), random.randint(1, 10)
        a1, b1 = random.randint(2, 5), random.randint(2, 5)
        c1 = a1 * x + b1 * y
        text = f"Solve the simultaneous equations: {a1}x + {b1}y = {c1} and x + y = {x + y}"
        correct = f"x = {x}, y = {y}"
    elif difficulty == 'hard':
        # Inequalities or more complex algebra
        a, b = random.randint(2, 10), random.randint(1, 20)
        text = f"Solve the inequality: {a}x + {b} > {a * 5 + b}"
        correct = "x > 5"
    else:  # very_hard
        # Algebraic fractions or complex expressions
        text = f"Simplify: (x² + {random.randint(2,5)}x + {random.randint(1,6)}) / (x + {random.randint(1,3)})"
        correct = "x + 3"
    
    wrong_answers = [f"{random.randint(-10, 10)}", f"{random.randint(-10, 10)}", f"{random.randint(-10, 10)}"]
    options = [correct] + wrong_answers
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_alg_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of algebra for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "algebra",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

def generate_geometry_question(difficulty: str, question_num: int) -> Dict:
    """Generate geometry questions"""
    if difficulty == 'easy':
        # Basic area/perimeter
        l, w = random.randint(5, 15), random.randint(5, 15)
        text = f"A rectangle has length {l} cm and width {w} cm. What is its area?"
        correct = f"{l * w} cm²"
    elif difficulty == 'medium':
        # Pythagoras theorem
        a, b = random.randint(3, 12), random.randint(3, 12)
        c = math.sqrt(a**2 + b**2)
        text = f"A right triangle has legs of {a} cm and {b} cm. What is the length of the hypotenuse?"
        correct = f"{c:.1f} cm"
    elif difficulty == 'hard':
        # Trigonometry
        angle = random.choice([30, 45, 60])
        side = random.randint(5, 15)
        if angle == 30:
            opp = side * 0.5
            text = f"In a right triangle, the hypotenuse is {side} cm and one angle is 30°. What is the length of the opposite side?"
            correct = f"{opp:.1f} cm"
        elif angle == 45:
            text = f"In a right triangle with a 45° angle, if one side is {side} cm, what is the hypotenuse?"
            correct = f"{side * math.sqrt(2):.1f} cm"
        else:  # 60
            adj = side * 0.5
            text = f"In a right triangle, the hypotenuse is {side} cm and one angle is 60°. What is the length of the adjacent side?"
            correct = f"{adj:.1f} cm"
    else:  # very_hard
        # Circle theorems or advanced geometry
        radius = random.randint(5, 15)
        text = f"A circle has radius {radius} cm. What is its area?"
        correct = f"{math.pi * radius**2:.1f} cm²"
    
    wrong_answers = [f"{random.randint(10, 200)} cm²", f"{random.randint(10, 200)} cm", f"{random.randint(10, 200)}"]
    options = [correct] + wrong_answers
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_geo_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of geometry for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "geometry",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

def generate_statistics_question(difficulty: str, question_num: int) -> Dict:
    """Generate statistics and probability questions"""
    if difficulty == 'easy':
        # Basic mean
        numbers = [random.randint(10, 100) for _ in range(5)]
        mean = sum(numbers) / len(numbers)
        text = f"Find the mean of: {', '.join(map(str, numbers))}"
        correct = f"{mean:.1f}"
    elif difficulty == 'medium':
        # Probability
        text = f"What is the probability of rolling a 6 on a fair die?"
        correct = "1/6"
    elif difficulty == 'hard':
        # Combined probability
        text = "A bag contains 5 red and 3 blue balls. What is the probability of drawing a red ball?"
        correct = "5/8"
    else:  # very_hard
        # Conditional probability or more complex stats
        text = "If two dice are rolled, what is the probability of getting a sum of 7?"
        correct = "1/6"
    
    wrong_answers = [f"{random.uniform(0, 1):.2f}", f"{random.randint(1, 10)}/{random.randint(1, 10)}", f"{random.randint(1, 10)}%"]
    options = [correct] + wrong_answers
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_stat_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of statistics and probability for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "statistics",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

def generate_calculus_question(difficulty: str, question_num: int) -> Dict:
    """Generate basic calculus questions"""
    if difficulty == 'easy':
        # Simple derivatives
        text = "What is the derivative of f(x) = x²?"
        correct = "2x"
    elif difficulty == 'medium':
        # Derivatives with constants
        n = random.randint(2, 5)
        text = f"What is the derivative of f(x) = x³ + {n}?"
        correct = "3x²"
    elif difficulty == 'hard':
        # More complex derivatives
        text = "What is the derivative of f(x) = 3x² + 2x + 1?"
        correct = "6x + 2"
    else:  # very_hard
        # Chain rule or product rule
        text = "What is the derivative of f(x) = (x + 1)²?"
        correct = "2(x + 1)"
    
    wrong_answers = ["x", "x²", "2x²", "x + 1"]
    options = [correct] + wrong_answers[:3]
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_calc_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of calculus for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "calculus",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

def generate_functions_question(difficulty: str, question_num: int) -> Dict:
    """Generate function questions"""
    if difficulty == 'easy':
        # Function evaluation
        x = random.randint(1, 10)
        text = f"If f(x) = 2x + 3, what is f({x})?"
        correct = str(2 * x + 3)
    elif difficulty == 'medium':
        # Function composition
        text = "If f(x) = x + 2 and g(x) = 2x, what is f(g(3))?"
        correct = "8"
    elif difficulty == 'hard':
        # Inverse functions
        text = "If f(x) = 2x + 1, what is f⁻¹(5)?"
        correct = "2"
    else:  # very_hard
        # Complex functions
        text = "What is the range of the function f(x) = x² + 1?"
        correct = "[1, ∞)"
    
    wrong_answers = [f"{random.randint(1, 20)}", f"{random.randint(1, 20)}", f"{random.randint(1, 20)}"]
    options = [correct] + wrong_answers
    random.shuffle(options)
    correct_index = options.index(correct)
    
    return {
        "id": f"edu_{GRADE_LEVEL.lower()}_math_func_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of functions for {GRADE_LEVEL}.",
        "category": SUBJECT,
        "difficulty": difficulty,
        "topic": "functions",
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": GRADE_LEVEL,
        "source": "CURATED",
        "language": "EN"
    }

# Topic generators
TOPIC_GENERATORS = {
    'quadratic_equations': generate_quadratic_question,
    'algebra': generate_algebra_question,
    'geometry': generate_geometry_question,
    'statistics': generate_statistics_question,
    'calculus': generate_calculus_question,
    'functions': generate_functions_question,
}

def generate_questions_for_grade_subject(count: int = 500) -> List[Dict]:
    """Generate questions for UK Year 11 Math"""
    questions = []
    
    # Distribute across difficulties
    difficulty_counts = {
        'easy': int(count * 0.4),      # 200 questions
        'medium': int(count * 0.3),    # 150 questions
        'hard': int(count * 0.2),      # 100 questions
        'very_hard': int(count * 0.1), # 50 questions
    }
    
    question_num = 1
    topics = list(TOPIC_GENERATORS.keys())
    
    for difficulty, num_questions in difficulty_counts.items():
        # Distribute questions across topics
        questions_per_topic = num_questions // len(topics)
        remainder = num_questions % len(topics)
        
        for topic_idx, topic in enumerate(topics):
            generator = TOPIC_GENERATORS[topic]
            topic_count = questions_per_topic + (1 if topic_idx < remainder else 0)
            
            for i in range(topic_count):
                questions.append(generator(difficulty, question_num))
                question_num += 1
    
    # Fill remaining if count doesn't match exactly
    while len(questions) < count:
        difficulty = random.choice(DIFFICULTIES)
        topic = random.choice(topics)
        generator = TOPIC_GENERATORS[topic]
        questions.append(generator(difficulty, question_num))
        question_num += 1
    
    return questions[:count]

def main():
    """Generate UK Year 11 Math questions"""
    print(f"🎓 Generating {SUBJECT} questions for {GRADE_LEVEL}...")
    print("=" * 60)
    
    # Generate 500 questions
    questions = generate_questions_for_grade_subject(count=500)
    
    print(f"✅ Generated {len(questions)} questions")
    
    # Load existing questions
    existing_file = 'assets/questions/education_questions.json'
    existing_questions = []
    
    try:
        with open(existing_file, 'r', encoding='utf-8') as f:
            existing_questions = json.load(f)
        print(f"📂 Loaded {len(existing_questions)} existing questions")
    except FileNotFoundError:
        print("📂 No existing questions file found, creating new one")
    except Exception as e:
        print(f"⚠️ Error loading existing questions: {e}")
    
    # Remove existing UK_YEAR_11 Math questions
    existing_questions = [q for q in existing_questions 
                          if not (q.get('gradeLevel') == GRADE_LEVEL and q.get('category') == SUBJECT)]
    print(f"🗑️  Removed existing {GRADE_LEVEL} {SUBJECT} questions")
    
    # Add new questions
    existing_questions.extend(questions)
    
    # Save to file
    print(f"\n💾 Saving {len(existing_questions)} total questions to {existing_file}...")
    with open(existing_file, 'w', encoding='utf-8') as f:
        json.dump(existing_questions, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Done! Added {len(questions)} {SUBJECT} questions for {GRADE_LEVEL}")
    print(f"\n📊 Breakdown by difficulty:")
    for diff in DIFFICULTIES:
        count = len([q for q in questions if q['difficulty'] == diff])
        print(f"  {diff}: {count} questions")

if __name__ == '__main__':
    main()








