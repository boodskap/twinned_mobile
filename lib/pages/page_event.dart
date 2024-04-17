import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_api/api/twinned.swagger.dart' as twin;

class EventPage extends StatefulWidget {
  const EventPage({Key? key}) : super(key: key);

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends BaseState<EventPage> {
  late Image bannerImage;
  String search = "*";

  bool sortAscending = true;
  int _currentPage = 1;
  int _selectedRowsPerPage = 10;
  List<int> _rowsPerPageOptions = [10, 20, 50, 100];
  List<twin.TriggeredEvent> tableData = [];

  void _onRowsPerPageChanged(int? newRowsPerPage) {
    if (newRowsPerPage != null) {
      setState(() {
        _selectedRowsPerPage = newRowsPerPage;
        _currentPage = 1;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    bannerImage = Image.asset(
      'assets/images/ldashboard_banner.png',
      fit: BoxFit.cover,
    );
    setup();
  }

  void setup() async {
    if (search.trim().isEmpty) {
      search = '*';
    }
    try {
      var res = await UserSession.twin.seearchTriggeredEvents(
          apikey: UserSession().getAuthToken(),
          body: twin.FilterSearchReq(
              search: search, page: 0, filter: null, size: 100));

      if (validateResponse(res)) {
        setState(() {
          tableData = res.body!.values!;
        });
      }
    } catch (e, x) {
      debugPrint('$e');
      debugPrint('$x');
    }
  }

  void _updatePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    setup();
  }

  List<Widget> _getPageData(int startIndex, int endIndex) {
    int adjustedEndIndex = endIndex < _buildTableRows().length
        ? endIndex
        : _buildTableRows().length;

    return _buildTableRows().sublist(startIndex, adjustedEndIndex);
  }

  @override
  Widget build(BuildContext context) {
    int startIndex = (_currentPage - 1) * _selectedRowsPerPage;
    int endIndex = startIndex + _selectedRowsPerPage;

    List<Widget> currentPageData = _getPageData(startIndex, endIndex);

    currentPageData = currentPageData.asMap().entries.map((entry) {
      int index = entry.key;
      Widget eventData = entry.value;

      return eventData;
    }).toList();
    return Scaffold(
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
                    SizedBox(
                      width: 200,
                      height: 30,
                      child: SearchBar(
                          hintText: 'Search',
                          leading: const Icon(Icons.search),
                          onChanged: (String value) {
                            search = value.isEmpty ? '*' : value;
                            setup();
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.only(left: 4, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Icon',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Created Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Updated Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentPageData.length,
                    itemBuilder: (BuildContext context, int index) {
                      int overallIndex = startIndex + index;
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
                        child: _buildTableRows()[overallIndex],
                      );
                    },
                  ),
                ),
                CustomPagination(
                  total: _buildTableRows().length,
                  rowsPerPage: _selectedRowsPerPage,
                  currentPage: _currentPage,
                  onPageChanged: _updatePage,
                  onRowsPerPageChanged: _onRowsPerPageChanged,
                  rowsPerPageOptions: _rowsPerPageOptions,
                  selectedRowsPerPage: _selectedRowsPerPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTableRows() {
    List<twin.TriggeredEvent> last25Devices =
        tableData.sublist(max(0, tableData.length - 25));

    return last25Devices.map((data) {
      DateTime reportingStamp =
          DateTime.fromMillisecondsSinceEpoch(data.createdStamp);
      DateTime processedStamp =
          DateTime.fromMillisecondsSinceEpoch(data.updatedStamp);

      String reportingStampDate =
          DateFormat('MM/dd/yyyy h:mm a').format(reportingStamp);
      String processedStampDate =
          DateFormat('MM/dd/yyyy h:mm a').format(reportingStamp);

      Color stateColor = Colors.green;

      return ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.device_thermostat,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reportingStampDate.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      processedStampDate.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Column(
              children: [
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Name :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(data.name),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Type :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(data.eventType.value.toString()),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Delivery Status :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(data.deliveryStatus.value.toString()),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Email Subject :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('${data.emailSubject}'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Email Content :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('${data.emailContent}'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SMS :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('${data.smsMessage}'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'VOice :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('${data.voiceMessage}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }
}

class CustomPagination extends StatelessWidget {
  final int total;
  final int rowsPerPage;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onRowsPerPageChanged;
  final List<int> rowsPerPageOptions;
  final int selectedRowsPerPage;

  CustomPagination({
    required this.total,
    required this.rowsPerPage,
    required this.currentPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    required this.rowsPerPageOptions,
    required this.selectedRowsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    int totalPages = (total / rowsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: $total'),
          Row(
            children: [
              DropdownButton<int>(
                value: selectedRowsPerPage,
                items: rowsPerPageOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: onRowsPerPageChanged,
              ),
              SizedBox(width: 16.0),
              Text('Page $currentPage of $totalPages'),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
