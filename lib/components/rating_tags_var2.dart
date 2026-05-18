import 'package:flutter/material.dart';
import 'package:food_run/components/rating_tag_button.dart';

// Теги для низкой оценки (1–2 звезды)
class RatingTagsVar2 extends StatelessWidget {
  const RatingTagsVar2({
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
                label: 'Долгое ожидание',
                isSelected: activeTags.contains('Долгое ожидание'),
                onTap: () => onToggleTag('Долгое ожидание'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Холодная еда',
                isSelected: activeTags.contains('Холодная еда'),
                onTap: () => onToggleTag('Холодная еда'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Маленькие порции',
                isSelected: activeTags.contains('Маленькие порции'),
                onTap: () => onToggleTag('Маленькие порции'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Грубый персонал',
                isSelected: activeTags.contains('Грубый персонал'),
                onTap: () => onToggleTag('Грубый персонал'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Шумно',
                isSelected: activeTags.contains('Шумно'),
                onTap: () => onToggleTag('Шумно'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Дорого',
                isSelected: activeTags.contains('Дорого'),
                onTap: () => onToggleTag('Дорого'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
