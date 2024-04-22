import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/common/busy_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/pages/homescreen/page_child.dart';
import 'package:twinned_mobile/pages/homescreen/page_infrastructure.dart';

class PremiseInfraCard extends StatefulWidget {
  final Premise premise;
  final bool popOnSelect;
  final int totalPremises;
  const PremiseInfraCard(
      {super.key,
      required this.premise,
      this.popOnSelect = false,
      required this.totalPremises});

  @override
  State<PremiseInfraCard> createState() => _PremiseInfraCardState();
}

class _PremiseInfraCardState extends BaseState<PremiseInfraCard> {
  static const Widget missingImage = Icon(
    Icons.question_mark,
    size: 150,
  );

  String facilities = '';
  String floors = '';
  String assets = '';
  String devices = '';
  DeviceData? data;
  String reported = '-';
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
        // reported = '${timeago.format(dt, locale: 'en')}';
        reported = timeago.format(dt, locale: 'en');
      }
    }
    if (data == null) {
      reported = 'Not Reported';
    }

    refresh();
  }

  void _pop() {
    if (widget.popOnSelect) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
                          children: [
                            const Icon(
                              Icons.home,
                              color: Color(0XFF26648e),
                              size: 25,
                            ),
                            divider(horizontal: true, width: 2),
                            Text(
                              widget.premise.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0XFF5f236b),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
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
          // ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.timer,
                size: 18,
                color: reported == 'Not Reported' ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                reported,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: reported == 'Not Reported' ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Color.fromARGB(255, 245, 228, 234),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                        ],
                      ),
                    ),
                    divider(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Color(0XFFadeee2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
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
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Color(0XFFe5efc1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
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
            Expanded(
              child: Card(
                color: Color(0XFFffe3be),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
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
          ],
        ),
      ],
    );
  }
}
