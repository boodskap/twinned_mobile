import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/pages/homescreen/page_myassets.dart';

class MyFiltersPage extends StatefulWidget {
  const MyFiltersPage({super.key});

  @override
  State<MyFiltersPage> createState() => _MyFiltersPageState();
}

class _MyFiltersPageState extends BaseState<MyFiltersPage> {
  final List<DataFilter> _filters = [];

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
    await _load();
  }

  Future _load() async {
    if (loading) return;
    loading = true;
    await execute(() async {
      _filters.clear();
      var res = await UserSession.twin.listDataFilters(
          apikey: UserSession().getAuthToken(),
          body: const ListReq(page: 0, size: 10000));
      if (validateResponse(res)) {
        setState(() {
          _filters.addAll(res.body!.values!);
        });
      }
      if (_filters.isNotEmpty) {
        debugPrint(_filters.first.toString());
      }
    });
    loading = false;
  }

  Future<void> _getBasicInfo(BuildContext context, String title,
      {required BasicInfoCallback onPressed}) async {
    String? nameText = '';
    String? descText = '';
    String? tagsText = '';
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 500,
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        nameText = value;
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        descText = value;
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        tagsText = value;
                      });
                    },
                    decoration: const InputDecoration(
                        hintText: 'Tags (space separated)'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                color: Colors.grey,
                textColor: Colors.black,
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              MaterialButton(
                color: Colors.blue,
                textColor: Colors.white,
                child: const Text('OK'),
                onPressed: () {
                  if (nameText!.length < 3) {
                    alert('Invalid',
                        'Name is required and should be minimum 3 characters');
                    return;
                  }
                  setState(() {
                    onPressed(nameText!, descText, tagsText);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [];

    for (var filter in _filters) {
      Widget? image;
      if (null != filter.icon && filter.icon!.isNotEmpty) {
        image = UserSession().getImage(filter.domainKey, filter.icon!);
      }
      cards.add(SizedBox(
          width: 200,
          height: 200,
          child: InkWell(
            onDoubleTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MyAssetsPage(
                          filter: filter,
                        )),
              );
            },
            child: Card(
              elevation: 10,
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (null != image)
                      SizedBox(width: 48, height: 48, child: image),
                    if (null != image) divider(),
                    Text(
                      filter.name,
                      style: const TextStyle(overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          )));
    }

    return Column(
      children: [
        // SizedBox(
        //   width: MediaQuery.of(context).size.width,
        //   height: 100,
        //   child: bannerImage,
        // ),
        divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const BusyIndicator(),
            divider(horizontal: true),
            divider(horizontal: true),
            IconButton(
                tooltip: 'reload data',
                onPressed: () async {
                  await _load();
                },
                icon: const Icon(Icons.refresh)),
            divider(horizontal: true),
          ],
        ),
        divider(),
        if (_filters.isNotEmpty)
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              children: cards,
            ),
          ),
        if (_filters.isEmpty)
          const Align(
              alignment: Alignment.center, child: Text('No filter found')),
      ],
    );
  }
}
