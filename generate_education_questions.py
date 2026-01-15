#!/usr/bin/env python3
"""
Education Question Generator
Generates questions for education mode organized by:
- School System: US, UK, General
- Grade Level: Grade/Year 5-12
- Subject: Math, Science, English, History, Geography
- Target: 500 questions per subject per grade per system
"""

import json
import random
import uuid
from typing import List, Dict

# Grade levels by system
US_GRADES = ['US_GRADE_5', 'US_GRADE_6', 'US_GRADE_7', 'US_GRADE_8', 'US_GRADE_9', 'US_GRADE_10', 'US_GRADE_11', 'US_GRADE_12']
UK_YEARS = ['UK_YEAR_5', 'UK_YEAR_6', 'UK_YEAR_7', 'UK_YEAR_8', 'UK_YEAR_9', 'UK_YEAR_10', 'UK_YEAR_11', 'UK_YEAR_12']
GENERAL_GRADES = ['GRADE_5', 'GRADE_6', 'GRADE_7', 'GRADE_8', 'GRADE_9', 'GRADE_10', 'GRADE_11', 'GRADE_12']

SUBJECTS = ['Math', 'Science', 'English', 'History', 'Geography']
DIFFICULTIES = ['easy', 'medium', 'hard', 'very_hard']

# Question templates by subject and grade level
MATH_TEMPLATES = {
    'easy': [
        ("What is {a} + {b}?", ["{sum}", "{wrong1}", "{wrong2}", "{wrong3}"], "Addition"),
        ("What is {a} - {b}?", ["{diff}", "{wrong1}", "{wrong2}", "{wrong3}"], "Subtraction"),
        ("What is {a} × {b}?", ["{prod}", "{wrong1}", "{wrong2}", "{wrong3}"], "Multiplication"),
        ("What is {a} ÷ {b}?", ["{quot}", "{wrong1}", "{wrong2}", "{wrong3}"], "Division"),
    ],
    'medium': [
        ("Solve: {a} + {b} × {c} = ?", ["{result}", "{wrong1}", "{wrong2}", "{wrong3}"], "Order of operations"),
        ("What is {a}% of {b}?", ["{percent}", "{wrong1}", "{wrong2}", "{wrong3}"], "Percentages"),
        ("If a rectangle has length {a} and width {b}, what is its area?", ["{area}", "{wrong1}", "{wrong2}", "{wrong3}"], "Area"),
    ],
    'hard': [
        ("Solve for x: {a}x + {b} = {c}", ["{x}", "{wrong1}", "{wrong2}", "{wrong3}"], "Algebra"),
        ("What is the square root of {square}?", ["{root}", "{wrong1}", "{wrong2}", "{wrong3}"], "Square roots"),
    ],
    'very_hard': [
        ("Solve: {a}x² + {b}x + {c} = 0. What is x?", ["{x}", "{wrong1}", "{wrong2}", "{wrong3}"], "Quadratic equations"),
        ("What is the derivative of {func}?", ["{deriv}", "{wrong1}", "{wrong2}", "{wrong3}"], "Calculus"),
    ],
}

SCIENCE_TEMPLATES = {
    'easy': [
        ("What is the largest planet in our solar system?", ["Jupiter", "Saturn", "Neptune", "Earth"], "Planets"),
        ("What gas do plants absorb from the atmosphere?", ["Carbon dioxide", "Oxygen", "Nitrogen", "Hydrogen"], "Photosynthesis"),
        ("What is the chemical symbol for water?", ["H₂O", "CO₂", "O₂", "H₂"], "Chemistry basics"),
    ],
    'medium': [
        ("What is the process by which plants make food?", ["Photosynthesis", "Respiration", "Digestion", "Fermentation"], "Biology"),
        ("What is the speed of light?", ["299,792,458 m/s", "150,000,000 m/s", "450,000,000 m/s", "100,000,000 m/s"], "Physics"),
    ],
    'hard': [
        ("What is the formula for kinetic energy?", ["KE = ½mv²", "KE = mv", "KE = mgh", "KE = Fd"], "Physics"),
        ("What is the pH of a neutral solution?", ["7", "0", "14", "1"], "Chemistry"),
    ],
    'very_hard': [
        ("What is the Schrödinger equation used for?", ["Quantum mechanics", "Thermodynamics", "Electromagnetism", "Relativity"], "Advanced physics"),
    ],
}

