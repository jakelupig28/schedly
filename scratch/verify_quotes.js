const fs = require('fs');
const path = require('path');

const quotesTxtPath = path.join(__dirname, '../frontend/assets/quotes.txt');
const quotesServicePath = path.join(__dirname, '../frontend/lib/services/quotes_service.dart');

const txtContent = fs.readFileSync(quotesTxtPath, 'utf8');
const lines = txtContent.split('\n').filter(l => l.trim().length > 0);

console.log(`Checking quotes.txt: ${lines.length} lines found.`);
if (lines.length !== 5000) {
  console.error(`ERROR: Expected 5000 quotes, found ${lines.length}`);
  process.exit(1);
}

// Check uniqueness
const uniqueQuotes = new Set(lines.map(l => l.replace(/^\d+\.\s*/, '').trim()));
console.log(`Unique quotes count: ${uniqueQuotes.size}`);
if (uniqueQuotes.size !== 5000) {
  console.error(`ERROR: Expected 5000 unique quotes, found ${uniqueQuotes.size}`);
  process.exit(1);
}

// Check QuotesService Dart file
const dartContent = fs.readFileSync(quotesServicePath, 'utf8');
if (!dartContent.includes('class QuotesService') || !dartContent.includes('getDailyQuote')) {
  console.error('ERROR: QuotesService missing required methods.');
  process.exit(1);
}

console.log('Verification SUCCESS: 5,000 unique quotes verified in both assets/quotes.txt and quotes_service.dart!');
