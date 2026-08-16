const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const allDeps = {...(pkg.dependencies || {}), ...(pkg.devDependencies || {})};
const bannedPrefixes = ['expo', '@expo/'];
const bannedDeps = Object.keys(allDeps).filter(name => bannedPrefixes.some(p => name === p || name.startsWith(p)) || name === 'expo-router');
if (bannedDeps.length) throw new Error(`Expo/EAS dependencies are forbidden: ${bannedDeps.join(', ')}`);

for (const rel of ['.eas', '.expo', 'eas.json', 'expo-env.d.ts']) {
  if (fs.existsSync(path.join(root, rel))) throw new Error(`Expo/EAS relic still exists: ${rel}`);
}
for (const rel of ['App.tsx','index.js','ios/AutoSaleUmar.xcodeproj/project.pbxproj','ios/AutoSaleUmar/AppDelegate.swift','ios/Podfile']) {
  if (!fs.existsSync(path.join(root, rel))) throw new Error(`Required file missing: ${rel}`);
}
const workflows = path.join(root, '.github', 'workflows');
if (fs.existsSync(workflows)) {
  for (const file of fs.readdirSync(workflows)) {
    const text = fs.readFileSync(path.join(workflows, file), 'utf8').toLowerCase();
    if (text.includes('eas-cli') || text.includes('expo export') || text.includes('expo start')) {
      throw new Error(`Expo command found in workflow ${file}`);
    }
  }
}
const pbx = fs.readFileSync(path.join(root, 'ios/AutoSaleUmar.xcodeproj/project.pbxproj'), 'utf8');
if (!pbx.includes('PRODUCT_BUNDLE_IDENTIFIER = com.autosaleumar.app;')) throw new Error('Bundle identifier mismatch in Xcode project');
if (pbx.includes('HelloWorld')) throw new Error('Unrenamed HelloWorld reference in Xcode project');
console.log('repo-check: OK — bare React Native, no Expo/EAS relics.');
