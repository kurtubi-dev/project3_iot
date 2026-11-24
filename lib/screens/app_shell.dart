import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';
import 'tabs/gates_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/monitoring_tab.dart';
import 'tabs/recommendations_tab.dart';

class AppShell extends StatefulWidget {
  final int initialTab;

  const AppShell({super.key, this.initialTab = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 4);
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index.clamp(0, 4));
  }

  String get _title {
    switch (_currentIndex) {
      case 0:
        return 'Siaga Irigasi';
      case 1:
        return 'Monitoring Stasiun';
      case 2:
        return 'Rekomendasi AI';
      case 3:
        return 'Kendali Pintu';
      case 4:
        return 'Riwayat Aktivitas';
      default:
        return 'Siaga Irigasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unreadCount = store.unreadNotificationCount;
        final criticalCount = store.unacknowledgedCriticalCount;
        final badgeCount = criticalCount > 0 ? criticalCount : unreadCount;

        return Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              // Status Online/Offline di Header
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pushNamed('/profil'),
                    child: ConnectivityBadge(
                      status: store.isAppOnline
                          ? ConnectivityStatus.online
                          : ConnectivityStatus.offline,
                      compact: true,
                    ),
                  ),
                ),
              ),
              // Notifikasi dengan Badge
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => Navigator.of(context).pushNamed('/notifikasi'),
                icon: Badge(
                  isLabelVisible: badgeCount > 0,
                  backgroundColor:
                      criticalCount > 0 ? AppColors.kritis : AppColors.puprGold,
                  label: Text('$badgeCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              // Profil Petugas
              IconButton(
                tooltip: 'Profil Petugas',
                onPressed: () => Navigator.of(context).pushNamed('/profil'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeTab(onSwitchTab: _switchTab),
              const MonitoringTab(),
              const RecommendationsTab(),
              const GatesTab(),
              const HistoryTab(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _switchTab,
            indicatorColor: AppColors.navyPrimary.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.navyPrimary),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.sensors_outlined),
                selectedIcon:
                    Icon(Icons.sensors_rounded, color: AppColors.navyPrimary),
                label: 'Monitoring',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon:
                    Icon(Icons.auto_awesome_rounded, color: AppColors.navyPrimary),
                label: 'AI',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded, color: AppColors.navyPrimary),
                label: 'Kendali',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon:
                    Icon(Icons.history_rounded, color: AppColors.navyPrimary),
                label: 'Riwayat',
              ),
            ],
          ),
        );
      },
    );
  }
}
