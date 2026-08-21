const fs = require('fs');
const path = require('path');

// Curated base quotes covering productivity, encouragement, and empowerment
const baseQuotes = [
  "The secret of getting ahead is getting started.",
  "Focus on progress, not perfection.",
  "Your future is created by what you do today, not tomorrow.",
  "Believe you can and you're halfway there.",
  "Make today your masterpiece.",
  "Small daily improvements over time lead to stunning results.",
  "Action is the foundational key to all success.",
  "Discipline is the bridge between goals and accomplishment.",
  "Do what you can, with what you have, where you are.",
  "Success is the sum of small efforts, repeated day in and day out.",
  "Don't count the days, make the days count.",
  "The only way to do great work is to love what you do.",
  "It always seems impossible until it's done.",
  "Start where you are. Use what you have. Do what you can.",
  "Energy flows where attention goes.",
  "Consistency is what transforms average into excellence.",
  "Productivity is never an accident; it is the result of a commitment to excellence.",
  "Focus on being productive instead of busy.",
  "You don't have to be great to start, but you have to start to be great.",
  "Great things are not done by impulse, but by a series of small things brought together.",
  "Deep work produces rare and valuable outcomes.",
  "Amateurs sit and wait for inspiration; the rest of us just get up and go to work.",
  "One day or day one. You decide.",
  "Your time is limited, don't waste it living someone else's life.",
  "The best way to predict the future is to create it.",
  "Don't watch the clock; do what it does. Keep going.",
  "Quality is not an act, it is a habit.",
  "Simplicity boils down to two steps: Identify the essential, eliminate the rest.",
  "Master your morning, master your day.",
  "Prioritize what truly matters and the rest will fall into place.",
  "Efficiency is doing things right; effectiveness is doing the right things.",
  "The tragedy in life doesn't lie in not reaching your goal; the tragedy lies in having no goal to reach.",
  "Clarity precedes mastery.",
  "A goal without a plan is just a wish.",
  "What gets measured gets managed.",
  "Do something today that your future self will thank you for.",
  "Strive for progress, not perfection.",
  "You are what you repeatedly do. Excellence, then, is not an act, but a habit.",
  "Plan your work and work your plan.",
  "The difference between ordinary and extraordinary is that little extra.",
  "Difficult roads often lead to beautiful destinations.",
  "Fall seven times, stand up eight.",
  "Courage doesn't always roar. Sometimes courage is the quiet voice saying, 'I will try again tomorrow.'",
  "Stars cannot shine without darkness.",
  "Everything you've ever wanted is on the other side of fear.",
  "Hardships often prepare ordinary people for an extraordinary destiny.",
  "You are stronger than you know, braver than you believe, and smarter than you think.",
  "Mistakes are proof that you are trying.",
  "Storms make trees take deeper roots.",
  "Every strike brings me closer to the next home run.",
  "Doubt kills more dreams than failure ever will.",
  "Turn your wounds into wisdom.",
  "Hope is being able to see that there is light despite all of the darkness.",
  "In the middle of every difficulty lies opportunity.",
  "You don't have to have it all figured out to move forward.",
  "The darkest nights produce the brightest stars.",
  "Keep your face always toward the sunshine, and shadows will fall behind you.",
  "Failure is not the opposite of success; it's part of success.",
  "Give yourself credit for how far you've come.",
  "There is no failure except in no longer trying.",
  "Healing and growth take time. Be patient with your journey.",
  "Breathe. You are doing the best you can with what you have.",
  "Your current situation is not your final destination.",
  "Every accomplishment starts with the decision to try.",
  "Trust the timing of your life.",
  "Grit is that extra something that separates the most successful people from the rest.",
  "When you feel like quitting, remember why you started.",
  "You are capable of amazing things.",
  "Every day may not be good, but there is something good in every day.",
  "Patience and persistence have a magical effect before which difficulties disappear.",
  "The only limit to our realization of tomorrow will be our doubts of today.",
  "Own your story and love yourself through that process.",
  "You have within you the strength, the patience, and the passion to reach for the stars.",
  "Dream big and dare to fail.",
  "Be the change that you wish to see in the world.",
  "No one can make you feel inferior without your consent.",
  "Empowerment comes from knowing who you are and standing tall in your truth.",
  "Your voice matters. Your story matters. You matter.",
  "Invest in your mind, your craft, and your character.",
  "The power to create a better tomorrow is in your hands today.",
  "Never underestimate the impact of your unique potential.",
  "Step out of your comfort zone and into your greatness.",
  "You are the author of your own life story; write a bold chapter today.",
  "Leadership is the capacity to translate vision into reality.",
  "Believe in the power of your dreams and the strength of your dedication.",
  "Knowledge is power, but the application of knowledge is transformation.",
  "Raise your standards, refuse to settle, and reach for your summit.",
  "Self-confidence is a superpower that unlocks boundless opportunities.",
  "The mind is everything. What you think you become.",
  "Do not wait for leaders; do it alone, person to person."
];

// Rich, diverse themes across productivity, encouragement, and empowerment
const domains = [
  "time management", "deep focus", "daily consistency", "goal setting", "curiosity",
  "self-discipline", "patience", "courageous action", "intentional living", "problem solving",
  "inner resilience", "quiet confidence", "mindful presence", "boundless grit", "strategic planning",
  "self-compassion", "growth mindset", "relentless effort", "positive optimism", "active learning",
  "clarity of purpose", "daily gratitude", "creative reflection", "energizing rest", "perseverance",
  "smart prioritization", "bold initiative", "unwavering integrity", "open mindedness", "continuous mastery",
  "inspirational leadership", "fearless ambition", "sharp focus", "self-trust", "patient practice",
  "hopeful vision", "unconditional dedication", "thorough preparation", "adaptability", "positive affirmations",
  "studious dedication", "academic excellence", "schedule mastery", "focused study sessions", "task simplification",
  "stress management", "mental clarity", "proactive habits", "constructive feedback", "long-term vision"
];

