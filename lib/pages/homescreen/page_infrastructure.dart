import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/default_assetview.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/dashboard/pages/page_device_history.dart';
import 'package:twinned_mobile/dashboard/pages/page_map.dart';
import 'package:twinned_mobile/pages/widgets/asset_infra_card.dart';
import 'package:twinned_mobile/pages/widgets/device_infra_card.dart';
import 'package:twinned_mobile/pages/widgets/facility_infra_card.dart';
import 'package:twinned_mobile/pages/widgets/floor_infra_card.dart';
import 'package:twinned_mobile/pages/widgets/premise_infra_card.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';

enum CurrentView { home, map, asset, grid }

class InfraPage extends StatefulWidget {
  final TwinInfraType type;
  CurrentView currentView;
  final Premise? premise;
  final Facility? facility;
  final Floor? floor;
  final Asset? asset;

  InfraPage(
      {super.key,
      required this.type,
      required this.currentView,
      this.premise,
      this.facility,
      this.floor,
      this.asset});

  @override
  State<InfraPage> createState() => _InfraPageState();
}

class _InfraPageState extends BaseState<InfraPage> {
  Widget bannerImage = Image.asset(
    'assets/images/ldashboard_banner.png',
    fit: BoxFit.cover,
  );

  bool loading = false;
  String search = '*';
  final List<Premise> _premises = [];
  final List<Facility> _facilities = [];
  final List<Floor> _floors = [];
  final List<Asset> _assets = [];
  final List<Device> _devices = [];
  final Map<String, PremiseStats> _premiseStats = {};
  final Map<String, FacilityStats> _facilityStats = {};
  final Map<String, FloorStats> _floorStats = {};
  final List<DeviceData> _data = [];

  final GlobalKey<_InfraMapViewState> mapViewKey = GlobalKey();
  final GlobalKey<_InfraGridViewState> gridViewKey = GlobalKey();
  final GlobalKey<_InfraAssetViewState> assetViewKey = GlobalKey();

  @override
  void initState() {
    if (null != twinSysInfo && twinSysInfo!.bannerImage!.isNotEmpty) {
      bannerImage = UserSession()
          .getImage(domainKey, twinSysInfo!.bannerImage!, fit: BoxFit.cover);
    }
    super.initState();
  }

  @override
  void setup() async {
    await _load();
  }

  Future _loadData() async {
    if (loading) return;
    loading = true;

    await execute(() async {
      _data.clear();
      var res = await UserSession.twin.searchRecentDeviceData(
          apikey: UserSession().getAuthToken(),
          assetId: widget.asset?.id,
          floorId: widget.floor?.id,
          facilityId: widget.facility?.id,
          premiseId: widget.premise?.id,
          body: FilterSearchReq(search: search, page: 0, size: 1000));
      if (validateResponse(res)) {
        List<DeviceData> data = [];
        data.addAll(res.body!.values!);
        setState(() {
          _data.addAll(data);
        });
      }
    });

    loading = false;
  }

  Future _load() async {
    if (widget.currentView == CurrentView.grid) {
      return _loadData();
    }
    if (loading) return;
    loading = true;

    await execute(() async {
      switch (widget.type) {
        case TwinInfraType.premise:
          await _loadPremises();
          break;
        case TwinInfraType.facility:
          await _loadFacilities();
          break;
        case TwinInfraType.floor:
          await _loadFloors();
          break;
        case TwinInfraType.asset:
          await _loadAssets();
          break;
        case TwinInfraType.device:
          await _loadDevices();
          break;
      }
    });
    loading = false;
  }

  Future _loadPremises() async {
    List<Premise> entities = [];
    _premises.clear();

    var res = await UserSession.twin.searchPremises(
        apikey: UserSession().getAuthToken(),
        body: SearchReq(search: search, page: 0, size: 25));

    if (validateResponse(res)) {
      entities.addAll(res.body!.values!);

      for (var e in entities) {
        var sRes = await UserSession.twin.getPremiseStats(
            apikey: UserSession().getAuthToken(), premiseId: e.id);
        if (validateResponse(sRes)) {
          _premiseStats[e.id] = sRes.body!.entity!;
        }
      }

      refresh(sync: () {
        _premises.addAll(entities);
      });
    }
  }

