import 'package:flutter/material.dart';
import 'package:nocode_commons/core/base_state.dart';
import 'package:nocode_commons/core/user_session.dart';
import 'package:twinned_api/api/twinned.swagger.dart';
import 'package:twinned_mobile/core/app_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: ProfilePage(),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends BaseState<ProfilePage> {
  late Image bannerImage;
  var twinUserId = "";
  String fullName = '';
  late String initials;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _webController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isEmailExpanded = false;
  bool _isNameExpanded = false;
  bool _isAddressExpanded = false;
  bool _isPhoneExpanded = false;
  bool _isWebExpanded = false;
  bool _isDescExpanded = false;

  @override
  void initState() {
    super.initState();

    String asset = 'assets/images/ldashboard_banner.png';
    bannerImage = Image.asset(
      asset,
      fit: BoxFit.fill,
    );
  }

  @override
  void setup() async {
    try {
      var response = await UserSession.twin.getMyProfile(
        apikey: UserSession().getAuthToken(),
      );
      var res = response.body!.entity;
      fullName = res!.name;
      setState(() {
        initials = getFirstLetterAndSpace(fullName);
      });

      setState(() {
        _emailController.text = response.body!.entity!.email ?? '';
        _nameController.text = response.body!.entity!.name ?? '';
        _addressController.text = response.body!.entity!.address ?? '';
        _phoneController.text = response.body!.entity!.phone ?? '';
        _descController.text = response.body!.entity!.description ?? '';
        twinUserId = response.body!.entity!.id;
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

  void updateProfile() async {
    busy();
    try {
      var res = await UserSession.twin.updateTwinUser(
        twinUserId: twinUserId,
        apikey: UserSession().getAuthToken(),
        body: TwinUserInfo(
          email: _emailController.text,
          name: _nameController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          description: _descController.text,
        ),
      );
      if (res.body!.ok) {
        alert('', 'Profile saved successfully!');
        setState(() {
          _emailController.text = _emailController.text;
          _nameController.text = _nameController.text;
          _addressController.text = _addressController.text;
          _phoneController.text = _phoneController.text;
          _webController.text = _webController.text;
          _descController.text = _descController.text;
        });
      } else {
        alert("Profile not Updated", res.body!.msg!);
      }
    } catch (e) {
      debugPrint(e.toString());
      alert('Error', e.toString());
    }
    busy(busy: false);
  }

  Future<void> _editPersonalDetails(BuildContext context) async {
    TextEditingController emailController =
        TextEditingController(text: _emailController.text);
    TextEditingController nameController =
        TextEditingController(text: _nameController.text);
    TextEditingController addressController =
        TextEditingController(text: _addressController.text);
    TextEditingController phoneController =
        TextEditingController(text: _phoneController.text);
    TextEditingController webController =
        TextEditingController(text: _webController.text);
    TextEditingController descController =
        TextEditingController(text: _descController.text);

    var result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Personal Details',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              divider(horizontal: true),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_outlined,
                  color: primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.email_outlined),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextFormField(
                        readOnly: true,
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.person_2_outlined),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.home_outlined),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.phone_android_outlined),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.link),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextField(
                        controller: webController,
                        decoration: const InputDecoration(labelText: 'Website'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 10,
                      child: Icon(Icons.description),
                    ),
                    divider(horizontal: true),
                    Expanded(
                      flex: 90,
                      child: TextField(
                        controller: descController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _emailController.text = emailController.text;
                  _nameController.text = nameController.text;
                  _addressController.text = addressController.text;
                  _phoneController.text = phoneController.text;
                  _webController.text = webController.text;
                  _descController.text = descController.text;
                });
                updateProfile();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: Text(
                'Save',
                style: UserSession.getLabelTextStyle()
                    .copyWith(color: secondaryColor),
              ),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _emailController.text = emailController.text;
        _nameController.text = nameController.text;
        _addressController.text = addressController.text;
        _phoneController.text = phoneController.text;
        _webController.text = webController.text;
        _descController.text = descController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = getFirstLetterAndSpace(fullName);
    return Column(
      children: [
        divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 35,
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  divider(),
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _editPersonalDetails(context);
                              },
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.teal,
                              ),
                            )
                          ],
                        ),
                      ),
                      Card(
                        elevation: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.withOpacity(0.1),
                                Colors.teal.withOpacity(0.2)
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            children: [
                              ExpansionTile(
                                trailing: _isEmailExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isEmailExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                shape: const Border(bottom: BorderSide.none),
                                expandedAlignment: Alignment.centerLeft,
                                children: [
                                  Text(
                                    _emailController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                trailing: _isNameExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isNameExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                expandedAlignment: Alignment.centerLeft,
                                shape: const Border(bottom: BorderSide.none),
                                children: [
                                  Text(
                                    _nameController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                trailing: _isAddressExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isAddressExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Address',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                expandedAlignment: Alignment.centerLeft,
                                shape: const Border(bottom: BorderSide.none),
                                children: [
                                  Text(
                                    _addressController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                trailing: _isPhoneExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isPhoneExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Phone',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                expandedAlignment: Alignment.centerLeft,
                                shape: const Border(bottom: BorderSide.none),
                                children: [
                                  Text(
                                    _phoneController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                trailing: _isWebExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isWebExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Website',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                expandedAlignment: Alignment.centerLeft,
                                shape: const Border(bottom: BorderSide.none),
                                children: [
                                  Text(
                                    _webController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                trailing: _isDescExpanded
                                    ? const Icon(Icons.expand_less)
                                    : const Icon(Icons.chevron_right),
                                onExpansionChanged: (bool isExpanded) {
                                  setState(() {
                                    _isDescExpanded = isExpanded;
                                  });
                                },
                                title: const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                childrenPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                expandedAlignment: Alignment.centerLeft,
                                shape: const Border(bottom: BorderSide.none),
                                children: [
                                  Text(
                                    _descController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
