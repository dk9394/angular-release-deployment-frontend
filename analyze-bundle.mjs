#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Read stats.json
const statsPath = path.join(__dirname, 'dist/angular-release-deployment-frontend/stats.json');

if (!fs.existsSync(statsPath)) {
  console.error('❌ stats.json not found. Run: ng build --stats-json');
  process.exit(1);
}

const stats = JSON.parse(fs.readFileSync(statsPath, 'utf8'));

console.log('\n📦 Bundle Analysis Report\n');
console.log('='.repeat(80));

// Analyze inputs by package
const packageSizes = {};
const totalSize = { bytes: 0 };

for (const [filePath, fileInfo] of Object.entries(stats.inputs)) {
  const bytes = fileInfo.bytes;
  totalSize.bytes += bytes;

  // Extract package name
  let packageName = 'Your App';
  if (filePath.startsWith('node_modules/')) {
    const parts = filePath.split('/');
    packageName = parts[1].startsWith('@') ? `${parts[1]}/${parts[2]}` : parts[1];
  }

  if (!packageSizes[packageName]) {
    packageSizes[packageName] = 0;
  }
  packageSizes[packageName] += bytes;
}

// Sort by size
const sortedPackages = Object.entries(packageSizes)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 20); // Top 20

// Format bytes
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
}

// Display results
console.log(`\n📊 Total Bundle Size (uncompressed): ${formatBytes(totalSize.bytes)}\n`);
console.log('Top Dependencies by Size:\n');

const maxNameLength = Math.max(...sortedPackages.map(([name]) => name.length));

sortedPackages.forEach(([name, size], index) => {
  const percentage = ((size / totalSize.bytes) * 100).toFixed(1);
  const bar = '█'.repeat(Math.round(percentage / 2));
  const paddedName = name.padEnd(maxNameLength);

  console.log(
    `${(index + 1).toString().padStart(2)}. ${paddedName}  ${formatBytes(size).padStart(10)}  ${percentage.padStart(5)}%  ${bar}`
  );
});

console.log('\n' + '='.repeat(80));
console.log('\n💡 Analysis Tips:\n');
console.log('  • Look for unexpectedly large packages');
console.log('  • Consider lazy loading for large features');
console.log('  • Use tree-shakeable imports (import { x } from "lib")');
console.log('  • Check for duplicate dependencies\n');

// Check against budget
const budgetKB = 512;
const actualKB = totalSize.bytes / 1024;

console.log('📋 Performance Budget Check:\n');
console.log(`  Budget:  ${budgetKB} KB`);
console.log(`  Actual:  ${actualKB.toFixed(2)} KB`);
console.log(`  Status:  ${actualKB <= budgetKB ? '✅ PASS' : '❌ FAIL'}`);
console.log(`  Margin:  ${(budgetKB - actualKB).toFixed(2)} KB ${actualKB <= budgetKB ? 'remaining' : 'over budget'}\n`);

console.log('='.repeat(80) + '\n');
