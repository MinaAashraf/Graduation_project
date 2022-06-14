import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:location/location.dart';
import 'package:object_detection/modules/volunteer/ui/volunteer_screen/cubit/states.dart';
import 'package:object_detection/shared/constants.dart';

import '../../../../../layouts/home_screen/home_screen.dart';
import '../../../../../strings/strings.dart';
import '../../../../../utils/tts_utils.dart';
import '../../../data/location/location_api.dart';


class VolunteerCubit extends Cubit<VolunteerStates> {
  VolunteerCubit() : super(InitialState());

  static VolunteerCubit get(context) => BlocProvider.of(context);

  onVolunteerInit ()
  {
    TTS.speak(VOLUNTEER_MOD_LABEL);
    HomeScreen.cubit.changeSelectedIndex(3);
  }

  onVolunteerRequest() async {
    emit(RequestLoading());
    await LocationApi.sendRealTimeLocationUpdates();
   // emit(LocationApi.requestState);
  }



}