import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';
import '../../../data/models/category.dart';
import 'category_add_screen.dart';
import 'category_edit_screen.dart';
import '../../widgets/liquid_glass_fab.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: isDark
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels <= 10) {
                if (!_isFabVisible) {
                  setState(() => _isFabVisible = true);
                }
                return false;
              }
              if (notification.scrollDelta != null) {
                if (notification.scrollDelta! > 5 && _isFabVisible) {
                  setState(() => _isFabVisible = false);
                } else if (notification.scrollDelta! < -5 && !_isFabVisible) {
                  setState(() => _isFabVisible = true);
                }
              }
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                systemOverlayStyle: AppTheme.headerOverlayStyle,
                automaticallyImplyLeading: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 110,
                collapsedHeight: 110,
                toolbarHeight: 110,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  background: Container(
                    decoration: AppTheme.headerDecoration(context),
                    padding: EdgeInsets.fromLTRB(
                        26, MediaQuery.of(context).padding.top + 10, 26, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Categories',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1)),
                        const Text(
                          'Your expense toolkit',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final cat = provider.categories[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 350 + (index * 60)),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCategoryCard(
                                context, cat, textColor, secondaryTextColor),
                          );
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
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 110),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isFabVisible ? 1.0 : 0.0,
            child: LiquidGlassFAB(
              heroTag: 'categories_fab',
              onPressed: () => CategoryAddScreen.show(context),
              icon: LucideIcons.plus,
            ),
            ),
          ),
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
          Text('Where\'s the structure?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
          const SizedBox(height: 8),
          Text('Add categories to keep your money in check.',
              style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor.withAlpha(180))),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category cat, Color textColor,
      Color secondaryTextColor) {
    final color =
        Color(int.parse((cat.color ?? '#79D2C1').replaceFirst('#', '0xff')));

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CategoryEditScreen(category: cat))),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: color.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(cat.icon ?? '📁',
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: textColor,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 2,
              child: PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreVertical,
                    size: 15, color: secondaryTextColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CategoryEditScreen(category: cat)));
                  } else if (value == 'delete') {
                    _confirmDelete(context, cat);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.edit3, size: 16),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash2,
                            size: 16, color: AppTheme.danger),
                        const SizedBox(width: 12),
                        Text('Delete',
                            style: TextStyle(color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ],
              ),
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
        title: Text('Wait, really?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
            'Once "${cat.name}" is gone, it\'s gone. Still want to proceed?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(cat.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
