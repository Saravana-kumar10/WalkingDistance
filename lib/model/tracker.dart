import 'dart:async';

import 'package:geolocator/geolocator.dart';

typedef PositionCallback = Function (Position position);
class Gps{

  late StreamSubscription<Position> _positionstream;

bool  isAccessgranted(LocationPermission permission){
    return permission==LocationPermission.whileInUse || permission == LocationPermission.always;
  }





  Future<bool> requestPermission() async{
    LocationPermission permission= await Geolocator.checkPermission();
    if(isAccessgranted(permission)){
        return true;
           }
    permission= await Geolocator.requestPermission();
    return isAccessgranted(permission);

  }

  Future<void> startPositionStream(Function(Position position) callback)
  async {
    bool permissiongranted = await requestPermission();
    if (!permissiongranted) {
      throw Exception("Permission not given");
    }
    _positionstream = await Geolocator.getPositionStream(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation)
    ).listen((callback));
  }


  Future<void> StoppositionStream() async{
    await _positionstream.cancel();
  }
}