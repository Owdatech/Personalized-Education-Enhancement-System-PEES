import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:pees/API_SERVICES/preference_manager.dart';
import 'package:pees/Authentication/Page/login_screen.dart';
import 'package:pees/Common_Screen/Pages/settings_screen.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/headMaster_dashboard_UI.dart';
import 'package:pees/Parent_Dashboard/Pages/parent_dashboard_UI.dart';
import 'package:pees/Teacher_Dashbord/Pages/teacher_dashboard_UI.dart';
import 'package:pees/custom_class/all_string.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PreferencesManager.shared.prefs;
  // String locale = await PreferencesManager.shared.getLanguage() ;
  // print("Selected Language : $locale");
  Locale savedLocale = await LocalizationService.loadSavedLocale();
  final fontSizeProvider = FontSizeProvider();
  await fontSizeProvider.loadFontSize();

  runApp(
      // MyApp(initialLocale: locale)
      MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (context) => ThemeManager()),
      ChangeNotifierProvider(create: (context) => fontSizeProvider),
    ],
    child: MyApp(savedLocale),
  ));
}

class MyApp extends StatelessWidget {
  final Locale savedLocale;
  MyApp(this.savedLocale);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return GetMaterialApp(
        translations: LocaleString(),
        theme: ThemeData(
            textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: fontSizeProvider.fontSize),
          bodyLarge: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
          bodySmall: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
        )),
        darkTheme: ThemeData.dark(),
        themeMode:
            themeManager.isHighContrast ? ThemeMode.dark : ThemeMode.light,
        locale: savedLocale,
        fallbackLocale: LocalizationService.defaultLocale,
        title: 'PEES',
        debugShowCheckedModeBanner: false,

        // theme: ThemeData(
        //     textTheme: TextTheme(
        //       bodyMedium: TextStyle(fontSize: fontSizeProvider.fontSize),
        //       bodyLarge: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
        //       bodySmall: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
        //     ),
        //   ),
        home: const InitialRouteHandler());
  }
}

class InitialRouteHandler extends StatelessWidget {
  const InitialRouteHandler({super.key});

  @override
  Widget build(BuildContext context) {
    checkSession(context); // Call the session check function
    return const Center(
        child:
            CircularProgressIndicator()); // Show a loading indicator while navigating
  }
}

Future<void> checkSession(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? userId = prefs.getString('userId');
  String? role = prefs.getString('role');

  if (token != null && userId != null && role != null) {
    print("User Id : $userId");
    if (role == "headmaster") {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HeadMasterDashboardUI()),
          (route) => false);
    } else if (role == "teacher") {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => TeacherDashBoardUI()),
          (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ParentDashboardUI()),
          (route) => false);
    }
  } else {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
