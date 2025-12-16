// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';

Widget buildEbookReader({
  required BuildContext context,
  required Book book,
  required Widget Function() onError,
}) {
  final viewId = 'ebook-reader-${book.id}';
  
  // Register the iframe view factory
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final iframe = html.IFrameElement()
        ..src = book.contentUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute('loading', 'lazy');
      return iframe;
    },
  );

  return Column(
    children: [
      // Info bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.primary.withValues(alpha: 0.05),
        child: Row(
          children: [
            const Icon(LucideIcons.bookOpen, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${book.title} - ${book.author}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      // Iframe reader
      Expanded(
        child: HtmlElementView(viewType: viewId),
      ),
    ],
  );
}
