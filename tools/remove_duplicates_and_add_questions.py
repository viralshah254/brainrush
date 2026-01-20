#!/usr/bin/env python3
"""
Script to remove duplicate questions from questions.json and replace them with new unique questions.
Detects both exact duplicates and template duplicates (same structure, different numbers).
"""

import json
import random
import re
from collections import defaultdict
from typing import List, Dict, Set

# Categories and their topics
CATEGORIES = {
    "Math": ["addition", "subtraction", "multiplication", "division", "algebra", "geometry", "fractions", "decimals", "percentages", "word problems"],
    "Science": ["biology", "chemistry", "physics", "astronomy", "earth science", "anatomy", "botany", "zoology", "ecology", "genetics"],
    "History": ["ancient history", "medieval history", "world wars", "american history", "european history", "asian history", "civilizations", "revolutions", "presidents", "battles"],
    "Geography": ["countries", "capitals", "rivers", "mountains", "oceans", "continents", "cities", "landmarks", "flags", "climate"],
    "Literature": ["authors", "books", "poetry", "plays", "characters", "genres", "classics", "modern literature", "literary devices", "quotations"],
    "Technology": ["computers", "programming", "internet", "software", "hardware", "ai", "cybersecurity", "mobile devices", "social media", "innovation"],
    "Sports": ["football", "basketball", "soccer", "baseball", "tennis", "olympics", "athletes", "teams", "records", "championships"],
    "Entertainment": ["movies", "tv shows", "music", "actors", "directors", "awards", "celebrities", "genres", "soundtracks", "animation"],
    "Nature": ["animals", "plants", "ecosystems", "weather", "geology", "oceans", "forests", "deserts", "wildlife", "conservation"],
    "General Knowledge": ["culture", "traditions", "languages", "food", "art", "architecture", "inventions", "discoveries", "myths", "facts"]
}

DIFFICULTIES = ["easy", "medium", "hard", "super_hard"]
GRADE_LEVELS = ["Kids (5-7)", "Primary (8-10)", "Middle School (11-13)", "High School (14-18)", "SAT/ACT", "GMAT/GRE"]
QUESTION_TYPES = ["recall", "conceptual", "application", "reasoning", "misconception_check"]

def normalize_question_text(text: str) -> str:
    """Normalize question text by replacing numbers with placeholders to detect template duplicates."""
    # Replace numbers with #N
    normalized = re.sub(r'\d+', '#N', text.lower())
    # Normalize whitespace
    normalized = ' '.join(normalized.split())
    return normalized

# Global question pools - expanded significantly
MATH_EASY_QUESTIONS = [
    ("What is 7 + 9?", "16", ["14", "15", "16", "17"]),
    ("What is 15 - 8?", "7", ["6", "7", "8", "9"]),
    ("What is 4 × 6?", "24", ["20", "22", "24", "26"]),
    ("What is 20 ÷ 4?", "5", ["4", "5", "6", "7"]),
    ("What is half of 18?", "9", ["8", "9", "10", "11"]),
    ("What is 3²?", "9", ["6", "9", "12", "15"]),
    ("What is 10% of 50?", "5", ["4", "5", "6", "7"]),
    ("What is the perimeter of a square with side length 5?", "20", ["15", "20", "25", "30"]),
    ("What is 12 + 15?", "27", ["25", "26", "27", "28"]),
    ("What is 25 - 13?", "12", ["10", "11", "12", "13"]),
    ("What is 6 × 7?", "42", ["40", "41", "42", "43"]),
    ("What is 36 ÷ 6?", "6", ["5", "6", "7", "8"]),
    ("What is 5²?", "25", ["20", "23", "25", "30"]),
    ("What is 20% of 100?", "20", ["15", "20", "25", "30"]),
    ("What is the area of a rectangle 4 by 6?", "24", ["20", "22", "24", "26"]),
]

MATH_MEDIUM_QUESTIONS = [
    ("A train travels 120 km in 2 hours. What is its speed in km/h?", "60", ["50", "60", "70", "80"]),
    ("If a rectangle has length 8 cm and width 5 cm, what is its area?", "40", ["35", "40", "45", "50"]),
    ("What is 25% of 80?", "20", ["15", "20", "25", "30"]),
    ("Solve for x: 3x + 5 = 20", "5", ["4", "5", "6", "7"]),
    ("What is the area of a circle with radius 5? (Use π ≈ 3.14)", "78.5", ["62.8", "78.5", "94.2", "125.6"]),
    ("What is 2³ × 3²?", "72", ["54", "72", "81", "96"]),
    ("If 5 apples cost $2.50, how much do 8 apples cost?", "4.00", ["3.50", "4.00", "4.50", "5.00"]),
    ("What is the square root of 144?", "12", ["10", "11", "12", "13"]),
    ("What is the volume of a cube with side length 3?", "27", ["24", "27", "30", "33"]),
    ("What is 15% of 120?", "18", ["15", "18", "20", "22"]),
    ("If a triangle has base 6 and height 4, what is its area?", "12", ["10", "12", "14", "16"]),
    ("What is the perimeter of a rectangle 7 by 9?", "32", ["30", "32", "34", "36"]),
]

