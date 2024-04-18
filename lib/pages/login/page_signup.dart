import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/constants.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_mobile/widgets/commons/busy_indicator.dart';
import 'package:twinned_mobile/core/app_logo.dart';
import 'package:twinned_mobile/core/app_settings.dart';
import 'package:twinned_mobile/widgets/commons/userid_textfield.dart';
import 'package:twinned_mobile/widgets/commons/validate_textformfield.dart';
import 'package:verification_api/api/verification.swagger.dart';

class SignUpMobilePage extends StatefulWidget {
  const SignUpMobilePage({super.key, required this.pageController});
  final PageController pageController;
  @override
  State<SignUpMobilePage> createState() => _SignUpMobilePageState();
}

class _SignUpMobilePageState extends BaseState<SignUpMobilePage> {
  final GlobalKey<_SignUpMobilePageState> _key = GlobalKey();
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isLoading = false;
  double cardHeight = 230;

  final eFormKey = GlobalKey<FormState>();
  final pFormKey = GlobalKey<FormState>();

  GlobalKey<State<StatefulWidget>> getKey() {
    return _key;
  }

  @override
  void setup() async {
    String? fname = await Constants.getString("saved.fname", "");
    String? lname = await Constants.getString("saved.lname", "");
    String? email = await Constants.getString("saved.email", "");

    setState(() {
      _fnameController.text = fname;
      _lnameController.text = lname;
      _emailController.text = email;
    });
  }

  void _showOtpPage(RegistrationRes registrationRes) {
    widget.pageController.jumpToPage(1);
  }

  void _doSignUp() async {
    busy();
    try {
      var fname = _fnameController.text;
      var lname = _lnameController.text;
      var email = _emailController.text;

      var body = Registration(
        phone: "",
        email: email,
        roles: roles,
        subject: emailSubject,
        template: activationTemplate,
        fname: fname,
        lname: lname,
        properties: {},
      );

      var res = await UserSession.vapi.registerUser(
        dkey: domainKey,
        body: body,
      );

      if (res.body!.ok) {
        var dets = ResetPassword(
            userId: email, pinToken: res.body!.pinToken, pin: "", password: "");
        UserSession().setRegisterDets(dets);
        _showOtpPage(res.body!);
      } else {
        // ignore: use_build_context_synchronously
        updateCardHeight(true);
        alert('Error', res.body!.msg);
      }
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
    } finally {
      updateCardHeight(false);
      // ignore: use_build_context_synchronously
      busy(busy: false);
    }
  }

  void updateCardHeight(bool hasError) {
    setState(() {
      cardHeight = hasError ? 280 : 230;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(child: AppLogo()),
                const SizedBox(
                  height: 30,
                ),
                Form(
                  key: eFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          'Register New User',
                          style: TextStyle(
                              // fontFamily: UserSession().getTwinSysInfo()!.headerFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Colors.white),
                        ),
                      ),
                      Card(
                        color: Colors.white.withOpacity(0.8),
                        elevation: 10,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            UseridTextField(
                              hintText: "Enter your email",
                              controller: _emailController,
                            ),
                            const SizedBox(height: 5),
                            ValidatedTextFormField(
                                hintText: "Enter the firstname",
                                controller: _fnameController,
                                minLength: 1),
                            const SizedBox(height: 5),
                            ValidatedTextFormField(
                              hintText: "Enter the lastname",
                              controller: _lnameController,
                              minLength: 1,
                            ),
                            const SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                        onPressed: () {
                          debugPrint('Cancel pressed');
                          widget.pageController.jumpToPage(
                            0,
                          );
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            // fontFamily: UserSession().getTwinSysInfo()!.labelFont,
                            color: primaryColor,
                            fontSize: 18,
                          ),
                        )),
                    const BusyIndicator(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: secondaryColor)),
                        minimumSize: const Size(130, 40),
                      ),
                      onPressed: () {
                        if (eFormKey.currentState!.validate()) {
                          _doSignUp();
                        }
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          // fontFamily: UserSession().getTwinSysInfo()!.labelFont,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(
                  // fontFamily: UserSession().getTwinSysInfo()!.labelFont,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.pageController.jumpToPage(
                    0,
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    // fontFamily: UserSession().getTwinSysInfo()!.labelFont,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
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
    );
  }
}
