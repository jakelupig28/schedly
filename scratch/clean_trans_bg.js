const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    // Let's sample the exact background color of the inner schedule paper at x=500, y=1000
    const sampleIdx = (this.width * 1000 + 500) << 2;
    const bgR = this.data[sampleIdx];
    const bgG = this.data[sampleIdx + 1];
    const bgB = this.data[sampleIdx + 2];
    const bgA = this.data[sampleIdx + 3];

    console.log(`Card background color at (500, 1000): RGB(${bgR}, ${bgG}, ${bgB}), Alpha: ${bgA}`);

    // Create a cleaned copy of trans bg.png
    // We clean the text area inside x: [170, 890], y: [820, 1750]
    // where dark text pixels (lum < 180) exist, by replacing them with the local card background color or filling clean background!
    
    for (let y = 820; y <= 1750; y++) {
      for (let x = 170; x <= 890; x++) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];

        if (a > 100) {
          const lum = 0.299 * r + 0.587 * g + 0.114 * b;
          // If it's old text/grid lines (darker brown/gray text pixels)
          if (lum < 170) {
            this.data[idx] = bgR;
            this.data[idx + 1] = bgG;
            this.data[idx + 2] = bgB;
            this.data[idx + 3] = bgA;
          }
        }
      }
    }

    const outPath = path.join(__dirname, '..', 'scratch', 'clean_trans_bg.png');
    this.pack().pipe(fs.createWriteStream(outPath)).on('finish', () => {
      console.log('Cleaned trans bg image saved to:', outPath);
    });
  });