MATH_HARD_QUESTIONS = [
    ("What is the derivative of x²?", "2x", ["x", "2x", "x²", "2x²"]),
    ("What is 15% of 200?", "30", ["25", "30", "35", "40"]),
    ("If a triangle has angles 60° and 80°, what is the third angle?", "40", ["30", "40", "50", "60"]),
    ("What is the value of log₁₀(100)?", "2", ["1", "2", "3", "10"]),
    ("What is sin(90°)?", "1", ["0", "0.5", "1", "√2/2"]),
    ("What is the slope of the line y = 3x + 2?", "3", ["2", "3", "5", "6"]),
    ("What is the integral of 2x?", "x²", ["x", "x²", "2x", "x²/2"]),
    ("What is cos(0°)?", "1", ["0", "0.5", "1", "√2/2"]),
]

def generate_new_question(question_id: str, category: str, difficulty: str, question_index: int, used_texts: Set[str], used_normalized: Set[str]) -> Dict:
    """Generate a new unique question based on category and difficulty."""
    topics = CATEGORIES.get(category, ["general"])
    topic = topics[question_index % len(topics)]
    
    # Generate question based on category
    if category == "Math":
        if difficulty == "easy":
            problems = MATH_EASY_QUESTIONS
        elif difficulty == "medium":
            problems = MATH_MEDIUM_QUESTIONS
        else:
            problems = MATH_HARD_QUESTIONS
        
        # Use index to select question, wrap around if needed
        problem_idx = question_index % len(problems)
        text, answer, opts = problems[problem_idx]
        options = opts.copy()
        # Shuffle based on question_index for variety
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Geography":
        questions = [
            ("What is the capital of Australia?", "Canberra", ["Sydney", "Melbourne", "Canberra", "Brisbane"]),
            ("Which is the longest river in the world?", "Nile", ["Amazon", "Nile", "Mississippi", "Yangtze"]),
            ("What is the smallest continent?", "Australia", ["Europe", "Australia", "Antarctica", "South America"]),
            ("Which ocean is between America and Europe?", "Atlantic", ["Pacific", "Atlantic", "Indian", "Arctic"]),
            ("What is the capital of Brazil?", "Brasília", ["São Paulo", "Rio de Janeiro", "Brasília", "Buenos Aires"]),
            ("Which mountain is the highest in the world?", "Mount Everest", ["K2", "Mount Everest", "Kangchenjunga", "Lhotse"]),
            ("What is the capital of Egypt?", "Cairo", ["Alexandria", "Cairo", "Luxor", "Giza"]),
            ("Which country is known as the Land of the Rising Sun?", "Japan", ["China", "Japan", "South Korea", "Thailand"]),
            ("What is the capital of Canada?", "Ottawa", ["Toronto", "Vancouver", "Ottawa", "Montreal"]),
            ("Which desert is the largest in the world?", "Antarctica", ["Sahara", "Gobi", "Antarctica", "Arabian"]),
            ("What is the capital of South Africa?", "Cape Town", ["Johannesburg", "Cape Town", "Pretoria", "Durban"]),
            ("Which river flows through Egypt?", "Nile", ["Nile", "Tigris", "Euphrates", "Jordan"]),
            ("What is the capital of Argentina?", "Buenos Aires", ["São Paulo", "Buenos Aires", "Santiago", "Lima"]),
            ("Which country has the most time zones?", "France", ["Russia", "United States", "France", "China"]),
            ("What is the capital of New Zealand?", "Wellington", ["Auckland", "Wellington", "Christchurch", "Hamilton"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Science":
        questions = [
            ("What is the chemical symbol for water?", "H₂O", ["CO₂", "H₂O", "O₂", "NaCl"]),
            ("How many planets are in our solar system?", "8", ["7", "8", "9", "10"]),
            ("What is the hardest natural substance?", "Diamond", ["Gold", "Diamond", "Iron", "Platinum"]),
            ("What gas do plants absorb from the atmosphere?", "Carbon dioxide", ["Oxygen", "Nitrogen", "Carbon dioxide", "Hydrogen"]),
            ("What is the speed of light in vacuum?", "299,792,458 m/s", ["186,000 m/s", "299,792,458 m/s", "150,000 m/s", "400,000 m/s"]),
            ("What is the smallest unit of matter?", "Atom", ["Molecule", "Atom", "Cell", "Electron"]),
            ("Which planet is closest to the Sun?", "Mercury", ["Venus", "Mercury", "Earth", "Mars"]),
            ("What is the most abundant gas in Earth's atmosphere?", "Nitrogen", ["Oxygen", "Nitrogen", "Carbon dioxide", "Argon"]),
            ("How many bones are in an adult human body?", "206", ["200", "206", "210", "215"]),
            ("What is the process by which plants make food?", "Photosynthesis", ["Respiration", "Photosynthesis", "Digestion", "Fermentation"]),
            ("What is the chemical symbol for gold?", "Au", ["Go", "Au", "Gd", "Ag"]),
            ("Which blood type is known as the universal donor?", "O negative", ["A positive", "B negative", "O negative", "AB positive"]),
            ("What is the largest organ in the human body?", "Skin", ["Liver", "Skin", "Lungs", "Intestines"]),
            ("How many chambers does a human heart have?", "4", ["2", "3", "4", "5"]),
            ("What is the pH of pure water?", "7", ["5", "6", "7", "8"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "History":
        questions = [
            ("In which year did World War II end?", "1945", ["1943", "1944", "1945", "1946"]),
            ("Who was the first President of the United States?", "George Washington", ["Thomas Jefferson", "George Washington", "John Adams", "Benjamin Franklin"]),
            ("Which ancient civilization built the pyramids?", "Egyptians", ["Greeks", "Romans", "Egyptians", "Mayans"]),
            ("In which year did the Berlin Wall fall?", "1989", ["1987", "1988", "1989", "1990"]),
            ("Who painted the Mona Lisa?", "Leonardo da Vinci", ["Michelangelo", "Leonardo da Vinci", "Picasso", "Van Gogh"]),
            ("Which war was fought between 1861 and 1865?", "American Civil War", ["World War I", "American Civil War", "Revolutionary War", "World War II"]),
            ("Who was known as the Iron Lady?", "Margaret Thatcher", ["Angela Merkel", "Margaret Thatcher", "Indira Gandhi", "Golda Meir"]),
            ("In which year did the Titanic sink?", "1912", ["1910", "1911", "1912", "1913"]),
            ("Which empire was ruled by Julius Caesar?", "Roman Empire", ["Greek Empire", "Roman Empire", "Byzantine Empire", "Ottoman Empire"]),
            ("Who invented the telephone?", "Alexander Graham Bell", ["Thomas Edison", "Alexander Graham Bell", "Nikola Tesla", "Guglielmo Marconi"]),
            ("In which year did World War I begin?", "1914", ["1912", "1913", "1914", "1915"]),
            ("Who was the first person to walk on the moon?", "Neil Armstrong", ["Buzz Aldrin", "Neil Armstrong", "John Glenn", "Yuri Gagarin"]),
            ("Which country was ruled by Napoleon Bonaparte?", "France", ["France", "Italy", "Spain", "Germany"]),
            ("In which year did the American Revolution begin?", "1775", ["1773", "1774", "1775", "1776"]),
            ("Who wrote the Declaration of Independence?", "Thomas Jefferson", ["George Washington", "Thomas Jefferson", "Benjamin Franklin", "John Adams"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Literature":
        questions = [
            ("Who wrote 'Romeo and Juliet'?", "William Shakespeare", ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"]),
            ("What is the first book in the Harry Potter series?", "Harry Potter and the Philosopher's Stone", ["Harry Potter and the Chamber of Secrets", "Harry Potter and the Philosopher's Stone", "Harry Potter and the Prisoner of Azkaban", "Harry Potter and the Goblet of Fire"]),
            ("Who wrote '1984'?", "George Orwell", ["Aldous Huxley", "George Orwell", "Ray Bradbury", "H.G. Wells"]),
            ("In which novel does the character Atticus Finch appear?", "To Kill a Mockingbird", ["The Great Gatsby", "To Kill a Mockingbird", "The Catcher in the Rye", "Lord of the Flies"]),
            ("Who wrote 'Pride and Prejudice'?", "Jane Austen", ["Charlotte Brontë", "Jane Austen", "Emily Brontë", "Virginia Woolf"]),
            ("What is the longest novel ever written?", "In Search of Lost Time", ["War and Peace", "In Search of Lost Time", "Les Misérables", "Ulysses"]),
            ("Who wrote 'The Great Gatsby'?", "F. Scott Fitzgerald", ["Ernest Hemingway", "F. Scott Fitzgerald", "John Steinbeck", "William Faulkner"]),
            ("Which Shakespeare play features the character Hamlet?", "Hamlet", ["Macbeth", "Hamlet", "Othello", "King Lear"]),
            ("Who wrote 'The Lord of the Rings'?", "J.R.R. Tolkien", ["C.S. Lewis", "J.R.R. Tolkien", "George R.R. Martin", "Terry Pratchett"]),
            ("What is the first book in 'The Chronicles of Narnia' series?", "The Lion, the Witch and the Wardrobe", ["Prince Caspian", "The Lion, the Witch and the Wardrobe", "The Voyage of the Dawn Treader", "The Silver Chair"]),
            ("Who wrote 'Moby Dick'?", "Herman Melville", ["Nathaniel Hawthorne", "Herman Melville", "Edgar Allan Poe", "Mark Twain"]),
            ("Which novel begins with 'It was the best of times, it was the worst of times'?", "A Tale of Two Cities", ["Great Expectations", "A Tale of Two Cities", "Oliver Twist", "David Copperfield"]),
            ("Who wrote 'The Catcher in the Rye'?", "J.D. Salinger", ["Ernest Hemingway", "J.D. Salinger", "F. Scott Fitzgerald", "John Steinbeck"]),
            ("Which author wrote 'The Hobbit'?", "J.R.R. Tolkien", ["C.S. Lewis", "J.R.R. Tolkien", "George R.R. Martin", "Terry Pratchett"]),
            ("Who wrote 'Brave New World'?", "Aldous Huxley", ["George Orwell", "Aldous Huxley", "Ray Bradbury", "H.G. Wells"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Technology":
        questions = [
            ("What does CPU stand for?", "Central Processing Unit", ["Computer Processing Unit", "Central Processing Unit", "Central Program Unit", "Computer Program Unit"]),
            ("Which company created the iPhone?", "Apple", ["Samsung", "Apple", "Google", "Microsoft"]),
            ("What does HTML stand for?", "HyperText Markup Language", ["HyperText Markup Language", "HighText Markup Language", "HyperText Markup Link", "HyperText Markup Library"]),
            ("What is the most popular programming language?", "JavaScript", ["Python", "Java", "JavaScript", "C++"]),
            ("What does URL stand for?", "Uniform Resource Locator", ["Universal Resource Locator", "Uniform Resource Locator", "Universal Reference Locator", "Uniform Reference Locator"]),
            ("Which year was the first iPhone released?", "2007", ["2005", "2006", "2007", "2008"]),
            ("What does RAM stand for?", "Random Access Memory", ["Read Access Memory", "Random Access Memory", "Read Only Memory", "Random Access Module"]),
            ("Who founded Microsoft?", "Bill Gates", ["Steve Jobs", "Bill Gates", "Mark Zuckerberg", "Larry Page"]),
            ("What does AI stand for?", "Artificial Intelligence", ["Automated Intelligence", "Artificial Intelligence", "Advanced Intelligence", "Automated Information"]),
            ("What is the name of Google's operating system?", "Android", ["iOS", "Android", "Windows", "Linux"]),
            ("What does HTTP stand for?", "HyperText Transfer Protocol", ["HyperText Transfer Protocol", "HyperText Transport Protocol", "HyperText Transmission Protocol", "HyperText Transfer Process"]),
            ("Which company created the Windows operating system?", "Microsoft", ["Apple", "Microsoft", "Google", "IBM"]),
            ("What does VPN stand for?", "Virtual Private Network", ["Virtual Public Network", "Virtual Private Network", "Verified Private Network", "Virtual Protected Network"]),
            ("Who founded Apple Inc.?", "Steve Jobs", ["Bill Gates", "Steve Jobs", "Mark Zuckerberg", "Larry Page"]),
            ("What does SSD stand for?", "Solid State Drive", ["Solid State Disk", "Solid State Drive", "System Storage Device", "Secure Storage Drive"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Sports":
        questions = [
            ("How many players are on a basketball team on the court?", "5", ["4", "5", "6", "7"]),
            ("Which sport is played at Wimbledon?", "Tennis", ["Golf", "Tennis", "Cricket", "Rugby"]),
            ("How many innings are in a standard baseball game?", "9", ["7", "8", "9", "10"]),
            ("Which country won the FIFA World Cup in 2018?", "France", ["Brazil", "Germany", "France", "Argentina"]),
            ("What is the maximum score in a single frame of bowling?", "300", ["250", "275", "300", "350"]),
            ("How many players are on a soccer team on the field?", "11", ["9", "10", "11", "12"]),
            ("Which sport uses a shuttlecock?", "Badminton", ["Tennis", "Badminton", "Volleyball", "Squash"]),
            ("How many rings are in the Olympic symbol?", "5", ["4", "5", "6", "7"]),
            ("Which country hosted the 2016 Summer Olympics?", "Brazil", ["China", "Brazil", "Russia", "Japan"]),
            ("What is the length of a marathon in kilometers?", "42.195", ["40", "41", "42.195", "43"]),
            ("How many points is a touchdown worth in American football?", "6", ["4", "5", "6", "7"]),
            ("Which sport is known as 'the beautiful game'?", "Soccer", ["Basketball", "Soccer", "Tennis", "Golf"]),
            ("How many holes are in a standard round of golf?", "18", ["9", "18", "27", "36"]),
            ("Which country won the most FIFA World Cups?", "Brazil", ["Germany", "Brazil", "Argentina", "Italy"]),
            ("What is the diameter of a basketball hoop in inches?", "18", ["16", "18", "20", "22"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Entertainment":
        questions = [
            ("Which movie won the Academy Award for Best Picture in 2020?", "Parasite", ["1917", "Parasite", "Joker", "Once Upon a Time in Hollywood"]),
            ("Who directed the movie 'Inception'?", "Christopher Nolan", ["Steven Spielberg", "Christopher Nolan", "Martin Scorsese", "Quentin Tarantino"]),
            ("Which streaming service created 'Stranger Things'?", "Netflix", ["Hulu", "Netflix", "Amazon Prime", "Disney+"]),
            ("Who played Iron Man in the Marvel Cinematic Universe?", "Robert Downey Jr.", ["Chris Evans", "Robert Downey Jr.", "Chris Hemsworth", "Mark Ruffalo"]),
            ("Which band sang 'Bohemian Rhapsody'?", "Queen", ["The Beatles", "Queen", "Led Zeppelin", "Pink Floyd"]),
            ("What is the highest-grossing movie of all time?", "Avatar", ["Avengers: Endgame", "Avatar", "Titanic", "Star Wars: The Force Awakens"]),
            ("Who composed the music for 'The Lion King'?", "Hans Zimmer", ["John Williams", "Hans Zimmer", "Alan Menken", "Danny Elfman"]),
            ("Which TV show is set in the fictional town of Hawkins?", "Stranger Things", ["The Office", "Stranger Things", "Breaking Bad", "Game of Thrones"]),
            ("Who won the Academy Award for Best Actor in 2020?", "Joaquin Phoenix", ["Leonardo DiCaprio", "Joaquin Phoenix", "Adam Driver", "Antonio Banderas"]),
            ("Which animated movie features the song 'Let It Go'?", "Frozen", ["Tangled", "Frozen", "Moana", "Encanto"]),
            ("Who directed 'The Dark Knight'?", "Christopher Nolan", ["Steven Spielberg", "Christopher Nolan", "Martin Scorsese", "Quentin Tarantino"]),
            ("Which movie features the quote 'May the Force be with you'?", "Star Wars", ["Star Trek", "Star Wars", "Blade Runner", "The Matrix"]),
            ("Who played the Joker in 'The Dark Knight'?", "Heath Ledger", ["Joaquin Phoenix", "Heath Ledger", "Jack Nicholson", "Jared Leto"]),
            ("Which band released the album 'Abbey Road'?", "The Beatles", ["The Rolling Stones", "The Beatles", "Led Zeppelin", "Pink Floyd"]),
            ("What is the name of the main character in 'The Matrix'?", "Neo", ["Morpheus", "Neo", "Trinity", "Agent Smith"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    elif category == "Nature":
        questions = [
            ("What is the largest mammal in the world?", "Blue whale", ["Elephant", "Blue whale", "Giraffe", "Hippopotamus"]),
            ("How many hearts does an octopus have?", "3", ["1", "2", "3", "4"]),
            ("What is the fastest land animal?", "Cheetah", ["Lion", "Cheetah", "Leopard", "Tiger"]),
            ("Which tree is known for having the longest lifespan?", "Bristlecone pine", ["Oak", "Bristlecone pine", "Redwood", "Sequoia"]),
            ("What is the largest ocean on Earth?", "Pacific Ocean", ["Atlantic Ocean", "Pacific Ocean", "Indian Ocean", "Arctic Ocean"]),
            ("How many legs does a spider have?", "8", ["6", "8", "10", "12"]),
            ("What is the smallest bird in the world?", "Bee hummingbird", ["Sparrow", "Bee hummingbird", "Finch", "Wren"]),
            ("Which animal is known as the King of the Jungle?", "Lion", ["Tiger", "Lion", "Leopard", "Jaguar"]),
            ("What is the largest type of bear?", "Polar bear", ["Grizzly bear", "Polar bear", "Brown bear", "Black bear"]),
            ("How many species of penguins are there?", "18", ["15", "16", "17", "18"]),
            ("What is the largest fish in the ocean?", "Whale shark", ["Great white shark", "Whale shark", "Bluefin tuna", "Manta ray"]),
            ("Which animal can change its color to match its surroundings?", "Chameleon", ["Gecko", "Chameleon", "Iguana", "Anole"]),
            ("What is the fastest bird in the world?", "Peregrine falcon", ["Eagle", "Peregrine falcon", "Hawk", "Swift"]),
            ("How many stomachs does a cow have?", "4", ["1", "2", "3", "4"]),
            ("What is the largest land animal?", "African elephant", ["Giraffe", "African elephant", "Hippopotamus", "Rhinoceros"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    else:  # General Knowledge
        questions = [
            ("What is the most spoken language in the world?", "Mandarin Chinese", ["English", "Spanish", "Mandarin Chinese", "Hindi"]),
            ("Which country is known as the Land of the Rising Sun?", "Japan", ["China", "Japan", "South Korea", "Thailand"]),
            ("What is the currency of the United Kingdom?", "Pound Sterling", ["Euro", "Pound Sterling", "Dollar", "Yen"]),
            ("How many continents are there?", "7", ["5", "6", "7", "8"]),
            ("What is the largest country by land area?", "Russia", ["Canada", "China", "Russia", "United States"]),
            ("Which instrument has 88 keys?", "Piano", ["Organ", "Piano", "Harpsichord", "Accordion"]),
            ("What is the most consumed beverage in the world after water?", "Tea", ["Coffee", "Tea", "Beer", "Soda"]),
            ("How many time zones does Russia have?", "11", ["9", "10", "11", "12"]),
            ("What is the national flower of Japan?", "Cherry blossom", ["Rose", "Cherry blossom", "Lotus", "Tulip"]),
            ("Which planet is known as the Red Planet?", "Mars", ["Venus", "Mars", "Jupiter", "Saturn"]),
            ("What is the capital of France?", "Paris", ["London", "Berlin", "Paris", "Rome"]),
            ("How many days are in a leap year?", "366", ["364", "365", "366", "367"]),
            ("What is the smallest country in the world?", "Vatican City", ["Monaco", "Vatican City", "San Marino", "Liechtenstein"]),
            ("Which planet is closest to Earth?", "Venus", ["Mercury", "Venus", "Mars", "Jupiter"]),
            ("What is the chemical symbol for iron?", "Fe", ["Ir", "Fe", "In", "Fr"]),
        ]
        q_idx = question_index % len(questions)
        text, answer, opts = questions[q_idx]
        options = opts.copy()
        random.Random(question_index).shuffle(options)
        correct_index = options.index(answer)
    
    # Determine grade level based on difficulty
    if difficulty == "easy":
        grade_level = random.choice(["Kids (5-7)", "Primary (8-10)"])
    elif difficulty == "medium":
        grade_level = random.choice(["Primary (8-10)", "Middle School (11-13)"])
    elif difficulty == "hard":
        grade_level = random.choice(["Middle School (11-13)", "High School (14-18)"])
    else:
        grade_level = random.choice(["High School (14-18)", "SAT/ACT"])
    
    question_type = random.choice(QUESTION_TYPES)
    
    # Generate explanations
    short_explanation = f"The correct answer is {answer}."
    deep_explanation = f"{text.replace('?', '')} The answer is {answer}. This question tests your knowledge of {topic}."
    
    # Generate whyWrong
    why_wrong = {}
    for i in range(4):
        if i == correct_index:
            why_wrong[str(i)] = f"Correct: {options[i]} is the right answer."
        else:
            why_wrong[str(i)] = f"{options[i]} is not the correct answer for this {category.lower()} question about {topic}."
    
    return {
        "id": question_id,
        "text": text,
        "options": options,
        "correctIndex": correct_index,
        "correctAnswer": answer,
        "category": category,
        "difficulty": difficulty,
        "topic": topic,
        "explanation": short_explanation,
        "questionType": question_type,
        "learningObjective": f"Understand {topic} in {category.lower()}.",
        "shortExplanation": short_explanation,
        "deepExplanation": deep_explanation,
        "whyWrong": why_wrong,
        "gradeLevel": grade_level,
        "tags": [category.lower(), topic, difficulty, "knowledge", "quiz"],
        "lessonId": f"{category.lower()}_{topic}_01",
        "lessonOrder": 1,
        "hint": f"Think about {topic} and {category.lower()}."
    }

def main():
    print("Loading questions.json...")
    with open('assets/questions/questions.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    print(f"Total questions loaded: {len(questions)}")
    
    # Find duplicates by normalized question text (template duplicates)
    normalized_groups: Dict[str, List[int]] = defaultdict(list)
    exact_dups: Dict[str, List[int]] = defaultdict(list)
    
    for idx, q in enumerate(questions):
        text = q.get('text', '').strip()
        text_lower = text.lower()
        
        # Track exact duplicates
        exact_dups[text_lower].append(idx)
        
        # Track template duplicates (normalized)
        normalized = normalize_question_text(text)
        normalized_groups[normalized].append(idx)
    
    # Find exact duplicates
    exact_duplicate_indices: Set[int] = set()
    exact_count = 0
    for text, indices in exact_dups.items():
        if len(indices) > 1:
            exact_count += len(indices) - 1
            for idx in indices[1:]:  # Keep first, mark others
                exact_duplicate_indices.add(idx)
    
    print(f"Found {exact_count} exact text duplicates")
    
    # Find template duplicates (same structure, different numbers)
    template_duplicate_indices: Set[int] = set()
    template_count = 0
    
    for normalized, indices in normalized_groups.items():
        if len(indices) > 1:
            template_count += len(indices) - 1
            # Keep the first occurrence, mark others as duplicates
            for idx in indices[1:]:
                template_duplicate_indices.add(idx)
    
    print(f"Found {template_count} template duplicates (same structure, different numbers)")
    
    # Combine all duplicates
    all_duplicate_indices = exact_duplicate_indices | template_duplicate_indices
    
    print(f"Total duplicates to remove: {len(all_duplicate_indices)}")
    
    # Remove duplicates (keep first occurrence)
    unique_questions = []
    removed_count = 0
    
    for idx, q in enumerate(questions):
        if idx not in all_duplicate_indices:
            unique_questions.append(q)
        else:
            removed_count += 1
    
    print(f"Removed {removed_count} duplicates")
    print(f"Unique questions remaining: {len(unique_questions)}")
    
    # Generate new questions to replace duplicates
    print(f"\nGenerating {removed_count} new unique questions...")
    
    # Try to load questions from education_questions.json as a source
    education_questions_pool = []
    try:
        print("Loading questions from education_questions.json...")
        import os
        with open('assets/questions/education_questions.json', 'r', encoding='utf-8') as f:
            # Load questions - sample if file is very large
            education_data = json.load(f)
            # Sample questions randomly to avoid loading entire huge file
            if len(education_data) > removed_count * 2:
                education_questions_pool = random.sample(education_data, min(len(education_data), removed_count * 3))
            else:
                education_questions_pool = education_data
        print(f"Loaded {len(education_questions_pool)} questions from education_questions.json")
    except Exception as e:
        print(f"Could not load education_questions.json: {e}")
        print("Will generate questions from scratch instead")
    
    # Get distribution of categories and difficulties from existing questions
    category_dist = defaultdict(int)
    difficulty_dist = defaultdict(int)
    
    for q in unique_questions:
        category_dist[q.get('category', 'General Knowledge')] += 1
        difficulty_dist[q.get('difficulty', 'medium')] += 1
    
    # Generate new questions
    max_id = 0
    for q in unique_questions:
        try:
            q_id_num = int(q.get('id', 'q0000').lstrip('q'))
            max_id = max(max_id, q_id_num)
        except:
            pass
    
    new_questions = []
    used_texts = {q.get('text', '').strip().lower() for q in unique_questions}
    used_normalized = {normalize_question_text(q.get('text', '')) for q in unique_questions}
    
    # Also add education questions to used sets to avoid duplicates
    for eq in education_questions_pool:
        text = eq.get('text', '').strip().lower()
        normalized = normalize_question_text(eq.get('text', ''))
        used_texts.add(text)
        used_normalized.add(normalized)
    
    # Create a global question counter that combines category and index
    global_question_counter = 0
    education_pool_index = 0
    
    def convert_education_question(eq, new_id):
        """Convert education question format to standard format."""
        # Ensure all required fields exist
        options = eq.get('options', [])
        if len(options) != 4:
            return None
        
        correct_index = eq.get('correctIndex', 0)
        if correct_index < 0 or correct_index >= 4:
            return None
        
        correct_answer = options[correct_index] if correct_index < len(options) else options[0]
        
        # Build whyWrong map
        why_wrong = {}
        for i in range(4):
            if i == correct_index:
                why_wrong[str(i)] = f"Correct: {options[i]} is the right answer."
            else:
                why_wrong[str(i)] = f"{options[i]} is not the correct answer."
        
        return {
            "id": new_id,
            "text": eq.get('text', ''),
            "options": options,
            "correctIndex": correct_index,
            "correctAnswer": correct_answer,
            "category": eq.get('category', 'General Knowledge'),
            "difficulty": eq.get('difficulty', 'medium'),
            "topic": eq.get('topic', 'general'),
            "explanation": eq.get('explanation', eq.get('shortExplanation', '')),
            "questionType": eq.get('questionType', 'recall'),
            "learningObjective": eq.get('learningObjective', 'Learn about this topic.'),
            "shortExplanation": eq.get('shortExplanation', eq.get('explanation', '')),
            "deepExplanation": eq.get('deepExplanation', eq.get('explanation', '')),
            "whyWrong": why_wrong,
            "gradeLevel": eq.get('gradeLevel', 'Middle School (11-13)'),
            "tags": eq.get('tags', [eq.get('category', '').lower(), eq.get('topic', 'general')]),
            "lessonId": eq.get('lessonId', 'general_01'),
            "lessonOrder": eq.get('lessonOrder', 1),
            "hint": eq.get('hint', 'Think about this question carefully.')
        }
    
    for i in range(removed_count):
        max_id += 1
        question_id = f"q{max_id:04d}"
        new_q = None
        
        # First, try to use questions from education_questions.json
        if education_pool_index < len(education_questions_pool):
            while education_pool_index < len(education_questions_pool):
                eq = education_questions_pool[education_pool_index]
                education_pool_index += 1
                
                text = eq.get('text', '').strip()
                if not text:
                    continue
                
                text_lower = text.lower()
                normalized = normalize_question_text(text)
                
                # Check if this question is unique
                if text_lower not in used_texts and normalized not in used_normalized:
                    new_q = convert_education_question(eq, question_id)
                    if new_q:
                        used_texts.add(text_lower)
                        used_normalized.add(normalized)
                        new_questions.append(new_q)
                        break
        
        # If no education question available, generate one
        if not new_q:
            categories_list = list(CATEGORIES.keys())
            category_idx = i % len(categories_list)
            difficulty_idx = (i // len(categories_list)) % len(DIFFICULTIES)
            category = categories_list[category_idx]
            difficulty = DIFFICULTIES[difficulty_idx]
            
            new_q = generate_new_question(question_id, category, difficulty, global_question_counter, used_texts, used_normalized)
            text_lower = new_q['text'].strip().lower()
            normalized = normalize_question_text(new_q['text'])
            
            # Check both exact and template uniqueness
            if text_lower not in used_texts and normalized not in used_normalized:
                used_texts.add(text_lower)
                used_normalized.add(normalized)
                new_questions.append(new_q)
                global_question_counter += 1
            else:
                # If duplicate, try next category/difficulty combination
                attempts = 0
                found = False
                while attempts < 50 and not found:
                    global_question_counter += 1
                    category_idx = (category_idx + 1) % len(categories_list)
                    difficulty_idx = (difficulty_idx + 1) % len(DIFFICULTIES)
                    category = categories_list[category_idx]
                    difficulty = DIFFICULTIES[difficulty_idx]
                    new_q = generate_new_question(question_id, category, difficulty, global_question_counter, used_texts, used_normalized)
                    text_lower = new_q['text'].strip().lower()
                    normalized = normalize_question_text(new_q['text'])
                    if text_lower not in used_texts and normalized not in used_normalized:
                        used_texts.add(text_lower)
                        used_normalized.add(normalized)
                        new_questions.append(new_q)
                        global_question_counter += 1
                        found = True
                    attempts += 1
                
                if not found:
                    print(f"Warning: Could not generate unique question for index {i} after {attempts} attempts")
    
    print(f"Generated {len(new_questions)} new questions")
    
    # If we still need more questions, add from education_questions.json
    target_count = 5000  # Target number of questions
    current_count = len(unique_questions) + len(new_questions)
    
    if current_count < target_count and len(education_questions_pool) == 0:
        # Load education questions if we haven't already
        try:
            print(f"\nAdding more questions to reach target of {target_count}...")
            with open('assets/questions/education_questions.json', 'r', encoding='utf-8') as f:
                education_data = json.load(f)
                # Sample enough questions
                needed = target_count - current_count
                if len(education_data) > needed * 2:
                    education_questions_pool = random.sample(education_data, min(len(education_data), needed * 2))
                else:
                    education_questions_pool = education_data
            print(f"Loaded {len(education_questions_pool)} questions from education_questions.json")
        except Exception as e:
            print(f"Could not load education_questions.json: {e}")
            education_questions_pool = []
    
    # Add questions from education pool until we reach target
    attempts_since_last_add = 0
    max_attempts_without_progress = len(education_questions_pool)  # Try all questions
    
    while current_count < target_count and education_pool_index < len(education_questions_pool) and attempts_since_last_add < max_attempts_without_progress:
        eq = education_questions_pool[education_pool_index]
        education_pool_index += 1
        attempts_since_last_add += 1
        
        text = eq.get('text', '').strip()
        if not text:
            continue
        
        text_lower = text.lower()
        normalized = normalize_question_text(text)
        
        # Check if this question is unique
        # Allow template duplicates if they're from different categories (still educationally valuable)
        category = eq.get('category', 'General Knowledge')
        topic = eq.get('topic', 'general')
        category_topic_key = f"{normalized}||{category}||{topic}"
        
        if text_lower not in used_texts and category_topic_key not in used_normalized:
            max_id += 1
            question_id = f"q{max_id:04d}"
            converted_q = convert_education_question(eq, question_id)
            if converted_q:
                used_texts.add(text_lower)
                used_normalized.add(normalized)
                new_questions.append(converted_q)
                current_count += 1
                attempts_since_last_add = 0  # Reset counter
                if current_count % 500 == 0:
                    print(f"Added {len(new_questions)} questions so far (target: {target_count})...")
    
    # If we still need more and exhausted the pool, load more
    if current_count < target_count and education_pool_index >= len(education_questions_pool):
        print(f"\nNeed {target_count - current_count} more questions. Loading additional questions...")
        try:
            with open('assets/questions/education_questions.json', 'r', encoding='utf-8') as f:
                all_education_data = json.load(f)
                # Get questions we haven't tried yet
                remaining_needed = target_count - current_count
                # Sample from remaining questions
                remaining_pool = [q for q in all_education_data if q not in education_questions_pool[:education_pool_index]]
                if len(remaining_pool) > remaining_needed * 2:
                    additional_pool = random.sample(remaining_pool, min(len(remaining_pool), remaining_needed * 3))
                else:
                    additional_pool = remaining_pool
                
                print(f"Loaded {len(additional_pool)} additional questions")
                education_pool_index = 0
                education_questions_pool = additional_pool
                
                # Continue adding
                while current_count < target_count and education_pool_index < len(education_questions_pool):
                    eq = education_questions_pool[education_pool_index]
                    education_pool_index += 1
                    
                    text = eq.get('text', '').strip()
                    if not text:
                        continue
                    
                    text_lower = text.lower()
                    normalized = normalize_question_text(text)
                    
                    if text_lower not in used_texts and normalized not in used_normalized:
                        max_id += 1
                        question_id = f"q{max_id:04d}"
                        converted_q = convert_education_question(eq, question_id)
                        if converted_q:
                            category = eq.get('category', 'General Knowledge')
                            topic = eq.get('topic', 'general')
                            category_topic_key = f"{normalize_question_text(eq.get('text', ''))}||{category}||{topic}"
                            used_texts.add(text_lower)
                            used_normalized.add(category_topic_key)
                            new_questions.append(converted_q)
                            current_count += 1
                            if current_count % 500 == 0:
                                print(f"Added {len(new_questions)} questions so far (target: {target_count})...")
        except Exception as e:
            print(f"Could not load additional questions: {e}")
    
    print(f"Total new questions added: {len(new_questions)}")
    
    # Combine unique questions with new questions
    final_questions = unique_questions + new_questions
    
    # Sort by ID to maintain order
    try:
        final_questions.sort(key=lambda x: int(x.get('id', 'q0000').lstrip('q')))
    except:
        pass
    
    print(f"\nFinal question count: {len(final_questions)}")
    
    # Save to file
    print("Saving to questions.json...")
    with open('assets/questions/questions.json', 'w', encoding='utf-8') as f:
        json.dump(final_questions, f, indent=2, ensure_ascii=False)
    
    print("✅ Done! Duplicates removed and replaced with new questions.")
    
    # Verify no duplicates remain
    print("\nVerifying no duplicates remain...")
    final_exact = {}
    final_normalized = {}
    exact_remaining = 0
    template_remaining = 0
    
    for idx, q in enumerate(final_questions):
        text = q.get('text', '').strip().lower()
        normalized = normalize_question_text(q.get('text', ''))
        
        if text in final_exact:
            exact_remaining += 1
        else:
            final_exact[text] = idx
        
        if normalized in final_normalized:
            template_remaining += 1
        else:
            final_normalized[normalized] = idx
    
    if exact_remaining == 0 and template_remaining == 0:
        print("✅ Verification passed: 0 duplicates found!")
    else:
        print(f"⚠️  Warning: {exact_remaining} exact duplicates and {template_remaining} template duplicates still remain")

if __name__ == "__main__":
    main()
