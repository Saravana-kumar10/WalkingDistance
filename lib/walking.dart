import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:walkdistance/area.dart';

import 'model/mathutil.dart';
import 'model/tracker.dart';
class DistancWlk extends StatefulWidget {
  const DistancWlk({super.key});

  @override
  State<DistancWlk> createState() => _DistancWlkState();
}

class _DistancWlkState extends State<DistancWlk> {

  final Gps _gps= Gps();
  Position? _userposition;
  var dist,km,wdist,wkm;

  Set<Marker> _markers={};
  List<LatLng> polygonVertices = [];

  final Set<Polygon> polygons = {};
  final Set<Polyline> polyline={};
  List<LatLng> polylinevertices=[];

  //////
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

      polylinevertices.add(LatLng(_userposition!.latitude,_userposition!.longitude));
      polyline.add(
          Polyline(polylineId: PolylineId("1"),
              points: polylinevertices,
              color: Colors.blue

          )

      );

    });

  }
  ////////
  MapType _currentMapType = MapType.normal;
  void _onMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }
  //////////
  Completer<GoogleMapController> _controller = Completer();
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller.complete(controller);


    });

  }
  //////////////

  void initState()
  {
    super.initState();
    _gps.startPositionStream(_handlepositionStream);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if(_userposition==null)
    {child=Center(child: CircularProgressIndicator());}
    else
    {
      child=SafeArea(
           child: Stack(
          children:[
            GoogleMap(
              markers: _markers,
              polylines: polyline,


              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType:_currentMapType,
              onMapCreated: _onMapCreated,

              initialCameraPosition: CameraPosition(
                target: LatLng(_userposition!.latitude, _userposition!.longitude),

                zoom: 18,
              ),),
            Row(
              children: [
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

                          dist=calculateDistance()*1000;
                          km=calculateDistance();
                          _gps.StoppositionStream();








                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:  Column(
                              children: [
                                Text('${dist.toString()}.meters'),
                                Text('${km.toString()}.km'),

                              ],
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                setState(() {
                                  _markers.clear();
                                  polylinevertices.clear();
                                  _gps.startPositionStream(_handlepositionStream);

                                });
                              },
                            ),
                          )
                          );
                        },
                        child: Column(
                          children: [
                            const Icon(Icons.social_distance),
                            Text("distance")
                          ],
                        ),
                      ),

                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FloatingActionButton(
                        onPressed:(){
                          wdist=walkDistance()*1000;
                          wkm=walkDistance();
                          _gps.StoppositionStream();








                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:  Column(
                              children: [
                                Text('${wdist.toStringAsFixed(5)}(meters)'),
                                Text('${wkm.toStringAsFixed(5)}(km)'),

                              ],
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                setState(() {
                                  _markers.clear();
                                  polylinevertices.clear();
                                  _gps.startPositionStream(_handlepositionStream);

                                });
                              },
                            ),
                          )
                          );
                        },
                        child: Column(
                          children: [
                            const Icon(Icons.directions_walk),
                            Text("distance")
                          ],
                        ),
                      ),

                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FloatingActionButton(
                        onPressed:(){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Walkarea()));
                          
                        },
                        child: Column(
                          children: [
                            const Icon(Icons.forward),
                            Text("AREA")
                          ],
                        ),
                      ),

                    )
                ),

              ],
            ),


          ] ),
    );}
    return Scaffold(
      body: child,
    );
  }
  ////////////////
  double calculateDistance(){

    double lat1=polylinevertices[0].latitude;
    double lat2=polylinevertices[1].latitude;
    double lon1=polylinevertices[0].longitude;
    double lon2=polylinevertices[1].longitude;





    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    print(12742 * asin(sqrt(a)));
    return 12742 * asin(sqrt(a));


  }
  ////////////////////
  double walkDistance(){
 var result=0.0;


    for(var i = 0; i < polylinevertices.length-1; i++)
    {  double lat1=polylinevertices[i].latitude;
    double lat2=polylinevertices[i+1].latitude;
    double lon1=polylinevertices[i].longitude;
    double lon2=polylinevertices[i+1].longitude;

    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    result=result+ (12742 * asin(sqrt(a)));
     }
    return result;





  }
  /////////////////////

  //////////////////////
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _gps.StoppositionStream();
  }


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
}
