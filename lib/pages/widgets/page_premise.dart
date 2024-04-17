import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_mobile/pages/homescreen/page_child.dart';
import 'package:twinned_mobile/pages/homescreen/page_infrastructure.dart';

class PremiseCard extends StatefulWidget {
  final Premise premise;
  final bool popOnSelect;
  const PremiseCard(
      {super.key, required this.premise, this.popOnSelect = false});

  @override
  State<PremiseCard> createState() => _PremiseCardState();
}

class _PremiseCardState extends BaseState<PremiseCard> {
  static const Widget missingImage = Icon(
    Icons.question_mark,
    size: 150,
  );

  String facilities = '';
  String floors = '';
  String assets = '';
  String devices = '';
  DeviceData? data;
  String reported = 'reported ?';
  Widget image = missingImage;
  @override
  void initState() {
    int sId = widget.premise.selectedImage ?? 0;
    sId = sId < 0 ? 0 : sId;
    if (widget.premise.images!.length > sId) {
      image = UserSession()
          .getImage(widget.premise.domainKey, widget.premise.images![sId]);
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
    var res = await UserSession.twin.getPremiseStats(
        apikey: UserSession().getAuthToken(), premiseId: widget.premise.id);
    if (validateResponse(res)) {
      facilities = '${res.body!.entity!.facilities ?? 0} facilities';
      floors = '${res.body!.entity!.floors ?? 0} floors';
      assets = '${res.body!.entity!.assets ?? 0} assets';
      devices = '${res.body!.entity!.devices ?? 0} devices';
    }
    var ddRes = await UserSession.twin.searchRecentDeviceData(
        apikey: UserSession().getAuthToken(),
        premiseId: widget.premise.id,
        body: const FilterSearchReq(search: '*', page: 0, size: 1));
    if (validateResponse(ddRes)) {
      if (ddRes.body!.values!.isNotEmpty) {
        data = ddRes.body!.values!.first;
        var dt = DateTime.fromMillisecondsSinceEpoch(data!.updatedStamp);
        reported = 'reported ${timeago.format(dt, locale: 'en')}';
      }
    }
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 5,
          child: Container(
            color: Colors.teal,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: image,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 5,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Facilities',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildLink(facilities, Icons.business, () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildPage(
                                    title:
                                        '${widget.premise.name} - Facilities',
                                    child: InfraPage(
                                      type: TwinInfraType.facility,
                                      currentView: CurrentView.home,
                                      premise: widget.premise,
                                    ),
                                  ),
                                ),
                              );
                              _pop();
                            }),
                          ],
                        ),
                      ),
                      divider(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 5,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'Floors',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            buildLink(floors, Icons.cabin, () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildPage(
                                    title: '${widget.premise.name} - Floors',
                                    child: InfraPage(
                                      type: TwinInfraType.floor,
                                      currentView: CurrentView.home,
                                      premise: widget.premise,
                                    ),
                                  ),
                                ),
                              );
                              _pop();
                            }),
                          ],
                        ),
                      ),
                      divider(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 5,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'Assets',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            buildLink(assets, Icons.view_comfy, () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildPage(
                                    title: '${widget.premise.name} - Assets',
                                    child: InfraPage(
                                      type: TwinInfraType.asset,
                                      currentView: CurrentView.home,
                                      premise: widget.premise,
                                    ),
                                  ),
                                ),
                              );
                              _pop();
                            }),
                          ],
                        ),
                      ),
                      divider(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 5,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'Devices',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            buildLink(devices, Icons.view_compact_sharp,
                                () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildPage(
                                    title: '${widget.premise.name} - Devices',
                                    child: InfraPage(
                                      type: TwinInfraType.device,
                                      currentView: CurrentView.home,
                                      premise: widget.premise,
                                    ),
                                  ),
                                ),
                              );
                              _pop();
                            }),
                          ],
                        ),
                      ),
                      divider(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      reported,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
