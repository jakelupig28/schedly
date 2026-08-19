const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    console.log(`Image size: ${this.width}x${this.height}`);

    // Let's sample pixel rows at y = 400, 600, 800, 1000, 1200, 1400, 1600, 1800
    // and find where dark pixels (text/lines) are located!
    for (let y = 400; y < 1850; y += 50) {
      let darkPixels = 0;
      let darkXs = [];
      let firstDarkColor = null;

      for (let x = 0; x < this.width; x++) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];

        // Dark color (text/stroke)
        if (a > 100 && (r < 100 || g < 100 || b < 100)) {
          darkPixels++;
          if (darkXs.length < 5) darkXs.push(x);
          if (!firstDarkColor) {
            firstDarkColor = `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
          }
        }
      }
      if (darkPixels > 0) {
        console.log(`y=${y}: ${darkPixels} dark pixels. First dark color: ${firstDarkColor}, sample X: ${darkXs.slice(0,3).join(',')}`);
      }
    }
  });
