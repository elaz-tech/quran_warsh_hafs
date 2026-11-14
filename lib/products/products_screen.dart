import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data model for one of our Google Play apps.
/// Source of truth: `lib/products/list_products.json`.
class ProductApp {
  final String name;
  final String idStore;
  final String logo;
  final String linkPlaystore;

  /// Bundled offline logo under `assets/products/`.
  /// Empty when no local file is mapped for this [idStore].
  final String assetLogo;

  const ProductApp({
    required this.name,
    required this.idStore,
    required this.logo,
    required this.linkPlaystore,
    this.assetLogo = '',
  });

  factory ProductApp.fromJson(Map<String, dynamic> json) {
    return ProductApp(
      name: (json['name'] ?? '').toString(),
      idStore: (json['id_store'] ?? '').toString(),
      logo: (json['logo_online'] ?? json['logo'] ?? '').toString(),
      linkPlaystore: (json['link_playstore'] ?? '').toString(),
      assetLogo: (json['logo_offline'] ?? '').toString(),
    );
  }

  /// Simple method: loads all products straight from
  /// `lib/products/list_products.json` (bundled asset, offline-safe).
  /// Returns an empty list if the asset is missing or malformed.
  static Future<List<ProductApp>> loadAll() async {
    try {
      final raw = await rootBundle.loadString(
        'lib/products/list_products.json',
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.values
          .whereType<Map<String, dynamic>>()
          .map(ProductApp.fromJson)
          .where((p) => p.name.isNotEmpty && p.linkPlaystore.isNotEmpty)
          .toList();
    } catch (_) {
      // Asset missing or malformed.
      return [];
    }
  }
}

/// Full screen listing our Google Play apps to invite users
/// to download them. Chosen over a popup/dialog because 4 apps
/// with logos + install/share actions need real list space.
///
/// Data comes solely from `lib/products/list_products.json`
/// (a bundled asset, so it works fully offline).
/// To add an app: one JSON entry + its logo file under `assets/products/`.
///
/// Note: this app builds its teal theme locally per screen (no app-wide
/// MaterialApp theme), so this screen wraps itself in the same teal
/// theme + RTL directionality instead of relying on the ambient theme.
/// Pass [isDark] from the caller so night mode stays consistent.
class ProductsScreen extends StatefulWidget {
  final bool isDark;

  const ProductsScreen({super.key, this.isDark = false});

  /// Reusable entry point: call from any settings screen instead of
  /// duplicating the navigation code in every app.
  static Future<void> open(BuildContext context, {bool isDark = false}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductsScreen(isDark: isDark),
      ),
    );
  }

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<ProductApp> _products = [];
  String _currentPackage = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Same teal theme as the other screens of this app
  /// (see `SettingsScreen._buildTheme`).
  ThemeData _buildTheme(bool dark) {
    final base = dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
      ),
      appBarTheme: base.appBarTheme.copyWith(centerTitle: true, elevation: 0),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF8F8F8),
      listTileTheme: ListTileThemeData(
        iconColor: dark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Future<void> _load() async {
    final products = await ProductApp.loadAll();
    String currentPackage = '';
    try {
      final info = await PackageInfo.fromPlatform();
      currentPackage = info.packageName;
    } catch (_) {
      // Package name is only used for the "you are using it now" badge.
    }
    if (!mounted) return;
    setState(() {
      _products = products;
      _currentPackage = currentPackage;
      _loaded = true;
    });
  }

  Future<void> _openStore(ProductApp app) async {
    final uri = Uri.tryParse(app.linkPlaystore);
    if (uri == null) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر فتح متجر Google Play — تحقق من اتصال الإنترنت',
            ),
          ),
        );
      }
    } catch (_) {
      // No internet / no browser / Play Store unavailable.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يتطلب فتح المتجر اتصالاً بالإنترنت')),
      );
    }
  }

  Future<void> _shareApp(ProductApp app) async {
    // share_plus 12 API (this project pins ^12.0.1): SharePlus.instance
    // with ShareParams — same style as SettingsScreen._shareApp.
    await SharePlus.instance.share(
      ShareParams(
        subject: app.name,
        text: 'جرّب تطبيق ${app.name}\nحمّله الآن: ${app.linkPlaystore}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: _buildTheme(widget.isDark),
        child: Builder(
          builder: (context) => _buildScaffold(context),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('تطبيقاتنا على Google Play')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد تطبيقات لعرضها حالياً',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _headerCard();
                if (index == _products.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Text(
                      'ملاحظة: تصفح التطبيقات يعمل بدون إنترنت، لكن التثبيت من المتجر يتطلب اتصالاً بالإنترنت',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  );
                }
                final app = _products[index - 1];
                final isCurrent = _currentPackage.isNotEmpty &&
                    app.idStore == _currentPackage;
                return _productCard(context, colorScheme, app, isCurrent);
              },
            ),
    );
  }

  /// Outfit with the app theme: teal gradient (the app's brand color)
  /// with white text.
  Widget _headerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00796B), Color(0xFF009688)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.apps_outlined, size: 40, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'اكتشف تطبيقاتنا الإسلامية الأخرى وحمّلها من متجر Google Play — ولا تنس مشاركتها مع أحبابك، فالدال على الخير كفاعله',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Offline-first logo: bundled asset, then network URL,
  /// then a placeholder icon. The screen itself stays fully
  /// usable offline — only opening the Play Store needs internet.
  Widget _logoWidget(ColorScheme colorScheme, ProductApp app) {
    // App-tinted placeholder derived from the teal color scheme,
    // so it stays on-brand in both light and dark mode.
    Widget placeholder() => Container(
          width: 64,
          height: 64,
          color: colorScheme.primary.withValues(alpha: 0.08),
          child: Icon(Icons.apps, size: 32, color: colorScheme.primary),
        );
    Widget network() {
      if (app.logo.isEmpty) return placeholder();
      return Image.network(
        app.logo,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }

    if (app.assetLogo.isEmpty) return network();
    return Image.asset(
      app.assetLogo,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => network(),
    );
  }

  Widget _productCard(
    BuildContext context,
    ColorScheme colorScheme,
    ProductApp app,
    bool isCurrent,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _logoWidget(colorScheme, app),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          app.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            height: 1.7,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 6),
                        Chip(
                          label: const Text(
                            'تستخدمه الآن',
                            style: TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          backgroundColor: colorScheme.secondaryContainer,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openStore(app),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('تثبيت من المتجر'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _shareApp(app),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('مشاركة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Drop-in settings button: one line, no navigation boilerplate.
/// Pass through the caller's night mode so the screen matches it.
class ProductsSettingsTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;

  const ProductsSettingsTile({
    super.key,
    this.isDark = false,
    this.title = 'تطبيقاتنا الإسلامية',
    this.subtitle = 'اكتشف وحمّل تطبيقاتنا الأخرى من Google Play',
    this.icon = Icons.apps_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => ProductsScreen.open(context, isDark: isDark),
    );
  }
}
