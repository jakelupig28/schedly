const fs = require('fs');
const path = require('path');

// 1. Curated Classic & Modern Master Quotes
const masterQuotes = [
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

// Rich core themes for productivity, encouragement, and empowerment
const topics = [
  "daily discipline", "deep focus", "consistent study", "time management", "goal execution",
  "perseverance", "courageous action", "mindful presence", "creative problem solving", "inner resilience",
  "quiet confidence", "boundless grit", "strategic planning", "self-compassion", "growth mindset",
  "active learning", "clarity of purpose", "daily gratitude", "purposeful reflection", "strategic rest",
  "smart prioritization", "bold initiative", "unwavering integrity", "open mindedness", "continuous mastery",
  "inspirational leadership", "fearless ambition", "sharp concentration", "self-belief", "patient persistence",
  "hopeful vision", "unconditional dedication", "thorough preparation", "adaptability", "positive affirmations",
  "academic excellence", "schedule mastery", "focused study sessions", "task simplification", "stress management",
  "mental clarity", "proactive habits", "constructive feedback", "long-term vision", "daily momentum",
  "intentional focus", "unshakeable optimism", "inner peace", "relentless effort", "self-improvement",
  "habit stacking", "deep work", "overcoming procrastination", "critical thinking", "intellectual curiosity",
  "empowered action", "resilient spirit", "relentless drive", "authenticity", "unyielding faith"
];

// 25 diverse sentence structures across Productivity, Encouragement, and Empowerment
const sentenceGenerators = [
  // Productivity
  (topic) => `Focus on ${topic} today; meaningful progress is forged one steady step at a time.`,
  (topic) => `Mastering ${topic} turns daily academic effort into lasting personal excellence.`,
  (topic) => `When you anchor your schedule in ${topic}, distractions naturally fade away.`,
  (topic) => `Small, disciplined practices in ${topic} create an unstoppable wave of success.`,
  (topic) => `Commit to ${topic} and watch how quickly your potential turns into reality.`,
  (topic) => `The journey to mastery begins with a quiet dedication to ${topic}.`,
  (topic) => `Harness the transformative power of ${topic} to elevate every goal you pursue.`,
  (topic) => `Clarity and ${topic} are the greatest allies in your pursuit of excellence.`,
  (topic) => `Allow ${topic} to guide your schedule and unlock peak productivity every day.`,
  (topic) => `True confidence is built when you consistently practice ${topic}.`,
  (topic) => `Make ${topic} your daily anchor, and watch your academic milestones fall into place.`,
  (topic) => `Efficiency expands the moment you align your daily routine with ${topic}.`,
  (topic) => `A relentless commitment to ${topic} turns ordinary study hours into masterclasses.`,
  (topic) => `Streamline your focus by prioritizing ${topic} over fleeting distractions.`,
  (topic) => `Your goals come within reach when you pair clear intention with ${topic}.`,

  // Encouragement & Resilience
  (topic) => `Even in challenging moments, remember that ${topic} keeps you moving forward.`,
  (topic) => `Embrace every difficulty with ${topic}; each trial strengthens your character.`,
  (topic) => `You possess the inner resilience to conquer tough times through ${topic}.`,
  (topic) => `Take a deep breath and let ${topic} restore your calm and confidence.`,
  (topic) => `Your dedication to ${topic} is silently opening doors to extraordinary opportunities.`,
  (topic) => `Celebrate every small victory today—${topic} creates long-term momentum.`,
  (topic) => `No storm lasts forever; anchor yourself in ${topic} and shine bright.`,
  (topic) => `Trust your path and let ${topic} turn setbacks into powerful stepping stones.`,
  (topic) => `Give yourself grace to learn, grow, and thrive with ${topic}.`,
  (topic) => `Every focused moment rooted in ${topic} is an investment in your future self.`,
  (topic) => `When doubts arise, stand firm in the knowledge that ${topic} will see you through.`,
  (topic) => `You are stronger than any temporary setback when supported by ${topic}.`,
  (topic) => `Keep going with quiet confidence; ${topic} is building an unbreakable foundation.`,
  (topic) => `Every challenge you face is simply an invitation to cultivate deeper ${topic}.`,
  (topic) => `Be proud of how far you've traveled, and let ${topic} carry you to new heights.`,

  // Empowerment & Growth Mindset
  (topic) => `Step boldly into your ambitions, empowered by ${topic} and authentic purpose.`,
  (topic) => `Refuse to doubt your worth; let ${topic} elevate your highest aspirations.`,
  (topic) => `Your unique voice and ${topic} have the strength to inspire and lead others.`,
  (topic) => `Claim your seat at the table with confidence rooted in ${topic}.`,
  (topic) => `Dare to think bigger, dream bolder, and lead with ${topic}.`,
  (topic) => `Self-mastery begins the moment you take full ownership of ${topic}.`,
  (topic) => `Break through invisible limits by cultivating steadfast ${topic}.`,
  (topic) => `Your future is an unwritten canvas—paint it with courage, purpose, and ${topic}.`,
  (topic) => `Stand proud of who you are and let ${topic} unlock your infinite potential.`,
  (topic) => `You hold the keys to your future when you lead with unwavering ${topic}.`,
  (topic) => `Transform your vision into reality by dedicating your heart and mind to ${topic}.`,
  (topic) => `Raise your standards and inspire those around you through steadfast ${topic}.`,
  (topic) => `Great leaders are forged through the daily, authentic practice of ${topic}.`,
  (topic) => `Empower yourself each morning by setting a firm intention for ${topic}.`,
  (topic) => `Own your brilliance and let ${topic} illuminate the path to your dreams.`
];

// Additional perspectives and contextual frames
const perspectives = [
  "Daily Wisdom:", "Morning Focus:", "Student Mindset:", "Power Reminder:", "Growth Insight:",
  "Proactive Thought:", "Inspirational Truth:", "Core Philosophy:", "Success Mantra:", "Empowerment Note:",
  "Deep Work Key:", "Resilience Principle:", "Study Compass:", "Momentum Builder:", "Mindset Anchor:"
];

const quotesSet = new Set();

// 1. Add baseline classic quotes
masterQuotes.forEach(q => quotesSet.add(q.trim()));

// 2. Generate structured matrix
for (const gen of sentenceGenerators) {
  for (const topic of topics) {
    if (quotesSet.size >= 5000) break;
    quotesSet.add(gen(topic));
  }
}

// 3. Generate perspective-framed variations to reach exactly 5,000 unique quotes
for (const prefix of perspectives) {
  for (const gen of sentenceGenerators) {
    for (const topic of topics) {
      if (quotesSet.size >= 5000) break;
      const baseSentence = gen(topic);
      // Create clean, unique quote with framed perspective
      quotesSet.add(`${prefix} ${baseSentence}`);
    }
  }
}

// 4. Fill any remaining with action affirmations
let affIdx = 1;
while (quotesSet.size < 5000) {
  const t = topics[quotesSet.size % topics.length];
  quotesSet.add(`Affirmation #${quotesSet.size + 1}: I am committed to ${t}, and I create positive results every single day.`);
}

const final5000Quotes = Array.from(quotesSet).slice(0, 5000);
console.log(`Successfully compiled exactly ${final5000Quotes.length} unique quotes.`);

// Write to assets/quotes.txt
const assetsDir = path.join(__dirname, '../frontend/assets');
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}
const txtContent = final5000Quotes.map((q, i) => `${i + 1}. ${q}`).join('\n');
fs.writeFileSync(path.join(assetsDir, 'quotes.txt'), txtContent, 'utf8');

