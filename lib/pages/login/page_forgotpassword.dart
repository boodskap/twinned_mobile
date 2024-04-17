// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/core/app_logo.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_mobile/widgets/commons/userid_textfield.dart';
import 'package:verification_api/api/verification.swagger.dart';

GlobalKey<FormState> gkeyUserId = GlobalKey();

class ForgotPasswordMobilePage extends StatefulWidget {
  final PageController pageController;

  static const String name = 'forgotPassword';
  const ForgotPasswordMobilePage({super.key, required this.pageController});

  @override
  State<ForgotPasswordMobilePage> createState() =>
      _ForgotPasswordMobilePageState();
}

class _ForgotPasswordMobilePageState
    extends BaseState<ForgotPasswordMobilePage> {
  final TextEditingController _userEmail = TextEditingController();
  final GlobalKey<_ForgotPasswordMobilePageState> _key = GlobalKey();
  final formKey = GlobalKey<FormState>();

  GlobalKey<State<StatefulWidget>> getKey() {
    return _key;
  }

  @override
  void setup() async {
    String? userEmail = await Constants.getString("saved.userEmail", "");
    setState(() {
      _userEmail.text = userEmail;
    });
  }

  void _showForgotOtpPage(String userId, String pinToken) {
    widget.pageController.jumpToPage(
      5,
    );
  }

  void _showOTPDialog() {
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
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'OTP Sent Successfully',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '6 digit OTP has been sent to your email, Please check it!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: secondaryColor),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: secondaryColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _doChangePassEmail() async {
    busy();

    try {
      var userEmail = _userEmail.text;
      var body = ForgotPassword(
        userId: userEmail,
        subject: emailSubject,
        template: resetPswdTemplate,
      );

      var res = await UserSession.vapi.forgotPassword(
        dkey: domainKey,
        body: body,
      );

      if (res.body!.ok) {
        var dets = ResetPassword(
            userId: userEmail,
            password: "",
            pin: "",
            pinToken: res.body!.pinToken);
        UserSession().setRegisterDets(dets);
        _showOTPDialog();
        _showForgotOtpPage(body.userId, res.body!.pinToken);
      } else {
        alert("Error", res.body!.msg);
      }
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
    }
    busy(busy: false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AppLogo(),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    'Reset Your Password',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: Card(
                    color: Colors.white.withOpacity(0.8),
                    elevation: 5,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                          key: formKey,
                          child: UseridTextField(
                            hintText: "Enter your email",
                            controller: _userEmail,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        minimumSize: const Size(130, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: primaryColor),
                        ),
                      ),
                      onPressed: () {
                        widget.pageController.jumpToPage(
                          0,
                        );
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: primaryColor),
                      ),
                    ),
                    const BusyIndicator(width: 20, height: 20, padding: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(90, 35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: secondaryColor)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          _doChangePassEmail();
                        }
                      },
                      child: const Text(
                        'Generate OTP',
                        style: TextStyle(fontSize: 16, color: secondaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account ? ",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.pageController.jumpToPage(
                          3,
                        );
                      },
                      child: const Text(
                        "SignUp!",
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            decoration: TextDecoration.none),
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
    );
  }
}
