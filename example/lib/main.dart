import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkzly_flutter_sdk/linkzly_flutter_sdk.dart';

/// SDK key from the Linkzly console.
/// You can override it at runtime via
/// `flutter run --dart-define=LINKZLY_SDK_KEY=slk_...`.
const String _bundledSdkKey =
    'slk_8876e9b590f0e782169bfa40a9314fa556b17a16664a2816';

const String _sdkKeyFromDartDefine = String.fromEnvironment('LINKZLY_SDK_KEY');
const String _sdkKey = _sdkKeyFromDartDefine != ''
    ? _sdkKeyFromDartDefine
    : _bundledSdkKey;

const LinkzlyEnvironment _environment = LinkzlyEnvironment.staging;

void main() {
  runZonedGuarded<void>(
    () {
      // Must run inside the same zone as `runApp` to avoid a zone-mismatch
      // assertion from Flutter's binding initialization.
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint(
          '[LinkzlyExample] Uncaught framework error: ${details.exception}',
        );
      };

      runApp(const LinkzlyExampleApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('[LinkzlyExample] Uncaught zone error: $error\n$stack');
    },
  );
}

class LinkzlyExampleApp extends StatelessWidget {
  const LinkzlyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linkzly Flutter SDK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6CFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const LinkzlyHomePage(),
    );
  }
}

class LinkzlyHomePage extends StatefulWidget {
  const LinkzlyHomePage({super.key});

  @override
  State<LinkzlyHomePage> createState() => _LinkzlyHomePageState();
}

enum _ConfigureState { idle, configuring, configured, missingKey, failed }

class _LinkzlyHomePageState extends State<LinkzlyHomePage> {
  _ConfigureState _configureState = _ConfigureState.idle;
  String? _configureError;

  DeepLinkData? _lastDeepLink;
  UniversalLinkEvent? _lastUniversalLink;
  String? _visitorId;
  String? _userId;
  bool _trackingEnabled = true;
  int _pendingEventCount = 0;
  AffiliateAttribution? _affiliate;

  StreamSubscription<DeepLinkData>? _deepLinkSub;
  StreamSubscription<UniversalLinkEvent>? _universalLinkSub;

