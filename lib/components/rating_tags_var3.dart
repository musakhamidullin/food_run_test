import 'package:flutter/material.dart';
import 'package:food_run/components/rating_tag_button.dart';

// Теги для средней оценки (3 звезды)
class RatingTagsVar3 extends StatelessWidget {
  const RatingTagsVar3({
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
                label: 'Нормально',
                isSelected: activeTags.contains('Нормально'),
                onTap: () => onToggleTag('Нормально'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Можно быстрее',
                isSelected: activeTags.contains('Можно быстрее'),
                onTap: () => onToggleTag('Можно быстрее'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Порции могли быть больше',
                isSelected: activeTags.contains('Порции могли быть больше'),
                onTap: () => onToggleTag('Порции могли быть больше'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'Неплохо',
                isSelected: activeTags.contains('Неплохо'),
                onTap: () => onToggleTag('Неплохо'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RatingTagButton(
                label: 'Ожидал большего',
                isSelected: activeTags.contains('Ожидал большего'),
                onTap: () => onToggleTag('Ожидал большего'),
              ),
              const SizedBox(width: 10),
              RatingTagButton(
                label: 'В следующий раз попробую другое',
                isSelected:
                    activeTags.contains('В следующий раз попробую другое'),
                onTap: () => onToggleTag('В следующий раз попробую другое'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
