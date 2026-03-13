import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';
import '../../../core/constants/emoji_constants.dart';

class CategoryAddScreen extends StatefulWidget {
  const CategoryAddScreen({super.key});

  /// Call this instead of Navigator.push — shows the form as a bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CategoryProvider>(),
        child: const CategoryAddScreen(),
      ),
    );
  }

  @override
  State<CategoryAddScreen> createState() => _CategoryAddScreenState();
}

class _CategoryAddScreenState extends State<CategoryAddScreen> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarHeight = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottomInset + navBarHeight),
      child: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.layoutGrid,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppTheme.getTextColor(context),
                            )),
                        Text('Add to your expense toolkit',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getTextColor(context,
                                  isSecondary: true),
                            )),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name field
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  onChanged: (_) {
                    if (_errorText != null) setState(() => _errorText = null);
                  },
                  decoration: AppTheme.inputDecoration(
                      'Category Name', LucideIcons.tag,
                      context: context).copyWith(
                    errorText: _errorText,
                    errorStyle: const TextStyle(
                        color: AppTheme.danger, fontWeight: FontWeight.w500),
                  ),
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                ),

                const SizedBox(height: 14),

                Text('Select an Icon',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.getTextColor(context))),
                const SizedBox(height: 10),

                // Emoji picker
                DefaultTabController(
                  length: EmojiConstants.categorizedEmojis.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.bgSecondaryDark
                          : AppTheme.bgSecondary,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            tabAlignment: TabAlignment.start,
                            tabs: EmojiConstants.categorizedEmojis.keys
                                .map((cat) => Tab(
                                      icon: Icon(
                                        EmojiConstants.categoryIcons[cat] ??
                                            LucideIcons.helpCircle,
                                        size: 18,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        SizedBox(
                          height: 160,
                          child: TabBarView(
                            children: EmojiConstants.categorizedEmojis.values
                                .map((emojis) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(10),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                                itemCount: emojis.length,
                                itemBuilder: (context, index) {
                                  final emoji = emojis[index];
                                  final isSelected =
                                      _iconController.text == emoji;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _iconController.text = emoji),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                                .withValues(alpha: 0.1)
                                            : (isDark
                                                ? AppTheme.bgPrimaryDark
                                                : Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(emoji,
                                          style:
                                              const TextStyle(fontSize: 20)),
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

                const SizedBox(height: 16),

                // Save button
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() => _errorText = 'Please enter a category name');
                      return;
                    }
                    final success = await provider.addCategory(
                        name, _iconController.text);
                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      setState(() =>
                          _errorText = '"$name" already exists. Try a different name.');
                    }
                  },
                  style: AppTheme.primaryButtonStyle.copyWith(
                    minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 54)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    backgroundColor:
                        WidgetStateProperty.all(AppTheme.primary),
                  ),
                  child: const Text('Create Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
