import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/custom/widgets/fillable_circle.dart';
import 'package:nocode_commons/custom/widgets/fillable_rectangle.dart';
import 'package:nocode_commons/widgets/common/busy_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/dashboard/pages/page_device_history.dart';

class DeviceInfraCard extends StatefulWidget {
  final Device device;
  final bool popOnSelect;
  const DeviceInfraCard(
      {super.key, required this.device, this.popOnSelect = false});

  @override
  State<DeviceInfraCard> createState() => _DeviceInfraCardState();
}

class _DeviceInfraCardState extends BaseState<DeviceInfraCard> {
  static const Widget missingImage = Icon(
    Icons.question_mark,
    size: 150,
  );

  String premiseName = '';
  String facilityName = '';
  String floorName = '';
  String assetName = '';
  DeviceData? data;
  String reported = '-';
  Widget image = missingImage;
  CustomWidget? customWidget;

  @override
  void initState() {
    if (null != widget.device.customWidget) {
      customWidget = widget.device.customWidget;
    } else {
      int sId = widget.device.selectedImage ?? 0;
      sId = sId < 0 ? 0 : sId;
      if (widget.device.images!.length > sId) {
        image = UserSession()
            .getImage(widget.device.domainKey, widget.device.images![sId]);
      }
    }
    super.initState();
  }

  @override
  void setup() async {
    await _load();
  }

  void _pop() {
    if (widget.popOnSelect) {
      Navigator.pop(context);
    }
  }

  Future _load() async {
    var pRes = await UserSession.twin.getPremise(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.device.premiseId);

    if (validateResponse(pRes)) {
      premiseName = pRes.body!.entity!.name;
    }

    var fRes = await UserSession.twin.getFacility(
        apikey: UserSession().getAuthToken(),
        facilityId: widget.device.facilityId);

    if (validateResponse(fRes)) {
      facilityName = fRes.body!.entity!.name;
    }

    var flRes = await UserSession.twin.getFloor(
        apikey: UserSession().getAuthToken(), floorId: widget.device.floorId);

    if (validateResponse(flRes)) {
      floorName = flRes.body!.entity!.name;
    }

    var aRes = await UserSession.twin.getAsset(
        apikey: UserSession().getAuthToken(), assetId: widget.device.assetId);

    if (validateResponse(aRes)) {
      assetName = aRes.body!.entity!.name;
    }

    var ddRes = await UserSession.twin.getDeviceData(
        apikey: UserSession().getAuthToken(),
        deviceId: widget.device.id,
        isHardwareDevice: false);

    if (validateResponse(ddRes)) {
      data = ddRes.body!.data!;
      var dt = DateTime.fromMillisecondsSinceEpoch(data!.updatedStamp);
      reported = timeago.format(dt, locale: 'en');
    }

    if (null == customWidget) {
      var mRes = await UserSession.twin.getDeviceModel(
          apikey: UserSession().getAuthToken(), modelId: widget.device.modelId);
      if (validateResponse(mRes)) {
        var dm = mRes.body!.entity!;
        customWidget = dm.customWidget;
        if (missingImage == image) {
          int sId = dm.selectedImage ?? 0;
          if (dm.images!.length > sId) {
            image = UserSession()
                .getImage(widget.device.domainKey, dm.images![sId]);
          }
        }
      }
    }

    if (null != customWidget && null != data) {
      Map<String, dynamic> attributes =
          customWidget!.attributes as Map<String, dynamic>;
      Map<String, dynamic> deviceData = {};
      if (null != data) {
        deviceData = data!.data as Map<String, dynamic>;
      }

      switch (ScreenWidgetType.values.byName(customWidget!.id)) {
        case ScreenWidgetType.fillableRectangle:
          image = SizedBox(
              width: 250,
              height: 250,
              child:
                  FillableRectangle(attributes: attributes, data: deviceData));
          break;
        case ScreenWidgetType.fillableCircle:
          image = SizedBox(
              width: 250,
              height: 250,
              child: FillableCircle(attributes: attributes, data: deviceData));
          break;
      }
    }

    image = InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DeviceHistoryPage(
                    deviceName: data!.deviceName ?? '-',
                    deviceId: data!.deviceId,
                    modelId: data!.modelId,
                    adminMode: false,
                  )),
        );
        _pop();
      },
      child: image,
    );
    if (data == null) {
      reported = 'Not Reported';
    }

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Card(
            elevation: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.2),
                    Colors.teal.withOpacity(0.1)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Row(
                            //       children: [
                            //         const Icon(
                            //           Icons.home,
                            //           color: Colors.blue,
                            //           size: 10,
                            //         ),
                            //         divider(horizontal: true, width: 2),
                            //         Text(
                            //           premiseName,
                            //           style: const TextStyle(
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 10,
                            //               color: Colors.blue,
                            //               overflow: TextOverflow.ellipsis),
                            //         ),
                            //       ],
                            //     ),
                            //     Row(
                            //       children: [
                            //         const Icon(
                            //           Icons.business,
                            //           size: 10,
                            //           color: Colors.blue,
                            //         ),
                            //         divider(horizontal: true, width: 2),
                            //         Text(
                            //           facilityName,
                            //           style: const TextStyle(
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 10,
                            //               color: Colors.blue,
                            //               overflow: TextOverflow.ellipsis),
                            //         ),
                            //       ],
                            //     ),
                            //   ],
                            // ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row(
                                //   children: [
                                //     const Icon(
                                //       Icons.cabin,
                                //       size: 10,
                                //       color: Colors.blue,
                                //     ),
                                //     divider(horizontal: true, width: 2),
                                //     Text(
                                //       floorName,
                                //       style: const TextStyle(
                                //           fontWeight: FontWeight.bold,
                                //           fontSize: 10,
                                //           color: Colors.blue,
                                //           overflow: TextOverflow.ellipsis),
                                //     ),
                                //   ],
                                // ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.view_comfy,
                                      size: 10,
                                      color: Colors.blue,
                                    ),
                                    divider(horizontal: true, width: 2),
                                    Text(
                                      assetName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Colors.blue,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        divider(),
                        Text(
                          widget.device.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  divider(),
                  Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Center(child: image),
                      )),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
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
                      color:
                          reported == 'Not Reported' ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
