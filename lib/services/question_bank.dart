import 'dart:math';
import '../models/question.dart';
import 'question_tracker_service.dart';

class QuestionBank {
  static final QuestionBank _instance = QuestionBank._internal();
  factory QuestionBank() => _instance;
  QuestionBank._internal();

  final Random _random = Random();

  // Sample question database - in production, this would come from a backend
  final Map<String, List<Question>> _questions = {
    'Math': [
      Question(
        id: 'm1',
        text: 'What is 15 × 12?',
        options: ['160', '180', '200', '210'],
        correctIndex: 1,
        explanation: '15 × 12 = 180. You can calculate this by (15 × 10) + (15 × 2) = 150 + 30 = 180.',
        category: 'Math',
        topic: 'multiplication',
      ),
      Question(
        id: 'm2',
        text: 'If a triangle has angles of 60° and 70°, what is the third angle?',
        options: ['40°', '50°', '60°', '70°'],
        correctIndex: 1,
        explanation: 'The sum of angles in a triangle is always 180°. So 180° - 60° - 70° = 50°.',
        category: 'Math',
        topic: 'geometry',
      ),
      Question(
        id: 'm3',
        text: 'What is the square root of 144?',
        options: ['10', '11', '12', '13'],
        correctIndex: 2,
        explanation: '12 × 12 = 144, so √144 = 12.',
        category: 'Math',
        topic: 'arithmetic',
      ),
      Question(
        id: 'm4',
        text: 'What is 25% of 80?',
        options: ['15', '20', '25', '30'],
        correctIndex: 1,
        explanation: '25% means 1/4, so 80 ÷ 4 = 20.',
        category: 'Math',
        topic: 'percentages',
      ),
      Question(
        id: 'm5',
        text: 'If x + 7 = 15, what is x?',
        options: ['6', '7', '8', '9'],
        correctIndex: 2,
        explanation: 'x = 15 - 7 = 8.',
        category: 'Math',
        topic: 'algebra',
      ),
    ],
    'Science': [
      Question(
        id: 's1',
        text: 'What is the chemical symbol for gold?',
        options: ['Go', 'Au', 'Gd', 'Ag'],
        correctIndex: 1,
        explanation: 'The symbol Au comes from the Latin word "aurum" meaning gold.',
        category: 'Science',
        topic: 'chemistry',
      ),
      Question(
        id: 's2',
        text: 'How many planets are in our solar system?',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
        explanation: 'There are 8 planets: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, and Neptune.',
        category: 'Science',
        topic: 'astronomy',
      ),
      Question(
        id: 's3',
        text: 'What is the powerhouse of the cell?',
        options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
        correctIndex: 1,
        explanation: 'Mitochondria produce energy (ATP) for the cell through cellular respiration.',
        category: 'Science',
        topic: 'biology',
      ),
      Question(
        id: 's4',
        text: 'What is the speed of light (approximately)?',
        options: ['300,000 km/s', '150,000 km/s', '450,000 km/s', '600,000 km/s'],
        correctIndex: 0,
        explanation: 'The speed of light in a vacuum is approximately 299,792 km/s, often rounded to 300,000 km/s.',
        category: 'Science',
        topic: 'physics',
      ),
      Question(
        id: 's5',
        text: 'What gas do plants absorb from the atmosphere?',
        options: ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'],
        correctIndex: 2,
        explanation: 'Plants absorb CO₂ during photosynthesis and release oxygen.',
        category: 'Science',
        topic: 'biology',
      ),
    ],
    'History': [
      Question(
        id: 'h1',
        text: 'In which year did World War II end?',
        options: ['1943', '1944', '1945', '1946'],
        correctIndex: 2,
        explanation: 'World War II ended in 1945 with Germany\'s surrender in May and Japan\'s in August.',
        category: 'History',
        topic: 'world-wars',
      ),
      Question(
        id: 'h2',
        text: 'Who was the first President of the United States?',
        options: ['Thomas Jefferson', 'George Washington', 'John Adams', 'Benjamin Franklin'],
        correctIndex: 1,
        explanation: 'George Washington served as the first U.S. President from 1789 to 1797.',
        category: 'History',
        topic: 'american-history',
      ),
      Question(
        id: 'h3',
        text: 'The ancient city of Rome was built on how many hills?',
        options: ['5', '6', '7', '8'],
        correctIndex: 2,
        explanation: 'Rome was famously built on seven hills: Palatine, Aventine, Capitoline, Quirinal, Viminal, Esquiline, and Caelian.',
        category: 'History',
        topic: 'ancient-history',
      ),
      Question(
        id: 'h4',
        text: 'Which Egyptian pharaoh\'s tomb was discovered in 1922?',
        options: ['Ramses II', 'Cleopatra', 'Tutankhamun', 'Nefertiti'],
        correctIndex: 2,
        explanation: 'Howard Carter discovered King Tutankhamun\'s tomb in the Valley of the Kings in 1922.',
        category: 'History',
        topic: 'ancient-egypt',
      ),
      Question(
        id: 'h5',
        text: 'The Great Wall of China was built to protect against which groups?',
        options: ['Mongols', 'Japanese', 'Europeans', 'Indians'],
        correctIndex: 0,
        explanation: 'The Great Wall was primarily built to protect against invasions from Mongol tribes from the north.',
        category: 'History',
        topic: 'asian-history',
      ),
    ],
    'Geography': [
      Question(
        id: 'g1',
        text: 'What is the capital of Australia?',
        options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
        correctIndex: 2,
        explanation: 'Canberra is the capital of Australia, chosen as a compromise between Sydney and Melbourne.',
        category: 'Geography',
        topic: 'capitals',
      ),
      Question(
        id: 'g2',
        text: 'Which is the longest river in the world?',
        options: ['Amazon', 'Nile', 'Yangtze', 'Mississippi'],
        correctIndex: 1,
        explanation: 'The Nile River in Africa is approximately 6,650 km long, making it the longest river.',
        category: 'Geography',
        topic: 'rivers',
      ),
      Question(
        id: 'g3',
        text: 'How many continents are there?',
        options: ['5', '6', '7', '8'],
        correctIndex: 2,
        explanation: 'There are 7 continents: Africa, Antarctica, Asia, Europe, North America, Australia (Oceania), and South America.',
        category: 'Geography',
        topic: 'continents',
      ),
      Question(
        id: 'g4',
        text: 'Which country has the most time zones?',
        options: ['Russia', 'USA', 'France', 'China'],
        correctIndex: 2,
        explanation: 'France has 12 time zones due to its overseas territories, more than any other country.',
        category: 'Geography',
        topic: 'countries',
      ),
      Question(
        id: 'g5',
        text: 'What is the smallest country in the world?',
        options: ['Monaco', 'Vatican City', 'San Marino', 'Liechtenstein'],
        correctIndex: 1,
        explanation: 'Vatican City is the smallest country at approximately 0.44 km².',
        category: 'Geography',
        topic: 'countries',
      ),
    ],
    'Literature': [
      Question(
        id: 'l1',
        text: 'Who wrote "Romeo and Juliet"?',
        options: ['Charles Dickens', 'William Shakespeare', 'Jane Austen', 'Mark Twain'],
        correctIndex: 1,
        explanation: 'William Shakespeare wrote this famous tragedy around 1594-1596.',
        category: 'Literature',
        topic: 'shakespeare',
      ),
      Question(
        id: 'l2',
        text: 'What is the first book in the Harry Potter series?',
        options: ['Chamber of Secrets', 'Philosopher\'s Stone', 'Prisoner of Azkaban', 'Goblet of Fire'],
        correctIndex: 1,
        explanation: '"Harry Potter and the Philosopher\'s Stone" (or Sorcerer\'s Stone in the US) was published in 1997.',
        category: 'Literature',
        topic: 'modern-fiction',
      ),
      Question(
        id: 'l3',
        text: 'Who wrote "1984"?',
        options: ['Aldous Huxley', 'George Orwell', 'Ray Bradbury', 'H.G. Wells'],
        correctIndex: 1,
        explanation: 'George Orwell wrote this dystopian novel, published in 1949.',
        category: 'Literature',
        topic: 'classic-fiction',
      ),
      Question(
        id: 'l4',
        text: 'In "The Lord of the Rings", who is the bearer of the One Ring?',
        options: ['Aragorn', 'Gandalf', 'Frodo', 'Sam'],
        correctIndex: 2,
        explanation: 'Frodo Baggins is tasked with destroying the One Ring in Mount Doom.',
        category: 'Literature',
        topic: 'fantasy',
      ),
      Question(
        id: 'l5',
        text: 'Who wrote "Pride and Prejudice"?',
        options: ['Emily Brontë', 'Jane Austen', 'Charlotte Brontë', 'George Eliot'],
        correctIndex: 1,
        explanation: 'Jane Austen published this romantic novel in 1813.',
        category: 'Literature',
        topic: 'romance',
      ),
    ],
  };

