import 'package:flutter/material.dart';
import 'package:food_run/components/rating_tag_button.dart';

// Теги для высокой оценки (4–5 звёзд)
class RatingTagsVar1 extends StatelessWidget {
  const RatingTagsVar1({
    super.key,
    required this.activeTags,
    required this.onToggleTag,
  });

  final List<String> activeTags;
  final void Function(String tag) onToggleTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              RatingTagButton(
                label: 'Вкусно',
                isSelected: activeTags.contains('Вкусно'),
                onTap: () => onToggleTag('Вкусно'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Быстро',
                isSelected: activeTags.contains('Быстро'),
                onTap: () => onToggleTag('Быстро'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Чисто',
                isSelected: activeTags.contains('Чисто'),
                onTap: () => onToggleTag('Чисто'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Хорошие порции',
                isSelected: activeTags.contains('Хорошие порции'),
                onTap: () => onToggleTag('Хорошие порции'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Снова приду',
                isSelected: activeTags.contains('Снова приду'),
                onTap: () => onToggleTag('Снова приду'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Дружелюбный персонал',
                isSelected: activeTags.contains('Дружелюбный персонал'),
                onTap: () => onToggleTag('Дружелюбный персонал'),
              ),
            ],
          ),
        ],
      ),
    );
  }

// пока не нужно 14.03.2024
  // Widget _storeReviewButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 50,
  //     child: ElevatedButton(
  //       onPressed: () => _openStorePage(),
  //       child: Text('Оставить отзыв в магазине приложений'),
  //     ),
  //   );
  // }
  //
  // Future<void> _openStorePage() async { ... }
}
