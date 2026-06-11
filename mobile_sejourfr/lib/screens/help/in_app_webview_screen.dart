import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';

/// Wrapper natif autour d'une `WebView` pour les pages FAQ, CGU et
/// Politique de confidentialité du site web.
///
/// Pourquoi WebView plutôt que natif : ces 3 pages sont des pavés HTML/JSX
/// (~600 lignes chacune pour CGU/Privacy) — les duppliquer en Dart imposerait
/// un mainteneur double à chaque évolution juridique. La WebView garde la
/// source de vérité côté web.
///
/// La barre d'app garde un look natif : back, titre, action retry en cas
/// d'erreur réseau. Pas d'icône partage / ouvrir-dans-le-navigateur — on
/// veut que l'utilisateur reste dans l'app.
class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;
  int _loadingPercent = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() => _loadingPercent = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loadingPercent = 100);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // On ne montre l'erreur que pour la requête principale — sinon
            // une 404 sur un sous-asset (police, image) bloque tout.
            if (error.isForMainFrame == true) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _loadingPercent = 0;
    });
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (!_hasError && _loadingPercent < 100)
            LinearProgressIndicator(
              value: _loadingPercent / 100.0,
              color: AppColors.blue,
              backgroundColor: AppColors.line2,
              minHeight: 2,
            ),
          if (_hasError)
            _ErrorState(message: _errorMessage, onRetry: _retry),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cloudOff, size: 40, color: AppColors.red),
            const SizedBox(height: 14),
            Text(
              'Impossible de charger cette page',
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Vérifie ta connexion et réessaie.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(
                'Réessayer',
                style: AppFonts.ui(size: 13.5, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
