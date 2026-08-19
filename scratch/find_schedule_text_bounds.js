const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    let textMinX = this.width, textMaxX = 0, textMinY = this.height, textMaxY = 0;
    
    // Schedule area is roughly y: 800 to 1800, x: 100 to 980
    for (let y = 800; y < 1800; y++) {
      for (let x = 100; x < 980; x++) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];

        if (a < 100) continue;

        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        
        // Dark pixels (text or grid lines)
        if (lum < 160) {
          if (x < textMinX) textMinX = x;
          if (x > textMaxX) textMaxX = x;
          if (y < textMinY) textMinY = y;
          if (y > textMaxY) textMaxY = y;
        }
      }
    }

    console.log(`Text & Grid Area inside trans bg.png: X [${textMinX}, ${textMaxX}], Y [${textMinY}, ${textMaxY}]`);
  });
