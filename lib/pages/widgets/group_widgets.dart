import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:nocode_commons/widgets/common/busy_indicator.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/core/app_settings.dart';

class GroupAssets extends StatefulWidget {
  final AssetGroup group;

  const GroupAssets({super.key, required this.group});

  @override
  State<GroupAssets> createState() => _GroupAssetsState();
}

class _GroupAssetsState extends BaseState<GroupAssets> {
  final List<Asset> _assets = [];
  final List<Asset> _selected = [];

  @override
  void setup() async {
    await _search('*');
  }

  bool _isSelected(Asset asset) {
    return _selected.any((element) => element.id == asset.id);
  }

  Future _search(String search) async {
    if (loading) return;

    loading = true;
    await execute(() async {
      _assets.clear();
      var res = await UserSession.twin.searchAssets(
          apikey: UserSession().getAuthToken(),
          body: SearchReq(search: search, page: 0, size: 100));
      if (validateResponse(res)) {
        for (var asset in res.body!.values!) {
          if (widget.group.assetIds.contains(asset.id)) {
            _selected.add(asset);
          }
          if (!_isSelected(asset)) {
            _assets.add(asset);
          }
        }
        setState(() {});
      }
    });
    loading = false;
  }

  Widget _buildAsset(int idx) {
    return Tooltip(
      message:
          'Double click to associate ${_assets[idx].name} with ${widget.group.name}',
      child: InkWell(
        onDoubleTap: () {
          setState(() {
            _selected.add(_assets.removeAt(idx));
          });
        },
        child: Card(
          elevation: 5,
          child: Container(
            color: Colors.white,
            child: Stack(children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: Text(
                    _assets[idx].name,
                    style: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAsset(int idx) {
    return Card(
      elevation: 5,
      child: Container(
        color: Colors.white,
        child: Stack(children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _selected[idx].name,
                style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Tooltip(
              message: 'Disassociate from ${widget.group.name}',
              child: IconButton(
                  onPressed: () {
                    _disassociate(idx);
                  },
                  icon: const Icon(Icons.delete_forever)),
            ),
          ),
        ]),
      ),
    );
  }

  Future _save() async {
    await execute(() async {
      widget.group.assetIds.clear();
      for (var asset in _selected) {
        widget.group.assetIds.add(asset.id);
      }
      var res = await UserSession.twin.updateAssetGroup(
          apikey: UserSession().getAuthToken(),
          assetGroupId: widget.group.id,
          body: AssetGroupInfo(
              name: widget.group.name,
              description: widget.group.description,
              tags: widget.group.tags,
              target: AssetGroupInfoTarget.user,
              assetIds: widget.group.assetIds));
      if (validateResponse(res)) {
        await alert(widget.group.name, 'Saved successfully');
        _close();
      }
    });
  }

  Future _disassociate(int idx) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Column(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Colors.red, size: 30),
                divider(),
                const Text(
                  "Are you sure?",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                divider(),
                Text(
                  'You want to disassociate ${_selected[idx].name} with ${widget.group.name}?',
                  style: TextStyle(fontSize: 14),
                ),
                divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: const RoundedRectangleBorder(
                          // borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: primaryColor),
                        ),
                        minimumSize: const Size(100, 30),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: primaryColor,

                          // fontFamily:
                          //     UserSession().getTwinSysInfo()!.labelFont,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _assets.add(_selected.removeAt(idx));
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(100, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: UserSession.getLabelTextStyle()
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  // Future _disassociate(int idx) async {
  //   await confirm(
  //     title: 'Are you sure?',
  //     message:
  //         'You want to disassociate ${_selected[idx].name} with ${widget.group.name}?',
  //     onPressed: () {
  //       setState(() {
  //         _assets.add(_selected.removeAt(idx));
  //       });
  //     },
  //   );
  // }

  void _close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 90,
          child: Column(
            children: [
              // Align(
              // alignment: Alignment.topCenter,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Asset Group - ${widget.group.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  InkWell(
                    onTap: () {
                      _close();
                    },
                    child: const Icon(Icons.close_outlined,
                        color: Colors.teal, size: 20),
                  ),
                ],
              ),
              divider(),
              SizedBox(
                height: 30,
                child: Align(
                  alignment: Alignment.topRight,
                  child: SearchBar(
                    leading: const Icon(Icons.search),
                    onChanged: (search) async {
                      await _search(search);
                    },
                  ),
                ),
              ),
              divider(),
              const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Available Assets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  )),
              SingleChildScrollView(
                child: SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8),
                        itemCount: _assets.length,
                        itemBuilder: (ctx, idx) {
                          return _buildAsset(idx);
                        }),
                  ),
                ),
              ),
              divider(),
              const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Selected Assets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  )),
              SingleChildScrollView(
                child: SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8),
                        itemCount: _selected.length,
                        itemBuilder: (ctx, idx) {
                          return _buildSelectedAsset(idx);
                        }),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const BusyIndicator(),
              divider(horizontal: true),
              ElevatedButton(
                onPressed: () async {
                  await _save();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  // minimumSize: const Size(140, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: Text(
                  'Save',
                  style: UserSession.getLabelTextStyle()
                      .copyWith(color: Colors.black),
                ),
              ),
              divider(horizontal: true),
            ],
          ),
        )
      ],
    );
  }
}
