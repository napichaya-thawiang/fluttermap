import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_maps/secrets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// import 'dart:math' show cos, sqrt, asin;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class PropsLatLng {
  LatLng origin, dest;
  PropsLatLng(this.origin, this.dest);

  setOrigin(double lat, double long) {
    origin = LatLng(lat, long);
  }

  setDest(double lat, double long) {
    dest = LatLng(lat, long);
  }

  PointLatLng toPointOrigin() {
    return PointLatLng(origin.latitude, origin.longitude);
  }

  PointLatLng toPointDest() {
    return PointLatLng(dest.latitude, dest.longitude);
  }

  copy() {
    return PropsLatLng(origin, dest);
  }
}

class _MapViewState extends State<MapView> {
  Map<MarkerId, Marker> markers = {};
  PropsLatLng propsLatLng = PropsLatLng(LatLng(0, 0), LatLng(0, 0));
  ValueNotifier<Map<PolylineId, Polyline>> polylines = ValueNotifier({});
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPiKey = Secrets.API_KEY;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Future<Position> fetchCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // log("$position");
    return position;
  }

  @override
  void initState() {
    super.initState();
    addMultipleMarkers();
  }

  void _updateMarkersAndPolylines() {
    propsLatLng.setDest(propsLatLng.dest.latitude + 0.0001,
        propsLatLng.dest.longitude + 0.0001);
    _addMarker(propsLatLng.origin, "origin", BitmapDescriptor.defaultMarker);
    _addMarker(propsLatLng.dest, "destination",
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
    _getPolyline(propsLatLng.toPointOrigin(), propsLatLng.toPointDest());
    }

void addMultipleMarkers() async {
  List<Map<String, dynamic>> markersData = [
    {'latitude': 16.7503449, 'longitude': 100.1897194, 'id': 'marker_1', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7494484, 'longitude': 100.1904319, 'id': 'marker_2', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.749877, 'longitude': 100.1918236, 'id': 'marker_3', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7482711, 'longitude': 100.1910321, 'id': 'marker_4', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7469047, 'longitude': 100.1938645, 'id': 'marker_5', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7425062, 'longitude': 100.196538, 'id': 'marker_6', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7427639, 'longitude': 100.196638, 'id': 'marker_7', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7422349, 'longitude': 100.1943044, 'id': 'marker_8', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7431331, 'longitude': 100.1893751, 'id': 'marker_9', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.745522, 'longitude': 100.1890049, 'id': 'marker_10', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7477374, 'longitude': 100.1880105, 'id': 'marker_11', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7452083, 'longitude': 100.1920723, 'id': 'marker_12', 'icon': 'assets/images/marker_icon_1.png'},
    {'latitude': 16.7480751, 'longitude': 100.1890331, 'id': 'marker_13', 'icon': 'assets/images/marker_icon_1.png'},
  ];

  for (var markerData in markersData) {
    try {
      BitmapDescriptor descriptor = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)),
        markerData['icon']
      );

      _addMarker1(markerData['latitude'], markerData['longitude'], markerData['id'], descriptor);
    } catch (e) {
      print('Error loading marker icon for ${markerData['id']}: $e');
    }
  }
}

void _addMarker1(double latitude, double longitude, String id, BitmapDescriptor descriptor) {
  final Marker marker = Marker(
    markerId: MarkerId(id),
    position: LatLng(latitude, longitude),
    icon: descriptor,
  );
    
   setState(() {
      markers[MarkerId(id)] = marker;
    });

}

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 2,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      geodesic: true,
    );
    polylines.value[id] = polyline;
    polylines.notifyListeners();
  }

  _getPolyline(PointLatLng origin, PointLatLng destination) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey, origin, destination,
        travelMode: TravelMode.driving,
        optimizeWaypoints:
            true); // กำหนดให้เรียงลำดับจุดใหม่เพื่อให้ได้เส้นทางที่ใกล้ที่สุด
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    polylines.notifyListeners();
    _addPolyLine();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: FutureBuilder(
        future: fetchCurrentLocation(),
        builder: (context, snapshot) {
        
          if (snapshot.hasData) {
            log(snapshot.data.toString());
            propsLatLng.setOrigin(
                snapshot.data!.latitude, snapshot.data!.longitude);
            propsLatLng.setDest(snapshot.data!.latitude + 0.001,
                snapshot.data!.longitude + 0.001);
              Timer.periodic(Duration(seconds: 3), (timer) {
            markers.clear();
            polylineCoordinates.clear();
            polylines.value.clear();
            _updateMarkersAndPolylines();
          });
            return ValueListenableBuilder(
              valueListenable: polylines,
              builder: (context, value, child) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: propsLatLng.origin,
                    zoom: 15,
                  ),
                  
                  myLocationEnabled: true,
                  tiltGesturesEnabled: true,
                  compassEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: Set<Marker>.of(markers.values),
                  polylines: Set<Polyline>.of(value.values),
                  // mapType: MapType.terrain,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                );
              },
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    ));
  }
}
