// Step 3 (charity mode): Select Charity

import 'package:flutter/material.dart';
import '../../../models/charity_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepSelectCharity extends StatelessWidget {
  final CharityModel? selectedCharity;
  final Function(CharityModel?) onChanged;

  const StepSelectCharity({
    super.key,
    this.selectedCharity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Choose a\ncharity',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'The winner chooses where the loser\'s stake goes. Select a charity.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(CharityModel.availableCharities.length, (index) {
            final charity = CharityModel.availableCharities[index];
            final isSelected = selectedCharity?.id == charity.id;
            return SlideIn(
              delay: Duration(milliseconds: 300 + (index * 80)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onChanged(charity),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.pink.withOpacity(0.08)
                          : context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.pink.withOpacity(0.15)
                                : Colors.pink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            charity.icon,
                            size: 24,
                            color: isSelected
                                ? Colors.pink[600]
                                : context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                charity.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.pink[600] : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                charity.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.textSecondary,
                                      height: 1.3,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Colors.pink[600], size: 24)
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              charity.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.pink[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