ENGLISH_TEMPLATES = {
    'easy': [
        ("What is the past tense of 'run'?", ["ran", "runned", "runed", "running"], "Grammar"),
        ("Which word is a noun?", ["book", "quickly", "very", "and"], "Parts of speech"),
    ],
    'medium': [
        ("What is the synonym of 'happy'?", ["joyful", "sad", "angry", "tired"], "Vocabulary"),
        ("Identify the metaphor: 'Time is money'", ["Metaphor", "Simile", "Personification", "Alliteration"], "Literary devices"),
    ],
    'hard': [
        ("What is the theme of 'Romeo and Juliet'?", ["Love and conflict", "Adventure", "Science", "History"], "Literature"),
    ],
    'very_hard': [
        ("Analyze the iambic pentameter in this line: 'Shall I compare thee to a summer's day?'", ["Correct", "Incorrect", "Partial", "Unclear"], "Poetry analysis"),
    ],
}

HISTORY_TEMPLATES = {
    'easy': [
        ("In what year did World War II end?", ["1945", "1944", "1946", "1943"], "World War II"),
        ("Who was the first President of the United States?", ["George Washington", "Thomas Jefferson", "John Adams", "Benjamin Franklin"], "US History"),
    ],
    'medium': [
        ("What was the main cause of the American Civil War?", ["Slavery", "Taxes", "Trade", "Religion"], "US History"),
        ("When did the Industrial Revolution begin?", ["1760s", "1800s", "1700s", "1850s"], "World History"),
    ],
    'hard': [
        ("What was the significance of the Battle of Hastings?", ["Norman conquest of England", "End of Roman Empire", "Start of Renaissance", "French Revolution"], "European History"),
    ],
    'very_hard': [
        ("What were the main causes of the French Revolution?", ["Economic inequality and political corruption", "Religious conflict", "Natural disasters", "Foreign invasion"], "European History"),
    ],
}

GEOGRAPHY_TEMPLATES = {
    'easy': [
        ("What is the capital of France?", ["Paris", "London", "Berlin", "Madrid"], "Capitals"),
        ("What is the longest river in the world?", ["Nile", "Amazon", "Mississippi", "Yangtze"], "Rivers"),
    ],
    'medium': [
        ("What is the largest ocean?", ["Pacific", "Atlantic", "Indian", "Arctic"], "Oceans"),
        ("Which continent is the smallest?", ["Australia", "Europe", "Antarctica", "South America"], "Continents"),
    ],
    'hard': [
        ("What is the process that forms mountains?", ["Tectonic plate movement", "Erosion", "Volcanic activity", "Glaciation"], "Geology"),
    ],
    'very_hard': [
        ("What is the Coriolis effect?", ["Deflection of moving objects due to Earth's rotation", "Ocean currents", "Wind patterns", "Climate zones"], "Physical geography"),
    ],
}

TEMPLATES_BY_SUBJECT = {
    'Math': MATH_TEMPLATES,
    'Science': SCIENCE_TEMPLATES,
    'English': ENGLISH_TEMPLATES,
    'History': HISTORY_TEMPLATES,
    'Geography': GEOGRAPHY_TEMPLATES,
}

