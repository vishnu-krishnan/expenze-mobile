import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wish_provider.dart';
import '../../../data/models/wish.dart';
import '../../widgets/liquid_glass_fab.dart';

class WishesScreen extends StatefulWidget {
  const WishesScreen({super.key});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

Future<bool?> _showDeleteConfirmation(BuildContext context, String itemName) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final textColor = AppTheme.getTextColor(context);
      final secondaryTextColor =
          AppTheme.getTextColor(context, isSecondary: true);
      return AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete \'$itemName\'?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this? This action cannot be undone.',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

class _WishesScreenState extends State<WishesScreen> {
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishProvider>().loadWishes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

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
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              shrinkWrap: true,
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Wishlist',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1)),
                          Text(
                            'Treat your future self.',
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
                if (context.watch<WishProvider>().isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Consumer<WishProvider>(
                builder: (context, provider, child) {
                  if (provider.wishes.isEmpty && !provider.isLoading) {
                    return _buildEmptyState(secondaryTextColor);
                  }

                  final wishes = provider.wishes;
                  double totalRemaining = wishes.fold(
                      0.0,
                      (sum, w) =>
                          sum + (w.isCompleted ? 0 : (w.amount - w.savedAmount)));

                  return NotificationListener<ScrollNotification>(
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
                          } else if (notification.scrollDelta! < -5 &&
                              !_isFabVisible) {
                            setState(() => _isFabVisible = true);
                          }
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 8),
                                child: Row(children: [
                                  Text('Remaining to save:',
                                      style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text('₹${totalRemaining.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18)),
                                ]))),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 10),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final wish = wishes[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                      milliseconds:
                                          400 + (index * 100).clamp(0, 600)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildWishCard(wish, textColor,
                                      secondaryTextColor, context),
                                );
                              },
                              childCount: wishes.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  );
                },
              ),
            ),
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
              heroTag: 'wishes_fab',
              onPressed: () => _showWishDialog(context),
              icon: LucideIcons.plus,
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
              color: AppTheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.gift,
                size: 64, color: AppTheme.primary.withAlpha(50)),
          ),
          const SizedBox(height: 24),
          Text('Your wishlist is empty!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
          const SizedBox(height: 8),
          Text("Dream big! Add items you'd love to treat yourself to later.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: secondaryTextColor.withAlpha(128))),
        ],
      ),
    );
  }

  Widget _buildWishCard(Wish wish, Color textColor, Color secondaryTextColor,
      BuildContext context) {
    final progress = (wish.savedAmount / wish.amount).clamp(0.0, 1.0);

    Color priorityColor;
    switch (wish.priority.toUpperCase()) {
      case 'HIGH':
        priorityColor = AppTheme.danger;
        break;
      case 'LOW':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = AppTheme.warning;
    }

    return Dismissible(
      key: Key(wish.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(25),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: AppTheme.danger),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, wish.name);
      },
      onDismissed: (_) {
        context.read<WishProvider>().deleteWish(wish.id!);
      },
      child: GestureDetector(
        onTap: () => _showWishDialog(context, wish: wish),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
                color: wish.isCompleted
                    ? AppTheme.success.withAlpha(50)
                    : Colors.transparent,
                width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<WishProvider>().toggleWishStatus(wish);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(
                        wish.isCompleted
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        size: 20,
                        color: wish.isCompleted
                            ? AppTheme.success
                            : secondaryTextColor.withAlpha(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wish.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.3,
                            decoration: wish.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            wish.priority.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: priorityColor,
                                letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${wish.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textColor),
                      ),
                      if (wish.savedAmount > 0 && !wish.isCompleted)
                        Text(
                          '₹${wish.savedAmount.toStringAsFixed(0)} saved',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
              if (!wish.isCompleted) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: secondaryTextColor.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppTheme.success : AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ],
              if (wish.sourceLink != null && wish.sourceLink!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.link,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        wish.sourceLink!,
                        style: TextStyle(fontSize: 12, color: AppTheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (wish.notes != null && wish.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  wish.notes!,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showWishDialog(BuildContext context, {Wish? wish}) {
    final nameController = TextEditingController(text: wish?.name);
    final amountController = TextEditingController(
        text: wish != null ? wish.amount.toStringAsFixed(0) : '');
    final sourceLinkController = TextEditingController(text: wish?.sourceLink);
    final notesController = TextEditingController(text: wish?.notes);
    final savedController = TextEditingController(
        text: wish != null ? wish.savedAmount.toStringAsFixed(0) : '0');
    bool isCompleted = wish?.isCompleted ?? false;
    String priority = wish?.priority ?? 'MEDIUM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final modalBgColor = isDark ? AppTheme.bgCardDark : Colors.white;
          final textColor = AppTheme.getTextColor(context);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              top: 32,
              left: 32,
              right: 32,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(wish == null ? 'New Wish' : 'Edit Wish',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.8)),
                      if (wish != null)
                        Row(
                          children: [
                            Text(isCompleted ? 'Got it! 🎉' : 'Pending',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? AppTheme.success
                                        : AppTheme.danger,
                                    fontWeight: FontWeight.bold)),
                            Switch(
                              value: isCompleted,
                              activeColor: AppTheme.success,
                              onChanged: (val) {
                                setModalState(() {
                                  isCompleted = val;
                                });
                              },
                            )
                          ],
                        )
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Wish Name',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'e.g. Sony WH-1000XM5', LucideIcons.gift,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Amount (₹)',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: AppTheme.inputDecoration(
                                  'Price', LucideIcons.indianRupee,
                                  context: context),
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saved (₹)',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: savedController,
                              keyboardType: TextInputType.number,
                              decoration: AppTheme.inputDecoration(
                                  'Progress', LucideIcons.piggyBank,
                                  context: context),
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Priority',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['LOW', 'MEDIUM', 'HIGH'].map((p) {
                      final isSelected = priority == p;
                      Color pColor = p == 'HIGH'
                          ? AppTheme.danger
                          : (p == 'LOW' ? Colors.blue : AppTheme.warning);
                      return GestureDetector(
                        onTap: () => setModalState(() => priority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? pColor : pColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    isSelected ? pColor : pColor.withAlpha(50)),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSelected ? Colors.white : pColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Source/Link (Optional)',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sourceLinkController,
                    decoration: AppTheme.inputDecoration(
                        'e.g. https://amazon.in/...', LucideIcons.link,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  Text('Notes (Optional)',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: AppTheme.inputDecoration(
                        'Any specific details?', LucideIcons.type,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            amountController.text.isEmpty) {
                          return;
                        }

                        final amount =
                            double.tryParse(amountController.text) ?? 0.0;
                        final saved =
                            double.tryParse(savedController.text) ?? 0.0;

                        final newWish = Wish(
                          id: wish?.id,
                          name: nameController.text,
                          amount: amount,
                          sourceLink: sourceLinkController.text,
                          notes: notesController.text,
                          isCompleted: isCompleted,
                          priority: priority,
                          savedAmount: saved,
                          createdAt: wish?.createdAt,
                        );

                        if (wish == null) {
                          await context.read<WishProvider>().addWish(newWish);
                        } else {
                          await context
                              .read<WishProvider>()
                              .updateWish(newWish);
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      style: AppTheme.primaryButtonStyle,
                      child: Text(wish == null ? 'Save Wish' : 'Update Wish',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
