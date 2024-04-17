import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/ui.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/dashboard/pages/page_analytics.dart';
import 'package:twinned_mobile/dashboard/pages/page_dashboard.dart';
import 'package:twinned_mobile/dashboard/pages/page_devices_view.dart';
import 'package:twinned_mobile/dashboard/pages/page_map.dart';
import 'package:twinned_mobile/dashboard/pages/page_mydevice.dart';
import 'package:twinned_mobile/pages/homescreen/page_infrastructure.dart';
import 'package:twinned_mobile/pages/homescreen/page_myfilters.dart';
import 'package:twinned_mobile/pages/homescreen/page_profile.dart';
import 'package:twinned_mobile/pages/homescreen/page_subscription.dart';
import 'package:twinned_mobile/pages/page_event.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key, this.selectedPage = SelectedPage.myHome})
      : super(key: key);
  final SelectedPage selectedPage;
  @override
  Widget build(BuildContext context) {
    return MyHomePage(
      selectedPage: selectedPage,
      title: '',
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.selectedPage})
      : super(key: key);

  final String title;
  final SelectedPage selectedPage;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends BaseState<MyHomePage> {
  int currentIndex = 0;
  SelectedPage _selectedIndex = SelectedPage.myHome;
  final GlobalKey<ConvexAppBarState> _appBarKey =
      GlobalKey<ConvexAppBarState>();

  String fullName = '';

  void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedPage;
  }

  @override
  void setup() async {
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

  Widget _getPageAt(SelectedPage index) {
    switch (index) {
      case SelectedPage.myHome:
        return InfraPage(
          key: Key(const Uuid().v4()),
          type: TwinInfraType.premise,
          currentView: CurrentView.asset,
        );
      case SelectedPage.devices:
        return const MyDevicesPage();
      case SelectedPage.filters:
        return const MyFiltersPage();
      case SelectedPage.myDevices:
        return const DevicesViewPage();
      case SelectedPage.analyticsView:
        return const AnalyticsPage();
      case SelectedPage.gridView:
        return const GridViewPage();
      case SelectedPage.mapView:
        return const MapViewPage();
      case SelectedPage.myEvents:
        return const EventPage();
      case SelectedPage.subscription:
        return const SubscriptionsPage();
      case SelectedPage.myProfile:
        return const ProfilePage();
    }
  }

  void _onItemTapped(SelectedPage index) {
    setState(() {
      _selectedIndex = index;
      _appBarKey.currentState?.animateTo(index.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String subTitle;

    String initials = getFirstLetterAndSpace(fullName);
    switch (_selectedIndex) {
      case SelectedPage.myHome:
        subTitle = 'Home';
        break;
      case SelectedPage.myDevices:
        subTitle = 'My Devices';
        break;
      case SelectedPage.filters:
        subTitle = 'Filters';
        break;
      case SelectedPage.devices:
        subTitle = 'All Devices';
        break;
      case SelectedPage.analyticsView:
        subTitle = 'Analytics';
        break;
      case SelectedPage.gridView:
        subTitle = 'Grid View';
        break;
      case SelectedPage.mapView:
        subTitle = 'Map View';
        break;
      case SelectedPage.myEvents:
        subTitle = 'Events';
        break;
      case SelectedPage.subscription:
        subTitle = 'Subscription';
        break;
      case SelectedPage.myProfile:
        subTitle = 'My Profile';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text(
          'Digital Twin - $subTitle',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0XFFFFFFFF),
              fontFamily: UserSession().getTwinSysInfo()!.headerFont),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Image.asset('assets/images/logo-large.png'),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  _onItemTapped(SelectedPage.myProfile);
                },
                child: CircleAvatar(
                  child: Text(
                    initials,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  UI().logout(context);
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: _getPageAt(_selectedIndex),
      ),
      drawer: SafeArea(
        child: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xfffaf5f0),
                  Color(0xffdff5f7),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // const UserAccountsDrawerHeader(
                //   decoration: BoxDecoration(
                //     image: DecorationImage(
                //       image: AssetImage('assets/images/logo-large.png'),
                //     ),
                //   ),
                //   accountName: Text(''),
                //   accountEmail: Text(''),
                // ),
                SizedBox(
                  height: 120,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.clear)),
                      ),
                      CircleAvatar(
                        child: Text(
                          initials,
                        ),
                      ),
                      Text(fullName),
                    ],
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    selected: _selectedIndex == SelectedPage.myHome,
                    onTap: () {
                      _onItemTapped(SelectedPage.myHome);
                      Navigator.pop(context);
                    },
                  ),
                ),
                divider(),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.device_hub),
                    title: const Text('My Devices'),
                    selected: _selectedIndex == SelectedPage.devices,
                    onTap: () {
                      _onItemTapped(SelectedPage.devices);
                      Navigator.pop(context);
                    },
                  ),
                ),
                divider(),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.filter_alt_rounded),
                    title: const Text('Filters'),
                    selected: _selectedIndex == SelectedPage.filters,
                    onTap: () {
                      _onItemTapped(SelectedPage.filters);
                      Navigator.pop(context);
                    },
                  ),
                ),
                // ExpansionTile(
                //   leading: const Icon(Icons.admin_panel_settings),
                //   title: const Text('Admin'),
                //   children: [
                //     ListTile(
                //       leading: const Icon(Icons.devices_other),
                //       title: const Text('Devices'),
                //       selected: _selectedIndex == SelectedPage.myDevices,
                //       onTap: () {
                //         _onItemTapped(SelectedPage.myDevices);
                //         Navigator.pop(context);
                //       },
                //     ),
                //     ListTile(
                //       leading: const Icon(Icons.analytics_rounded),
                //       title: const Text('Analytics'),
                //       selected: _selectedIndex == SelectedPage.analyticsView,
                //       onTap: () {
                //         _onItemTapped(SelectedPage.analyticsView);
                //         Navigator.pop(context);
                //       },
                //     ),
                //     ListTile(
                //       leading: const Icon(Icons.grid_view),
                //       title: const Text('Grid View'),
                //       selected: _selectedIndex == SelectedPage.gridView,
                //       onTap: () {
                //         _onItemTapped(SelectedPage.gridView);
                //         Navigator.pop(context);
                //       },
                //     ),
                //     ListTile(
                //       leading: const Icon(Icons.location_on_rounded),
                //       title: const Text('Map View'),
                //       selected: _selectedIndex == SelectedPage.mapView,
                //       onTap: () {
                //         _onItemTapped(SelectedPage.mapView);
                //         Navigator.pop(context);
                //       },
                //     ),
                //   ],
                // ),
                divider(),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('My Events'),
                    selected: _selectedIndex == SelectedPage.myEvents,
                    onTap: () {
                      _onItemTapped(SelectedPage.myEvents);
                      Navigator.pop(context);
                    },
                  ),
                ),
                divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 5),
                  child: Text('Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.subscriptions_sharp),
                        title: const Text('Subscriptions'),
                        selected: _selectedIndex == SelectedPage.subscription,
                        onTap: () {
                          _onItemTapped(SelectedPage.subscription);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_2_sharp),
                        title: const Text('My Profile'),
                        selected: _selectedIndex == SelectedPage.myProfile,
                        onTap: () {
                          _onItemTapped(SelectedPage.myProfile);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                divider(),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      UI().logout(context);
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum SelectedPage {
  myHome,
  myDevices,
  filters,
  devices,
  analyticsView,
  gridView,
  myEvents,
  subscription,
  myProfile,
  mapView,
}
