import os
import re
import sys

# (pattern_old, pattern_new) replacements
REPLACEMENTS = [
    (r'Color\(0xFF1A1A1A\)', 'AppColors.neutralBlack'),
    (r'Color\(0xFFF0F2F5\)', 'AppColors.backgroundGray'),
    (r'Color\(0xFFF7F8FA\)', 'AppColors.neutralGray100'),
    (r'Color\(0xFFEEF0F3\)', 'AppColors.divider'),
    (r'Color\(0xFFE4E6EB\)', 'AppColors.borderGray'),
    (r'Color\(0xFF65676B\)', 'AppColors.neutralGray700'),
    (r'Color\(0xFFEEEEEE\)', 'AppColors.divider'),
    (r'Color\(0xFF999999\)', 'AppColors.textHint'),
    (r'Color\(0xFF666666\)', 'AppColors.textSecondary'),
    (r'Color\(0xFFE0E0E0\)', 'AppColors.borderGray'),
    (r'Color\(0xFFAAAAAA\)', 'AppColors.textHint'),
    (r'Color\(0xFFBBBBBB\)', 'AppColors.textHint'),
    (r'Color\(0xFF707070\)', 'AppColors.neutralGray700'),
    (r'Color\(0xFF333333\)', 'AppColors.neutralBlack'),
    (r'Color\(0xFF555555\)', 'AppColors.neutralGray700'),
    (r'Color\(0xFF606060\)', 'AppColors.neutralGray700'),
    (r'Color\(0xFF1A1A2E\)', 'AppColors.darkBackground'),
    (r'Color\(0xFF242438\)', 'AppColors.darkSurface'),
    (r'Color\(0xFF2D2D44\)', 'AppColors.darkCard'),
    (r'Color\(0xFF3A3A4D\)', 'AppColors.darkDivider'),
    # Brand colors
    (r'Color\(0xFF0068FF\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFF4A9EFF\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFF0052CC\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF005AE0\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF34C759\)', 'AppColors.successLight'),
    (r'Color\(0xFF2DA44E\)', 'AppColors.success'),
    (r'Color\(0xFF4CAF50\)', 'AppColors.success'),
    (r'Color\(0xFFFF9500\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFFF7A00\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFFFFA726\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFEA4335\)', 'AppColors.accentRed'),
    (r'Color\(0xFFE94B6E\)', 'AppColors.accentRed'),
    (r'Color\(0xFFE0294A\)', 'AppColors.accentRed'),
    (r'Color\(0xFFFF3B30\)', 'AppColors.accentRed'),
    (r'Color\(0xFFB91C1C\)', 'AppColors.accentRedDark'),
    (r'Color\(0xFFDC2626\)', 'AppColors.accentRed'),
    (r'Color\(0xFF1877F2\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFF42A5F5\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFF66BB6A\)', 'AppColors.success'),
    (r'Color\(0xFFAB47BC\)', 'AppColors.accentBrown'),
    (r'Color\(0xFFEC407A\)', 'AppColors.accentRed'),
    (r'Color\(0xFF00CC44\)', 'AppColors.successLight'),
    (r'Color\(0xFF6C63FF\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF3F3D9E\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF9C27B0\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF2196F3\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFFFF9800\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFE91E63\)', 'AppColors.accentRed'),
    (r'Color\(0xFF00BCD4\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF795548\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF607D8B\)', 'AppColors.neutralGray700'),
    (r'Color\(0xFF3F51B5\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFFBDBDBD\)', 'AppColors.neutralGray500'),
    (r'Color\(0xFF9E9E9E\)', 'AppColors.neutralGray500'),
    (r'Color\(0xFF80D8FF\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFF0072FF\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFFFBAA47\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFD91A46\)', 'AppColors.accentRed'),
    (r'Color\(0xFFA20BFF\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF00C6FF\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFA16207\)', 'AppColors.accentBrownLight'),
    (r'Color\(0xFFB45309\)', 'AppColors.accentBrown'),
    (r'Color\(0xFFD97706\)', 'AppColors.primaryOrange'),
    (r'Color\(0xFFF59E0B\)', 'AppColors.primaryOrangeLight'),
    (r'Color\(0xFFFED7AA\)', 'AppColors.primaryOrangePale'),
    (r'Color\(0xFFFFEDD5\)', 'AppColors.primaryOrangePale'),
    (r'Color\(0xFF451A03\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF78350F\)', 'AppColors.accentBrown'),
    (r'Color\(0xFF15803D\)', 'AppColors.success'),
    (r'Color\(0xFF22C55E\)', 'AppColors.successLight'),
    (r'Color\(0xFFE53935\)', 'AppColors.accentRed'),
    (r'Color\(0xFFA8A29E\)', 'AppColors.neutralGray500'),
    (r'Color\(0xFFD6D3D1\)', 'AppColors.neutralGray300'),
    (r'Color\(0xFFF5F5F4\)', 'AppColors.neutralGray100'),
    (r'Color\(0xFFFFFAF6\)', 'AppColors.neutralWhite'),
    (r'Color\(0xFF1C1917\)', 'AppColors.neutralBlack'),
    (r'Color\(0xFF292524\)', 'AppColors.neutralGray900'),
    (r'Color\(0xFF57534E\)', 'AppColors.neutralGray700'),
]

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    updated = 0
    for dirpath, dirnames, filenames in os.walk(root):
        for filename in filenames:
            if not filename.endswith('.dart'):
                continue
            filepath = os.path.join(dirpath, filename)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
            except Exception as e:
                print(f"Skip {filepath}: {e}")
                continue
            original = content
            for old, new in REPLACEMENTS:
                content = re.sub(old, new, content)
            if content != original:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated: {filepath}")
                updated += 1
    print(f"\nTotal files updated: {updated}")

if __name__ == '__main__':
    main()
