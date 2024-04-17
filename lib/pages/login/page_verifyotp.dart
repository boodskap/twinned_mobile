import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_mobile/core/app_logo.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/pages/login/page_forgotpasswordotp.dart';
import 'package:verification_api/api/verification.swagger.dart';

class VerifyOtpMobilePage extends StatefulWidget {
  final RegistrationRes? registrationRes;
  const VerifyOtpMobilePage({
    super.key,
    required this.pageController,
    required this.registrationRes,
  });
  final PageController pageController;
  @override
  State<VerifyOtpMobilePage> createState() => _VerifyOtpMobilePageState();
}

class _VerifyOtpMobilePageState extends BaseState<VerifyOtpMobilePage> {
  final GlobalKey<_VerifyOtpMobilePageState> _key = GlobalKey();

  TextEditingController pinController = TextEditingController();

  GlobalKey<State<StatefulWidget>> getKey() {
    return _key;
  }

  @override
  void setup() async {
    String? pin = await Constants.getString("saved.pin", "");
    setState(() {
      pinController.text = pin;
    });
  }

  void _doShowResetPassword(String userId, String pinToken, String pin) {
    widget.pageController.jumpToPage(
      2,
    );
  }

  void _doVerifyPin() async {
    busy();
    String pinToken = UserSession().getRegisterDets()?.pinToken ?? '';

    try {
      var body = VerificationReq(
        pinToken: pinToken,
        pin: pinController.text,
      );

      var res = await UserSession.vapi.verifyPin(
        dkey: domainKey,
        body: body,
      );

      if (res.body!.ok) {
        var dets = ResetPassword(
            userId: res.body!.user.email,
            pinToken: pinToken,
            pin: body.pin,
            password: "");
        UserSession().setRegisterDets(dets);
        _doShowResetPassword(
            res.body!.user.email, body.pinToken, pinController.text);
      } else {
        alert('Error', res.body!.msg);
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
              const SizedBox(
                height: 30,
              ),
              const Text(
                "Verify your OTP",
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(
                height: 40,
              ),
              OtpForm(pinController: pinController),
              const SizedBox(
                height: 60,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: primaryColor),
                        ),
                        minimumSize: const Size(130, 40),
                      ),
                      onPressed: () async {
                        widget.pageController.jumpToPage(
                          3,
                        );
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 20, color: primaryColor),
                      )),
                  const BusyIndicator(),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(130, 40),
                      ),
                      onPressed: () async {
                        if (pinController.text.isNotEmpty) {
                          if (pinController.text.length == 6) {
                            _doVerifyPin();
                          } else {
                            alert("Pin length mismatch", "");
                          }
                        } else {
                          alert("", "Pin required");
                        }
                      },
                      child: const Text(
                        'Verify',
                        style: TextStyle(fontSize: 20, color: secondaryColor),
                      )),
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
                  color: poweredByColor,
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
                  Expanded(
                    flex: 25,
                    child: Image.asset("assets/images/Platform-digitaltwin.png",
                        height: 40, width: 40),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
