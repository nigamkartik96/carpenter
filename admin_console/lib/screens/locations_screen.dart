import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

// Default map center (Pune) used only when no carpenter has reported a
// real position yet -- real lat/lng comes from the carpenter app's
// foreground location reporting (see AppState.reportLocationOnce there).
const _defaultCenter = LatLng(18.5204, 73.8567);

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final mapController = MapController();
  int? selected;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final active = app.carpenters.where((c) => c.status == 'Approved').toList();
    final withLocation = <Carpenter>[];
    final withoutLocation = <Carpenter>[];
    for (final c in active) {
      if (c.lat != null && c.lng != null) {
        withLocation.add(c);
      } else {
        withoutLocation.add(c);
      }
    }
    final center = withLocation.isNotEmpty ? LatLng(withLocation.first.lat!, withLocation.first.lng!) : _defaultCenter;

    return ListView(
      children: [
        const Heading('Live locations', subtitle: 'Last known position of active carpenters, reported while they have the app open'),
        const SizedBox(height: 12),
        if (withoutLocation.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${withoutLocation.length} carpenter(s) have not reported a location yet -- they need to open the app and accept location sharing at least once.',
                    style: const TextStyle(fontSize: 12, color: Colors.brown),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Container(
            height: 400,
            decoration: const BoxDecoration(border: Border.fromBorderSide(kCardBorder)),
            child: withLocation.isEmpty
                ? Container(
                    color: kBgApp,
                    alignment: Alignment.center,
                    child: const Text('No carpenter locations reported yet', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  )
                : FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 12,
                      onTap: (_, __) => setState(() => selected = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.carpenterhub.admin_console',
                      ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < withLocation.length; i++)
                            Marker(
                              point: LatLng(withLocation[i].lat!, withLocation[i].lng!),
                              width: 160,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => setState(() => selected = selected == i ? null : i),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected == i)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          '${withLocation[i].name}\nLast seen: ${withLocation[i].lastSeen}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    const Icon(Icons.location_on, color: kPrimaryDark, size: 32),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const SubHeading('Active carpenters'),
        const SizedBox(height: 10),
        if (active.isEmpty) const EmptyState(icon: Icons.people_outline, message: 'No approved carpenters yet'),
        if (active.isNotEmpty)
          DataListView(
            columns: const [
              ('Carpenter', expanded: true),
              ('Area', expanded: true),
              ('Last seen', expanded: false),
            ],
            rows: active.map((c) => DataListRow(
              cells: [
                Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(child: Text(c.area, style: const TextStyle(fontSize: 13))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.lastSeen, style: const TextStyle(color: kTextMuted, fontSize: 12)),
                    if (c.lat != null && c.lng != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on, size: 14, color: kAccentPrimary),
                    ],
                  ],
                ),
              ],
            )).toList(),
          ),
      ],
    );
  }
}
