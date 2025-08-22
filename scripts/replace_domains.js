const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const exts = ['.js', '.html', '.dart', '.ps1', '.md', '.json', '.txt'];
const oldToNew = {
  'https://clownfish-app-krnk9.ondigitalocean.app': 'https://montajati-official-backend-production.up.railway.app',
  'http://clownfish-app-krnk9.ondigitalocean.app': 'https://montajati-official-backend-production.up.railway.app',
  'clownfish-app-krnk9.ondigitalocean.app': 'montajati-official-backend-production.up.railway.app',
  'https://montajati-backend.onrender.com': 'https://montajati-official-backend-production.up.railway.app',
  'http://montajati-backend.onrender.com': 'https://montajati-official-backend-production.up.railway.app',
  'montajati-backend.onrender.com': 'montajati-official-backend-production.up.railway.app'
};

const isTextFile = (file) => exts.includes(path.extname(file).toLowerCase());

let report = [];

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      // skip node_modules and .git and build caches
      if (['node_modules', '.git', 'build', 'bin', 'obj', '.dart_tool'].includes(ent.name)) continue;
      walk(full);
    } else if (ent.isFile()) {
      if (!isTextFile(ent.name)) continue;
      try {
        let content = fs.readFileSync(full, 'utf8');
        let original = content;
        let changes = 0;
        for (const [oldStr, newStr] of Object.entries(oldToNew)) {
          const idx = content.indexOf(oldStr);
          if (idx !== -1) {
            const re = new RegExp(escapeRegExp(oldStr), 'g');
            content = content.replace(re, newStr);
            changes += (original.match(new RegExp(escapeRegExp(oldStr), 'g')) || []).length;
            original = content;
          }
        }
        if (changes > 0) {
          // backup
          fs.copyFileSync(full, full + '.bak');
          fs.writeFileSync(full, content, 'utf8');
          report.push({ file: full, replacements: changes });
          console.log(`Updated ${full} -> ${changes} replacements`);
        }
      } catch (err) {
        console.error('Error processing', full, err.message);
      }
    }
  }
}

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

console.log('Starting domain replacement from', root);
walk(root);
console.log('\nSummary:');
let total = report.reduce((s, r) => s + r.replacements, 0);
console.log('Files changed:', report.length);
console.log('Total replacements:', total);
if (report.length > 0) console.log(report.map(r => `${r.file}: ${r.replacements}`).join('\n'));
else console.log('No matches found.');
