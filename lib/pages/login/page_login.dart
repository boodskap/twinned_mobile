import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/core/app_logo.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/pages/homescreen/page_homepage.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_mobile/widgets/commons/password_textfield.dart';
import 'package:twinned_mobile/widgets/commons/userid_textfield.dart';
import 'package:verification_api/api/verification.swagger.dart';

GlobalKey<FormState> gkeyUserId = GlobalKey();
GlobalKey<FormState> gkeyPassword = GlobalKey();

class LoginMobilePage extends StatefulWidget {
  final PageController pageController;
  const LoginMobilePage({super.key, required this.pageController});

  @override
  State<LoginMobilePage> createState() => _LoginMobilePageState();
}

class _LoginMobilePageState extends BaseState<LoginMobilePage> {
  final GlobalKey<_LoginMobilePageState> _key = GlobalKey();
  final formKey = GlobalKey<FormState>();
  // final textFieldFocusNode = FocusNode();

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController domainKeyController = TextEditingController();

  bool _rememberMe = false;

  GlobalKey<State<StatefulWidget>> getKey() {
    return _key;
  }

  @override
  void setup() async {
    String? user = await Constants.getString("saved.user", "");
    String? password = await Constants.getString("saved.password", "");
    bool? remember = await Constants.getBool("remember.me", _rememberMe);

    setState(() {
      _userController.text = user;
      _passwordController.text = password;
      _rememberMe = remember;
    });

    setTwinSysInfo();
  }

  void setTwinSysInfo() async {
    busy();

    try {
      String prefDK = await Constants.getString("domainKey", "");
      debugPrint('********************************');
      debugPrint("default domain $domainKey");
      debugPrint("cookie domain $prefDK");

      domainKey = prefDK.isNotEmpty ? prefDK : defaultDomainKey;
      debugPrint('selected domain $domainKey');
      debugPrint('********************************');

      var res = await UserSession.twin.getTwinSysInfo(domainKey: domainKey);

      if (validateResponse(res)) {
        UserSession().setTwinSysInfo(res.body!.entity!);
      }
    } catch (e) {
      alert('Error', e.toString());
    }

    busy(busy: false);
  }

  void _doLogin() async {
    busy();

    try {
      debugPrint('sysInfo ${UserSession().getTwinSysInfo()}');
      debugPrint("selected domain $domainKey");
      debugPrint(UserSession.vapi.client.baseUrl.toString());

      var user = _userController.text;
      var password = _passwordController.text;
      var body = Login(userId: user, password: password);
      debugPrint(body.toString());
      var res = await UserSession.vapi.loginUser(
        dkey: domainKey,
        body: body,
      );
      debugPrint(res.body.toString());
      if (res.body!.ok) {
        UserSession().setLoginResponse(res.body!);

        if (_rememberMe) {
          Constants.putString("saved.user", user);
          Constants.putString("saved.password", password);
          Constants.putBool("remember.me", true);
        } else {
          Constants.putString("saved.password", "");
          Constants.putBool("remember.me", false);
        }

        if (validateResponse(res)) {
          _showHome();
        }
      } else {
        alert("Invalid Credentials", "Email or Password is incorrect");

        List<String> errMsg = res.body!.msg.split(": ");
        if ('javax.naming.AuthenticationException' == errMsg[0]) {
          throw ArgumentError('Email or Password is incorrect', errMsg[0]);
        }
      }
    } on ArgumentError catch (e) {
      alert("Login Error", e.message);
    } catch (e, s) {
      List<String> exception = e.toString().split(": ");
      if ('ClientException' == exception[0]) {
        alert("Error", "Network is not reachable");
      } else {
        debugPrint(s.toString());
        log('Fatal error', time: DateTime.now(), error: e, stackTrace: s);
        // alert('Login Error', 'Unknown error: $e');
        alert("Error", "Network is not reachable");
      }
    }

    busy(busy: false);
  }

  void saveDomainsSettings() async {
    busy();

    try {
      String nDK = domainKeyController.text;
      var res = await UserSession.twin.getTwinSysInfo(domainKey: nDK);

      if (validateResponse(res)) {
        UserSession().setTwinSysInfo(res.body!.entity!);
        domainKey = nDK;
        await Constants.putString("domainKey", nDK);
      } else {
        alert('Error', res.body!.msg.toString());
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
      alert('Error', e.toString());
    }

    Navigator.of(context).pop();
    busy(busy: false);
  }

  void _showSettingsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        domainKeyController.text = domainKey;
        return AlertDialog(
          title: const Text('Enter Domain Key'),
          content: TextFormField(
            controller: domainKeyController,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.key,
              ),
              hintText: 'Enter domain key',
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: primaryColor),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: saveDomainsSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: secondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const HomePage(
          selectedPage: SelectedPage.myHome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () {
                        _showSettingsDialog();
                      },
                      child: const Icon(Icons.settings),
                    ),
                  ),
                  Center(
                    child: AppLogo(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                        // fontFamily: UserSession().getTwinSysInfo()!.headerFont,
                        fontSize: 30,
                        color: Colors.white),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 190,
                    child: Card(
                      color: Colors.white.withOpacity(0.8),
                      elevation: 10,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          UseridTextField(
                            hintText: "Enter your mail",
                            controller: _userController,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          PasswordTextField(
                            hintText: "Enter your password",
                            controller: _passwordController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                            ),
                            const Text(
                              'Remember Me',
                              style: TextStyle(
                                fontSize: 15,
                                // fontFamily:
                                // UserSession().getTwinSysInfo()!.labelFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        child: const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xff031b42),
                          ),
                        ),
                        onTap: () {
                          widget.pageController.jumpToPage(
                            4,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: primaryColor),
                          ),
                          minimumSize: const Size(140, 40),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            // fontFamily:
                            //     UserSession().getTwinSysInfo()!.labelFont,
                          ),
                        ),
                      ),
                      const BusyIndicator(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(140, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: secondaryColor),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            _doLogin();
                          }
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            color: secondaryColor,
                            // fontFamily:
                            //     UserSession().getTwinSysInfo()!.labelFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                            // fontFamily: UserSession().getTwinSysInfo()!.labelFont,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.pageController.jumpToPage(3);
                        },
                        child: const Text(
                          "SignUp",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Powered By",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 50,
                        child: Image.asset(
                          "assets/images/poweredby.png",
                          width: 150,
                          height: 50,
                        ),
                      ),
                      Expanded(
                        flex: 25,
                        child: Image.asset("assets/images/Logo-16.png",
                            height: 40, width: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
