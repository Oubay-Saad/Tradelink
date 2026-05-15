import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ImageUtils {
  static String _cleanBase64(String b64) {
    String result = b64;
    if (result.contains(',')) result = result.substring(result.indexOf(',') + 1);
    result = result.trim().replaceAll(RegExp(r'\s+'), '');
    while (result.length % 4 != 0) result += '=';
    return result;
  }

  static String _fixUrl(String url) {
    if (url.startsWith('http://localhost:3000')) {
      return url.replaceFirst('http://localhost:3000', kBaseUrl);
    }
    return url;
  }

  static ImageProvider getImageProvider(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    String src = _fixUrl(imageSource);

    // Handle relative paths from server
    if (src.startsWith('/') || src.startsWith('uploads')) {
      final path = src.startsWith('/') ? src : '/$src';
      return NetworkImage('$kBaseUrl$path');
    }

    final isUrl = src.startsWith('http');
    final isBase64 = src.startsWith('data:image') || (!isUrl && src.length > 100);

    if (isBase64 && !isUrl) {
      try {
        return MemoryImage(base64Decode(_cleanBase64(src)));
      } catch (e) {
        return const AssetImage('assets/placeholder.png');
      }
    }

    return NetworkImage(src);
  }

  static Widget buildCircleAvatar({required String? imageUrl, double radius = 24, IconData fallbackIcon = Icons.person}) {
    final double diameter = radius * 2;
    
    Widget fallback = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(fallbackIcon, size: radius, color: Colors.grey),
    );

    if (imageUrl == null || imageUrl.isEmpty) return fallback;

    String url = _fixUrl(imageUrl);

    // Handle relative paths
    if (url.startsWith('/') || url.startsWith('uploads')) {
      final path = url.startsWith('/') ? url : '/$url';
      url = '$kBaseUrl$path';
    }

    final isUrl = url.startsWith('http');
    final isBase64 = url.startsWith('data:image') || (!isUrl && url.length > 100);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: ClipOval(
        child: Builder(
          builder: (context) {
            if (isBase64 && !isUrl) {
              try {
                return Image.memory(
                  base64Decode(_cleanBase64(url)),
                  fit: BoxFit.cover,
                  width: diameter,
                  height: diameter,
                  errorBuilder: (_, __, ___) => fallback,
                );
              } catch (e) {
                return fallback;
              }
            }

            return Image.network(
              url,
              fit: BoxFit.cover,
              width: diameter,
              height: diameter,
              errorBuilder: (_, __, ___) => fallback,
            );
          },
        ),
      ),
    );
  }
}
