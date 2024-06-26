// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:pinput/pinput.dart';
import 'package:twinned_mobile/core/app_logo.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:verification_api/api/verification.swagger.dart';

class ForgotOtpMobilePage extends StatefulWidget {
  final String userId;
  final String pinToken;
  final PageController pageController;

  const ForgotOtpMobilePage({
    super.key,
    required this.pinToken,
    required this.userId,
    required this.pageController,
  });

  @override
  State<ForgotOtpMobilePage> createState() => _ForgotOtpMobilePageState();
}

class _ForgotOtpMobilePageState extends BaseState<ForgotOtpMobilePage> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _conPassController = TextEditingController();
  bool isObscured = true;
  bool isObscurednew = true;
  bool isLoading = false;

  final formKey = GlobalKey<FormState>();

  GlobalKey<State<StatefulWidget>> getKey() {
    return _key;
  }

  @override
  void setup() async {
    String? pin = await Constants.getString("pin", "");
    String? newPass = await Constants.getString("newPass", "");
    String? conPass = await Constants.getString("conPass", "");

    setState(() {
      _pinController.text = pin;
      _newPassController.text = newPass;
      _conPassController.text = conPass;
    });
  }

  void _showLogin() {
    widget.pageController.jumpToPage(
      0,
    );
  }

  void _showPasswordSuccessDialog() {
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
                'Password Changed Successfully!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                    borderRadius: BorderRadius.circular(18),
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

  void _doEnterPass() async {
    busy();

    try {
      var pin = _pinController.text;
      var conPass = _conPassController.text;

      String pinToken = UserSession().getRegisterDets()?.pinToken ?? '';
      String userId = UserSession().getRegisterDets()?.userId ?? '';

      final ResetPassword body = ResetPassword(
        userId: userId,
        pinToken: pinToken,
        pin: pin,
        password: conPass,
      );
      var res = await UserSession.vapi.resetPassword(
        dkey: domainKey,
        body: body,
      );

      if (res.body!.ok) {
        // alert("", "Password changed successfully");
        _showPasswordSuccessDialog();
        _showLogin();
      } else {
        alert(
          "Password not changed",
          res.body!.msg,
        );
      }
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
    }
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
                height: 10,
              ),
              const Text(
                'OTP And Password',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white),
              ),
              OtpForm(
                pinController: _pinController,
              ),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: TextFormField(
                        controller: _newPassController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isObscurednew = !isObscurednew;
                              });
                            },
                            icon: isObscurednew
                                ? const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                          ),
                          border: const OutlineInputBorder(),
                          hintText: "Enter New Password",
                        ),
                        obscureText: isObscurednew,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "New Password Required";
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: TextFormField(
                        controller: _conPassController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isObscured = !isObscured;
                              });
                            },
                            icon: isObscured
                                ? const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                          ),
                          border: const OutlineInputBorder(),
                          hintText: "Enter Confirm Password",
                        ),
                        obscureText: isObscured,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Confirm Password Required";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: secondaryColor)),
                  minimumSize: const Size(355, 50),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (_newPassController.text == _conPassController.text) {
                      if (_pinController.text.isNotEmpty) {
                        if (_pinController.text.length == 6) {
                          _doEnterPass();
                        } else {
                          alert("Pin length mismatch", "");
                        }
                      } else {
                        alert("", "Pin required");
                      }
                    } else {
                      alert("Password mismatch", "");
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 16,
                        ),
                      ),
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

class OtpForm extends StatelessWidget {
  final TextEditingController pinController;

  const OtpForm({super.key, required this.pinController});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 40,
      height: 40,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Pinput(
                controller: pinController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(
                      color: const Color(0Xff375ee9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
