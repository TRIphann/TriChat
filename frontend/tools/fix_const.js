// Fix `const AppColors.xxx` -> `AppColors.xxx` for legacy alias fields
// (which are not const because they reference other const fields)
const fs = require('fs');
const path = require('path');

const LEGACY_ALIASES = [
  'primaryBlue', 'lightBlue', 'darkBlue',
  'backgroundWhite', 'backgroundGray',
  'textPrimary', 'textSecondary', 'textHint', 'textWhite', 'textBlue',
  'borderGray', 'divider',
  'callRed', 'callGreen', 'callBackground', 'whiteOpacity',
  'sidebarDark', 'sidebarLight',
];

function walk(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(fullPath, files);
    else if (entry.isFile() && entry.name.endsWith('.dart')) files.push(fullPath);
  }
  return files;
}

const files = walk(process.argv[2] || '.');

// Match patterns like:
//   const Color(AppColors.xxx ...)
//   const BorderSide(color: AppColors.xxx)
//   const AppBarTheme(backgroundColor: AppColors.xxx, ...)
//
// Replace `const ` followed by any constructor name with the same args using AppColors.alias
// We simply replace `const (... AppColors.legacyAlias ...)` with `(...)` — if the only
// const requirement comes from alias usage.
//
// Simpler: replace `const AppColors.alias` patterns and `const Something(...AppColors.alias...)` patterns.

let updated = 0;
for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  const orig = content;

  // Build regex for each legacy alias
  for (const alias of LEGACY_ALIASES) {
    // 1. Replace `const AppColors.alias` -> `AppColors.alias`
    const r1 = new RegExp(`const(\\s+)AppColors\\.${alias}\\b`, 'g');
    content = content.replace(r1, 'AppColors.' + alias);

    // 2. Replace `const SOMETHING(...AppColors.alias...)` where the leading const is needed only for the alias
    //    We do this by finding `const IDENT(` then scanning until closing paren,
    //    and if the inside uses an alias, we drop the const.
    //    To keep it simple, we match patterns like: const SOMETHING(...AppColors.alias...)
    //    and remove the const.
    const r2 = new RegExp(`(\\bconst\\s+[A-Za-z_][A-Za-z0-9_]*\\s*\\([^;]*?AppColors\\.${alias}[^;]*?\\))`, 'g');
    // This regex is risky - skip this step (we'll handle via flutter analyze errors)
  }

  // ALSO: drop leading `const ` for constructors whose all args are AppColors.xxx (legacy aliases)
  // Match `const Constructor(...)` where ... contains AppColors.alias
  // Note: we use a simple approach - find constructor calls starting with const and containing AppColors.alias
  const r3 = /\bconst\s+([A-Z][A-Za-z0-9_]*)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)/g;

  // Actually, the Dart analyzer will tell us exactly which lines are invalid.
  // Better: regex-wise, find any `const KW(` preceded by AppColors.legacyAlias inside,
  // and remove the leading `const`. The constraints:
  // - Doesn't span across multiple statements
  // - Has balanced parens
  // For simplicity: just replace specific known patterns.

  // Pattern: `const BoxDecoration(` ... `color: AppColors.alias`
  // Pattern: `const TextStyle(` ... `color: AppColors.alias`
  // Pattern: `const ColorScheme(` -> already handled by app_theme.dart
  // We just need to remove the `const` when AppColors.alias is in the args

  // Approach: scan line-by-line. For each line starting with `const ` and containing AppColors.legacy,
  // remove the leading `const ` from that line IF the line appears inside parens (i.e. is an arg list).
  // We'll only handle lines like:
  //   const InputDecoration(... color: AppColors.alias, ...),
  //   const BorderSide(color: AppColors.alias),
  //   const SnackBarThemeData(contentTextStyle: TextStyle(color: AppColors.alias)),
  //
  // Heuristic: replace leading `const ` before factory constructors when a legacy alias is referenced.
  // We keep `const Text(...)` but remove `const` from other constructors.
  // This is fragile; better to just remove const in front of any constructor with AppColors.legacy.

  // Match: const Identifier( ...AppColors.legacyAlias... )
  const aliasPattern = LEGACY_ALIASES.map(a => `AppColors\\.${a}`).join('|');
  const reConstWithAlias = new RegExp(
    `\\b(const)\\s+([A-Z][A-Za-z0-9_]*)\\s*\\([^)]*(?:${aliasPattern})[^)]*\\)`,
    'g'
  );
  content = content.replace(reConstWithAlias, (match, kconst, klass, offset, full) => {
    // Only replace the captured `const ` with empty.
    // The match starts at `const ` - we want to remove it.
    return match.replace(/^(\s*)\bconst\s+/, '$1');
  });

  if (content !== orig) {
    fs.writeFileSync(file, content, 'utf8');
    updated++;
    console.log('Updated:', file);
  }
}

console.log('Total files updated:', updated);
