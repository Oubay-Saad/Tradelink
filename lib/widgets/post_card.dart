import 'package:flutter/material.dart';
import 'dart:convert';


class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final num budget;
  final String authorName;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.budget,
    required this.authorName,
    required this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Builder(
                  builder: (context) {
                    final isUrl = imageUrl!.startsWith('http');
                    final isBase64 = imageUrl!.startsWith('data:image') || (!isUrl && imageUrl!.length > 50);
                    final isHtml = imageUrl!.trim().startsWith('<');

                    if (isBase64 && !isHtml && !isUrl) {
                      try {
                        String base64String = imageUrl!;
                        if (base64String.contains(',')) {
                          base64String = base64String.substring(base64String.indexOf(',') + 1);
                        }
                        base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                        
                        while (base64String.length % 4 != 0) {
                          base64String += '=';
                        }

                        final bytes = base64Decode(base64String);
                        return Image.memory(
                          bytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _errorPlaceholder(),
                        );
                      } catch (e) {
                        return _errorPlaceholder();
                      }
                    }
                    
                    if (isHtml) {
                      return _errorPlaceholder();
                    }
                    return Image.network(
                      imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _errorPlaceholder(),
                    );
                  }
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$$budget',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    MouseRegion(
                      cursor: onProfileTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onProfileTap,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                              child: const Icon(Icons.person, size: 16, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              authorName, 
                              style: TextStyle(
                                fontWeight: FontWeight.w600, 
                                fontSize: 14, 
                                color: onProfileTap != null ? Colors.grey[800] : Colors.black87
                              )
                            ),
                          ],
                        ),
                      ),
                    )
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
      height: 180,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