  Future _loadFacilities() async {
    List<Facility> entities = [];
    _facilities.clear();

    var res = await UserSession.twin.searchFacilities(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.premise?.id,
        body: SearchReq(search: search, page: 0, size: 50));

    for (var e in entities) {
      var sRes = await UserSession.twin.getFacilityStats(
          apikey: UserSession().getAuthToken(), facilityId: e.id);
      if (validateResponse(sRes)) {
        _facilityStats[e.id] = sRes.body!.entity!;
      }
    }

    if (validateResponse(res)) {
      entities.addAll(res.body!.values!);
      refresh(sync: () {
        _facilities.addAll(entities);
      });
    }
  }

  Future _loadFloors() async {
    List<Floor> entities = [];
    _floors.clear();

    var res = await UserSession.twin.searchFloors(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.premise?.id,
        facilityId: widget.facility?.id,
        body: SearchReq(search: search, page: 0, size: 150));

    for (var e in entities) {
      var sRes = await UserSession.twin
          .getFloorStats(apikey: UserSession().getAuthToken(), floorId: e.id);
      if (validateResponse(sRes)) {
        _floorStats[e.id] = sRes.body!.entity!;
      }
    }

    if (validateResponse(res)) {
      entities.addAll(res.body!.values!);
      refresh(sync: () {
        _floors.addAll(entities);
      });
    }
  }

