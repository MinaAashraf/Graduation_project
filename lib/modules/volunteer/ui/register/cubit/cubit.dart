import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:object_detection/modules/volunteer/ui/register/cubit/states.dart';

import '../../../../../models/User.dart';
import '../../../../../shared/constants.dart';
import '../../../data/firebase/user_firebase.dart';


class RegisterCubit extends Cubit<RegisterStates> {
  RegisterCubit() : super(RegisterInitState());

  static RegisterCubit get(context) => BlocProvider.of(context);

  enterNextStage(RegisterStates stageState) {
    emit(RegisterFirstStageCompletedState());
  }

  backStage(RegisterStates stageState) {
    emit(RegisterInitState());
  }

  String verificationId = '',
      smsCode = '',
      nationalId = '',
      fullName = '',
      phone = '';

  Future<void> sendPhoneOtp(int fromRegisterOrVerifyScreen) async {
    try {
      await UserFirebase.signIn(
          phone: phone,
          onCodeSent: onCodeSentHandler,
          onVerificationFailed: onVerificationFailed);
      if (fromRegisterOrVerifyScreen == 0) //request from registerScreen
        emit(RegisterSuccessState());
      else
        emit(PhoneCodeResentState()); //request from phone verification screen
    } on FirebaseAuthException catch (err) {
      String errMessage = handleError(err.code);
      emit(RegisterErrorState(errMessage));
    }
  }

  signUp({PhoneAuthCredential? phoneAuthCredential}) async {
    try {
      emit(PhoneVerificationLoading());
      UserCredential credential;
      if (phoneAuthCredential != null) {
        credential =
            await UserFirebase.signInWithCredential(phoneAuthCredential);
      } else {
        credential = await UserFirebase.createCredentialAndSignIn(
            verificationId, smsCode);
      }

      UserModel user = UserModel(
          nationalId: nationalId,
          fullName: fullName,
          phone: phone,
          key: credential.user!.uid);
      try {
        await UserFirebase.storeUserData(user: user, uId: credential.user!.uid);
        emit(VerificationSuccessState());
      } catch (err) {
        credential.user!.delete();
        emit(RegisterErrorState('Check internet connection!'));
      }
    } on FirebaseAuthException catch (err) {
      emit(RegisterErrorState(err.message.toString()));
    }
  }

  onAutoVerification(PhoneAuthCredential phoneAuthCredential) async {
    emit(PhoneAutoVerification());
    this.smsCode = phoneAuthCredential.smsCode ?? "";
    await signUp(phoneAuthCredential: phoneAuthCredential);
  }

  onCodeSentHandler(String verificationId, int? resendToken) {
    emit(PhoneCodeSentState());
    this.verificationId = verificationId;
  }

  onVerificationFailed(FirebaseAuthException e) {
    String errMessage = handleError(e.code);
    //emit(RegisterErrorState(errMessage));
    if (e.code == 'invalid-phone-number') {
      showToast('The provided phone number is not valid.');
    } else
      showToast(e.message.toString());
    emit(VerificationFailed(e.message.toString()));
  }

  IconData idSuffixIcon = Icons.remove_red_eye;
  bool idSecure = true;

  changeIDVisibility() {
    idSecure = !idSecure;
    idSuffixIcon = idSecure ? Icons.remove_red_eye : Icons.visibility_off;
    emit(RegisterSecureVisibilityChangeState());
  }
}