import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/category_provider.dart';
import '../../../core/constants/emoji_constants.dart';

class CategoryAddScreen extends StatefulWidget {
  const CategoryAddScreen({super.key});

  @override
  State<CategoryAddScreen> createState() => _CategoryAddScreenState();
}

class _CategoryAddScreenState extends State<CategoryAddScreen> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();

  final List<Map<String, dynamic>> _quickAddCategories = [
    {'name': 'Rent', 'emoji': '🏠'},
    {'name': 'Groceries', 'emoji': '🛒'},
    {'name': 'Food & Dining', 'emoji': '🍕'},
    {'name': 'Transportation', 'emoji': '🚗'},
    {'name': 'Bills & Utilities', 'emoji': '💡'},
    {'name': 'Healthcare', 'emoji': '🏥'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Shopping', 'emoji': '🛍️'},
    {'name': 'Investment', 'emoji': '📈'},
    {'name': 'Gifts', 'emoji': '🎁'},
    {'name': 'Subscriptions', 'emoji': '📺'},
    {'name': 'Education', 'emoji': '📚'},
    {'name': 'Fitness', 'emoji': '💪'},
    {'name': 'Travel', 'emoji': '✈️'},
    {'name': 'Recharge', 'emoji': '📱'},
    {'name': 'Petrol/Fuel', 'emoji': '⛽'},
    {'name': 'Loan', 'emoji': '📜'},
    {'name': 'EMI', 'emoji': '💳'},
    {'name': 'Others', 'emoji': '📦'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('New Squad Member',
                  style: TextStyle(color: AppTheme.getTextColor(context))),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'The Usual Suspects',
                            'Pick from our common categories'),
                        const SizedBox(height: 16),
                        _buildQuickAddGrid(provider),
                        const SizedBox(height: 40),
                        _buildSectionHeader(context, 'Custom Personality',
                            'Give this category a unique name & icon'),
                        const SizedBox(height: 16),
                        _buildCustomForm(provider, isDark),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context))),
        Text(subtitle,
            style: TextStyle(
                color: AppTheme.getTextColor(context, isSecondary: true),
                fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickAddGrid(CategoryProvider provider) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _quickAddCategories.map((cat) {
        final exists = provider.categories
            .any((c) => c.name.toLowerCase() == cat['name'].toLowerCase());

        return GestureDetector(
          onTap: exists
              ? null
              : () async {
                  await provider.addCategory(cat['name'], cat['emoji']);
                  if (mounted) Navigator.pop(context);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: exists
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: exists
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: exists ? [] : AppTheme.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat['emoji'], style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  cat['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: exists
                        ? AppTheme.getTextColor(context, isSecondary: true)
                        : AppTheme.getTextColor(context),
                  ),
                ),
                if (exists) ...[
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.check,
                      size: 14, color: AppTheme.success),
                ]
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomForm(CategoryProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: AppTheme.inputDecoration(
                'Category Name', LucideIcons.tag,
                context: context),
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
          const SizedBox(height: 20),
          Text('Select an Icon',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.getTextColor(context))),
          const SizedBox(height: 12),
          DefaultTabController(
            length: EmojiConstants.categorizedEmojis.length,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgSecondaryDark : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: (isDark ? AppTheme.borderDark : AppTheme.border)
                        .withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: (isDark
                                      ? AppTheme.borderDark
                                      : AppTheme.border)
                                  .withValues(alpha: 0.2))),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tabAlignment: TabAlignment.start,
                      tabs: EmojiConstants.categorizedEmojis.keys.map((cat) {
                        return Tab(
                          icon: Icon(
                            EmojiConstants.categoryIcons[cat] ??
                                LucideIcons.helpCircle,
                            size: 18,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children:
                          EmojiConstants.categorizedEmojis.values.map((emojis) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index];
                            final isSelected = _iconController.text == emoji;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _iconController.text = emoji),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : (isDark
                                          ? AppTheme.bgPrimaryDark
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                ),
                                child:
                                    Text(emoji, style: TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) return;
              await provider.addCategory(
                  _nameController.text, _iconController.text);
              if (mounted) Navigator.pop(context);
            },
            style: AppTheme.primaryButtonStyle.copyWith(
              minimumSize:
                  WidgetStateProperty.all(const Size(double.infinity, 54)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              backgroundColor: WidgetStateProperty.all(AppTheme.primary),
            ),
            child: Text('Bring it to life',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
