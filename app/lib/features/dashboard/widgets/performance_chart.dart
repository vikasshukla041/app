import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/design_system/tokens/app_radius.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../l10n/app_localizations.dart';
import '../models/performance_history.dart';
import 'performance_chart_message.dart';
import 'performance_chart_page.dart';

/// Draws the portfolio's value over time with TradingView Lightweight Charts,
/// running inside a WebView.
class PerformanceChart extends StatefulWidget {
  const PerformanceChart({super.key, required this.history});

  final PerformanceHistory history;

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

// Stateful so the WebView and its page survive a rebuild instead of reloading.
class _PerformanceChartState extends State<PerformanceChart> {
  static const String _chartLibraryAsset =
      'assets/chart/lightweight-charts.standalone.production.js';

  // Read once per app run; the file is about 200 KB.
  static Future<String>? _chartLibrary;

  WebViewController? _controller;
  String? _loadedPage;

  // No WebView on this platform (desktop, or a widget test).
  bool get _isSupported => WebViewPlatform.instance != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPage();
  }

  @override
  void didUpdateWidget(PerformanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (!_isSupported) {
      return;
    }
    // Read these now: after the await, the context may be gone.
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toString();
    final WebViewController controller = _controller ??= _createController(
      colors.surfaceContainerLow,
    );

    final String library = await (_chartLibrary ??= rootBundle.loadString(
      _chartLibraryAsset,
    ));
    final String page = PerformanceChartPage.html(
      chartLibrary: library,
      history: widget.history,
      colors: colors,
      locale: locale,
    );
    // Theme or language changes rebuild the page; plain rebuilds do not.
    if (!mounted || page == _loadedPage) {
      return;
    }
    _loadedPage = page;
    await controller.loadHtmlString(page);
    if (mounted) {
      setState(() {});
    }
  }

  WebViewController _createController(Color background) {
    final WebViewController controller = WebViewController();
    // The web iframe always runs scripts and has no such settings to change.
    if (!kIsWeb) {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(background);
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final WebViewController? controller = _controller;

    if (!_isSupported) {
      return PerformanceChartMessage(message: l10n.performanceChartUnavailable);
    }

    final NumberFormat money = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: widget.history.currency,
    );
    final PerformanceHistory history = widget.history;

    // A screen reader cannot see inside a WebView, so say what it shows.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: history.candles.isEmpty
          ? null
          : l10n.performanceChartSemantics(
              money.format(history.baseline),
              money.format(history.lastClose),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          height: AppSizing.chartHeight,
          child: controller == null || _loadedPage == null
              ? ColoredBox(color: theme.colorScheme.surfaceContainerLow)
              : WebViewWidget(
                  controller: controller,
                  // Sideways drags go to the chart; up and down still scroll the page.
                  gestureRecognizers:
                      const <Factory<OneSequenceGestureRecognizer>>{
                        Factory<HorizontalDragGestureRecognizer>(
                          HorizontalDragGestureRecognizer.new,
                        ),
                      },
                ),
        ),
      ),
    );
  }
}