// Write to lib/services/quotes_service.dart
const dartContent = `// 5,000 Curated Inspirational Quotes for Schedly
// Spanning Productivity, Encouragement, and Empowerment

class QuotesService {
  /// Exactly 5,000 unique, inspiring quotes
  static const List<String> allQuotes = [
${final5000Quotes.map(q => `    ${JSON.stringify(q)},`).join('\n')}
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

  /// Get a random quote from the 5,000 collection
  static String getRandomQuote([int? seed]) {
    if (seed != null) {
      return allQuotes[(seed.abs()) % allQuotes.length];
    }
    final now = DateTime.now();
    final index = (now.microsecondsSinceEpoch ~/ 1000) % allQuotes.length;
    return allQuotes[index];
  }

  /// Total count of curated quotes in library (5,000)
  static int get totalCount => allQuotes.length;

  /// Get quote by 1-based index (1 to 5000)
  static String getQuoteById(int id) {
    if (id < 1 || id > allQuotes.length) {
      return getDailyQuote();
    }
    return allQuotes[id - 1];
  }
}
`;

fs.writeFileSync(path.join(__dirname, '../frontend/lib/services/quotes_service.dart'), dartContent, 'utf8');
console.log('Successfully generated 5,000 quotes in quotes_service.dart and assets/quotes.txt!');
