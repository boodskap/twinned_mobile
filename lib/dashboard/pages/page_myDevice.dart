import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/pages/homescreen/page_myassets.dart';
import 'package:twinned_mobile/pages/widgets/group_widgets.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';

class MyDevicesPage extends StatefulWidget {
  const MyDevicesPage({super.key});

  @override
  State<MyDevicesPage> createState() => _MyDevicesPageState();
}

class _MyDevicesPageState extends BaseState<MyDevicesPage> {
  final List<AssetGroup> _groups = [];

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
      _groups.clear();
      var res = await UserSession.twin.listAssetGroups(
          apikey: UserSession().getAuthToken(),
          myGroups: true,
          body: const ListReq(page: 0, size: 10000));
      if (validateResponse(res)) {
        setState(() {
          _groups.addAll(res.body!.values!);
        });
      }
      res = await UserSession.twin.listAssetGroups(
          apikey: UserSession().getAuthToken(),
          myGroups: false,
          body: const ListReq(page: 0, size: 10000));
      if (validateResponse(res)) {
        setState(() {
          _groups.addAll(res.body!.values!);
        });
      }
      if (_groups.isNotEmpty) {
        debugPrint(_groups.first.toString());
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

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              divider(),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Success',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'New Group added successfully!',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
              ),
            ],
          );
        });
  }

  Future _addNew() async {
    await _getBasicInfo(context, 'New Group',
        onPressed: (name, description, tags) async {
      var res = await UserSession.twin.createAssetGroup(
          apikey: UserSession().getAuthToken(),
          body: AssetGroupInfo(
              name: name,
              description: description,
              tags: (tags ?? '').split(' '),
              target: AssetGroupInfoTarget.user,
              assetIds: []));
    });
  }

  Future _editGroup(AssetGroup group) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            scrollable: true,
            title: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xfffaf5f0),
                    Color(0xffdff5f7),
                  ],
                ),
              ),
              width: MediaQuery.of(context).size.width,
              height: 600,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GroupAssets(
                  group: group,
                ),
              ),
            ),
          );
        });
    await _load();
  }

  // Future _deleteGroup(String id) async {
  //   showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Column(
  //             children: [
  //               const Icon(Icons.warning_amber_outlined,
  //                   color: Colors.red, size: 30),
  //               divider(),
  //               const Text(
  //                 "Are you sure?",
  //                 style: TextStyle(
  //                   color: Colors.red,
  //                 ),
  //               ),
  //               divider(),
  //               const Text(
  //                 "Deleting is unrecoverable",
  //                 style: TextStyle(fontSize: 14),
  //               ),
  //               divider(),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: secondaryColor,
  //                       shape: const RoundedRectangleBorder(
  //                         // borderRadius: BorderRadius.circular(20),
  //                         side: BorderSide(color: primaryColor),
  //                       ),
  //                       minimumSize: const Size(100, 30),
  //                     ),
  //                     onPressed: () {
  //                       Navigator.pop(context);
  //                     },
  //                     child: const Text(
  //                       "Cancel",
  //                       style: TextStyle(
  //                         color: primaryColor,

  //                         // fontFamily:
  //                         //     UserSession().getTwinSysInfo()!.labelFont,
  //                       ),
  //                     ),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () async {
  //                       await execute(() async {
  //                         var res = await UserSession.twin.deleteAssetGroup(
  //                             apikey: UserSession().getAuthToken(),
  //                             assetGroupId: id);
  //                         validateResponse(res);
  //                         await _load();
  //                       });
  //                       Navigator.pop(context);
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.red,
  //                       minimumSize: const Size(100, 30),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(3),
  //                       ),
  //                     ),
  //                     child: Text(
  //                       'Delete',
  //                       style: UserSession.getLabelTextStyle()
  //                           .copyWith(color: Colors.white),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         );
  //       });
  // }
  
  Future _deleteGroup(String id) async {
    await confirm(
        title: 'Warning',
        message: 'Deleting is unrecoverable\n\nDo you want to proceed?',
        titleStyle: const TextStyle(color: Colors.red),
        messageStyle: const TextStyle(fontWeight: FontWeight.bold),
        onPressed: () async {
          await execute(() async {
            var res = await UserSession.twin.deleteAssetGroup(
                apikey: UserSession().getAuthToken(), assetGroupId: id);
            validateResponse(res);
            await _load();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [];

    for (var group in _groups) {
      Widget? image;
      if (null != group.icon && group.icon!.isNotEmpty) {
        image = UserSession().getImage(group.domainKey, group.icon!);
      }
      cards.add(SizedBox(
          width: 200,
          height: 200,
          child: InkWell(
            onDoubleTap: group.assetIds.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MyAssetsPage(
                                group: group,
                              )),
                    );
                  },
            child: Card(
              elevation: 10,
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (null != image)
                            Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: image,
                                )),
                          divider(),
                          Align(
                              alignment: Alignment.center,
                              child: Tooltip(
                                  message: group.name,
                                  child: Text(
                                    group.name,
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ))),
                          divider(),
                          Text(
                            '${group.assetIds.length} assets',
                            style: TextStyle(
                                color: group.assetIds.isNotEmpty
                                    ? Colors.blue
                                    : null),
                          ),
                        ],
                      ),
                    ),
                    if (group.target == AssetGroupTarget.user)
                      Align(
                          alignment: Alignment.topRight,
                          child: Wrap(
                            children: [
                              IconButton(
                                  onPressed: () async {
                                    await _editGroup(group);
                                  },
                                  icon: const Icon(Icons.edit)),
                              IconButton(
                                  onPressed: () async {
                                    await _deleteGroup(group.id);
                                  },
                                  icon: const Icon(Icons.delete_forever)),
                            ],
                          )),
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
            ElevatedButton(
                onPressed: () async {
                  await _addNew();
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_box,
                      color: Colors.blue,
                    ),
                    divider(horizontal: true, width: 4),
                    const Text(
                      'Add New',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
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
        if (_groups.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: cards,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
