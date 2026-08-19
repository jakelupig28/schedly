const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');
console.log('Reading:', imgPath);

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    console.log(`Width: ${this.width}, Height: ${this.height}`);
    
    // Check some pixel colors across the image to see what background/text is on it
    let nonTransparent = 0;
    let samplePixels = [];
    
    for (let y = 0; y < this.height; y += 100) {
      for (let x = 0; x < this.width; x += 100) {
        const idx = (this.width * y + x) << 2;
        const r = this.data[idx];
        const g = this.data[idx + 1];
        const b = this.data[idx + 2];
        const a = this.data[idx + 3];
        if (a > 0) nonTransparent++;
        if (samplePixels.length < 20) {
          samplePixels.push({ x, y, r, g, b, a });
        }
      }
    }
    console.log('Sample pixels:', samplePixels);
  });
