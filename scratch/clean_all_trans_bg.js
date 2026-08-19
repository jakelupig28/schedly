const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const targets = [
  path.join(__dirname, '..', 'trans bg.png'),
  path.join(__dirname, '..', 'assets', 'trans bg.png'),
  path.join(__dirname, '..', 'prototype', 'trans bg.png'),
];

targets.forEach(imgPath => {
  if (!fs.existsSync(imgPath)) {
    console.log('File does not exist:', imgPath);
    return;
  }

  console.log('Processing:', imgPath);
  fs.createReadStream(imgPath)
    .pipe(new PNG())
    .on('parsed', function() {
      // Sample background color of card paper at x=500, y=1000
      const sampleIdx = (this.width * 1000 + 500) << 2;
      const bgR = this.data[sampleIdx];
      const bgG = this.data[sampleIdx + 1];
      const bgB = this.data[sampleIdx + 2];
      const bgA = this.data[sampleIdx + 3];

      // Replace dark old schedule text inside the schedule card area (x: 160 to 900, y: 810 to 1760)
      for (let y = 810; y <= 1760; y++) {
        for (let x = 160; x <= 900; x++) {
          const idx = (this.width * y + x) << 2;
          const r = this.data[idx];
          const g = this.data[idx + 1];
          const b = this.data[idx + 2];
          const a = this.data[idx + 3];

          if (a > 100) {
            const lum = 0.299 * r + 0.587 * g + 0.114 * b;
            // Old schedule text and grid lines are dark pixels
            if (lum < 170) {
              this.data[idx] = bgR;
              this.data[idx + 1] = bgG;
              this.data[idx + 2] = bgB;
              this.data[idx + 3] = bgA;
            }
          }
        }
      }

      this.pack().pipe(fs.createWriteStream(imgPath)).on('finish', () => {
        console.log('Successfully cleaned trans bg image:', imgPath);
      });
    });
});
