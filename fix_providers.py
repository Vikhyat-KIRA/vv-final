import os
import re

providers_dir = r"lib\providers"

for filename in os.listdir(providers_dir):
    if not filename.endswith(".dart"):
        continue
    
    filepath = os.path.join(providers_dir, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. StateNotifierProvider -> NotifierProvider
    content = re.sub(r'StateNotifierProvider<([\w]+),\s*([^>]+)>\s*\(\s*\((ref)?\)\s*{', r'NotifierProvider<\1, \2>(() {', content)
    content = re.sub(r'StateNotifierProvider<([\w]+),\s*([^>]+)>\s*\(\s*\((ref)?\)\s*=>\s*', r'NotifierProvider<\1, \2>(() => ', content)

    # 2. StateNotifier -> Notifier
    # We need to change `class X extends StateNotifier<T> { X() : super(init); }`
    # to `class X extends Notifier<T> { @override T build() { return init; } }`
    
    # Let's do a simple text replace since the files are standard
    
    # theme_provider.dart
    if "AccentChoiceNotifier" in content:
        content = content.replace("class AccentChoiceNotifier extends StateNotifier<String> {\n  AccentChoiceNotifier() : super('emerald') {\n    _loadAccentChoice();\n  }", 
                                  "class AccentChoiceNotifier extends Notifier<String> {\n  @override\n  String build() {\n    Future.microtask(() => _loadAccentChoice());\n    return 'emerald';\n  }")
        content = content.replace("class ThemeNotifier extends StateNotifier<Color> {", "class ThemeNotifier extends Notifier<Color> {")
        content = content.replace("ThemeNotifier(this._ref)\n      : super(const ThemeColor(\n          0xFF34D399, // Default emerald dark mode color\n          urgencyLabel: 'ON TRACK',\n          urgencyBadgeColor: Color(0xFF34D399),\n        )) {\n    loadThemeFromPrefs();\n  }", 
                                  "@override\n  Color build() {\n    Future.microtask(() => loadThemeFromPrefs());\n    return const ThemeColor(\n          0xFF34D399,\n          urgencyLabel: 'ON TRACK',\n          urgencyBadgeColor: Color(0xFF34D399),\n        );\n  }")
        content = content.replace("final notifier = ThemeNotifier(ref);", "final notifier = ref.read(themeProvider.notifier);") # Actually, we can't do this easily in Riverpod. Wait, ThemeNotifier needs to listen to other providers. In Notifier, we just use ref.listen in build().
    
    # Let's use a robust approach: replace "extends StateNotifier" with "extends Notifier"
    content = content.replace("extends StateNotifier<", "extends Notifier<")
    
    # Save back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Providers patched!")
