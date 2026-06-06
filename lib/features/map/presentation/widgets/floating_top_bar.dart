import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingTopBar extends StatelessWidget {
  const FloatingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white70),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Search territories...',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(label: 'All', isSelected: true),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Mine', isSelected: false),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Friends', isSelected: false),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Uncaptured', isSelected: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterPill({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF00E676).withOpacity(0.2) 
                : const Color(0xFF1C1C1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E676) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
