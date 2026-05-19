import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final num budget;
  final String authorName;
  final String? location;
  final List<String> jobTypes;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.budget,
    required this.authorName,
    this.location,
    required this.jobTypes,
    required this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image (4:3) ──
              if (imageUrl != null && imageUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Builder(
                    builder: (context) {
                      final isUrl = imageUrl!.startsWith('http');
                      final isBase64 = imageUrl!.startsWith('data:image') || (!isUrl && imageUrl!.length > 50);
                      final isHtml = imageUrl!.trim().startsWith('<');

                      if (isBase64 && !isHtml && !isUrl) {
                        try {
                          String base64String = imageUrl!;
                          if (base64String.contains(',')) base64String = base64String.substring(base64String.indexOf(',') + 1);
                          base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                          while (base64String.length % 4 != 0) base64String += '=';
                          return Image.memory(base64Decode(base64String), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorPlaceholder());
                        } catch (e) {
                          return _errorPlaceholder();
                        }
                      }
                      if (isHtml) return _errorPlaceholder();
                      return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorPlaceholder());
                    },
                  ),
                ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text('$budget DA', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13)),
                    
                    // Location and Job Types row
                    if ((location != null && location!.isNotEmpty) || jobTypes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (location != null && location!.isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (jobTypes.isNotEmpty) const SizedBox(width: 12),
                          ],
                          if (jobTypes.isNotEmpty)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: jobTypes.map((jt) {
                                    final label = jt.substring(0, 1).toUpperCase() + jt.substring(1);
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Author
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.person_rounded, size: 14, color: AppTheme.accent),
                          ),
                          const SizedBox(width: 6),
                          Text(authorName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: AppTheme.background,
      child: const Center(child: Icon(Icons.image_not_supported_rounded, color: AppTheme.textMuted, size: 36)),
    );
  }
}