const patterns = [
  (d) => `Focus on ${d} today; meaningful progress is forged one steady step at a time.`,
  (d) => `Mastering ${d} turns daily academic effort into lasting personal excellence.`,
  (d) => `When you anchor your schedule in ${d}, distractions naturally fade away.`,
  (d) => `Small, disciplined practices in ${d} create an unstoppable wave of success.`,
  (d) => `Commit to ${d} and watch how quickly your potential turns into reality.`,
  (d) => `The journey to mastery begins with a quiet dedication to ${d}.`,
  (d) => `Harness the transformative power of ${d} to elevate every goal you pursue.`,
  (d) => `Clarity and ${d} are the greatest allies in your pursuit of excellence.`,
  (d) => `Allow ${d} to guide your schedule and unlock peak productivity every day.`,
  (d) => `True confidence is built when you consistently practice ${d}.`,
  (d) => `Even in challenging moments, remember that ${d} keeps you moving forward.`,
  (d) => `Embrace every difficulty with ${d}; each trial strengthens your character.`,
  (d) => `You possess the inner resilience to conquer tough times through ${d}.`,
  (d) => `Take a deep breath and let ${d} restore your calm and confidence.`,
  (d) => `Your dedication to ${d} is silently opening doors to extraordinary opportunities.`,
  (d) => `Celebrate every small victory today—${d} creates long-term momentum.`,
  (d) => `No storm lasts forever; anchor yourself in ${d} and shine bright.`,
  (d) => `Trust your path and let ${d} turn setbacks into powerful stepping stones.`,
  (d) => `Give yourself grace to learn, grow, and thrive with ${d}.`,
  (d) => `Every focused moment rooted in ${d} is an investment in your future self.`
];

const quotesSet = new Set();
baseQuotes.forEach(q => quotesSet.add(q.trim()));

for (const pattern of patterns) {
  for (const domain of domains) {
    if (quotesSet.size >= 1000) break;
    quotesSet.add(pattern(domain));
  }
}

// Add more inspirational variations if needed to ensure exactly 1000 unique quotes
const qualities = [
  "unshakable courage", "limitless curiosity", "deep determination", "authentic kindness",
  "visionary thinking", "passionate drive", "fearless persistence", "radiant optimism",
  "unwavering dedication", "grace under pressure"
];

const affirmations = [
  (q) => `Empower your mind with ${q}; you are capable of achieving greatness.`,
  (q) => `Lead your day with ${q} and let your positive impact be felt by all.`,
  (q) => `Stand tall in your purpose, backed by ${q} and steadfast belief.`,
  (q) => `Never doubt the strength that comes from practicing ${q} every day.`,
  (q) => `Your future is bright when you approach every challenge with ${q}.`,
  (q) => `Cultivate ${q} and transform every obstacle into a stepping stone.`,
  (q) => `Wake up ready to conquer your goals with ${q} and persistent enthusiasm.`,
  (q) => `Success is an inevitable outcome when ${q} guides your daily actions.`,
  (q) => `Celebrate your uniqueness and let ${q} illuminate your path.`,
  (q) => `Greatness is not a coincidence—it is fueled by ${q} day in and day out.`
];

for (const aff of affirmations) {
  for (const q of qualities) {
    if (quotesSet.size >= 1000) break;
    quotesSet.add(aff(q));
  }
}

const finalQuotes = Array.from(quotesSet).slice(0, 1000);
console.log(`Final unique quotes count: ${finalQuotes.length}`);

// Make sure frontend/assets folder exists
const assetsDir = path.join(__dirname, '../frontend/assets');
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

// Write assets/quotes.txt
const quotesTxt = finalQuotes.map((q, i) => `${i + 1}. ${q}`).join('\n');
fs.writeFileSync(path.join(assetsDir, 'quotes.txt'), quotesTxt, 'utf8');

// Write lib/services/quotes_service.dart
const dartCode = `// 1,000 Curated Inspirational Quotes for Schedly
// Spanning Productivity, Encouragement, and Empowerment

class QuotesService {
  /// Exactly 1,000 unique, inspiring quotes
  static const List<String> allQuotes = [
${finalQuotes.map(q => `    ${JSON.stringify(q)},`).join('\n')}
  ];

  /// Get the daily quote deterministically based on the calendar date (day count).
  /// Every calendar day at midnight local time, this changes to the next quote in the collection.
  static String getDailyQuote([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    // Normalize to date-only days since epoch (Jan 1, 1970)
    final daysSinceEpoch = targetDate.difference(DateTime(1970, 1, 1)).inDays;
    final index = (daysSinceEpoch.abs()) % allQuotes.length;
    return allQuotes[index];
  }

  /// Get a random quote from the 1,000 collection
  static String getRandomQuote([int? seed]) {
    if (seed != null) {
      return allQuotes[(seed.abs()) % allQuotes.length];
    }
    final now = DateTime.now();
    final index = (now.microsecondsSinceEpoch ~/ 1000) % allQuotes.length;
    return allQuotes[index];
  }

  /// Total count of curated quotes in library
  static int get totalCount => allQuotes.length;

  /// Get quote by 1-based index (1 to 1000)
  static String getQuoteById(int id) {
    if (id < 1 || id > allQuotes.length) {
      return getDailyQuote();
    }
    return allQuotes[id - 1];
  }
}
`;

fs.writeFileSync(path.join(__dirname, '../frontend/lib/services/quotes_service.dart'), dartCode, 'utf8');
console.log('Successfully generated quotes_service.dart and assets/quotes.txt!');
