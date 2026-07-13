const fs = require('fs');
const path = require('path');

const DIRECTORIES_TO_SCAN = [
  path.join(__dirname, '../app/faculty'),
  path.join(__dirname, '../app/student'),
  path.join(__dirname, '../app/alumni'),
  path.join(__dirname, '../app/hod')
];

// Mapping rules for ALL remaining SaaS generic colors to our premium cream theme
const REPLACEMENTS = [
  // Backgrounds
  { regex: /bg-\[\#(F5F3FF|EFF6FF|ECFDF5|FFFBEB|FEF2F2|ECFEFF|FFF1F2|E5D4FF)\]\/?\d*/gi, replacement: 'bg-page-bg' },
  { regex: /bg-\[\#(10B981|059669)\]/gi, replacement: 'bg-electric-blue' }, // Green -> Sage
  { regex: /bg-\[\#(F59E0B|D97706)\]/gi, replacement: 'bg-illus-gold' }, // Amber -> Gold
  { regex: /bg-\[\#(EF4444|DC2626|F43F5E)\]/gi, replacement: 'bg-deep-violet' }, // Red -> Terracotta
  { regex: /bg-\[\#(3B82F6|06B6D4)\]/gi, replacement: 'bg-primary-purple' }, // Blue -> Coral
  { regex: /bg-\[\#(8B5CF6)\]\/50/gi, replacement: 'bg-primary-purple/20' }, 
  { regex: /bg-\[\#FEF2F2\]/gi, replacement: 'bg-page-bg' },

  // Text
  { regex: /text-\[\#(10B981|059669)\]/gi, replacement: 'text-electric-blue' }, // Green -> Sage
  { regex: /text-\[\#(F59E0B|D97706)\]/gi, replacement: 'text-illus-gold' }, // Amber -> Gold
  { regex: /text-\[\#(EF4444|DC2626|F43F5E)\]/gi, replacement: 'text-deep-violet' }, // Red -> Terracotta
  { regex: /text-\[\#(3B82F6|06B6D4)\]/gi, replacement: 'text-primary-purple' }, // Blue -> Coral

  // Borders
  { regex: /border-\[\#(A7F3D0|10B981)\]/gi, replacement: 'border-electric-blue/30' },
  { regex: /border-\[\#(FDE68A|F59E0B)\]/gi, replacement: 'border-illus-gold/30' },
  { regex: /border-\[\#(FECACA|EF4444|F43F5E)\]/gi, replacement: 'border-deep-violet/30' },
  { regex: /border-\[\#(BFDBFE|3B82F6)\]/gi, replacement: 'border-primary-purple/30' },
  { regex: /border-\[\#E5D4FF\]\/\d+/gi, replacement: 'border-primary-purple/20' },

  // Strokes / Fills / Shadows
  { regex: /stroke-\[\#(10B981|059669)\]/gi, replacement: 'stroke-electric-blue' },
  { regex: /stroke-\[\#(F59E0B|D97706)\]/gi, replacement: 'stroke-illus-gold' },
  { regex: /stroke-\[\#(EF4444|DC2626|F43F5E)\]/gi, replacement: 'stroke-deep-violet' },
  
  // Hardcoded hex strings in props (like color="#10B981")
  { regex: /color:\s*['"]\#6C3DFF['"]/gi, replacement: 'color: "var(--primary-purple)"' },
  { regex: /color:\s*['"]\#10B981['"]/gi, replacement: 'color: "var(--electric-blue)"' },
  { regex: /color:\s*['"]\#F59E0B['"]/gi, replacement: 'color: "var(--illus-gold)"' },
  { regex: /color:\s*['"]\#F43F5E['"]/gi, replacement: 'color: "var(--deep-violet)"' },
  { regex: /color:\s*['"]\#06B6D4['"]/gi, replacement: 'color: "var(--primary-purple)"' },
  { regex: /color:\s*['"]\#3B82F6['"]/gi, replacement: 'color: "var(--primary-purple)"' },

  // Linear gradients
  { regex: /from-\[\#6C3DFF\]/gi, replacement: 'from-primary-purple' },
  { regex: /to-\[\#3B82F6\]/gi, replacement: 'to-deep-violet' },
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
  if (!fs.existsSync(dir)) return;
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

console.log('Starting secondary theme sweep...');
DIRECTORIES_TO_SCAN.forEach((dir) => traverseDirectory(dir));
console.log('Secondary theme unification complete!');
