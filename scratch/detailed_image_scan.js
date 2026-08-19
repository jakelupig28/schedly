const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    console.log('Scanning rows for dark pixels (text)...');

    let rowsWithText = [];
    for (let y = 370; y < 1876; y += 10) {
      let count = 0;
      let minX = 1080, maxX = 0;
      for (let x = 50; x < 1030; x++) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];
        if (a > 100) {
          const lum = 0.299 * r + 0.587 * g + 0.114 * b;
          if (lum < 160) {
            count++;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
          }
        }
      }
      if (count > 5) {
        rowsWithText.push({ y, count, minX, maxX });
      }
    }

    console.log(`Found ${rowsWithText.length} sample rows with text/strokes.`);
    console.log(rowsWithText);
  });
