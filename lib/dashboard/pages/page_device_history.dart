import 'package:eventify/eventify.dart' as event;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/ui.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/util/nocode_utils.dart';
import 'package:nocode_commons/widgets/default_deviceview.dart';
import 'package:nocode_commons/widgets/device_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twinned_api/api/twinned.swagger.dart' as twin;
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/dashboard/pages/page_device_analytics.dart';
import 'package:twinned_mobile/pages/homescreen/page_homepage.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';

class DeviceHistoryPage extends StatefulWidget {
  final String deviceName;
  final String deviceId;
  final String modelId;
  final bool adminMode;
  const DeviceHistoryPage(
      {Key? key,
      required this.deviceName,
      required this.deviceId,
      required this.modelId,
      required this.adminMode})
      : super(key: key);

  @override
  State<DeviceHistoryPage> createState() => _DeviceHistoryPageState();
}

class _DeviceHistoryPageState extends BaseState<DeviceHistoryPage>
    with SingleTickerProviderStateMixin {
  twin.DeviceModel? deviceModel;
  final List<event.Listener> listeners = [];
  late Image bannerImage;
  final List<twin.DeviceData> data = [];
  final List<Widget> columns = [];
  final List<String> dataColumns = [];
  String search = "*";
  int selectedFilter = -1;
  int? beginStamp;
  int? endStamp;
  String? timeZoneName;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    bannerImage = Image.asset(
      'assets/images/ldashboard_banner.png',
      fit: BoxFit.cover,
    );

    listeners.add(BaseState.layoutEvents
        .on(PageEvent.twinMessageReceived.name, this, (e, o) {
      if (e.eventData == widget.deviceId) {
        if ('*' == search) {
          setup();
        }
      }
    }));
  }

  String fullName = '';

  @override
  void setup() async {
    await _load();
    try {
      var response = await UserSession.twin
          .getMyProfile(apikey: UserSession().getAuthToken());
      var res = response.body!.entity;
      debugPrint("DATA: $res");
      fullName = res!.name;
      String initials = getFirstLetterAndSpace(fullName);
      setState(() {
        initials = getFirstLetterAndSpace(fullName);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String getFirstLetterAndSpace(String fullName) {
    String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : '';
    int spaceIndex = fullName.indexOf(' ');
    if (spaceIndex != -1) {
      String secondLetter = fullName[spaceIndex + 1].toUpperCase();
      return '$firstLetter$secondLetter';
    } else {
      return firstLetter;
    }
  }

  void _navigateTo(String? menu, BuildContext context) {
    switch (menu ?? '') {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(
              selectedPage: SelectedPage.myProfile,
            ),
          ),
        );
        break;
    }
  }

  Future _load() async {
    if (loading) return;

    loading = true;

    await execute(() async {
      data.clear();

      twin.RangeFilter? filter;

      timeZoneName ??= DateTime.now().timeZoneName;

      switch (selectedFilter) {
        case -1:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.recent, tz: timeZoneName);
          break;
        case 0:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.today, tz: timeZoneName);
          break;
        case 1:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.yesterday, tz: timeZoneName);
          break;
        case 2:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.thisweek, tz: timeZoneName);
          break;
        case 3:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.lastweek, tz: timeZoneName);
          break;
        case 4:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.thismonth, tz: timeZoneName);
          break;
        case 5:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.lastmonth, tz: timeZoneName);
          break;
        case 6:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.thisquarter, tz: timeZoneName);
          break;
        case 7:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.thisyear, tz: timeZoneName);
          break;
        case 8:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.lastyear, tz: timeZoneName);
          break;
        case 9:
          filter = twin.RangeFilter(
              filter: twin.RangeFilterFilter.range,
              beginStamp: beginStamp,
              endStamp: endStamp,
              tz: timeZoneName);
          break;
      }

      var res = await UserSession.twin.searchDeviceHistoryData(
          apikey: UserSession().getAuthToken(),
          deviceId: widget.deviceId,
          body: twin.FilterSearchReq(
              search: search, filter: filter, page: 0, size: 100));
      if (validateResponse(res)) {
        data.addAll(res.body!.values!);
      }

      if (null == deviceModel) {
        var mRes = await UserSession.twin.getDeviceModel(
            apikey: UserSession().getAuthToken(), modelId: widget.modelId);
        if (validateResponse(mRes)) {
          deviceModel = mRes.body!.entity;
          var fields = NoCodeUtils.getSortedFields(deviceModel!);
          for (var p in fields) {
            dataColumns.add(p);
            columns.add(
              Expanded(
                child: Text(
                  NoCodeUtils.getParameterLabel(p, deviceModel!),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          }
        }
      }

      refresh();
    });

    loading = false;
  }

  @override
  void dispose() {
    for (event.Listener l in listeners) {
      BaseState.layoutEvents.off(l);
    }
    super.dispose();
  }

  void _changeFilter(int value) async {
    if (value == 9) {
      DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(DateTime.now().year - 5),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(
            start: DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day - 7),
            end: DateTime.now(),
          ),
          builder: (context, child) {
            return Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400.0,
                    maxHeight: 800.0,
                  ),
                  child: child,
                )
              ],
            );
          });
      if (null != picked) {
        selectedFilter = value;
        beginStamp = picked!.start.millisecondsSinceEpoch;
        endStamp = picked!.end.millisecondsSinceEpoch;
        timeZoneName = picked!.start.timeZoneName;
        setup();
      }
    } else {
      selectedFilter = value;
      setup();
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = getFirstLetterAndSpace(fullName);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F65AD),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.keyboard_double_arrow_left,
              color: Color(0XFFFFFFFF),
            )),
        title: Text(
          '${widget.deviceName} - History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: UserSession().getTwinSysInfo()!.subHeaderFont,
            color: secondaryColor,
          ),
        ),
        actions: [
          Row(
            children: [
              Tooltip(
                message: 'Profile',
                child: InkWell(
                  onTap: () {
                    _navigateTo('Profile', context);
                  },
                  child: CircleAvatar(
                    // backgroundColor: secondaryColor,
                    child: Text(
                      initials,
                      // style: const TextStyle(color: primaryColor),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Color(0XFFFFFFFF),
                  size: 18,
                ),
                onPressed: () {
                  UI().logout(context);
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // SizedBox(
          //   width: MediaQuery.of(context).size.width,
          //   height: 150,
          //   child: bannerImage,
          // ),
          Expanded(
            flex: 20,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const BusyIndicator(),
                    divider(horizontal: true),
                    IconButton(
                        onPressed: () async {
                          search = '*';
                          selectedFilter = -1;
                          await _load();
                        },
                        icon: const Icon(Icons.refresh)),
                    PopupMenuButton<int>(
                      initialValue: selectedFilter,
                      icon: const FaIcon(
                        FontAwesomeIcons.filter,
                        size: 18,
                      ),
                      itemBuilder: (context) {
                        return <PopupMenuEntry<int>>[
                          const PopupMenuItem<int>(
                            value: -1,
                            child: Text('Recent'),
                          ),
                          const PopupMenuItem<int>(
                            value: 0,
                            child: Text('Today'),
                          ),
                          const PopupMenuItem<int>(
                            value: 1,
                            child: Text('Yesterday'),
                          ),
                          const PopupMenuItem<int>(
                            value: 2,
                            child: Text('This Week'),
                          ),
                          const PopupMenuItem<int>(
                            value: 3,
                            child: Text('Last Week'),
                          ),
                          const PopupMenuItem<int>(
                            value: 4,
                            child: Text('This Month'),
                          ),
                          const PopupMenuItem<int>(
                            value: 5,
                            child: Text('Last Month'),
                          ),
                          const PopupMenuItem<int>(
                            value: 6,
                            child: Text('This Quarter'),
                          ),
                          const PopupMenuItem<int>(
                            value: 7,
                            child: Text('This Year'),
                          ),
                          const PopupMenuItem<int>(
                            value: 8,
                            child: Text('Last Year'),
                          ),
                          const PopupMenuItem<int>(
                            value: 9,
                            child: Text('Date Range'),
                          ),
                        ];
                      },
                      onSelected: (int value) {
                        _changeFilter(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _buildTableRows().length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: _buildTableRows()[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTableRows() {
    if (data.isEmpty) {
      return [
        Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            Text(loading ? 'Loading...' : 'No data')
          ],
        )
      ];
    }

    return data.map((data) {
      DateTime reportingStamp =
          DateTime.fromMillisecondsSinceEpoch(data.createdStamp);

      Map<String, dynamic> map = data.data as Map<String, dynamic>;

      final List<Widget> content = [];
      content.add(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${data.events.length}',
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Triggers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${data.triggers.length}',
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      for (int i = 0; i < dataColumns.length; i++) {
        var columnName = dataColumns[i];
        var dynValue = map[columnName] ?? '-';
        content.add(
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$columnName ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '$dynValue',
                      style: const TextStyle(overflow: TextOverflow.ellipsis),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }

      return ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Last Reported  ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            divider(horizontal: true),
            Text(timeago.format(reportingStamp, locale: 'en')),
          ],
        ),
        children: [
          SizedBox(
            height: 500,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: double.maxFinite,
                    child: Center(
                    child: DefaultDeviceView(
                        deviceData: data,
                        deviceId: data.deviceId,
                        twinned: UserSession.twin,
                        authToken: UserSession().getAuthToken(),
                        onDeviceAnalyticsTapped: (dd) async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeviceAnalyticsPage(
                                        data: data,
                                      )));
                        },
                        onDeviceDoubleTapped: (dd) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DeviceHistoryPage(
                                      deviceName: data.deviceName ?? '-',
                                      deviceId: data.deviceId,
                                      modelId: data.modelId,
                                      adminMode: true,
                                    )),
                          );
                        },
                      ),
                   
                      // child: SimpleDeviceView(
                      //   twinned: UserSession.twin,
                      //   authToken: UserSession().getAuthToken(),
                      //   data: data,
                      //   liveData: false,
                      //   height: 300,
                      //   topMenuHeight: 35,
                      //   bottomMenuHeight: 35,
                      //   onDeviceDoubleTapped: null,
                      //   onDeviceAnalyticsTapped: () async {
                      //     await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => DeviceAnalyticsPage(
                      //           data: data,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                   
                    ),
                  ),
                ),
                ...content,
              ],
            ),
          )
        ],
      );
    }).toList();
  }
}
