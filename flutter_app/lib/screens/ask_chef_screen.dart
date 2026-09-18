import 'package:flutter/material.dart';
import '../services/gemini_recipe_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AskChefScreen extends StatefulWidget {
  final AppState appState;

  const AskChefScreen({super.key, required this.appState});

  @override
  State<AskChefScreen> createState() => _AskChefScreenState();
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? recipeTitle;
  final DateTime time;

  _ChatMessage({
    required this.isUser,
    required this.text,
    this.recipeTitle,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _AskChefScreenState extends State<AskChefScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;

  List<String> _getQuickPrompts(AppState appState) => [
    appState.tr('chipScale5'),
    appState.tr('chipScale2'),
    appState.tr('chipSwap'),
    appState.tr('chipAirFryer'),
    appState.tr('chipFaster'),
    appState.tr('chipHealthy'),
  ];

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    final activeRecipe = widget.appState.selectedAskRecipe;
    final isBn = widget.appState.isBangla;
    if (activeRecipe != null) {
      final title = activeRecipe.getTitle(isBn);
      final welcome = isBn
          ? "👋 নমস্কার! আমি আপনার এআই শেফ। আপনি বেছে নিয়েছেন **$title** (পরিবেশন: ${activeRecipe.servings})।\n\nআমায় যেকোনো প্রশ্ন করতে পারেন! যেমন: নিচের **'৫ জনের জন্য মাপ দিন'** বাটনে চাপ দিয়ে উপকরণের নতুন মাপ বের করতে পারেন, বিকল্প উপকরণ জানতে পারেন বা রান্নার সময় কমাতে পারেন।"
          : "👋 Hi! I'm your AI Chef. You selected **$title** (serves ${activeRecipe.servings}).\n\nAsk me anything! For example: tap **'Scale for 5 people'** to get adjusted ingredient amounts, ask for substitutions, or get air fryer steps.";

      _messages.add(
        _ChatMessage(
          isUser: false,
          recipeTitle: title,
          text: welcome,
        ),
      );
    } else {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: widget.appState.tr('initialChefGreeting'),
        ),
      );
    }
  }

  Future<void> _sendMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isThinking) return;

    final activeRecipe = widget.appState.selectedAskRecipe;
    final appState = widget.appState;

    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: text,
        recipeTitle: activeRecipe?.title,
      ));
      _isThinking = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      final answer = await GeminiRecipeService.askChef(
        recipe: activeRecipe,
        question: text,
        language: appState.language,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage(
          isUser: false,
          text: answer,
          recipeTitle: activeRecipe?.title,
        ));
        _isThinking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          isUser: false,
          text: appState.isBangla
              ? "⚠️ দুঃখিত, এই মুহূর্তে উত্তর দেওয়া সম্ভব হচ্ছে না। অনুগ্রহ করে আবার চেষ্টা করুন!"
              : "⚠️ Sorry, I couldn't process that right now. Please try asking again!",
        ));
        _isThinking = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _showRecipeSelectorSheet(BuildContext context) {
    final appState = widget.appState;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appState.tr('selectRecipe'),
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, color: AppColors.primaryOrange, size: 18),
                  ),
                  title: Text(
                    appState.tr('generalCooking'),
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    appState.setAskRecipe(null);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                ),
                ...appState.allRecipes.map((r) {
                  final isSelected = appState.selectedAskRecipe?.id == r.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        r.imageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 36, height: 36, color: AppColors.surfaceElevated),
                      ),
                    ),
                    title: Text(
                      r.getTitle(appState.isBangla),
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryOrange : AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${r.servings} • ${r.cookTime}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryOrange, size: 20) : null,
                    onTap: () {
                      appState.setAskRecipe(r);
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final activeRecipe = appState.selectedAskRecipe;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Compact Top Bar (Maximizing text space)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    appState.tr('askChefTitle'),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Active Recipe Selector / Switcher Pill
                  GestureDetector(
                    onTap: () => _showRecipeSelectorSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: activeRecipe != null
                            ? AppColors.primaryOrange.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: activeRecipe != null
                              ? AppColors.primaryOrange.withValues(alpha: 0.5)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeRecipe != null ? Icons.restaurant_menu : Icons.tune,
                            size: 13,
                            color: activeRecipe != null ? AppColors.primaryOrange : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              activeRecipe != null
                                  ? activeRecipe.getTitle(appState.isBangla)
                                  : appState.tr('selectRecipe'),
                              style: TextStyle(
                                color: activeRecipe != null ? AppColors.primaryOrange : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: activeRecipe != null ? AppColors.primaryOrange : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (activeRecipe != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        appState.setAskRecipe(null);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(Icons.close, color: AppColors.textMuted, size: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: AppColors.borderSubtle, height: 1),

            // 2. Chat History (Full Expanded Height)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Loading indicator
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            appState.tr('chefThinking'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Compact Suggested Prompts (Docked above input)
            Container(
              height: 34,
              margin: const EdgeInsets.only(bottom: 6),
              child: Builder(
                builder: (context) {
                  final prompts = _getQuickPrompts(appState);
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: prompts.length,
                    itemBuilder: (context, index) {
                      final prompt = prompts[index];
                      return GestureDetector(
                        onTap: () => _sendMessage(prompt),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Center(
                            child: Text(
                              prompt,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 4. Centered Clean Text Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: TextField(
                        controller: _inputController,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: appState.tr('askInputHint'),
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_upward, color: Colors.white, size: 22),
                      ),
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

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 14),
                SizedBox(width: 6),
                Text(
                  'Chef Gemini',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
