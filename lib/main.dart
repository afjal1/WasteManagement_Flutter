import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './scoped_models/main.dart';
import './models/user.dart';

import './widgets/custom_text.dart' as customText;

import './pages/launch/welcome.dart';
// import './pages/login.dart';
// import './pages/signup.dart';
import './pages/home.dart';
import './pages/search.dart';
import './pages/profile/profile.dart';
import './pages/dispose/dispose_waste.dart';
// import './pages/recycle_waste.dart';
import './pages/vendor/vendor_home.dart';
// import './pages/vendor/offerings.dart';
// import './pages/book_vendor.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  final MainModel _model = MainModel();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Waste Master',
          theme: ThemeData(
            primaryColor: Colors.greenAccent,
            accentColor: Colors.amber,
            buttonColor: Colors.amber.shade700,
            // fontFamily: 'Lato',
            buttonTheme: ButtonThemeData(
              buttonColor: Colors.amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
          ),
          color: Colors.green,
          home: WelcomePage(),
          routes: {
            // '/': (BuildContext context) => ScopedModelDescendant<MainModel>(
            //       builder:
            //           (BuildContext context, Widget child, MainModel model) {
            //         return _setPage(model);
            //       },
            //     ),
            // '/': (BuildContext context) => BookVendorPage(),
            // 'login': (BuildContext context) => LoginPage(),
            'welcome': (BuildContext context) => WelcomePage(),
            // 'signup': (BuildContext context) => SignUpPage('user'),
            'home': (BuildContext context) => HomePage(),
            'vendor_home': (BuildContext context) => VendorHomePage(),
            'search': (BuildContext context) => SearchPage(),
            'profile': (BuildContext context) => ProfilePage(),
            'dispose_waste': (BuildContext context) => DisposeWastePage(),
          }),
    );
  }

  Widget _setPage(MainModel model) {
    if (model.isLoading) {
      return _buildLoadingPage();
    } else if (!model.authResponse.success) {
      print(model.authResponse.message);
      return _buildNoNetworkPage();
    } else if (model.user == null) {
      return WelcomePage();
    } else if (model.user.userType == UserType.Client) {
      return HomePage();
    } else {
      return VendorHomePage();
    }
  }

  Scaffold _buildNoNetworkPage() {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image(
              image: AssetImage('assets/no-network.png'),
            ),
            SizedBox(height: 20),
            customText.HeadlineText(
              text: 'No Connection',
              textColor: Colors.white,
            ),
            SizedBox(height: 20),
            RaisedButton(
              child: customText.BodyText(
                text: "Retry",
              ),
              onPressed: () {
                _model.autoAuthenticate();
              },
            )
          ],
        ),
      ),
    );
  }

  Scaffold _buildLoadingPage() {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image(
              height: 300,
              image: AssetImage('assets/logo.png'),
            ),
            SizedBox(
              height: 20,
            ),
            customText.HeadlineText(
              text: 'Waste Master',
              textColor: Colors.white,
            ),
            SizedBox(
              height: 30,
            ),
            CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
