import 'package:flutter/material.dart';
import '../models/experience_model.dart';

class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final bool isSelected;
  final VoidCallback onTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(experience.imageUrl),
            fit: BoxFit.cover,
            colorFilter: isSelected
                ? null
                : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          ),
        ),
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Text(
            experience.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