  /// Get random questions for a category
  /// Ensures no duplicates within the returned list
  Future<List<Question>> getQuestions({
    required String category,
    required int count,
  }) async {
    final tracker = QuestionTrackerService();
    await tracker.initialize();
    
    final categoryQuestions = _questions[category] ?? [];
    if (categoryQuestions.isEmpty) {
      // Fallback to all questions if category not found
      final allQuestions = _questions.values.expand((q) => q).toList();
      // Filter out used questions
      final unused = tracker.filterUsedQuestions(allQuestions, (q) => q.id);
      unused.shuffle(_random);
      final selected = unused.take(count).toList();
      // Mark as used
      if (selected.isNotEmpty) {
        tracker.markQuestionsAsUsed(selected.map((q) => q.id).toList());
      }
      return selected;
    }

    // Filter out used questions
    final unused = tracker.filterUsedQuestions(categoryQuestions, (q) => q.id);
    final shuffled = List<Question>.from(unused)..shuffle(_random);
    final selected = shuffled.take(count).toList();
    
    // Ensure no duplicates by ID
    final uniqueSelected = <String, Question>{};
    for (final q in selected) {
      if (!uniqueSelected.containsKey(q.id)) {
        uniqueSelected[q.id] = q;
      }
    }
    final finalSelected = uniqueSelected.values.toList();
    
    // Mark as used
    if (finalSelected.isNotEmpty) {
      tracker.markQuestionsAsUsed(finalSelected.map((q) => q.id).toList());
    }
    
    return finalSelected;
  }

