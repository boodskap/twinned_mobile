import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_api/api/twinned.swagger.dart' as twinned;
import 'package:eventify/eventify.dart' as event;
import 'package:twinned_mobile/widgets/commons/map_pin.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends BaseState<MapViewPage> {
  Alignment selectedAlignment = Alignment.topCenter;
  event.Listener? listener;
  late final customMarkers = <Marker>[];
  bool counterRotate = false;
  bool? _liveMode = true;
  bool? _showGenofences = true;
  bool? _showStaticDevices = true;
  bool loading = false;
  @override
  void setup() async {
    await _load();
  }

  Future _load() async {
    if (loading) return;
    loading = true;
    await execute(() async {
      final markers = <Marker>[];

      var res = await UserSession.twin.searchRecentDeviceData(
          apikey: UserSession().getAuthToken(),
          filterByLocation: true,
          body:
              const twinned.FilterSearchReq(search: '*', page: 0, size: 1000));

      if (validateResponse(res)) {
        for (var dd in res.body!.values!) {
          debugPrint(dd.toString());
          markers.add(buildPin(
              dd.deviceName ?? '-',
              dd.modelName ?? '-',
              LatLng(dd.geolocation!.coordinates[1],
                  dd.geolocation!.coordinates[0])));
        }
      }

      refresh(sync: () {
        customMarkers.clear();
        customMarkers.addAll(markers);
      });

      listener = BaseState.layoutEvents.on('twinMessageReceived', this, (e, o) {
        _load();
      });
    });
    loading = false;
  }

  @override
  void dispose() {
    if (null != listener) {
      BaseState.layoutEvents.off(listener!);
    }
    super.dispose();
  }

  Marker buildPin(String name, String model, LatLng point) => Marker(
      width: 150,
      height: 50,
      point: point,
      child: MapPin(deviceName: name, deviceModel: model));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Checkbox(
                value: _liveMode,
                onChanged: (changed) {
                  setState(() {
                    _liveMode = changed;
                  });
                }),
            const Text('Live Mode'),
            Checkbox(
                value: _showGenofences,
                onChanged: (changed) {
                  setState(() {
                    _showGenofences = changed;
                  });
                }),
            const Text('Show Geofence'),
            Checkbox(
                value: _showStaticDevices,
                onChanged: (changed) {
                  setState(() {
                    _showStaticDevices = changed;
                  });
                }),
            const Tooltip(
                message: 'Non movable devices with locations',
                child: Text('Fixed Locations')),
          ],
        ),
        Flexible(
          child: FlutterMap(
            options: const MapOptions(
              initialZoom: 3,
              interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapDragZoom),
            ),
            children: [
              openStreetMapTileLayer,
              MarkerLayer(
                markers: customMarkers,
                rotate: counterRotate,
                alignment: selectedAlignment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      tileProvider: CancellableNetworkTileProvider(),
    );
