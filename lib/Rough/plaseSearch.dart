import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class SearchPlaceEx extends StatefulWidget {
  const SearchPlaceEx({super.key});

  @override
  State<SearchPlaceEx> createState() => _SearchPlaceExState();
}

class _SearchPlaceExState extends State<SearchPlaceEx> {
  String _apiKey = 'AIzaSyCy6TbAdJKairdnqz6Wvh3qcv1rypGW-Wo';
  var uuid = Uuid();
  String _sessionToken = '1234';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller.addListener(() {
      onChange();
    });
  }

  onChange() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSugesion(_controller.text);
  }

  getSugesion(String input) async {
    String apiURL =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request =
        '$apiURL?input?input=$input&key=$_apiKey&sessiontoken=$_sessionToken';

    var res = await http.get(Uri.parse(request));
    print("RES_DATA=>${res.body}");
    if (res.statusCode == 200) {
      print("RES_DATA=>${res.body}");
    } else {
      throw Exception('Faild to load Data');
    }
  }

  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextField(
            onChanged: (v) {},
            controller: _controller,
            decoration: const InputDecoration(),
          )
        ],
      ),
    );
  }
}
