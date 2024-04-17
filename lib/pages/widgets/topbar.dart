import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/ui.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/pages/homescreen/page_homepage.dart';
import 'package:twinned_mobile/pages/homescreen/page_profile.dart';

class TopBar extends StatefulWidget {
  final String title;

  const TopBar({super.key, required this.title});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends BaseState<TopBar> {
  String fullName = '';

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

  @override
  Widget build(BuildContext context) {
    String initials = getFirstLetterAndSpace(fullName);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 70,
      color: primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Go back',
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.keyboard_double_arrow_left,
                  color: Colors.white,
                )),
          ),
          Expanded(
              child: Center(
            child: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: UserSession().getTwinSysInfo()!.subHeaderFont,
                color: secondaryColor,
              ),
            ),
          )),
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
              Tooltip(
                message: "Logout",
                child: IconButton(
                    onPressed: () {
                      UI().logout(context);
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 18,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
