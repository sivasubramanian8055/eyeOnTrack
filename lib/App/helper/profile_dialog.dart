import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypoexchange/App/data/auth_data.dart';
import 'package:crypoexchange/App/helper/app_paths.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../routes/app_pages.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  bool checkAwareness = false;
  bool notifyRewards = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load preferences from Firestore and update UI state.
  Future<void> _loadPreferences() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userLoginModel!.id)
          .get();
      if (docSnapshot.exists) {
        final Map<String, dynamic>? prefs =
            (docSnapshot.data() ?? {})['preferences'] as Map<String, dynamic>?;
        if (prefs != null) {
          setState(() {
            checkAwareness = prefs['checkAwareness'] ?? false;
            notifyRewards = prefs['notifyRewards'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  // Update preferences in Firestore.
  Future<void> _updatePreferences() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userLoginModel!.id)
          .update({
        'preferences': {
          'checkAwareness': checkAwareness,
          'notifyRewards': notifyRewards,
        }
      });
    } catch (e) {
      debugPrint("Error updating preferences: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.all(15),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top AppBar
                    AppBar(
                      automaticallyImplyLeading: false,
                      // Add some left padding to the leading to create space
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _historyButton(context),
                      ),
                      leadingWidth: 80,
                      toolbarHeight: 40,
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      title: myText(
                        title: 'Profile',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      actions: [
                        // Add some right padding to the close icon
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => Get.back(),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.grey.withOpacity(0.6),
                              child: const Icon(
                                Icons.clear,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),

                    // A small gap below the AppBar
                    const SizedBox(height: 10),

                    // Row with Profile Icon (left) and Number (next to it)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.blueGrey,
                            size: 30,
                          ),
                        ),
                        const SizedBox(
                            width: 10), // Space between icon and number
                        myText(
                          title: userLoginModel!.mobileNumber.toString(),
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Preferences heading
                    Align(
                      alignment: Alignment.centerLeft,
                      child: myText(
                        title: "Preferences",
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Toggle: Check Awareness
                    SwitchListTile(
                      title: myText(
                        title: "Check Awareness during walking",
                        color: Colors.black,
                      ),
                      value: checkAwareness,
                      onChanged: (value) {
                        setState(() {
                          checkAwareness = value;
                        });
                        _updatePreferences();
                      },
                    ),

                    // Toggle: Inform rewards
                    SwitchListTile(
                      title: myText(
                        title: "Inform rewards through notification",
                        color: Colors.black,
                      ),
                      value: notifyRewards,
                      onChanged: (value) {
                        setState(() {
                          notifyRewards = value;
                        });
                        _updatePreferences();
                      },
                    ),

                    const SizedBox(height: 15),

                    // Log Out button
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(Colors.red),
                      ),
                      onPressed: () {
                        List<Map<String, dynamic>> empty = [];
                        setuserLoginModel(null).whenComplete(() {
                          setuserHazardModelFromPF(empty).whenComplete(() {
                            userLoginModel = null;
                            hazardListHistory.clear();
                            Get.offAllNamed(Routes.LOGIN);
                          });
                        });
                      },
                      child: myText(
                        title: 'Log Out',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
  }

  // History button in the AppBar.
  _historyButton(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () {
          Get.back();
          Get.dialog(const HazardHistoryVi());
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: myText(
            title: 'History',
            color: Theme.of(context).primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

// ---------------------------------------------------------------------
// Below are the other classes you provided (unchanged except for imports).
// ---------------------------------------------------------------------

class HazardHistoryVi extends StatefulWidget {
  const HazardHistoryVi({super.key});

  @override
  State<HazardHistoryVi> createState() => _HazardHistoryViState();
}

class _HazardHistoryViState extends State<HazardHistoryVi> {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  int yourPointCoin = 0;
  int _initialTab = 0;

  _selectedTab(int position) {
    setState(() {
      _initialTab = position;
    });
  }

  @override
  void initState() {
    super.initState();
    _refres();
  }

  _refres() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: AppBar(
              leading: _totalCoinUI(context),
              automaticallyImplyLeading: false,
              leadingWidth: 70,
              toolbarHeight: 40,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: myText(
                title: 'History',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
              actions: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Get.back(),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.grey.withOpacity(0.6),
                    child: const Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectedTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: _initialTab == 0
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    child: myText(
                      title: 'History',
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectedTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: _initialTab == 1
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    child: myText(
                      title: 'Leaderboard',
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 15),
          Expanded(
            child: _initialTab == 0 ? _historyUI() : _leaderBoardUI(),
          )
        ],
      ),
    );
  }

  _historyUI() => FutureBuilder(
        future: firestore
            .collection('users')
            .doc(userLoginModel?.id)
            .collection('reword')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data found.'));
          } else {
            var documents = snapshot.data!.docs;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  if (_initialTab == 0) {
                    yourPointCoin = 0;
                    for (var data in documents) {
                      int coin = data['coin'];
                      yourPointCoin += coin;
                    }
                  }
                  var document = documents[index].data();
                  return _cardUI(document, context);
                },
              ),
            );
          }
        },
      );

  _leaderBoardUI() => FutureBuilder(
        future: firestore.collection('leaderboard').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data found.'));
          } else {
            var documents = snapshot.data!.docs;

            // Sort documents by 'coin' in descending order
            documents.sort((a, b) {
              int coinA = a.data()['coin'];
              int coinB = b.data()['coin'];
              return coinB.compareTo(coinA);
            });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  var document = documents[index].data();
                  return _cardUI(document, context);
                },
              ),
            );
          }
        },
      );

  _cardUI(data, BuildContext context) => ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_initialTab == 1)
              myText(
                title:
                    "${userLoginModel!.id.toString() == data['id'].toString() ? "You" : 'User Id'}: " +
                        data['id'].toString(),
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            myText(
              title: data['title'].toString(),
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            myText(
              title: data['locality'],
              color: Colors.black38,
              fontSize: 14.2,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(width: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 3),
                myText(
                  title: _formateTime(data['time']),
                  fontSize: 13.2,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          children: [
            Image.asset(
              'assets/coin.png',
              height: 30,
              width: 30,
              fit: BoxFit.cover,
            ),
            myText(
              title: data['coin'].toString(),
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            )
          ],
        ),
      );

  String _formateTime(String time) {
    DateTime dateTime = DateTime.parse(time);
    DateFormat dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    String formattedDate = dateFormat.format(dateTime);
    return formattedDate;
  }

  _totalCoinUI(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset(
            'assets/coin.png',
            height: 30,
            width: 30,
            fit: BoxFit.cover,
          ),
          myText(
            title: yourPointCoin.toString(),
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          )
        ],
      ),
    );
  }
}

