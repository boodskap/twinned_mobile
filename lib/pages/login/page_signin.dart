import 'package:flutter/material.dart';
import 'package:twinned_mobile/pages/login/page_forgotpassword.dart';
import 'package:twinned_mobile/pages/login/page_forgotpasswordotp.dart';
import 'package:twinned_mobile/pages/login/page_login.dart';
import 'package:twinned_mobile/pages/login/page_reset_password.dart';
import 'package:twinned_mobile/pages/login/page_signup.dart';
import 'package:twinned_mobile/pages/login/page_verifyotp.dart';
import 'package:verification_api/api/verification.swagger.dart';

class NavigationControlMobile extends StatefulWidget {
  const NavigationControlMobile({
    Key? key,
    required Null Function() onCreateAccountPressed,
  });

  @override
  State<NavigationControlMobile> createState() =>
      _NavigationControlMobileState();
}

class _NavigationControlMobileState extends State<NavigationControlMobile> {
  late PageController _pageController;
  RegistrationRes? registrationRes;

  final eFormKey = GlobalKey<FormState>();
  final pFormKey = GlobalKey<FormState>();

  get userId => "defaultUserId";
  get pinToken => "defaultPinToken";
  get pin => "defaultPin";

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/splash_screen_bg.png'),
                  fit: BoxFit.cover),
            ),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                LoginMobilePage(pageController: _pageController),
                VerifyOtpMobilePage(
                  pageController: _pageController,
                  registrationRes: registrationRes,
                ),
                ResetPasswordMobilepage(
                  userId: userId,
                  pinToken: pinToken,
                  pin: pin,
                  pageController: _pageController,
                ),
                SignUpMobilePage(pageController: _pageController),
                ForgotPasswordMobilePage(pageController: _pageController),
                ForgotOtpMobilePage(
                  pageController: _pageController,
                  userId: userId,
                  pinToken: pinToken,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  static const String name = 'signin';
  const SignInPage({Key? key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var currentYear = DateTime.now().year;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: Column(
              children: [
                NavigationControlMobile(
                  onCreateAccountPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
