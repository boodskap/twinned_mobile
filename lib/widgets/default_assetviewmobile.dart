import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/util/nocode_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart' as twin;
import 'package:twinned_mobile/core/app_settings.dart';

typedef OnAssetDoubleTapped = Future<void> Function(twin.DeviceData dd);
typedef OnAssetAnalyticsTapped = Future<void> Function(twin.DeviceData dd);

class DefaultMobileAssetView extends StatefulWidget {
  final twin.Twinned twinned;
  final String authToken;
  final String assetId;
  final OnAssetDoubleTapped onAssetDoubleTapped;
  final OnAssetAnalyticsTapped onAssetAnalyticsTapped;
  const DefaultMobileAssetView(
      {super.key,
      required this.twinned,
      required this.authToken,
      required this.assetId,
      required this.onAssetDoubleTapped,
      required this.onAssetAnalyticsTapped});

  @override
  State<DefaultMobileAssetView> createState() => _DefaultMobileAssetViewState();
}

class _DefaultMobileAssetViewState extends BaseState<DefaultMobileAssetView> {
  final List<Widget> _alarms = [];
  final List<Widget> _displays = [];
  final List<Widget> _controls = [];
  final List<Widget> _fields = [];
  final List<twin.DeviceData> _data = [];
  Widget image = const Icon(Icons.image);
  String title = '?';
  String info = '?';
  String reported = '-';

  @override
  void initState() {
    _alarms.add(
        const SizedBox(width: 45, height: 45, child: Icon(Icons.sensor_door)));
    _alarms.add(
        const SizedBox(width: 45, height: 45, child: Icon(Icons.sensor_door)));
    //_alarms.clear();
    _displays.addAll(_alarms);
    _controls.addAll(_alarms);
    _fields.addAll(_alarms);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  Center(
                                    child: Text(
                                      info,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                    )
                  ],
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Expanded(child: Center(child: image)),
                          ],
                        )),
                    Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Center(
                            child: Wrap(
                              spacing: 80,
                              children: _fields,
                            ),
                          ),
                        )),
                    divider(horizontal: true)
                  ],
                ),
              ),
            ),
            divider(),
            divider(),
            if (reported.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color:
                          reported == 'Not Reported' ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      reported,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: reported == 'Not Reported'
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future load() async {
    if (loading) return;
    loading = true;

    _alarms.clear();
    _displays.clear();
    _controls.clear();
    _fields.clear();
    _data.clear();

    refresh();

    await execute(() async {
      var res = await widget.twinned
          .getAsset(apikey: widget.authToken, assetId: widget.assetId);
      if (validateResponse(res)) {
        twin.Asset asset = res.body!.entity!;
        title = asset.name;
        String imageId =
            UserSession().getSelectImageId(asset.selectedImage, asset.images);
        image = UserSession().getImage(asset.domainKey, imageId);

        var dRes = await widget.twinned.searchRecentDeviceData(
            apikey: widget.authToken,
            assetId: widget.assetId,
            body:
                const twin.FilterSearchReq(search: '*', page: 0, size: 10000));

        if (validateResponse(dRes)) {
          _data.addAll(dRes.body!.values!);
        }
      }
      int lastReported = 0;

      for (twin.DeviceData dd in _data) {
        if (lastReported < dd.updatedStamp) {
          lastReported = dd.updatedStamp;
        }
        var res = await widget.twinned
            .getDeviceModel(apikey: widget.authToken, modelId: dd.modelId);
        if (validateResponse(res)) {
          twin.DeviceModel deviceModel = res.body!.entity!;
          var fields = NoCodeUtils.getSortedFields(deviceModel);

          for (String field in fields) {
            String icon = NoCodeUtils.getParameterIcon(field, deviceModel);
            String unit = NoCodeUtils.getParameterUnit(field, deviceModel);
            String label = NoCodeUtils.getParameterLabel(field, deviceModel);
            dynamic value = NoCodeUtils.getParameterValue(field, dd);
            late Widget image;

            if (icon.isEmpty) {
              image = const Icon(Icons.device_unknown_sharp);
            } else {
              image = SizedBox(
                  width: 20, child: UserSession().getImage(dd.domainKey, icon));
            }

            refresh(sync: () {
              _fields.add(
                Card(
                  elevation: 5,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.2),
                          Colors.teal.withOpacity(0.1)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        image,
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0XFF3D8C95),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [
                            Text('$value',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0XFF250C67),
                                )),
                            Text(unit,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0XFF250C67),
                                ))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
          }
        }
      }

      if (_data.isNotEmpty) {
        twin.DeviceData dd = _data.first;
        info = '${dd.premise} -> ${dd.facility} -> ${dd.floor}';
      }

      if (lastReported > 0) {
        var dt = DateTime.fromMillisecondsSinceEpoch(lastReported);
        reported = timeago.format(dt, locale: 'en');
      } else {
        reported = 'Not Reported';
      }

      refresh();
    });
    loading = false;
  }

  @override
  void setup() {
    load();
  }
}
