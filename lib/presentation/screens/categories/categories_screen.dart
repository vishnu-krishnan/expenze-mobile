import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../data/models/category.dart';
import 'category_add_screen.dart';
import 'category_edit_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: themeProvider.isDarkMode
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Categories',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.categories.isEmpty) {
                    return _buildEmptyState(secondaryTextColor);
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spending Categories',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              Text(
                                'Organize your finances by category',
                                style: TextStyle(
                                    color: secondaryTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = provider.categories[index];
                              return _buildCategoryItem(
                                  context, cat, textColor, secondaryTextColor);
                            },
                            childCount: provider.categories.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryAddScreen()),
        ),
        backgroundColor: AppTheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folderOpen,
              size: 64, color: secondaryTextColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Categories Found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding some categories\nto track your expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category cat, Color textColor,
      Color secondaryTextColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CategoryEditScreen(category: cat)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cat.icon ?? '📁',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }
}
