import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.settings,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          
          // Theme Section
          _SettingRow(
            label: "Dark Mode",
            icon: Icons.dark_mode_rounded,
            trailing: Switch.adaptive(
              value: settings.themeMode == ThemeMode.dark,
              activeColor: AppColors.orange,
              onChanged: (val) => settings.toggleTheme(val),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Language Section
          Text(
            "Language",
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LangChip(
                label: "English",
                isSelected: settings.locale.languageCode == 'en',
                onTap: () => settings.setLocale(const Locale('en')),
              ),
              const SizedBox(width: 12),
              _LangChip(
                label: "Français",
                isSelected: settings.locale.languageCode == 'fr',
                onTap: () => settings.setLocale(const Locale('fr')),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget trailing;

  const _SettingRow({
    required this.label,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.orange : (isDark ? Colors.white24 : Colors.black.withOpacity(0.1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.dark : (isDark ? Colors.white70 : AppColors.dark),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
