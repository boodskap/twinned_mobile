import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/common/busy_indicator.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_mobile/pages/homescreen/page_child.dart';
import 'package:twinned_mobile/pages/homescreen/page_infrastructure.dart';

class FacilityInfraCard extends StatefulWidget {
  final Facility facility;
  final bool popOnSelect;
  const FacilityInfraCard(
      {super.key,
      required this.facility,
      this.popOnSelect = false,
      required int totalFacilities});

  @override
  State<FacilityInfraCard> createState() => _FacilityInfraCardState();
}

class _FacilityInfraCardState extends BaseState<FacilityInfraCard> {
  static const Widget missingImage = Icon(
    Icons.question_mark,
    size: 150,
  );

  String premiseName = '';
  String floors = '';
  String assets = '';
  String devices = '';
  DeviceData? data;
  String reported = '-';
  Widget image = missingImage;

  @override
  void initState() {
    int sId = widget.facility.selectedImage ?? 0;
    sId = sId < 0 ? 0 : sId;
    if (widget.facility.images!.length > sId) {
      image = UserSession()
          .getImage(widget.facility.domainKey, widget.facility.images![sId]);
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
        premiseId: widget.facility.premiseId);

    if (validateResponse(pRes)) {
      premiseName = pRes.body!.entity!.name;
    }

    var res = await UserSession.twin.getFacilityStats(
        apikey: UserSession().getAuthToken(), facilityId: widget.facility.id);

    if (validateResponse(res)) {
      floors = '${res.body!.entity!.floors ?? 0} floors';
      assets = '${res.body!.entity!.assets ?? 0} assets';
      devices = '${res.body!.entity!.devices ?? 0} devices';
    }

    var ddRes = await UserSession.twin.searchRecentDeviceData(
        apikey: UserSession().getAuthToken(),
        facilityId: widget.facility.id,
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  size: 16,
                                  color: Color(0XFF26648e),
                                ),
                                divider(horizontal: true, width: 2),
                                Text(
                                  premiseName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0XFF5f236b),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Color(0XFF26648e),
                                ),
                                divider(horizontal: true, width: 2),
                                Text(
                                  widget.facility.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0XFF5f236b),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
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
        divider(),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildLink(floors, Icons.cabin, () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChildPage(
                                      title:
                                          '$premiseName - ${widget.facility.name} - Floors',
                                      child: InfraPage(
                                        type: TwinInfraType.floor,
                                        currentView: CurrentView.home,
                                        facility: widget.facility,
                                      ))),
                            );
                            _pop();
                          }),
                        ],
                      ),
                    ),
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
                      child: buildLink(assets, Icons.view_comfy, () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChildPage(
                                  title:
                                      '$premiseName - ${widget.facility.name} - Assets',
                                  child: InfraPage(
                                    type: TwinInfraType.asset,
                                    currentView: CurrentView.home,
                                    facility: widget.facility,
                                  ))),
                        );
                        _pop();
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Color(0XFFe5efc1),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: buildLink(devices, Icons.view_compact_sharp,
                          () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChildPage(
                                  title:
                                      '$premiseName - ${widget.facility.name} - Devices',
                                  child: InfraPage(
                                    type: TwinInfraType.device,
                                    currentView: CurrentView.home,
                                    facility: widget.facility,
                                  ))),
                        );
                        _pop();
                      }),
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