  final TextEditingController _userIdController =
      TextEditingController(text: 'demo_user_123');

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    // Defer configure until after first frame so any errors surface in UI
    // rather than blocking the initial render.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _universalLinkSub?.cancel();
    _userIdController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  void _subscribeToStreams() {
    try {
      _deepLinkSub = Linkzly.instance.deepLinkStream.listen(
        (DeepLinkData data) {
          if (!mounted) return;
          setState(() => _lastDeepLink = data);
          _showSnack('Deep link received: ${data.path ?? data.url ?? '—'}');
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('[LinkzlyExample] Deep link stream error: $error');
        },
        cancelOnError: false,
      );

      _universalLinkSub = Linkzly.instance.universalLinkStream.listen(
        (UniversalLinkEvent event) {
          if (!mounted) return;
          setState(() => _lastUniversalLink = event);
          _showSnack('Universal link received: ${event.url}');
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('[LinkzlyExample] Universal link stream error: $error');
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      debugPrint('[LinkzlyExample] Failed to subscribe to streams: $e\n$stack');
    }
  }

  Future<void> _bootstrap() async {
    if (_sdkKey.isEmpty || _sdkKey == 'slk_your_sdk_key') {
      setState(() {
        _configureState = _ConfigureState.missingKey;
        _configureError =
            'No SDK key set. Add one in main.dart or run with --dart-define=LINKZLY_SDK_KEY=slk_...';
      });
      debugPrint(
        '[LinkzlyExample] SDK key is missing — add one in main.dart '
        'or pass --dart-define=LINKZLY_SDK_KEY=... to configure the SDK.',
      );
      return;
    }

    setState(() {
      _configureState = _ConfigureState.configuring;
      _configureError = null;
    });

    try {
      await Linkzly.instance.configure(
        const LinkzlyConfig(
          sdkKey: _sdkKey,
          environment: _environment,
          autoTrackAppOpens: true,
        ),
      );
      if (!mounted) return;
      setState(() => _configureState = _ConfigureState.configured);
      await _refreshState();
    } on PlatformException catch (e, stack) {
      debugPrint(
        '[LinkzlyExample] configure PlatformException: ${e.code} — '
        '${e.message}\n$stack',
      );
      if (!mounted) return;
      setState(() {
        _configureState = _ConfigureState.failed;
        _configureError = '${e.code}: ${e.message ?? 'Unknown error'}';
      });
    } catch (e, stack) {
      debugPrint('[LinkzlyExample] configure failed: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _configureState = _ConfigureState.failed;
        _configureError = e.toString();
      });
    }
  }

  Future<void> _refreshState() async {
    await _runSafely('getVisitorId', () async {
      final String id = await Linkzly.instance.getVisitorId();
      if (mounted) setState(() => _visitorId = id);
    });
    await _runSafely('getUserId', () async {
      final String? id = await Linkzly.instance.getUserId();
      if (mounted) setState(() => _userId = id);
    });
    await _runSafely('isTrackingEnabled', () async {
      final bool enabled = await Linkzly.instance.isTrackingEnabled();
      if (mounted) setState(() => _trackingEnabled = enabled);
    });
    await _runSafely('getPendingEventCount', () async {
      final int count = await Linkzly.instance.getPendingEventCount();
      if (mounted) setState(() => _pendingEventCount = count);
    });
    await _runSafely('getAffiliateAttribution', () async {
      final AffiliateAttribution attribution =
          await Linkzly.instance.getAffiliateAttribution();
      if (mounted) setState(() => _affiliate = attribution);
    });
  }

  // ---------------------------------------------------------------------------
  // SDK actions
  // ---------------------------------------------------------------------------

  Future<void> _trackSimpleEvent() async {
    await _runSafely('trackEvent', () async {
      await Linkzly.instance.trackEvent(
        'example_button_tapped',
        <String, Object?>{
          'source': 'flutter_example',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _showSnack('Tracked event: example_button_tapped');
    });
    await _runSafely(
      'getPendingEventCount',
      () async {
        final int count = await Linkzly.instance.getPendingEventCount();
        if (mounted) setState(() => _pendingEventCount = count);
      },
    );
  }

  Future<void> _trackPurchase() async {
    await _runSafely('trackPurchase', () async {
      final bool ok = await Linkzly.instance.trackPurchase(<String, Object?>{
        'currency': 'USD',
        'amount': 9.99,
        'productId': 'premium_monthly',
      });
      _showSnack(ok ? 'Purchase tracked' : 'Purchase tracking returned false');
    });
  }

  Future<void> _flushEvents() async {
    await _runSafely('flushEvents', () async {
      final bool ok = await Linkzly.instance.flushEvents();
      _showSnack(ok ? 'Events flushed' : 'Flush returned false');
    });
    await _runSafely(
      'getPendingEventCount',
      () async {
        final int count = await Linkzly.instance.getPendingEventCount();
        if (mounted) setState(() => _pendingEventCount = count);
      },
    );
  }

  Future<void> _setUserId() async {
    final String value = _userIdController.text.trim();
    if (value.isEmpty) {
      _showSnack('Enter a user id first');
      return;
    }
    await _runSafely('setUserId', () async {
      await Linkzly.instance.setUserId(value);
      if (mounted) setState(() => _userId = value);
      _showSnack('User id set to "$value"');
    });
  }

  Future<void> _resetVisitorId() async {
    await _runSafely('resetVisitorId', () async {
      await Linkzly.instance.resetVisitorId();
      final String id = await Linkzly.instance.getVisitorId();
      if (mounted) setState(() => _visitorId = id);
      _showSnack('Visitor id reset');
    });
  }

  Future<void> _toggleTracking(bool value) async {
    setState(() => _trackingEnabled = value);
    await _runSafely('setTrackingEnabled', () async {
      await Linkzly.instance.setTrackingEnabled(value);
      _showSnack(value ? 'Tracking enabled' : 'Tracking disabled');
    });
  }

  Future<void> _requestAttPermission() async {
    await _runSafely('requestTrackingPermission', () async {
      final String? status = await Linkzly.instance.requestTrackingPermission();
      _showSnack('ATT status: ${status ?? 'unavailable'}');
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Runs [action] and prints any error to the console without breaking the
  /// UI. This is the recommended integration pattern: SDK calls are best-effort
  /// and should never crash the host app.
  Future<void> _runSafely(String label, Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (e, stack) {
      debugPrint(
        '[LinkzlyExample] $label PlatformException: ${e.code} — '
        '${e.message}\n$stack',
      );
      _showSnack('$label failed: ${e.code}');
    } catch (e, stack) {
      debugPrint('[LinkzlyExample] $label failed: $e\n$stack');
      _showSnack('$label failed');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linkzly Flutter SDK'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh state',
            onPressed: _refreshState,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshState,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            _ConfigureCard(
              state: _configureState,
              error: _configureError,
              environment: _environment,
              onRetry: _bootstrap,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Identity',
              icon: Icons.badge_outlined,
              children: <Widget>[
                _KeyValueRow(label: 'Visitor ID', value: _visitorId ?? '—'),
                _KeyValueRow(label: 'User ID', value: _userId ?? '—'),
                const SizedBox(height: 12),
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _setUserId,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Set user ID'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetVisitorId,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset visitor'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Event tracking',
              icon: Icons.event_note_outlined,
              children: <Widget>[
                _KeyValueRow(
                  label: 'Pending events',
                  value: '$_pendingEventCount',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _trackSimpleEvent,
                      icon: const Icon(Icons.touch_app),
                      label: const Text('Track event'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _trackPurchase,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Track purchase'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _flushEvents,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Flush'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Privacy',
              icon: Icons.privacy_tip_outlined,
              children: <Widget>[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _trackingEnabled,
                  onChanged: _toggleTracking,
                  title: const Text('Tracking enabled'),
                  subtitle: const Text(
                    'When off, the SDK stops collecting analytics events.',
                  ),
                ),
                const SizedBox(height: 8),
                if (defaultTargetPlatform == TargetPlatform.iOS)
                  OutlinedButton.icon(
                    onPressed: _requestAttPermission,
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Request ATT permission (iOS)'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Deep link',
              icon: Icons.link,
              children: <Widget>[
                if (_lastDeepLink == null)
                  const Text(
                    'No deep link yet. Open the app via a Linkzly link to '
                    'populate this section.',
                  )
                else ...<Widget>[
                  _KeyValueRow(
                    label: 'URL',
                    value: _lastDeepLink!.url ?? '—',
                  ),
                  _KeyValueRow(
                    label: 'Path',
                    value: _lastDeepLink!.path ?? '—',
                  ),
                  _KeyValueRow(
                    label: 'Smart link ID',
                    value: _lastDeepLink!.smartLinkId ?? '—',
                  ),
                  _KeyValueRow(
                    label: 'Click ID',
                    value: _lastDeepLink!.clickId ?? '—',
                  ),
                  if (_lastDeepLink!.parameters.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    const Text(
                      'Parameters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    _CodeBlock(text: _lastDeepLink!.parameters.toString()),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Universal link',
              icon: Icons.public,
              children: <Widget>[
                if (_lastUniversalLink == null)
                  const Text(
                    'No universal link yet. iOS Universal Links and Android '
                    'App Links will surface here.',
                  )
                else ...<Widget>[
                  _KeyValueRow(
                    label: 'URL',
                    value: _lastUniversalLink!.url,
                  ),
                  _KeyValueRow(
                    label: 'Path',
                    value: _lastUniversalLink!.path ?? '—',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Affiliate attribution',
              icon: Icons.handshake_outlined,
              children: <Widget>[
                if (_affiliate == null)
                  const Text('Not loaded yet.')
                else ...<Widget>[
                  _KeyValueRow(
                    label: 'Attributed',
                    value: _affiliate!.hasAttribution ? 'Yes' : 'No',
                  ),
                  _KeyValueRow(
                    label: 'Source',
                    value: _affiliate!.source,
                  ),
                  _KeyValueRow(
                    label: 'Click ID',
                    value: _affiliate!.clickId ?? '—',
                  ),
                  _KeyValueRow(
                    label: 'Program ID',
                    value: _affiliate!.programId ?? '—',
                  ),
                  _KeyValueRow(
                    label: 'Affiliate ID',
                    value: _affiliate!.affiliateId ?? '—',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable presentational widgets
// =============================================================================

class _ConfigureCard extends StatelessWidget {
  const _ConfigureCard({
    required this.state,
    required this.error,
    required this.environment,
    required this.onRetry,
  });

  final _ConfigureState state;
  final String? error;
  final LinkzlyEnvironment environment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon, String title) = switch (state) {
      _ConfigureState.idle => (
          cs.surfaceContainerHighest,
          cs.onSurface,
          Icons.hourglass_empty,
          'Preparing…',
        ),
      _ConfigureState.configuring => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          Icons.sync,
          'Configuring SDK…',
        ),
      _ConfigureState.configured => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          Icons.check_circle,
          'SDK configured',
        ),
      _ConfigureState.missingKey => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
          Icons.vpn_key_outlined,
          'SDK key missing',
        ),
      _ConfigureState.failed => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.error_outline,
          'Configuration failed',
        ),
    };

    return Card(
      elevation: 0,
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Environment: ${environment.name}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: fg.withValues(alpha: 0.8),
                        ),
                  ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: fg,
                          ),
                    ),
                  ],
                  if (state == _ConfigureState.failed ||
                      state == _ConfigureState.missingKey) ...<Widget>[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
