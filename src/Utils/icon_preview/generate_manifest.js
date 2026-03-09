const fs = require('fs');
const path = require('path');

const root = process.cwd();
const iconsDir = path.join(root, 'Assets', 'Icons');
const outArg = process.argv[2] || path.join('tools', 'icon_preview', 'images.json');
const outPath = path.isAbsolute(outArg) ? outArg : path.join(root, outArg);

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir, { withFileTypes: true });
  for (const d of list) {
    const res = path.join(dir, d.name);
    if (d.isDirectory()) {
      results = results.concat(walk(res));
    } else {
      if (res.toLowerCase().endsWith('.png')) results.push(res);
    }
  }
  return results;
}

if (!fs.existsSync(iconsDir)) {
  console.error('Directory not found:', iconsDir);
  process.exit(2);
}

const files = walk(iconsDir).map(p => path.relative(root, p).split(path.sep).join('/'));

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(files, null, 2), 'utf8');

console.log('Wrote', files.length, 'entries to', outPath);
