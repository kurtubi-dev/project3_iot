import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/gate_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/node_detail_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendation_detail_screen.dart';
import 'state/irrigation_store.dart';

void main() {
  runApp(const SiagaIrigasiApp());
}

class SiagaIrigasiApp extends StatefulWidget {
  const SiagaIrigasiApp({super.key});

  @override
  State<SiagaIrigasiApp> createState() => _SiagaIrigasiAppState();
}

class _SiagaIrigasiAppState extends State<SiagaIrigasiApp> {
  @override
  void initState() {
    super.initState();
    IrrigationStore.instance.checkSavedSession();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final store = IrrigationStore.instance;
    final name = settings.name ?? '/';

    // Jika belum login, arahkan route selain /login ke LoginScreen
    if (!store.isLoggedIn && name != '/login') {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/login'),
        builder: (_) => const LoginScreen(),
      );
    }

    if (name == '/login') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
    }

    if (name == '/') {
      final args = settings.arguments as Map<String, dynamic>?;
      final initialTab = (args?['tab'] as int?) ?? 0;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AppShell(initialTab: initialTab),
      );
    }

    if (name == '/monitoring') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AppShell(initialTab: 1),
      );
    }

    if (name == '/monitoring/hulu') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const NodeDetailScreen(nodeSlug: 'hulu'),
      );
    }

    if (name == '/monitoring/hilir') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const NodeDetailScreen(nodeSlug: 'hilir'),
      );
    }

    if (name == '/rekomendasi') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AppShell(initialTab: 2),
      );
    }

    if (name.startsWith('/rekomendasi/')) {
      final recId = name.replaceFirst('/rekomendasi/', '');
      if (recId.isNotEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecommendationDetailScreen(recommendationId: recId),
        );
      }
    }

    if (name == '/kendali') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AppShell(initialTab: 3),
      );
    }

    if (name.startsWith('/kendali/')) {
      final gateId = name.replaceFirst('/kendali/', '');
      if (gateId.isNotEmpty) {
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GateDetailScreen(
            gateId: gateId,
            recommendationId: args?['recommendationId'] as String?,
            initialTarget: args?['initialTarget'] as int?,
            mode: args?['mode'] as String?,
          ),
        );
      }
    }

    if (name == '/notifikasi') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const NotificationsScreen(),
      );
    }

    if (name == '/riwayat') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AppShell(initialTab: 4),
      );
    }

    if (name == '/profil') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ProfileScreen(),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => NotFoundScreen(routeName: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'Siaga Irigasi — PUPR Subang',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: store.isLoggedIn ? '/' : '/login',
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }
}
