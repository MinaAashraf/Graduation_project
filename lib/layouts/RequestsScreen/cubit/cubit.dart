import 'dart:ffi';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:volunteer_application/layouts/RequestsScreen/cubit/states.dart';
import 'package:volunteer_application/location_api/location_api.dart';
import 'package:volunteer_application/models/Directions.dart';
import 'package:volunteer_application/models/Request.dart';
import 'package:volunteer_application/models/Response.dart';
import 'package:volunteer_application/shared/remote/user_firebase.dart';

import '../../../map_helper/transport_means.dart';
import '../../../shared/constants.dart';
import '../../../shared/remote/dio.dart';

class RequestsCubit extends Cubit<RequestStates> {
  RequestsCubit() : super(RequestInitState());

  static RequestsCubit get(context) => BlocProvider.of(context);

  List<Request> requestsList = [];
  List<String> blinds_ids = [];
  List<String> addresses = [];



  Future<void> getRequests() async {
   LocationData? source = await LocationApi.getCurrentLocation();
    emit(RequestsLoading());
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await UserFirebase.getRequests();
      int i = 0;

      snapshot.docs.forEach((doc) async {
        i++;
        Request request = Request.fromJson(doc.data());
        if (source == null) {
          return;
        }
        // get the distance from directions api between the source and destination of request
        Directions? directions = await getSourceDestinationDistance(request.blindLocation.getLatLongObject(), LatLng(source.latitude!, source.longitude!));
        if (directions ==null) {
          return;
        }
        // filter requests with distances <= 5 km, and store them
        if (directions.distance / 1000 <= 5){
            requestsList.add(request);
            addresses.add(await getAddressFromCoordinates(
                 request.blindLocation.latitude, request.blindLocation.longitude));
            blinds_ids.add(doc.id);
        }
        if (i == snapshot.docs.length) {
          emit(RequestsRead());
        }
      });
    } catch (e) {}
  }



  Future<void> checkLocationPermission() async {
    if (await LocationApi.checkServiceAvailability()) {
      await LocationApi.checkLocationPermission();
    }
  }


  Future<String> getAddressFromCoordinates(double lat, double long) async {
    Placemark placeMark = await LocationApi.getPlaceFromCoordinates(lat, long);
    return '${placeMark.street}, ${placeMark.administrativeArea}';
  }

  void signOut() async {
    await UserFirebase.signOut();
  }


  void acceptRequest (int requestIndex)async {
    // send responses with real time changes in route duration and distance
   await LocationApi.sendRealTimeLocationUpdates(requestsList[requestIndex].blindLocation.getLatLongObject(), blinds_ids[requestIndex]);
   emit(RequestAccepted(requestIndex));
  }

}
