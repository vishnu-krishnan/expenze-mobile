import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/category_provider.dart';
import '../../../core/constants/emoji_constants.dart';
import '../../../data/models/category.dart';

class CategoryEditScreen extends StatefulWidget {
  final Category category;
  const CategoryEditScreen({super.key, required this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _iconController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _iconController = TextEditingController(text: widget.category.icon);
  }

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
              title: Text('Edit Category',
                  style: TextStyle(color: AppTheme.getTextColor(context))),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Modify Identity',
                            'Update how this category appears'),
                        const SizedBox(height: 24),
                        _buildEditForm(provider, isDark),
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

  Widget _buildEditForm(CategoryProvider provider, bool isDark) {
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
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 22)),
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
              await provider.updateCategory(widget.category.id,
                  _nameController.text, _iconController.text);
              if (context.mounted) Navigator.pop(context);
            },
            style: AppTheme.primaryButtonStyle.copyWith(
              minimumSize:
                  WidgetStateProperty.all(const Size(double.infinity, 54)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              backgroundColor: WidgetStateProperty.all(AppTheme.primary),
            ),
            child: const Text('Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final provider = context.read<CategoryProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'Are you sure you want to delete "${widget.category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await provider.deleteCategory(widget.category.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child:
                const Text('DELETE', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
