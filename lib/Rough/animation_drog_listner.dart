import 'package:flutter/material.dart';

class AnimationSheet extends StatefulWidget {
  const AnimationSheet({Key? key}) : super(key: key);

  @override
  State<AnimationSheet> createState() => _AnimationSheetState();
}

class _AnimationSheetState extends State<AnimationSheet> {
  double _percent = 0.0;
  bool isDragged = false;

  void checkStateDragged() {
    if (_percent > 0.5) {
      setState(() {
        isDragged = true;
      });
    } else {
      setState(() {
        isDragged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkStateDragged();
    return Scaffold(
      drawer: Drawer(
        elevation: 0,
        child: SafeArea(
          child: Column(
            children: const [
              Text("Hello world"),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset(
                'AppLogo',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {},
                child: const Icon(
                  Icons.menu,
                  color: Colors.black,
                ),
              ),
            ),

            /* draggable scrollable sheet*/
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _percent = 2 * notification.extent - 0.8;
                  });
                  return true;
                },
                child: DraggableScrollableSheet(
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Material(
                      elevation: 10.0,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20.0),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15.0),
                            Container(
                              height: 10.0,
                              margin: const EdgeInsets.symmetric(horizontal: 120.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: const Text(
                                "Akwaaba !",
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                                vertical: 5.0,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: const Text(
                                "Where are you going?",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22.0,
                                ),
                              ),
                            ),
                            !isDragged
                                ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _percent = 1.0;
                                });
                              },
                              child: TextFormField(
                                decoration: InputDecoration(
                                  enabled: false,
                                  hintText: "Search Destination",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    ),
                                    gapPadding: 2.0,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.purple[300],
                                  ),
                                ),
                              ),
                            )
                                : Container(),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.only(bottom: 40.0),
                                itemCount: 20,
                                itemBuilder: (context, index) {
                                  return const ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                    ),
                                    title: Text(
                                      "Street No 12345 NY Street",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "New York City",
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /* search destination */
            Positioned(
              left: 0.0,
              right: 0.0,
              top: -180 * (1 - _percent),
              child: Opacity(
                opacity: _percent,
                child: const SearchDestination(),
              ),
            ),

            /* select destination on map */
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: -50 * (1 - _percent),
              child: Opacity(
                opacity: _percent,
                child: const PickOnMap(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// search destination sheet
class SearchDestination extends StatelessWidget {
  const SearchDestination({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 10.0,
          bottom: 10.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black87,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Choose Destination".toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const SizedBox(height: 10.0),
                  //  pick up location
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Avenue 34 St 34 NY",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  //  destination
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Where are you going",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// select destination on map
class PickOnMap extends StatelessWidget {
  const PickOnMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      color: Colors.amber,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 10.0,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.place_sharp,
                color: Colors.purple,
              ),
              SizedBox(width: 30.0),
              Text(
                "Select on Map",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
