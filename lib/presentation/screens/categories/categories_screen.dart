import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';
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
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 100,
            floating: true,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Organization',
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    Text('Categories',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            sliver: Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }

                if (provider.categories.isEmpty) {
                  return SliverFillRemaining(
                      child: _buildEmptyState(secondaryTextColor));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cat = provider.categories[index];
                      return _buildCategoryCard(
                          context, cat, textColor, secondaryTextColor);
                    },
                    childCount: provider.categories.length,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          heroTag: 'categories_fab',
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoryAddScreen())),
          backgroundColor: AppTheme.primary,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.layoutGrid,
                size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text('No categories found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category cat, Color textColor,
      Color secondaryTextColor) {
    final color =
        Color(int.parse((cat.color ?? '#79D2C1').replaceFirst('#', '0xff')));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(cat.icon ?? '📁', style: const TextStyle(fontSize: 24)),
        ),
        title: Text(cat.name,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(LucideIcons.edit3,
                  size: 18, color: secondaryTextColor.withValues(alpha: 0.6)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CategoryEditScreen(category: cat))),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2,
                  size: 18, color: AppTheme.danger),
              onPressed: () => _confirmDelete(context, cat),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(cat.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