  Future _loadAssets() async {
    List<Asset> entities = [];
    _assets.clear();

    var res = await UserSession.twin.searchAssets(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.premise?.id,
        facilityId: widget.facility?.id,
        floorId: widget.floor?.id,
        body: SearchReq(search: search, page: 0, size: 50));

    if (validateResponse(res)) {
      entities.addAll(res.body!.values!);
      refresh(sync: () {
        _assets.addAll(entities);
      });
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required CurrentView currentView,
    required CurrentView targetView,
    required VoidCallback onPressed,
  }) {
    final isSelected = currentView == targetView;
    final iconColor = isSelected
        ? const Color(0xff501b1d)
        : Color(0XFF737273).withOpacity(.8);
    // final borderColor = isSelected ? Colors.white : const Color(0XFF263571);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: iconColor,
      ),
      iconSize: 28.0,
      padding: EdgeInsets.zero,
      splashRadius: 24.0,
      color: iconColor,
      tooltip: targetView.toString(),
      style: ButtonStyle(
        shape: MaterialStateProperty.all(const CircleBorder()),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        // side: MaterialStateProperty.all(BorderSide(color: borderColor)),
        // backgroundColor: MaterialStateProperty.resolveWith<Color>(
        //   (states) {
        //     if (states.contains(MaterialState.disabled)) {
        //       return const Color(0XFFA2E3C1);
        //     } else {
        //       return isSelected ? Color(0XFFCCCCCC) : Colors.red;
        //     }
        //   },
        // ),
      ),
    );
  }

  Future _loadDevices() async {
    List<Device> entities = [];
    _devices.clear();

    var res = await UserSession.twin.searchDevices(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.premise?.id,
        facilityId: widget.facility?.id,
        floorId: widget.floor?.id,
        assetId: widget.asset?.id,
        body: SearchReq(search: search, page: 0, size: 50));

    if (validateResponse(res)) {
      entities.addAll(res.body!.values!);
      refresh(sync: () {
        _devices.addAll(entities);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPremises = 0;
    int totalFacility = 0;
    int totalFloor = 0;
    int totalAsset = 0;
    int totalDevice = 0;
    if (widget.type == TwinInfraType.premise) {
      totalPremises = _premises.length;
    } else if (widget.type == TwinInfraType.facility) {
      totalFacility = _facilities.length;
    } else if (widget.type == TwinInfraType.floor) {
      totalFloor = _floors.length;
    } else if (widget.type == TwinInfraType.asset) {
      totalAsset = _assets.length;
    } else if (widget.type == TwinInfraType.device) {
      totalDevice = _devices.length;
    }

    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        // backgroundColor: const Color(0XFF737273).withOpacity(.8),
        backgroundColor: Colors.transparent,
        color: const Color(0XFFECDFF5),
        buttonBackgroundColor: const Color(0XFFECDFF5),
        height: 50,
        animationDuration: const Duration(milliseconds: 400),
        animationCurve: Curves.easeIn,
        index: widget.currentView.index,
        onTap: (index) {
          setState(() {
            widget.currentView = CurrentView.values[index];
          });
        },
        items: <Widget>[
          _buildIconButton(
            icon: Icons.home,
            currentView: widget.currentView,
            targetView: CurrentView.home,
            onPressed: () {
              setState(() {
                widget.currentView = CurrentView.home;
              });
            },
          ),
          _buildIconButton(
            icon: Icons.location_pin,
            currentView: widget.currentView,
            targetView: CurrentView.map,
            onPressed: () {
              setState(() {
                widget.currentView = CurrentView.map;
              });
            },
          ),
          _buildIconButton(
            icon: Icons.view_comfy_alt_rounded,
            currentView: widget.currentView,
            targetView: CurrentView.asset,
            onPressed: () {
              setState(() {
                widget.currentView = CurrentView.asset;
              });
            },
          ),
          _buildIconButton(
            icon: Icons.view_compact_outlined,
            currentView: widget.currentView,
            targetView: CurrentView.grid,
            onPressed: () {
              setState(() {
                widget.currentView = CurrentView.grid;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SizedBox(
          //   width: MediaQuery.of(context).size.width,
          //   height: 100,
          //   child: bannerImage,
          // ),
          // divider(),
          Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 90,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        // height: 40,
                        // width: 320,
                        child: SearchBar(
                          leading: const Icon(Icons.search),
                          hintText: 'Search',
                          onChanged: (value) async {
                            search = value;
                            if (search.isEmpty) {
                              search = '*';
                            }
                            switch (widget.currentView) {
                              case CurrentView.home:
                                await _load();
                                break;
                              case CurrentView.map:
                                await mapViewKey.currentState!._load();
                                break;
                              case CurrentView.asset:
                                await assetViewKey.currentState!._load();
                                break;
                              case CurrentView.grid:
                                await gridViewKey.currentState!._load();
                                break;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: IconButton(
                        tooltip: 'reload data',
                        onPressed: () async {
                          search = '*';
                          switch (widget.currentView) {
                            case CurrentView.home:
                              await _load();
                              break;
                            case CurrentView.map:
                              if (null != mapViewKey.currentState) {
                                await mapViewKey.currentState!._load();
                              }
                              break;
                            case CurrentView.asset:
                              if (null != assetViewKey.currentState) {
                                await assetViewKey.currentState!._load();
                              }
                              break;
                            case CurrentView.grid:
                              if (null != gridViewKey.currentState) {
                                await gridViewKey.currentState!._load();
                              }
                              break;
                          }
                        },
                        icon: const Icon(Icons.refresh)),
                  ),
                ],
              ),
              divider(horizontal: true),
              const Padding(
                padding: EdgeInsets.only(left: 190),
                child: Center(child: BusyIndicator()),
              ),
              const SizedBox(height: 10),
              if (widget.currentView == CurrentView.home)
                if (widget.type == TwinInfraType.premise)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total No of Premises: $totalPremises',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (widget.currentView == CurrentView.home)
                if (widget.type == TwinInfraType.facility)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total No of Facilities: $totalFacility',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (widget.currentView == CurrentView.home)
                if (widget.type == TwinInfraType.floor)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total No of Floors: $totalFloor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (widget.currentView == CurrentView.home)
                if (widget.type == TwinInfraType.asset)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total No of Assets: $totalAsset',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (widget.currentView == CurrentView.home)
                if (widget.type == TwinInfraType.device)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total No of Devices: $totalDevice',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          if (widget.currentView == CurrentView.home)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _InfraCardView(
                  page: widget,
                  state: this,
                ),
              ),
            ),
          if (widget.currentView == CurrentView.map)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _InfraMapView(
                  key: mapViewKey,
                  page: widget,
                  state: this,
                ),
              ),
            ),
          if (widget.currentView == CurrentView.asset)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _InfraAssetView(
                  key: assetViewKey,
                  page: widget,
                  state: this,
                ),
              ),
            ),
          if (widget.currentView == CurrentView.grid)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _InfraGridView(
                  key: gridViewKey,
                  page: widget,
                  state: this,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfraCardView extends StatefulWidget {
  final InfraPage page;
  final _InfraPageState state;

  const _InfraCardView({
    super.key,
    required this.page,
    required this.state,
  });

  @override
  State<_InfraCardView> createState() => _InfraCardViewState();
}

class _InfraCardViewState extends State<_InfraCardView> {
  @override
  Widget build(BuildContext context) {
    late final int count;

    switch (widget.page.type) {
      case TwinInfraType.premise:
        count = widget.state._premises.length;

        break;
      case TwinInfraType.facility:
        count = widget.state._facilities.length;

        break;
      case TwinInfraType.floor:
        count = widget.state._floors.length;

        break;
      case TwinInfraType.asset:
        count = widget.state._assets.length;

        break;
      case TwinInfraType.device:
        count = widget.state._devices.length;

        break;
    }

    if (count <= 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No data found'),
              divider(horizontal: true),
              const BusyIndicator(),
            ],
          )
        ],
      );
    }

    const double runSpacing = 4;
    const double spacing = 4;
    const columns = 4;
    final w = (MediaQuery.of(context).size.width - runSpacing * (columns - 1)) /
        columns;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            shrinkWrap: true,
            itemCount: count,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              switch (widget.page.type) {
                case TwinInfraType.premise:
                  return PremiseInfraCard(
                    premise: widget.state._premises[index],
                    totalPremises: count,
                  );
                case TwinInfraType.facility:
                  return FacilityInfraCard(
                    facility: widget.state._facilities[index],
                    totalFacilities: count,
                  );
                case TwinInfraType.floor:
                  return FloorInfraCard(
                    floor: widget.state._floors[index],
                  );
                case TwinInfraType.asset:
                  return AssetInfraCard(
                    asset: widget.state._assets[index],
                  );
                case TwinInfraType.device:
                  return DeviceInfraCard(
                    device: widget.state._devices[index],
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfraMapView extends StatefulWidget {
  final InfraPage page;
  final _InfraPageState state;

  const _InfraMapView({super.key, required this.page, required this.state});

  @override
  State<_InfraMapView> createState() => _InfraMapViewState();
}

class _InfraMapViewState extends BaseState<_InfraMapView> {
  final List<Marker> _markers = [];
  bool loading = false;
  late final Icon pin;

  @override
  void setup() async {
    await _load();
  }

  Future _load() async {
    if (loading) return;
    loading = true;
    _markers.clear();
    execute(() async {
      final Map<dynamic, GeoLocation> locations = {};
      switch (widget.page.type) {
        case TwinInfraType.premise:
          pin = const Icon(
            Icons.home,
            color: Colors.green,
          );
          for (var e in widget.state._premises) {
            if (null != e.location) {
              locations[e] = e.location!;
            }
          }
          debugPrint('${locations.length} geo premises found');
          break;
        case TwinInfraType.facility:
          pin = const Icon(
            Icons.business,
            color: Colors.green,
          );
          for (var e in widget.state._facilities) {
            if (null != e.location) {
              locations[e] = e.location!;
            }
          }
          debugPrint('${locations.length} geo facilities found');
          break;
        case TwinInfraType.floor:
          pin = const Icon(
            Icons.cabin,
            color: Colors.green,
          );
          for (var e in widget.state._floors) {
            if (null != e.location) {
              locations[e] = e.location!;
            }
          }
          debugPrint('${locations.length} geo floors found');
          break;
        case TwinInfraType.asset:
          pin = const Icon(
            Icons.view_comfy,
            color: Colors.green,
          );
          for (var e in widget.state._assets) {
            if (null != e.location) {
              locations[e] = e.location!;
            }
          }
          debugPrint('${locations.length} geo assets found');
          break;
        case TwinInfraType.device:
          pin = const Icon(
            Icons.view_compact_sharp,
            color: Colors.green,
          );
          for (var e in widget.state._devices) {
            if (null != e.geolocation) {
              locations[e] = e.geolocation!;
            }
          }
          debugPrint('${locations.length} geo devices found');
          break;
      }

      locations.forEach((entity, value) {
        if (null != value.coordinates && value.coordinates.length >= 2) {
          _markers.add(Marker(
              width: 200,
              height: 60,
              point: LatLng(value.coordinates[1], value.coordinates[0]),
              child: Tooltip(
                message: entity.name,
                child: InkWell(
                  onTap: () async {
                    showDialog(
                        useSafeArea: true,
                        context: context,
                        builder: (context) {
                          switch (widget.page.type) {
                            case TwinInfraType.premise:
                              return AlertDialog(
                                content: SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: PremiseInfraCard(
                                    premise: entity,
                                    popOnSelect: true,
                                    totalPremises:
                                        widget.state._premises.length,
                                  ),
                                ),
                              );
                            case TwinInfraType.facility:
                              return AlertDialog(
                                content: SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: FacilityInfraCard(
                                    facility: entity,
                                    popOnSelect: true,
                                    totalFacilities:
                                        widget.state._facilities.length,
                                  ),
                                ),
                              );
                            case TwinInfraType.floor:
                              return AlertDialog(
                                content: SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: FloorInfraCard(
                                    floor: entity,
                                    popOnSelect: true,
                                  ),
                                ),
                              );
                            case TwinInfraType.asset:
                              return AlertDialog(
                                content: SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: AssetInfraCard(
                                    asset: entity,
                                    popOnSelect: true,
                                  ),
                                ),
                              );
                            case TwinInfraType.device:
                              return AlertDialog(
                                content: SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: DeviceInfraCard(
                                    device: entity,
                                    popOnSelect: true,
                                  ),
                                ),
                              );
                          }
                        });
                  },
                  child: Column(
                    children: [
                      pin,
                      Text(
                        entity.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )));
        }
      });

      refresh();
    });
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        //initialCenter: LatLng(51.5, -0.09),
        initialZoom: 3,
        //onTap: (_, p) => setState(() => customMarkers.add(buildPin(p))),
        interactionOptions: InteractionOptions(),
      ),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(
          markers: _markers,
          rotate: false,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }
}

class _InfraAssetView extends StatefulWidget {
  final InfraPage page;
  final _InfraPageState state;

  const _InfraAssetView({super.key, required this.page, required this.state});

  @override
  State<_InfraAssetView> createState() => _InfraAssetViewState();
}

class _InfraAssetViewState extends BaseState<_InfraAssetView> {
  final List<String> _assetIds = [];

  @override
  void setup() {
    _load();
  }

  Future _load() async {
    if (loading) return;
    loading = true;

    await execute(() async {
      _assetIds.clear();

      var aRes = await UserSession.twin.getReportedAssetIds(
          apikey: UserSession().getAuthToken(), size: 10000);

      if (validateResponse(aRes)) {
        _assetIds.addAll(aRes.body!.values!);
      }
    });

    loading = false;
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_assetIds.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No data found'),
              divider(horizontal: true),
              const BusyIndicator(),
            ],
          )
        ],
      );
    }

    return SafeArea(
        child: SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        children: _assetIds.map((e) {
          return SizedBox(
            width: 500,
            height: 400,
            child: Card(
              elevation: 10,
              child: DefaultAssetView(
                twinned: UserSession.twin,
                assetId: e,
                authToken: UserSession().getAuthToken(),
                onAssetDoubleTapped: (DeviceData dd) async {},
                onAssetAnalyticsTapped: (DeviceData dd) async {},
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }
}

class _InfraGridView extends StatefulWidget {
  final InfraPage page;
  final _InfraPageState state;

  const _InfraGridView({super.key, required this.page, required this.state});

  @override
  State<_InfraGridView> createState() => _InfraGridViewState();
}

class Tuple<K, V> {
  final K key;
  final V value;

  Tuple({required this.key, required this.value});
}

class _InfraGridViewState extends BaseState<_InfraGridView> {
  bool loading = false;
  final Map<String, List<DeviceData>> _modelData = {};
  final List<AccordionSection> _sections = [];
  final Map<String, DeviceModel> _models = {};
  final Map<String, List<Tuple<String, String>>> _modelSortedFields = {};
  final Map<String, Map<String, Tuple<String, String>>> _modelFieldLabels = {};

  @override
  void setup() {
    _load();
  }

  Future _load() async {
    if (loading) return;
    loading = true;

    await execute(() async {
      _modelData.clear();
      _sections.clear();
      _models.clear();
      _modelSortedFields.clear();
      _modelFieldLabels.clear();

      var dRes = await UserSession.twin.searchRecentDeviceData(
          apikey: UserSession().getAuthToken(),
          body: FilterSearchReq(
              search: widget.state.search, page: 0, size: 1000));

      if (validateResponse(dRes)) {
        List<DeviceData> data = [];
        data.addAll(dRes.body!.values!);

        for (DeviceData dd in data) {
          List<DeviceData> mData = _modelData[dd.modelId!] ?? [];
          mData.add(dd);
          _modelData[dd.modelId] = mData;
          if (!_models.containsKey(dd.modelId)) {
            var mRes = await UserSession.twin.getDeviceModel(
                apikey: UserSession().getAuthToken(), modelId: dd.modelId);
            if (validateResponse(mRes)) {
              _models[dd.modelId] = mRes.body!.entity!;
            }
          }
        }
      }

      _models.forEach((id, model) {
        Map<String, Parameter> params = {};
        for (var p in model.parameters) {
          if (p.label!.contains(':')) {
            params[p.name] = p;
          }
        }
        var sorted = params.keys.toList()..sort();
        List<Tuple<String, String>> fields = [];
        Map<String, Tuple<String, String>> labels = {};

        for (String name in sorted) {
          Parameter p = params[name]!;
          int idx = p.label!.indexOf(':');
          String label = p.label!.substring(idx + 1);
          fields.add(Tuple(key: name, value: p.icon ?? ''));
          labels[name] =
              Tuple(key: null != p.unit ? '(${p.unit})' : '', value: label);
        }
        _modelSortedFields[id] = fields;
        _modelFieldLabels[id] = labels;
      });

      int idx = 0;
      _modelData.forEach((key, value) {
        List<Tuple<String, String>> fields = _modelSortedFields[key] ?? [];
        Map<String, Tuple<String, String>> labels =
            _modelFieldLabels[key] ?? {};
        AccordionSection section = AccordionSection(
            header: Text(
              _models[key]?.name ?? '-',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            isOpen: idx == 0,
            content: _buildTable(value, fields, labels));
        _sections.add(section);
        ++idx;
      });
    });

    loading = false;
    refresh();
  }

  Widget _buildTable(
    List<DeviceData> data,
    List<Tuple<String, String>> fields,
    Map<String, Tuple<String, String>> labels,
  ) {
    List<Widget> expansionTiles = [];

    for (var dd in data) {
      var dt = DateTime.fromMillisecondsSinceEpoch(dd.updatedStamp);
      Map<String, dynamic> dynData = dd.data as Map<String, dynamic>;

      List<Widget> fieldWidgets = [];
      for (Tuple<String, String> f in fields) {
        String label = labels[f.key]?.value ?? '-';
        String value = dynData[f.key]?.toString() ?? '-';
        fieldWidgets.add(
          Row(
            children: [
              Expanded(child: Text('$label: ')),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      expansionTiles.add(
        ExpansionTile(
          shape: const Border(bottom: BorderSide.none),
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceHistoryPage(
                        deviceName: dd.deviceName ?? '-',
                        deviceId: dd.deviceId,
                        modelId: dd.modelId,
                        adminMode: false,
                      ),
                    ),
                  );
                },
                child: Text(
                  dd.deviceName ?? '-',
                  style: const TextStyle(
                    color: Colors.blue,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              divider(horizontal: true, width: 20),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Infrastructure Info",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.close_outlined,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Premise : "),
                                ),
                                Expanded(
                                  child: Text(
                                    dd.premise ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Facility : "),
                                ),
                                Expanded(
                                  child: Text(
                                    dd.facility ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Floor : "),
                                ),
                                Expanded(
                                  child: Text(
                                    dd.floor ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Asset : "),
                                ),
                                Expanded(
                                  child: Text(
                                    dd.asset ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Assigned Devices : "),
                                ),
                                Expanded(
                                  child: Text(
                                    dd.deviceName ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: fieldWidgets,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Colors.grey,
                        size: 18,
                      ),
                      divider(horizontal: true),
                      Text(
                        timeago.format(dt, locale: 'en'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: expansionTiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No data found'),
              divider(horizontal: true),
              const BusyIndicator(),
            ],
          )
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 600,
        child: Accordion(
          maxOpenSections: 1,
          headerBorderColor: Colors.indigo,
          headerBorderColorOpened: Colors.transparent,
          // headerBorderWidth: 1,
          headerBackgroundColorOpened: Colors.green,
          contentBackgroundColor: Colors.white,
          contentBorderColor: Colors.green,
          contentBorderWidth: 3,
          contentHorizontalPadding: 20,
          scaleWhenAnimating: true,
          openAndCloseAnimation: true,
          headerPadding:
              const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
          sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
          sectionClosingHapticFeedback: SectionHapticFeedback.light,
          children: _sections,
        ),
      ),
    );
  }
}
