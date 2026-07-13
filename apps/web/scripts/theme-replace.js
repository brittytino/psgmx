const fs = require('fs');
const path = require('path');

const DIRECTORIES_TO_SCAN = [
  path.join(__dirname, '../app'),
  path.join(__dirname, '../components')
];

// Mapping rules for arbitrary tailwind classes to semantic tokens
const REPLACEMENTS = [
  // Backgrounds
  { regex: /bg-\[\#(F8F9FC|F1F5F9|F5F3FF)\]/g, replacement: 'bg-page-bg' },
  { regex: /bg-\[\#6C3DFF\]/g, replacement: 'bg-primary-purple' }, // Maps to coral in our theme
  { regex: /bg-\[\#(1E293B|0F172A)\]/g, replacement: 'bg-rich-black' },
  { regex: /bg-\[\#E2E8F0\]/g, replacement: 'bg-border-light' },
  { regex: /bg-\[\#(EFF6FF|ECFDF5|FFFBEB)\]/g, replacement: 'bg-white' },
  { regex: /bg-\[\#F8F6FF\]/g, replacement: 'bg-white/40 backdrop-blur-md border border-white/20' },
  { regex: /bg-\[\#3B82F6\]/g, replacement: 'bg-electric-blue' }, // Sage green

  // Text
  { regex: /text-\[\#(1E293B|0F172A)\]/g, replacement: 'text-text-main' },
  { regex: /text-\[\#(475569|64748B|94A3B8)\]/g, replacement: 'text-text-muted' },
  { regex: /text-\[\#6C3DFF\]/g, replacement: 'text-primary-purple' },
  { regex: /text-\[\#(3B82F6|06B6D4)\]/g, replacement: 'text-electric-blue' },

  // Borders
  { regex: /border-\[\#(E2E8F0|F1F5F9|CBD5E1)\]/g, replacement: 'border-border-light' },
  { regex: /border-\[\#6C3DFF\]/g, replacement: 'border-primary-purple' },

  // Strokes / Fills / Shadows
  { regex: /stroke-\[\#6C3DFF\]/g, replacement: 'stroke-primary-purple' },
  { regex: /stroke-\[\#3B82F6\]/g, replacement: 'stroke-electric-blue' },
  { regex: /shadow-\[\#6C3DFF\]\/20/g, replacement: 'shadow-md shadow-primary-purple/10' },
];

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf-8');
  let originalContent = content;

  REPLACEMENTS.forEach(({ regex, replacement }) => {
    content = content.replace(regex, replacement);
  });

  if (content !== originalContent) {
    fs.writeFileSync(filePath, content, 'utf-8');
    console.log(`Updated: ${filePath}`);
  }
}

function traverseDirectory(dir) {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      traverseDirectory(fullPath);
    } else if (file.endsWith('.tsx') || file.endsWith('.ts')) {
      processFile(fullPath);
    }
  });
}

console.log('Starting theme unification...');
DIRECTORIES_TO_SCAN.forEach((dir) => traverseDirectory(dir));
console.log('Theme unification complete!');
