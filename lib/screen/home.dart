import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:location/location.dart' as loc;
import 'package:oaubot/screen/login_signup_page.dart';
import 'package:oaubot/services/authentication.dart';
import 'package:oaubot/services/map_request.dart';

// import 'login_signup_page.dart';

const kGoogleApiKey = 'API_KEY';

List<LatLng> result = <LatLng>[];

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class HomePage extends StatefulWidget {
  const HomePage(
      {Key key,

      /// If set, enable the FusedLocationProvider on Android
      @required this.androidFusedLocation,
      this.auth,
      this.userId,
      this.onSignedOut})
      : super(key: key);

  final bool androidFusedLocation;
  final Auth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  loc.LocationData _startLocation;
  loc.LocationData _currentLocation;

  StreamSubscription<loc.LocationData> _locationSubscription;
  loc.Location _locationService = loc.Location();
  bool _permission = false;
  String error;

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 4.0,
  );

  CameraPosition _currentCameraPosition;

  GoogleMap googleMap;

  bool loading = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  Set<Polyline> get polyLines => _polyLines;
  Set<Marker> get markers => _markers;
  Mode _mode = Mode.overlay;

  String _userEmail = '';

  static String where = 'Where would you like to go?';
  static String directionFrom = 'Direction from ';
  static String to = 'to ';
  static String instructionFrom = 'Instruction: From your current location ';
  static String lookFor = 'look for nearest bus stop then take a bike to ';
  static String duration = 'Duration: ';
  static String distance = 'Distance: ';
  static String price = 'Price: ';
  static String note =
      'Note: You can also turn-off your location and follow the blue line on the map to get your detailed direction';
  static String language = 'Language';

  @override
  void initState() {
    initPlatformState();
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userEmail = user?.email;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _locationSubscription.cancel();

    super.dispose();
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  initPlatformState() async {
    final GoogleMapController controller = await _controller.future;
    await _locationService.changeSettings(
        accuracy: loc.LocationAccuracy.HIGH, interval: 1000);

    loc.LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      bool serviceStatus = await _locationService.serviceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await _locationService.requestPermission();
        print("Permission: $_permission");
        if (_permission) {
          location = await _locationService.getLocation();
          LatLng latLng = LatLng(location.latitude, location.longitude);
          _addMarker(latLng, 'Current location');

          _locationSubscription = _locationService
              .onLocationChanged()
              .listen((loc.LocationData result) async {
            _currentCameraPosition = CameraPosition(
              target: LatLng(result.latitude, result.longitude),
              zoom: 18.0,
            );

            controller.animateCamera(
                CameraUpdate.newCameraPosition(_currentCameraPosition));

            if (mounted) {
              setState(() {
                _currentLocation = result;
              });
            }
          });
        }
      } else {
        bool serviceStatusResult = await _locationService.requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
      location = null;
    }

    setState(() {
      _startLocation = location;
    });
  }

  // slowRefresh() async {
  //   _locationSubscription.cancel();
  //   await _locationService.changeSettings(
  //       accuracy: loc.LocationAccuracy.BALANCED, interval: 10000);
  //   _locationSubscription =
  //       _locationService.onLocationChanged().listen((loc.LocationData result) {
  //     if (mounted) {
  //       setState(() {
  //         _currentLocation = result;
  //       });
  //     }
  //   });
  // }

  List<LatLng> _convertToLatLng(List points) {
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  void sendRequest(Prediction p) async {
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
    final lat = detail.result.geometry.location.lat;
    final lng = detail.result.geometry.location.lng;
    LatLng destination = LatLng(lat, lng);
    Map route = await routeCoordinates(destination);
    LatLng currentLatLng =
        LatLng(_startLocation.latitude, _startLocation.longitude);

    createRoute(route["overview_polyline"]["points"]);

    _addMarker(currentLatLng, 'Current location');
    _addMarker(destination, p.description);
    print('sendRequest is working');
  }

  Future<Map> routeCoordinates(LatLng destination) {
    LatLng currentLatLng =
        LatLng(_startLocation.latitude, _startLocation.longitude);
    // _addMarker(currentLatLng, 'Current location');
    return _googleMapsServices.getRouteCoordinates(currentLatLng, destination);
  }

  void createRoute(String encondedPoly) {
    LatLng currentLatLng =
        LatLng(_startLocation.latitude, _startLocation.longitude);
    // _addMarker(currentLatLng, 'Current location');
    _polyLines.add(Polyline(
        polylineId: PolylineId(currentLatLng.toString()),
        width: 3,
        points: _convertToLatLng(_decodePoly(encondedPoly)),
        color: Colors.blue));
  }

  void _addMarker(LatLng location, String address) {
    _markers.clear();
    _markers.add(
      Marker(
          markerId: MarkerId("112"),
          position: location,
          infoWindow: InfoWindow(title: address, snippet: ""),
          icon: BitmapDescriptor.defaultMarker),
    );
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    // print(lList.toString());

    return lList;
  }

  @override
  Widget build(BuildContext context) {
    // LatLng currentLatLng =
    //     LatLng(_startLocation.latitude, _startLocation.longitude);
    // print("getLocation111:$currentLatLng");
    return Scaffold(
      // key: homeScaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            result.clear();
            // _markers.clear();
            // LatLng currentLatLng =
            // LatLng(_startLocation.latitude, _startLocation.longitude);
            // _addMarker(currentLatLng, 'Current location');

            _handlePressPrediction();
            print('Prediction is working');
          },
          child: Row(
            children: <Widget>[
              Icon(
                Icons.location_on,
                color: Colors.pink,
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 17.0,
                ),
                height: 55.0,
                width: MediaQuery.of(context).size.width - 110,
                color: Colors.white,
                // decoration: BoxDecoration(),
                child: Text(
                  where,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.pink,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          Container(
            color: Colors.pink[300],
            child: PopupMenuButton<String>(
              onSelected: choiceAction,
              itemBuilder: (context) {
                return ActionItems.choices.map((String value) {
                  return PopupMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          googleMap = GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: _markers,
            mapToolbarEnabled: true,
            polylines: polyLines,
            initialCameraPosition: _initialCamera,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            child: Text(_userEmail),
            left: 10.0,
            top: 20.0,
          )
        ],
      ),
    );
  }

  void choiceAction(String value) {
    switch (value) {
      case 'Logout':
        setState(() {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return LoginSignUpPage(
              auth: Auth(),
            );
          }));
          _signOut();
        });
        break;
      case 'Yorùbá':
        setState(() {
          where = 'Ibo ni o fẹ́ lọ?';
          directionFrom = 'Ìtọ́sọ́nà láti ';
          to = 'lọ ';
          instructionFrom = 'Ẹ̀kọ́: Láti ipò rẹ lọ́wọ́lọ́wọ́ ';
          lookFor =
              'wá ibùdó ọkọ̀ ayọ́kẹ́lẹ́ tó súnmọ́, lẹ́hìnná gun ọ̀kadà lọ sí ';
          duration = 'Iye àkókò: ';
          distance = 'Bó se jìnà tó: ';
          price = 'Iye: ';
          note =
              'Àkíyèsí: O tún lè pa ipò rẹ́, kí o tẹ̀lé láìnì búlùù lórí máàpù láti gba ìtọ́sọ́nà àlàyé rẹ.';
          language = 'Ẹ̀dẹ̀';
        });
        break;
      case 'Igbo':
        setState(() {
          where = 'Ebee ka i ga-achọ iga?';
          directionFrom = 'Ntuziaka si ';
          to = 'ka ';
          instructionFrom = 'Ntuziaka: Si ebe I di ugbu a ';
          lookFor =
              'chọọ, maka nkwusi bos kacha nso wee jiri igwe kwu otu ebe gaa ';
          duration = 'Ogologo oge: ';
          distance = 'Distance: ';
          price = 'Ọnuahia: ';
          note =
              'Mara: cannwekwara ike igbanyu, ọnọdu gi ma soro eriri igwe na-acha anunu anunu na maapu iji nweta uzo zuru ezu gi.';
          language = 'Asusu';
        });
        break;
      case 'Hausa':
        setState(() {
          where = 'Aina kuke so kuje?';
          directionFrom = 'Jagora daga ';
          to = 'zuwa ';
          instructionFrom = 'Koyarwa: Daga wurin da kuke a yanzu ';
          lookFor = 'nemi tashar bas mafi kusa sannan sai a dauki keke don  ';
          duration = 'Tsawon lokaci: ';
          distance = 'Distance: ';
          price = 'Farashi: ';
          note =
              'Lura: Hakanan zaka iya kasha wurinka kuma bi layin shudi akan taswirar don samun cikakken jagora.';
          language = 'Harshe';
        });
        break;
      case 'English':
        setState(() {
          where = 'Where would you like to go?';
          directionFrom = 'Direction from ';
          to = 'to ';
          instructionFrom = 'Instruction: From your current location ';
          lookFor = 'look for nearest bus stop then take a bike to ';
          duration = 'Duration: ';
          distance = 'Distance: ';
          price = 'Price: ';
          note =
              'Note: You can also turn-off your location and follow the blue line on the map to get your detailed direction';
          language = 'Language';
        });
        break;
      default:
    }
    print(value);
  }

  void onError(PlacesAutocompleteResponse response) {
    // homeScaffoldKey.currentState.showSnackBar(
    //   SnackBar(content: Text(response.errorMessage)),
    // );
  }

  Future<void> _handlePressPrediction() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    _markers.clear();
    LatLng currentLatLng =
        LatLng(_startLocation.latitude, _startLocation.longitude);
    _addMarker(currentLatLng, 'Current location');

    Prediction p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiKey,
        onError: onError,
        mode: _mode,
        language: "en",
        logo: Image.asset(
          '',
          // scale: 2000,
        ),
        // components: [Component(Component.country, "ng")],
        location: Location(7.518475, 4.521020),
        radius: 2360,
        strictbounds: true);

    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
    final lat = detail.result.geometry.location.lat;
    final lng = detail.result.geometry.location.lng;
    LatLng destination = LatLng(lat, lng);
    Map route = await routeCoordinates(destination);

    sendRequest(p);

    _showModalBottomSheet(route, p);
  }

  Future<void> _showModalBottomSheet(Map route, Prediction p) {
    return showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          double dist =
              double.parse(route["legs"][0]["distance"]["text"].split(' ')[0]);

          String desc = p.description;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(width: 3.0),
              borderRadius: BorderRadius.circular(15),
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text(
                      '$directionFrom${route["legs"][0]["start_address"].toString()} $to$desc.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Text(
                      '$instructionFrom(${route["legs"][0]["start_address"].toString()}), $lookFor$desc.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$duration${route["legs"][0]["duration"]["text"].toString()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$distance${route["legs"][0]["distance"]["text"]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        dist > 3.5 && dist <= 4.5
                            ? '$price 100 naira'
                            : dist > 2.5 && dist <= 3.5
                                ? '$price 60 naira'
                                : '$price 50 naira',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Text(
                      note,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class ActionItems {
  static const String en = 'English';
  static const String yor = 'Yorùbá';
  static const String igbo = 'Igbo';
  static const String hausa = 'Hausa';
  static const String logout = 'Logout';

  static const List<String> choices = <String>[en, yor, igbo, hausa, logout];
}