class GuestHazardHistoryView extends StatelessWidget {
  const GuestHazardHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: AppBar(
              leading: _totalCoinUI(context),
              automaticallyImplyLeading: false,
              leadingWidth: 70,
              toolbarHeight: 40,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: myText(
                title: 'History',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
              actions: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Get.back(),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.grey.withOpacity(0.6),
                    child: const Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hazardListHistory.isEmpty
                ? Center(
                    child: myText(
                      title: 'No History Found',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  )
                : ListView.builder(
                    itemCount: hazardListHistory.length,
                    itemBuilder: (ctx, i) {
                      var data = hazardListHistory[i];
                      return _cardUI(data, context);
                    },
                  ),
          )
        ],
      ),
    );
  }

  _cardUI(data, BuildContext context) => ListTile(
        title: myText(
          title: data['title'].toString(),
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            myText(
              title: data['locality'],
              color: Colors.black38,
              fontSize: 14.2,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(width: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 3),
                myText(
                  title: _formateTime(data['time']),
                  fontSize: 13.2,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          children: [
            Image.asset(
              'assets/coin.png',
              height: 30,
              width: 30,
              fit: BoxFit.cover,
            ),
            myText(
              title: data['coin'].toString(),
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ],
        ),
      );

  String _formateTime(String time) {
    DateTime dateTime = DateTime.parse(time);
    DateFormat dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    String formattedDate = dateFormat.format(dateTime);
    return formattedDate;
  }

  _totalCoinUI(BuildContext context) {
    int tatolCoin = 0;
    for (var data in hazardListHistory) {
      int coin = data['coin'];
      tatolCoin += coin;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset(
            'assets/coin.png',
            height: 30,
            width: 30,
            fit: BoxFit.cover,
          ),
          myText(
            title: tatolCoin.toString(),
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}
