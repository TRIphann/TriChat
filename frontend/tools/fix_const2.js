// Fix all "const AppColors.xxx" -> "AppColors.xxx" since legacy aliases are not const.
const fs = require('fs');
const path = require('path');

function walk(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(fullPath, files);
    else if (entry.isFile() && entry.name.endsWith('.dart')) files.push(fullPath);
  }
  return files;
}

const files = walk(process.argv[2] || '.');

let updated = 0;
for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  const orig = content;

  // Skip app_colors.dart itself (it has internal aliases that resolve correctly when used by class name)
  if (file.endsWith('app_colors.dart')) {
    // But other files might also reference AppColors via const, fix only external references
  }

  // 1. Replace `const AppColors.ANY` (when used directly as a value) - removes const prefix
  const r1 = /\bconst\s+AppColors\.([a-zA-Z_][a-zA-Z0-9_]*)/g;
  content = content.replace(r1, 'AppColors.$1');

  // 2. Replace `const List<Color>([Color(X), ...])` and `const <Type>(...)` patterns
  //    where the const is required because all values are compile-time consts.
  //    Specifically: drop const that is positioned right before any constructor that
  //    uses AppColors.alias as argument.
  // For this, find lines beginning with `const ` and remove if the line references AppColors.X
  // when X is a legacy alias and the only const-compelling thing was the alias value.

  // Already done in pass 1, but this may leave behind "const SomeConstructor(...AppColors.alias)"
  // The regex `const\s+AppColors\.xxx` doesn't catch "const Type(...AppColors.xxx)".
  // Let's do a multi-line regex.
  // This will match `const IDENT(` and skip until matching `)` and only remove `const` if
  // it contains AppColors.SOMETHING (which may be legacy alias).
  // For safety, only remove if AppColors.alias is present in the call.

  // Simpler: replace `const X(...AppColors.` with `X(...AppColors.`
  // The regex with [^()]* doesn't allow nested parens, but we use a heuristic.
  // We match `const ` immediately followed by an identifier and '(' and (in the args) AppColors.legacy
  const aliasRe = /\bconst\s+([A-Z][A-Za-z0-9_<>]*)\s*\((?:[^()]|\([^()]*\))*\)/g;
  content = content.replace(aliasRe, (match) => {
    if (!/AppColors\./.test(match)) return match;
    return match.replace(/^(\s*)\bconst\s+/, '$1');
  });

  if (content !== orig) {
    fs.writeFileSync(file, content, 'utf8');
    updated++;
    console.log('Updated:', file);
  }
}

console.log('Total files updated:', updated);