def generate_question(
    grade_level: str,
    subject: str,
    difficulty: str,
    question_num: int
) -> Dict:
    """Generate a single question"""
    templates = TEMPLATES_BY_SUBJECT.get(subject, {})
    difficulty_templates = templates.get(difficulty, [])
    
    if not difficulty_templates:
        # Fallback to easy if difficulty not available
        difficulty_templates = templates.get('easy', [])
        if not difficulty_templates:
            difficulty = 'easy'
            difficulty_templates = [("Sample question?", ["Answer", "Wrong1", "Wrong2", "Wrong3"], "Topic")]
    
    template, options_template, topic = random.choice(difficulty_templates)
    
    # Generate values for math questions
    if subject == 'Math' and '{' in template:
        a = random.randint(1, 100)
        b = random.randint(1, 100)
        c = random.randint(1, 20)
        
        if 'sum' in options_template[0]:
            correct = a + b
        elif 'diff' in options_template[0]:
            correct = a - b
        elif 'prod' in options_template[0]:
            correct = a * b
        elif 'quot' in options_template[0]:
            correct = a // b if b != 0 else a
        elif 'result' in options_template[0]:
            correct = a + b * c
        elif 'percent' in options_template[0]:
            correct = int(a * b / 100)
        elif 'area' in options_template[0]:
            correct = a * b
        elif 'x' in options_template[0]:
            correct = (c - b) // a if a != 0 else 0
        else:
            correct = random.randint(1, 100)
        
        # Fill template
        text = template.format(a=a, b=b, c=c)
        options = [str(correct)]
        for _ in range(3):
            wrong = correct + random.randint(-20, 20)
            while wrong == correct or wrong < 0:
                wrong = correct + random.randint(-20, 20)
            options.append(str(wrong))
    else:
        # Use template as-is for non-math
        text = template
        options = list(options_template)
        correct = options[0]
    
    random.shuffle(options)
    correct_index = options.index(correct) if correct in options else 0
    
    return {
        "id": f"edu_{grade_level.lower()}_{subject.lower()}_{question_num:04d}",
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "explanation": f"This question tests your understanding of {topic.lower()}.",
        "category": subject,
        "difficulty": difficulty,
        "topic": topic.lower(),
        "mode": "EDUCATION_SCHOOL",
        "gradeLevel": grade_level,
        "source": "CURATED",
        "language": "EN"
    }

def generate_questions_for_grade_subject(
    grade_level: str,
    subject: str,
    count: int = 500
) -> List[Dict]:
    """Generate questions for a specific grade and subject"""
    questions = []
    
    # Distribute across difficulties
    difficulty_counts = {
        'easy': int(count * 0.4),
        'medium': int(count * 0.3),
        'hard': int(count * 0.2),
        'very_hard': int(count * 0.1),
    }
    
    question_num = 1
    for difficulty, num_questions in difficulty_counts.items():
        for i in range(num_questions):
            questions.append(generate_question(grade_level, subject, difficulty, question_num))
            question_num += 1
    
    # Fill remaining if count doesn't match exactly
    while len(questions) < count:
        difficulty = random.choice(DIFFICULTIES)
        questions.append(generate_question(grade_level, subject, difficulty, question_num))
        question_num += 1
    
    return questions[:count]

def main():
    """Generate all education questions"""
    all_questions = []
    
    # Generate for each system
    systems = [
        ('US', US_GRADES),
        ('UK', UK_YEARS),
        ('General', GENERAL_GRADES),
    ]
    
    for system_name, grades in systems:
        print(f"\n📚 Generating questions for {system_name} system...")
        for grade in grades:
            print(f"  Grade: {grade}")
            for subject in SUBJECTS:
                print(f"    Subject: {subject}...", end=' ')
                questions = generate_questions_for_grade_subject(grade, subject, count=500)
                all_questions.extend(questions)
                print(f"✅ {len(questions)} questions")
    
    # Save to JSON file
    output_file = 'assets/questions/education_questions.json'
    print(f"\n💾 Saving {len(all_questions)} questions to {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Done! Generated {len(all_questions)} education questions")
    print(f"\n📊 Breakdown:")
    for system_name, grades in systems:
        for grade in grades:
            for subject in SUBJECTS:
                count = len([q for q in all_questions if q['gradeLevel'] == grade and q['category'] == subject])
                print(f"  {grade} - {subject}: {count} questions")

if __name__ == '__main__':
    main()

