import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'model/mathutil.dart';
import 'model/tracker.dart';
class Walkarea extends StatefulWidget {
  const Walkarea({super.key});


  @override
  State<Walkarea> createState() => _WalkareaState();
}

class _WalkareaState extends State<Walkarea> {

  final Gps _gps= Gps();
  Position? _userposition;
  List<LatLng> polygonVertices = [];
  final Set<Polygon> polygons = {};
  final Set<Polyline> polyline={};
  Set<Marker> _markers={};
  ///////////////////////
  void _handlepositionStream(Position position){
    setState(() {
      _markers.clear();
      _userposition=position;
      _markers.add(
          Marker(
            markerId: MarkerId(_userposition.toString()),
            position: LatLng(_userposition!.latitude,_userposition!.longitude),
            infoWindow: InfoWindow(
              title: 'Lat=${_userposition!.latitude.toStringAsFixed(3)},Long:${_userposition!.longitude.toStringAsFixed(3)}',
            ),
            icon:
            BitmapDescriptor.defaultMarker,
            onDragEnd:  ((LatLng newPosition) {

            }),

          ));

    });

  }
  //////////////////
  MapType _currentMapType = MapType.normal;
  void _onMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }
  //////////////////
  Completer<GoogleMapController> _controller = Completer();
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller.complete(controller);


    });

  }
  //////////////////////////
  void initState()
  {
    super.initState();
    _gps.startPositionStream(_handlepositionStream);
  }

  @override
  Widget build(BuildContext context) {

    Widget content;
    if(_userposition==null)
    {content=Center(child: CircularProgressIndicator());}
    else
    { content=SafeArea(
      child: Stack(
          children:[
            GoogleMap(
              markers: _markers,
              polylines: polyline,
              polygons: polygons,



              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType:_currentMapType,
              onMapCreated: _onMapCreated,

              initialCameraPosition: CameraPosition(
                target: LatLng(_userposition!.latitude, _userposition!.longitude),

                zoom: 20,
              ),),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FloatingActionButton(
                    onPressed:_onMapType,
                    child:   Icon(Icons.change_circle),
                  ),

                )
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FloatingActionButton(
                    onPressed:(){
                      setState(() {
                        _markers.add(
                            Marker(
                              markerId: MarkerId(_userposition.toString()),
                              position: LatLng(_userposition!.latitude,_userposition!.longitude),
                              infoWindow: InfoWindow(
                                title: 'Lat=${_userposition!.latitude.toStringAsFixed(3)},Long:${_userposition!.longitude.toStringAsFixed(3)}',
                              ),
                              icon:
                              BitmapDescriptor.defaultMarker,
                              onDragEnd:  ((LatLng newPosition) {

                              }),

                            ));
                        polygonVertices.add(LatLng(_userposition!.latitude,_userposition!.longitude));
                        polygons.add(
                            Polygon(
                              polygonId: PolygonId('my_polygon'),
                              points: polygonVertices,
                              fillColor: Colors.blue.withOpacity(0.3),
                              strokeColor: Colors.amberAccent,
                              geodesic: true,
                              consumeTapEvents: true,
                              visible: true,
                              strokeWidth: 4,
                            )
                        );
                      });


                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:  Column(
                          children: [
                            Text('added'),


                          ],
                        ),

                      )
                      );
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.add_location_alt),
                        Text("distance")
                      ],
                    ),
                  ),

                )
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FloatingActionButton(
                    onPressed:(){

                      var res=calculatearea();
                     var acre=calculatearea()*0.000247105;
                      _gps.StoppositionStream();








                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:  Column(
                          children: [
                            Text('${res.toString()}((AREA))'),
                            Text('${acre.toString()}((ACRE))'),


                          ],
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            setState(() {
                              _markers.clear();
                              polygonVertices.clear();
                              _gps.startPositionStream(_handlepositionStream);

                            });
                          },
                        ),
                      )
                      );
                    },
                    child:   Icon(Icons.area_chart),
                  ),

                )
            ),




          ] ),
    );
      }
    return Scaffold(
      body: content,
    );
  }
  double calculatearea () {
    var area;
    if(polygonVertices.length>=3)
    {

        final p1 = polygonVertices[0];
        final p2 = polygonVertices[1];
        final p3 = polygonVertices[2];
        final p4 = polygonVertices[3];
        area = computeArea([p1, p2, p3, p4, p1]);

    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:  Text("need more points to calculte area"),

      ));
    }
    return area;



  }
  ///////////
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _gps.StoppositionStream();
  }
  /////////////////////////

  static const num earthRadius=6371009.0;
  static num computeArea(List<LatLng> path) => computeSignedArea(path).abs();


  static num computeSignedArea(List<LatLng> path) =>
      _computeSignedArea(path, earthRadius);


  static num _computeSignedArea(List<LatLng> path, num radius) {
    if (path.length < 3) {
      return 0;
    }
    final prev = path.last;
    var prevTanLat = tan((pi / 2 - MathUtil.toRadians(prev.latitude)) / 2);
    var prevLng = MathUtil.toRadians(prev.longitude);

    // For each edge, accumulate the signed area of the triangle formed by the
    // North Pole and that edge ("polar triangle").
    final total = path.fold<num>(0.0, (value, point) {
      final tanLat = tan((pi / 2 - MathUtil.toRadians(point.latitude)) / 2);
      final lng = MathUtil.toRadians(point.longitude);

      value += _polarTriangleArea(tanLat, lng, prevTanLat, prevLng);

      prevTanLat = tanLat;
      prevLng = lng;

      return value;
    });

    return total * (radius * radius);
  }


  static num _polarTriangleArea(num tan1, num lng1, num tan2, num lng2) {
    final deltaLng = lng1 - lng2;
    final t = tan1 * tan2;
    return 2 * atan2(t * sin(deltaLng), 1 + t * cos(deltaLng));
  }
////////////////////////////
}
