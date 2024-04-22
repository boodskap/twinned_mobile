import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/common/busy_indicator.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_mobile/pages/homescreen/page_child.dart';
import 'package:twinned_mobile/pages/homescreen/page_infrastructure.dart';

class AssetInfraCard extends StatefulWidget {
  final Asset asset;
  final bool popOnSelect;
  const AssetInfraCard(
      {super.key, required this.asset, this.popOnSelect = false});

  @override
  State<AssetInfraCard> createState() => _AssetInfraCardState();
}

class _AssetInfraCardState extends BaseState<AssetInfraCard> {
  static const Widget missingImage = Icon(
    Icons.question_mark,
    size: 150,
  );

  String premiseName = '';
  String facilityName = '';
  String floorName = '';
  String devices = '';
  DeviceData? data;
  String reported = '-';
  Widget image = missingImage;

  @override
  void initState() {
    int sId = widget.asset.selectedImage ?? 0;
    sId = sId < 0 ? 0 : sId;
    if (widget.asset.images!.length > sId) {
      image = UserSession()
          .getImage(widget.asset.domainKey, widget.asset.images![sId]);
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
        premiseId: widget.asset.premiseId);

    if (validateResponse(pRes)) {
      premiseName = pRes.body!.entity!.name;
    }

    var fRes = await UserSession.twin.getFacility(
        apikey: UserSession().getAuthToken(),
        facilityId: widget.asset.facilityId);

    if (validateResponse(fRes)) {
      facilityName = fRes.body!.entity!.name;
    }

    var flRes = await UserSession.twin.getFloor(
        apikey: UserSession().getAuthToken(), floorId: widget.asset.floorId);

    if (validateResponse(flRes)) {
      floorName = flRes.body!.entity!.name;
    }

    devices = '${widget.asset.devices?.length ?? 0} devices';

    var ddRes = await UserSession.twin.searchRecentDeviceData(
        apikey: UserSession().getAuthToken(),
        assetId: widget.asset.id,
        body: const FilterSearchReq(search: '*', page: 0, size: 1));

    if (validateResponse(ddRes)) {
      if (ddRes.body!.values!.isNotEmpty) {
        data = ddRes.body!.values!.first;
        data = ddRes.body!.values!.first;
        var dt = DateTime.fromMillisecondsSinceEpoch(data!.updatedStamp);
        reported = timeago.format(dt, locale: 'en');
      }
    }
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
                            //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Row(
                            //       children: [
                            //         const Icon(
                            //           Icons.home,
                            //           size: 10,
                            //           color: Colors.blue,
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
                            //     divider(),
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
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                      color: Color(0XFF26648e),
                                    ),
                                    divider(horizontal: true, width: 2),
                                    Text(
                                      widget.asset.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Color(0XFF5f236b),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        divider(),
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
        divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Card(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             buildLink(devices, Icons.view_compact_sharp, () async {
            //               await Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                     builder: (context) => ChildPage(
            //                         title:
            //                             '$premiseName - $facilityName - $floorName - ${widget.asset.name} - Devices',
            //                         child: InfraPage(
            //                           type: TwinInfraType.device,
            //                           currentView: CurrentView.home,
            //                           asset: widget.asset,
            //                         ))),
            //               );
            //               _pop();
            //             }),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            Row(
              children: [
                const Icon(
                  Icons.view_compact_sharp,
                  size: 20,
                  color: Color(0XFF26648e),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChildPage(
                          title:
                              '$premiseName - $facilityName - $floorName - ${widget.asset.name} - Devices',
                          child: InfraPage(
                            type: TwinInfraType.device,
                            currentView: CurrentView.home,
                            asset: widget.asset,
                          ),
                        ),
                      ),
                    );
                    _pop();
                  },
                  child: Text(
                    devices,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0XFF5f236b),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
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
                      color:
                          reported == 'Not Reported' ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        divider(),
      ],
    );
  }
}
