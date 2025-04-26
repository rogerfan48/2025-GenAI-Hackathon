import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'amplifyconfiguration.dart';

Future<void> configureAmplify() async {
  if (Amplify.isConfigured) return;
  await Amplify.addPlugin(AmplifyAPI());       // No DataStore / Auth for now
  await Amplify.configure(amplifyconfig);
}
