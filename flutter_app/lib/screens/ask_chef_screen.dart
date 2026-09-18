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
      final welcome = isBn
          ? "👋 নমস্কার! আমি আপনার এআই শেফ। আপনি বেছে নিয়েছেন **${activeRecipe.title}** (পরিবেশন: ${activeRecipe.servings})।\n\nআমায় যেকোনো প্রশ্ন করতে পারেন! যেমন: নিচের **'৫ জনের জন্য মাপ দিন'** বাটনে চাপ দিয়ে উপকরণের নতুন মাপ বের করতে পারেন, বিকল্প উপকরণ জানতে পারেন বা রান্নার সময় কমাতে পারেন।"
          : "👋 Hi! I'm your AI Chef. You selected **${activeRecipe.title}** (serves ${activeRecipe.servings}).\n\nAsk me anything! For example: tap **'Scale for 5 people'** to get adjusted ingredient amounts, ask for substitutions, or get air fryer steps.";

      _messages.add(
        _ChatMessage(
          isUser: false,
          recipeTitle: activeRecipe.title,
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

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final activeRecipe = appState.selectedAskRecipe;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.tr('askChefTitle'),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.tr('askChefSubtitle'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (activeRecipe != null)
                    GestureDetector(
                      onTap: () {
                        appState.setAskRecipe(null);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.close, color: AppColors.textMuted, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              appState.isBangla ? 'রেসিপি বাদ দিন' : 'Clear Recipe',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Recipe Selector Chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _recipeChip(
                    title: appState.tr('generalCooking'),
                    isSelected: activeRecipe == null,
                    onTap: () {
                      appState.setAskRecipe(null);
                      setState(() {});
                    },
                  ),
                  ...appState.allRecipes.map((r) {
                    final isSelected = activeRecipe?.id == r.id;
                    return _recipeChip(
                      title: r.title,
                      isSelected: isSelected,
                      onTap: () {
                        appState.setAskRecipe(r);
                        setState(() {});
                        _sendMessage('Tell me how you can help customize ${r.title}');
                      },
                    );
                  }),
                ],
              ),
            ),

            // 3. Active Recipe Banner (if one is selected)
            if (activeRecipe != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        activeRecipe.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.restaurant, size: 20, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeRecipe.title,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.group_outlined, size: 12, color: AppColors.primaryOrange),
                              const SizedBox(width: 4),
                              Text(
                                activeRecipe.servings,
                                style: const TextStyle(color: AppColors.primaryOrange, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                activeRecipe.cookTime,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Quick Suggested Prompts
            Container(
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Builder(
                builder: (context) {
                  final prompts = _getQuickPrompts(appState);
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: prompts.length,
                    itemBuilder: (context, index) {
                      final prompt = prompts[index];
                      return GestureDetector(
                        onTap: () => _sendMessage(prompt),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Center(
                            child: Text(
                              prompt,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(color: AppColors.borderSubtle, height: 1),

            // 5. Chat History
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
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

            // 6. Text Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: activeRecipe != null
                              ? (appState.isBangla
                                  ? '${activeRecipe.title} সম্পর্কে জিজ্ঞাসা করুন...'
                                  : 'Ask about ${activeRecipe.title}...')
                              : appState.tr('askInputHint'),
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
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

  Widget _recipeChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.borderSubtle,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
