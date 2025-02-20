import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:google_places_flutter/DioErrorHandler.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_details.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';

class PlaceSearchFieldView extends StatefulWidget {
  final InputDecoration inputDecoration;
  final ItemClick itemClick;
  GetPlaceDetailsWithLatLng? getPlaceDetailWithLatLng;
  final bool isLatLngRequired;
  final TextStyle textStyle;
  final String googleAPIKey;
  final int debounceTime;
  final List<String>? countries;
  final TextEditingController textEditingController;
  final ListItemBuilder? itemBuilder;
  final Widget? separatedBuilder;
  final BoxDecoration? boxDecoration;
  final bool isCrossBtnShown;
  final bool showError;
  final bool? readOnly;
  final double? containerHorizontalPadding;
  final double? containerVerticalPadding;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final void Function() clearData; // Add this line
  PlaceSearchFieldView({
    required this.textEditingController,
    required this.googleAPIKey,
    this.debounceTime = 600,
    this.inputDecoration = const InputDecoration(),
    required this.itemClick,
    this.isLatLngRequired = true,
    this.textStyle = const TextStyle(),
    this.countries,
    this.getPlaceDetailWithLatLng,
    this.itemBuilder,
    this.boxDecoration,
    this.isCrossBtnShown = true,
    this.separatedBuilder,
    this.showError = true,
    this.readOnly,
    this.containerHorizontalPadding,
    this.containerVerticalPadding,
    this.focusNode,
    required this.onChanged,
    required this.clearData,
  });

  @override
  _PlaceSearchFieldViewState createState() => _PlaceSearchFieldViewState();
}

class _PlaceSearchFieldViewState extends State<PlaceSearchFieldView> {
  final subject = PublishSubject<String>();
  OverlayEntry? _overlayEntry;
  List<Prediction> alPredictions = [];
  final LayerLink _layerLink = LayerLink();
  bool isSearched = false;
  bool isCrossBtn = true;
  final Dio _dio = Dio();
  CancelToken? _cancelToken = CancelToken();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.containerHorizontalPadding ?? 0,
          vertical: widget.containerVerticalPadding ?? 0,
        ),
        alignment: Alignment.centerLeft,
        decoration: widget.boxDecoration ??
            BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.grey, width: 0.6),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                autofocus: false,
                readOnly: widget.readOnly??false,
                decoration: widget.inputDecoration,
                style: widget.textStyle,
                controller: widget.textEditingController,
                focusNode: widget.focusNode ?? FocusNode(),

                onChanged: (string) {
                  widget.onChanged(string);
                  print("fdskjhfkdshfkdsfdsgdg");
                  subject.add(string);
                  if (widget.isCrossBtnShown) {
                    setState(() {
                      isCrossBtn = string.isNotEmpty;
                      
                    });
                  }
                        
                },
              ),
            ),
            if (widget.isCrossBtnShown && isCrossBtn && _showCrossIconWidget())
              IconButton(
                onPressed: clearData,
                icon: Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }

  getLocation(String text) async {
    print("TEXT_-------------$text");
    String apiURL =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=${widget.googleAPIKey}";

    if (widget.countries != null) {
      for (int i = 0; i < widget.countries!.length; i++) {
        String country = widget.countries![i];
        apiURL += (i == 0 ? "&components=country:" : "|country:") + country;
      }
    }

    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();
    }

    try {
      String proxyURL = "https://cors-anywhere.herokuapp.com/";
      String url = kIsWeb ? proxyURL + apiURL : apiURL;
      final options = kIsWeb
          ? Options(headers: {"x-requested-with": "XMLHttpRequest"})
          : null;
      Response response = await _dio.get(url, options: options);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Map map = response.data;
      print("REsponseDaDa=>$map");
      if (map.containsKey("error_message")) {
        throw response.data;
      }

      PlacesAutocompleteResponse subscriptionResponse =
          PlacesAutocompleteResponse.fromJson(response.data);

      if (text.isEmpty) {
        alPredictions.clear();
        _overlayEntry?.remove();
        return;
      }

      isSearched = false;
      alPredictions.clear();
      if (subscriptionResponse.predictions!.isNotEmpty &&
          widget.textEditingController.text.trim().isNotEmpty) {
        alPredictions.addAll(subscriptionResponse.predictions!);
        print("SERCH_PLACESS_LIST_LENGTH=>${alPredictions.length}");
      }

      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      var errorHandler = ErrorHandler.internal().handleError(e);
      _showSnackBar("${errorHandler.message}");
    }
  }

  @override
  void initState() {
    super.initState();
    subject.stream
        .distinct()
        .debounceTime(Duration(milliseconds: widget.debounceTime))
        .listen(textChanged);
  }

  textChanged(String text) async {
    getLocation(text);
  }

  OverlayEntry? _createOverlayEntry() {
    if (context.findRenderObject() == null) return null;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: size.height + offset.dy,
        width: size.width,
        child: CompositedTransformFollower(
          showWhenUnlinked: false,
          link: _layerLink,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: alPredictions.length,
              separatorBuilder: (context, pos) =>
                  widget.separatedBuilder ?? SizedBox(),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    print("SELECTED_Place=>${alPredictions[index]}");
                    if (index < alPredictions.length) {
                      widget.itemClick.call(alPredictions[index]);
                      if (widget.isLatLngRequired) {
                        getPlaceDetailsFromPlaceId(alPredictions[index]);
                      }
                      removeOverlay();
                    }
                  },
                  child: widget.itemBuilder != null
                      ? widget.itemBuilder!(
                          context, index, alPredictions[index])
                      : Container(
                          padding: EdgeInsets.all(10),
                          child: Text(alPredictions[index].description!),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void removeOverlay() {
    alPredictions.clear();
    _overlayEntry = _createOverlayEntry();
    if (context != null) {
      Overlay.of(context)?.insert(_overlayEntry!);
      _overlayEntry?.markNeedsBuild();
    }
  }

  Future<Response?> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    var url =
        "https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction.placeId}&key=${widget.googleAPIKey}";
    try {
      Response response = await _dio.get(url);
      PlaceDetails placeDetails = PlaceDetails.fromJson(response.data);
      prediction.lat = placeDetails.result?.geometry?.location?.lat?.toString();
      prediction.lng = placeDetails.result?.geometry?.location?.lng?.toString();
      widget.getPlaceDetailWithLatLng?.call(prediction);
    } catch (e) {
      var errorHandler = ErrorHandler.internal().handleError(e);
      _showSnackBar("${errorHandler.message}");
    }
  }

  void clearData() {
        widget.clearData.call(); // Call the passed clearData function if not null
    widget.textEditingController.clear();
    _cancelToken?.cancel();
    setState(() {
      alPredictions.clear();
      isCrossBtn = false;
    });
    _overlayEntry?.remove();


  }

  bool _showCrossIconWidget() {
    return widget.textEditingController.text.isNotEmpty;
  }

  void _showSnackBar(String errorData) {
    if (widget.showError) {
      final snackBar = SnackBar(content: Text("$errorData"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

// PlaceDetails parsePlaceDetailMap(Map responseBody) {
//   return PlaceDetails.fromJson(responseBody as Map<String, dynamic>);
// }

typedef GetPlaceDetailsWithLatLng = void Function(
    Prediction postalCodeResponse);





