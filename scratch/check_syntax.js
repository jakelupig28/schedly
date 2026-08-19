const fs = require('fs');
const vm = require('vm');

const html = fs.readFileSync('c:/Users/User/schedly/prototype/index.html', 'utf8');
const scriptRegex = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
let match;
let scriptIndex = 0;

while ((match = scriptRegex.exec(html)) !== null) {
  const js = match[1];
  const srcAttr = match[0].match(/src\s*=\s*["']([^"']+)["']/i);
  
  if (srcAttr && !js.trim()) {
    continue;
  }
  
  scriptIndex++;
  console.log(`Checking script block #${scriptIndex}...`);
  try {
    new vm.Script(js);
    console.log(`Script block #${scriptIndex} is syntactically valid.`);
  } catch (err) {
    console.error(`Syntax error in script block #${scriptIndex}:`);
    console.error(err.stack);
    
    const lines = js.split('\n');
    const errLine = err.stack.match(/evalmachine\.<anonymous>:(\d+)/);
    if (errLine) {
      const lineNum = parseInt(errLine[1], 10);
      console.error(`--- Error at line ${lineNum} inside script block ---`);
      for (let i = Math.max(0, lineNum - 5); i < Math.min(lines.length, lineNum + 5); i++) {
        console.error(`${i + 1}: ${lines[i]}`);
      }
    }
  }
}
