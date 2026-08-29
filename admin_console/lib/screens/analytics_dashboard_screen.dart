import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphify/graphify.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _chartDays = 30;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final approved = app.approvedCarpenters;
    final pending = app.carpenters.where((c) => c.status == 'Pending').length;

    return ListView(
      padding: const EdgeInsets.only(bottom: space2xl),
      children: [
        const Heading('Analytics'),
        const SizedBox(height: spaceLg),

        // ── Tier 1: User Health KPIs ──────────────────────────────────
        _responsiveKpis([
          Kpi(label: 'Total carpenters', value: '${approved.length}', icon: Icons.people_outline, onTap: () => context.go('/carpenters')),
          Kpi(label: 'Online now', value: '${app.onlineCount}', icon: Icons.circle),
          Kpi(label: 'Active today', value: '${app.dauCount}', icon: Icons.today_outlined),
          Kpi(label: 'Active this week', value: '${app.wauCount}', icon: Icons.date_range_outlined),
        ]),
        const SizedBox(height: spaceMd),
        _responsiveKpis([
          Kpi(label: 'Active this month', value: '${app.mauCount}', icon: Icons.calendar_month_outlined),
          Kpi(label: 'Pending approvals', value: '$pending', icon: Icons.person_search_outlined, onTap: () => context.go('/carpenters')),
          Kpi(label: 'Total orders', value: '${app.orders.length + app.partyOrders.length}', icon: Icons.inventory_2_outlined, onTap: () => context.go('/orders')),
          Kpi(label: 'Total revenue', value: '₹${_fmtNum(app.totalRevenue)}', icon: Icons.currency_rupee_outlined),
        ]),

        const SizedBox(height: spaceXl),

        // ── Chart time range toggle ───────────────────────────────────
        _section('Trends', trailing: _dayToggle()),

        const SizedBox(height: spaceMd),

        // ── Orders trend + Revenue trend (side by side on wide) ───────
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          final ordersChart = _chartCard('Orders', _EChart(_buildLineChart(app.ordersPerDay(_chartDays), const Color(0xFF2563EB))));
          final revenueChart = _chartCard('Revenue (₹)', _EChart(_buildBarChart(app.revenuePerDay(_chartDays), kAccentPrimary)));
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ordersChart),
              const SizedBox(width: spaceMd),
              Expanded(child: revenueChart),
            ]);
          }
          return Column(children: [ordersChart, const SizedBox(height: spaceMd), revenueChart]);
        }),

        const SizedBox(height: spaceXl),

        // ── Distribution charts (pie charts row) ──────────────────────
        _section('Distribution'),
        const SizedBox(height: spaceMd),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          final versionChart = _chartCard('App versions', _EChart(_buildPieChart(app.versionDistribution, _versionColors)));
          final tierChart = _chartCard('Carpenter tiers', _EChart(_buildPieChart(app.tierDistribution, _tierColors)));
          final orderTypeChart = _chartCard('Order types', _EChart(_buildPieChart(app.orderTypeDistribution, _typeColors)));
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: versionChart),
              const SizedBox(width: spaceMd),
              Expanded(child: tierChart),
              const SizedBox(width: spaceMd),
              Expanded(child: orderTypeChart),
            ]);
          }
          return Column(children: [
            versionChart,
            const SizedBox(height: spaceMd),
            tierChart,
            const SizedBox(height: spaceMd),
            orderTypeChart,
          ]);
        }),

        const SizedBox(height: spaceXl),

        // ── Business metrics row ──────────────────────────────────────
        _section('Business'),
        const SizedBox(height: spaceMd),
        _responsiveKpis([
          Kpi(label: 'Payment collected', value: '₹${_fmtNum(app.totalCollected)}', icon: Icons.account_balance_wallet_outlined),
          Kpi(label: 'Points awarded', value: _fmtNum(app.totalPointsAwarded), icon: Icons.star_outline),
          Kpi(label: 'Points redeemed', value: _fmtNum(app.totalPointsRedeemed), icon: Icons.redeem_outlined),
          Kpi(label: 'Open feedback', value: '${app.newFeedbackCount}', icon: Icons.feedback_outlined, onTap: () => context.go('/feedback')),
        ]),

        const SizedBox(height: spaceXl),

        // ── Pipeline status charts ────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          final orderStatus = _chartCard('Order pipeline', _EChart(_buildHBarChart(app.orderStatusDistribution, _statusColors)));
          final leadStatus = _chartCard('Lead pipeline', _EChart(_buildHBarChart(app.leadStatusDistribution, _leadColors)));
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: orderStatus),
              const SizedBox(width: spaceMd),
              Expanded(child: leadStatus),
            ]);
          }
          return Column(children: [orderStatus, const SizedBox(height: spaceMd), leadStatus]);
        }),

        const SizedBox(height: spaceXl),

        // ── Tier 1+3: User health table ───────────────────────────────
        _section('Carpenter activity', trailing: Text('${app.inactiveCarpenters.length} inactive (7+ days)', style: kTypeMeta.copyWith(color: kStatusClosed))),
        const SizedBox(height: spaceMd),
        _CarpenterHealthTable(carpenters: approved, app: app),

        const SizedBox(height: spaceXl),

        // ── Top performers ────────────────────────────────────────────
        _section('Top performers'),
        const SizedBox(height: spaceMd),
        _TopPerformersCard(app: app),
      ],
    );
  }

  Widget _dayToggle() => Container(
        decoration: BoxDecoration(color: kBgApp, borderRadius: BorderRadius.circular(kRadiusControl)),
        padding: const EdgeInsets.all(3),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final d in [7, 14, 30])
            GestureDetector(
              onTap: () => setState(() => _chartDays = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chartDays == d ? kBgSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                  boxShadow: _chartDays == d ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
                ),
                child: Text('${d}d', style: kTypeMeta.copyWith(fontWeight: _chartDays == d ? FontWeight.w600 : FontWeight.w400, color: _chartDays == d ? kTextPrimary : kTextSecondary)),
              ),
            ),
        ]),
      );

  Widget _section(String title, {Widget? trailing}) => Row(
        children: [
          SubHeading(title),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      );

  Widget _responsiveKpis(List<Widget> cards) => LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : double.infinity;
        if (!isNarrow) {
          return Row(children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: spaceMd),
              Expanded(child: cards[i]),
            ],
          ]);
        }
        return Wrap(spacing: spaceMd, runSpacing: spaceMd, children: [for (final c in cards) SizedBox(width: cardWidth, child: c)]);
      });

  // ── Chart builders ────────────────────────────────────────────────

  Widget _chartCard(String title, Widget chart) => Container(
        decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kRadiusCard), border: Border.all(color: kBorderSubtle)),
        padding: const EdgeInsets.all(spaceLg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: kTypeSection),
          const SizedBox(height: spaceMd),
          SizedBox(height: 220, child: chart),
        ]),
      );

  Map<String, dynamic> _buildLineChart(Map<String, int> data, Color color) => {
        'tooltip': {'trigger': 'axis'},
        'grid': {'left': 40, 'right': 16, 'top': 16, 'bottom': 28},
        'xAxis': {
          'type': 'category',
          'data': data.keys.toList(),
          'axisLabel': {'fontSize': 10, 'interval': (data.length / 6).floor()},
          'axisLine': {'lineStyle': {'color': '#DFE4E2'}},
        },
        'yAxis': {
          'type': 'value',
          'minInterval': 1,
          'axisLine': {'show': false},
          'splitLine': {'lineStyle': {'color': '#F0F2F1'}},
        },
        'series': [
          {
            'data': data.values.toList(),
            'type': 'line',
            'smooth': true,
            'showSymbol': false,
            'lineStyle': {'color': _hex(color), 'width': 2},
            'areaStyle': {'color': {'type': 'linear', 'x': 0, 'y': 0, 'x2': 0, 'y2': 1, 'colorStops': [{'offset': 0, 'color': _hex(color.withValues(alpha: 0.15))}, {'offset': 1, 'color': _hex(color.withValues(alpha: 0.01))}]}},
          }
        ],
      };

  Map<String, dynamic> _buildBarChart(Map<String, int> data, Color color) => {
        'tooltip': {'trigger': 'axis'},
        'grid': {'left': 50, 'right': 16, 'top': 16, 'bottom': 28},
        'xAxis': {
          'type': 'category',
          'data': data.keys.toList(),
          'axisLabel': {'fontSize': 10, 'interval': (data.length / 6).floor()},
          'axisLine': {'lineStyle': {'color': '#DFE4E2'}},
        },
        'yAxis': {
          'type': 'value',
          'axisLine': {'show': false},
          'splitLine': {'lineStyle': {'color': '#F0F2F1'}},
        },
        'series': [
          {
            'data': data.values.toList(),
            'type': 'bar',
            'barMaxWidth': 20,
            'itemStyle': {'color': _hex(color), 'borderRadius': [3, 3, 0, 0]},
          }
        ],
      };

  Map<String, dynamic> _buildPieChart(Map<String, int> data, Map<String, String> colorMap) => {
        'tooltip': {'trigger': 'item', 'formatter': '{b}: {c} ({d}%)'},
        'legend': {'bottom': 0, 'textStyle': {'fontSize': 11}},
        'series': [
          {
            'type': 'pie',
            'radius': ['40%', '70%'],
            'center': ['50%', '42%'],
            'avoidLabelOverlap': true,
            'label': {'show': false},
            'data': data.entries.map((e) => {
                  'name': e.key,
                  'value': e.value,
                  if (colorMap.containsKey(e.key)) 'itemStyle': {'color': colorMap[e.key]},
                }).toList(),
          }
        ],
      };

  Map<String, dynamic> _buildHBarChart(Map<String, int> data, Map<String, String> colorMap) {
    final entries = data.entries.toList();
    return {
      'tooltip': {'trigger': 'axis'},
      'grid': {'left': 90, 'right': 32, 'top': 8, 'bottom': 8},
      'xAxis': {
        'type': 'value',
        'minInterval': 1,
        'axisLine': {'show': false},
        'splitLine': {'lineStyle': {'color': '#F0F2F1'}},
      },
      'yAxis': {
        'type': 'category',
        'data': entries.map((e) => e.key).toList(),
        'axisLine': {'lineStyle': {'color': '#DFE4E2'}},
        'axisLabel': {'fontSize': 11},
      },
      'series': [
        {
          'type': 'bar',
          'barMaxWidth': 18,
          'data': entries.map((e) => {
                'value': e.value,
                'itemStyle': {'color': colorMap[e.key] ?? '#5B6866', 'borderRadius': [0, 3, 3, 0]},
              }).toList(),
        }
      ],
    };
  }

  static String _hex(Color c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  static String _fmtNum(int n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static const _versionColors = <String, String>{};
  static const _tierColors = <String, String>{
    'Bronze': '#CD7F32',
    'Silver': '#8A9694',
    'Gold': '#D4A017',
    'Platinum': '#5B6866',
  };
  static const _typeColors = <String, String>{
    'Manual': '#0F4C51',
    'Photo': '#2563EB',
    'Voice': '#7C3AED',
  };
  static const _statusColors = <String, String>{
    'Submitted': '#5B6866',
    'Processing': '#2563EB',
    'Fulfilled': '#15803D',
    'Delivered': '#0F4C51',
  };
  static const _leadColors = <String, String>{
    'New': '#5B6866',
    'Contacted': '#2563EB',
    'Qualified': '#B45309',
    'Converted': '#15803D',
    'Closed': '#B91C1C',
  };
}

// ── Inline chart widget ───────────────────────────────────────────────

class _EChart extends StatelessWidget {
  const _EChart(this.options);
  final Map<String, dynamic> options;

  @override
  Widget build(BuildContext context) => GraphifyView(initialOptions: options);
}

// ── Carpenter health table ────────────────────────────────────────────

class _CarpenterHealthTable extends StatefulWidget {
  const _CarpenterHealthTable({required this.carpenters, required this.app});
  final List<Carpenter> carpenters;
  final AdminState app;

  @override
  State<_CarpenterHealthTable> createState() => _CarpenterHealthTableState();
}

class _CarpenterHealthTableState extends State<_CarpenterHealthTable> {
  String _sortBy = 'lastLogin';
  bool _ascending = true;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    var list = List<Carpenter>.from(widget.carpenters);
    if (_filter == 'online') list = list.where((c) => c.isOnline).toList();
    if (_filter == 'inactive') {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      list = list.where((c) => c.lastLogin == null || c.lastLogin!.isBefore(cutoff)).toList();
    }
    if (_filter == 'outdated') {
      final latest = widget.app.appBuildNumber;
      list = list.where((c) => c.appBuildNumber != null && c.appBuildNumber! < latest).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'orders':
          cmp = widget.app.orderCountFor(a.id).compareTo(widget.app.orderCountFor(b.id));
        case 'revenue':
          cmp = widget.app.totalOrderAmount(a.id).compareTo(widget.app.totalOrderAmount(b.id));
        case 'logins':
          cmp = a.loginCount.compareTo(b.loginCount);
        default:
          final al = a.lastLogin ?? DateTime(2000);
          final bl = b.lastLogin ?? DateTime(2000);
          cmp = al.compareTo(bl);
      }
      return _ascending ? cmp : -cmp;
    });

    return Container(
      decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kRadiusCard), border: Border.all(color: kBorderSubtle)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(spaceLg, spaceMd, spaceLg, 0),
            child: Wrap(spacing: spaceSm, runSpacing: spaceSm, children: [
              _filterChip('All', 'all'),
              _filterChip('Online', 'online'),
              _filterChip('Inactive (7d+)', 'inactive'),
              _filterChip('Outdated app', 'outdated'),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 280),
              child: DataTable(
                sortColumnIndex: ['name', 'lastLogin', 'orders', 'revenue', 'logins'].indexOf(_sortBy).clamp(0, 4),
                sortAscending: _ascending,
                headingRowHeight: 40,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 44,
                columnSpacing: spaceLg,
                horizontalMargin: spaceLg,
                headingTextStyle: kTypeMicro,
                dataTextStyle: kTypeBody.copyWith(fontSize: 13),
                columns: [
                  DataColumn(label: const Text('Carpenter'), onSort: (_, asc) => _sort('name', asc)),
                  DataColumn(label: const Text('Status'), onSort: (_, asc) => _sort('lastLogin', asc)),
                  DataColumn(label: const Text('Last login'), onSort: (_, asc) => _sort('lastLogin', asc)),
                  DataColumn(label: const Text('App version')),
                  DataColumn(label: const Text('Orders'), numeric: true, onSort: (_, asc) => _sort('orders', asc)),
                  DataColumn(label: const Text('Revenue'), numeric: true, onSort: (_, asc) => _sort('revenue', asc)),
                  DataColumn(label: const Text('Logins'), numeric: true, onSort: (_, asc) => _sort('logins', asc)),
                ],
                rows: list.take(50).map((c) {
                  final orderCount = widget.app.orderCountFor(c.id);
                  final revenue = widget.app.totalOrderAmount(c.id);
                  return DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () => context.push('/carpenters/${c.id}'),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Avatar(name: c.name, photoUrl: c.photoUrl, radius: 14),
                            const SizedBox(width: spaceSm),
                            Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                      DataCell(_onlineIndicator(c)),
                      DataCell(Text(_fmtLastLogin(c.lastLogin), style: _loginStyle(c.lastLogin))),
                      DataCell(_versionBadge(c, widget.app.appBuildNumber)),
                      DataCell(Text('$orderCount', style: kTypeFigure.copyWith(fontSize: 13))),
                      DataCell(Text('₹${_AnalyticsDashboardScreenState._fmtNum(revenue)}', style: kTypeFigure.copyWith(fontSize: 13))),
                      DataCell(Text('${c.loginCount}', style: kTypeFigure.copyWith(fontSize: 13))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) => StatusFilterChip(label: label, selected: _filter == value, onTap: () => setState(() => _filter = value));

  void _sort(String col, bool asc) => setState(() {
        _sortBy = col;
        _ascending = asc;
      });

  static Widget _onlineIndicator(Carpenter c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c.isOnline ? kStatusSuccess : kTextMuted)),
        const SizedBox(width: 6),
        Text(c.isOnline ? 'Online' : 'Offline', style: kTypeMeta.copyWith(color: c.isOnline ? kStatusSuccess : kTextMuted)),
      ]);

  static Widget _versionBadge(Carpenter c, int latestBuild) {
    if (c.appVersion == null) return Text('-', style: kTypeMeta.copyWith(color: kTextMuted));
    final outdated = c.appBuildNumber != null && c.appBuildNumber! < latestBuild;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outdated ? const Color(0xFFFEF3C7) : kTintSuccess,
        borderRadius: BorderRadius.circular(kRadiusPill),
      ),
      child: Text(c.appVersion!, style: kTypeMicro.copyWith(color: outdated ? const Color(0xFF92400E) : kInkSuccess)),
    );
  }

  static String _fmtLastLogin(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  static TextStyle _loginStyle(DateTime? dt) {
    if (dt == null) return kTypeMeta.copyWith(color: kStatusClosed);
    final days = DateTime.now().difference(dt).inDays;
    if (days >= 7) return kTypeMeta.copyWith(color: kStatusClosed);
    if (days >= 3) return kTypeMeta.copyWith(color: kStatusAttention);
    return kTypeMeta;
  }
}

// ── Top performers card ───────────────────────────────────────────────

class _TopPerformersCard extends StatelessWidget {
  const _TopPerformersCard({required this.app});
  final AdminState app;

  @override
  Widget build(BuildContext context) {
    final top = app.topCarpentersByRevenue;
    if (top.isEmpty) return const EmptyState(icon: Icons.leaderboard_outlined, message: 'No order data yet');
    return Container(
      decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kRadiusCard), border: Border.all(color: kBorderSubtle)),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: spaceLg, endIndent: spaceLg),
            InkWell(
              onTap: () => context.push('/carpenters/${top[i].$1.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
                child: Row(children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}', style: kTypeFigure.copyWith(fontWeight: FontWeight.w600, color: i < 3 ? kAccentPrimary : kTextSecondary)),
                  ),
                  Avatar(name: top[i].$1.name, photoUrl: top[i].$1.photoUrl, radius: 16),
                  const SizedBox(width: spaceMd),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(top[i].$1.name, style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                      Text('${app.orderCountFor(top[i].$1.id)} orders', style: kTypeMeta),
                    ]),
                  ),
                  Text('₹${_AnalyticsDashboardScreenState._fmtNum(top[i].$2)}', style: kTypeFigureLarge.copyWith(fontSize: 16)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
