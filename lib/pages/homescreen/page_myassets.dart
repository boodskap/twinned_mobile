import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/default_assetview.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/dashboard/pages/page_device_analytics.dart';
import 'package:twinned_mobile/dashboard/pages/page_device_history.dart';
import 'package:twinned_mobile/pages/widgets/topbar.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:uuid/uuid.dart';

typedef BasicInfoCallback = void Function(
    String name, String? description, String? tags);

enum AssetViewType { card, /*grid*/ }

class MyAssetsPage extends StatefulWidget {
  final AssetGroup? group;
  final DataFilter? filter;
  const MyAssetsPage({super.key, this.group, this.filter});

  @override
  State<MyAssetsPage> createState() => _MyAssetsPageState();
}

class _MyAssetsPageState extends BaseState<MyAssetsPage> {
  final List<DeviceData> _data = [];
  AssetViewType viewType = AssetViewType.card;

  Widget bannerImage = Image.asset(
    'assets/images/ldashboard_banner.png',
    fit: BoxFit.cover,
  );

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
    _load();
  }

  Future _load() async {
    if (null != widget.group) {
      await _loadData();
    } else {
      await _filterData();
    }
  }

  Future _loadData() async {
    if (loading) return;
    loading = true;
    await execute(() async {
      _data.clear();
      for (var assetId in widget.group!.assetIds) {
        var ddRes = await UserSession.twin.searchRecentDeviceData(
            apikey: UserSession().getAuthToken(),
            assetId: assetId,
            body: const FilterSearchReq(search: '*', page: 0, size: 1000));
        if (validateResponse(ddRes, shouldAlert: false)) {
          setState(() {
            viewType = AssetViewType.card;
            _data.addAll(ddRes.body!.values!);
          });
        }
      }
    });
    loading = false;
    setState(() {
      viewType = AssetViewType.card;
    });
  }

  Future _filterData() async {
    if (loading) return;
    loading = true;
    await execute(() async {
      _data.clear();
      var ddRes = await UserSession.twin.filterRecentDeviceData(
        apikey: UserSession().getAuthToken(),
        filterId: widget.filter!.id,
      );
      if (validateResponse(ddRes, shouldAlert: false)) {
        setState(() {
          viewType = AssetViewType.card;
          _data.addAll(ddRes.body!.values!);
        });
      }
    });
    loading = false;
    setState(() {
      viewType = AssetViewType.card;
    });
  }

  Widget _buildCards(BuildContext context) {
    final List<Widget> cards = [];
    final List<String> assetIds = [];

    if (null != widget.group) {
      assetIds.addAll(widget.group!.assetIds);
    } else {
      for (var dd in _data) {
        if (null == dd.assetId || dd.assetId!.isEmpty) continue;
        if (!assetIds.contains(dd.assetId!)) {
          assetIds.add(dd.assetId!);
        }
      }
    }

    for (var assetId in assetIds) {
      cards.add(SizedBox(
        width: 200,
        height: 400,
        child: DefaultAssetView(
            twinned: UserSession.twin,
            authToken: UserSession().getAuthToken(),
            assetId: assetId,
            onAssetDoubleTapped: (DeviceData dd) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DeviceHistoryPage(
                          deviceName: dd.deviceName ?? '-',
                          deviceId: dd.deviceId,
                          modelId: dd.modelId,
                          adminMode: false,
                        )),
              );
            },
            onAssetAnalyticsTapped: (DeviceData dd) async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DeviceAnalyticsPage(
                            data: dd,
                          )));
            }),
      ));
    }

    if (cards.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No data found'),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return cards[index];
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        null == widget.group ? widget.filter!.name : widget.group!.name;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(title: name),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 100,
              child: bannerImage,
            ),
            divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const BusyIndicator(),
                divider(horizontal: true),
                IconButton(
                    tooltip: 'reload data',
                    onPressed: () async {
                      switch (viewType) {
                        case AssetViewType.card:
                          setState(() {});
                        // case AssetViewType.grid:
                        //   await _load();
                        //   break;
                      }
                    },
                    icon: const Icon(Icons.refresh)),
                divider(horizontal: true),
                IconButton(
                    tooltip: 'Card View',
                    onPressed: viewType == AssetViewType.card
                        ? null
                        : () async {
                            setState(() {
                              viewType = AssetViewType.card;
                            });
                          },
                    icon: Icon(Icons.view_comfy,
                        color: viewType == AssetViewType.card
                            ? Colors.blue
                            : null)),
                divider(horizontal: true),
                // IconButton(
                //     tooltip: 'Data Grid View',
                //     onPressed: viewType == AssetViewType.grid
                //         ? null
                //         : () async {
                //             await _load();
                //           },
                //     icon: Icon(Icons.view_compact_outlined,
                //         color: viewType == AssetViewType.grid
                //             ? Colors.blue
                //             : null)),
                // divider(horizontal: true),
              ],
            ),
            divider(),
            if (viewType == AssetViewType.card) _buildCards(context),
            // if (viewType == AssetViewType.grid)
            //   AssetDataGridView(
            //     key: Key(const Uuid().v4()),
            //     group: widget.group,
            //     filter: widget.filter,
            //   ),
          ],
        ),
      ),
    );
  }
}

class AssetDataGridView extends StatefulWidget {
  final AssetGroup? group;
  final DataFilter? filter;
  const AssetDataGridView({super.key, this.group, this.filter});

  @override
  State<AssetDataGridView> createState() => _AssetDataGridViewState();
}

class Tuple<K, V> {
  final K key;
  final V value;

  Tuple({required this.key, required this.value});
}

class _AssetDataGridViewState extends BaseState<AssetDataGridView> {
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

      if (null != widget.group) {
        for (var assetId in widget.group!.assetIds) {
          var dRes = await UserSession.twin.searchRecentDeviceData(
              apikey: UserSession().getAuthToken(),
              assetId: assetId,
              body: const FilterSearchReq(search: '*', page: 0, size: 1000));

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
        }
      } else {
        var dRes = await UserSession.twin.filterRecentDeviceData(
            apikey: UserSession().getAuthToken(), filterId: widget.filter!.id);
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
                            )
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
                                ),
                              ],
                            ),
                          ],
                        ),
                        // actionsAlignment: MainAxisAlignment.end,
                        // actions: [
                        //   ElevatedButton(
                        //     onPressed: () {
                        //       Navigator.pop(context);
                        //     },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: primaryColor,
                        //       // minimumSize: const Size(140, 40),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(3),
                        //       ),
                        //     ),
                        //     child: Text(
                        //       'Close',
                        //       style: UserSession.getLabelTextStyle()
                        //           .copyWith(color: secondaryColor),
                        //     ),
                        //   ),
                        // ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
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
                      )
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
      return SizedBox(
        height: 250,
        child: Column(
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
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 500,
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
        ),
      ),
    );
  }
}