  /// Get questions for multiple categories (for mixed mode)
  /// Ensures no duplicates within the returned list
  Future<List<Question>> getMixedQuestions({
    required List<String> categories,
    required int count,
  }) async {
    final tracker = QuestionTrackerService();
    await tracker.initialize();
    
    final allQuestions = <Question>[];
    for (final category in categories) {
      allQuestions.addAll(_questions[category] ?? []);
    }
    
    // Filter out used questions
    final unused = tracker.filterUsedQuestions(allQuestions, (q) => q.id);
    unused.shuffle(_random);
    
    // Ensure no duplicates by ID
    final uniqueSelected = <String, Question>{};
    for (final q in unused.take(count * 2)) { // Take more to ensure we have enough unique
      if (uniqueSelected.length >= count) break;
      if (!uniqueSelected.containsKey(q.id)) {
        uniqueSelected[q.id] = q;
      }
    }
    
    final finalSelected = uniqueSelected.values.toList();
    
    // Mark as used
    if (finalSelected.isNotEmpty) {
      tracker.markQuestionsAsUsed(finalSelected.map((q) => q.id).toList());
    }
    
    return finalSelected;
  }

  /// Get all available categories
  List<String> getCategories() {
    return _questions.keys.toList();
  }

  /// Get question count for a category
  int getCategoryQuestionCount(String category) {
    return _questions[category]?.length ?? 0;
  }
}
