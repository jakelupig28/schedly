const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    console.log(`Dimensions: ${this.width}x${this.height}`);

    // Find the bounding box of the background paper/card and the text drawn on it.
    // Let's sample colors in the middle of the card (around x=300 to 800, y=900 to 1700)
    let textColors = {};
    let bgColors = {};

    for (let y = 900; y < 1750; y++) {
      for (let x = 180; x < 900; x++) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];

        if (a < 50) continue;

        const hex = `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
        
        // Luminance calculation
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        if (lum < 100) {
          textColors[hex] = (textColors[hex] || 0) + 1;
        } else {
          bgColors[hex] = (bgColors[hex] || 0) + 1;
        }
      }
    }

    console.log('Top Dark Text Colors in schedule area:');
    console.log(Object.entries(textColors).sort((a,b) => b[1] - a[1]).slice(0, 10));

    console.log('Top Card Background Colors in schedule area:');
    console.log(Object.entries(bgColors).sort((a,b) => b[1] - a[1]).slice(0, 10));
  });
