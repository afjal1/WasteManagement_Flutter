import 'package:flutter/material.dart';

import '../../models/user.dart';

import '../../utils/assets.dart';
import '../../utils/responsive.dart';

import '../../widgets/custom_text.dart' as customText;

import './login.dart';

class SelectRolePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SelectRolePageState();
  }
}

class _SelectRolePageState extends State<SelectRolePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        // leading: Padding(
        //   padding: EdgeInsets.symmetric(
        //     vertical: 10,
        //   ),
        //   child: Image(image: AssetImage('assets/logo.png')),
        // ),
        centerTitle: true,
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w100,
              ),
              children: [customText.LogoText.textSpan(context)]),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image(
                image: AssetImage(ImageAssets.logo),
                height: getSize(context, 150),
              ),
              SizedBox(
                height: getSize(context, 70),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w100,
                      ),
                      children: [
                        // TextSpan(text: 'How would you like to use  '),
                        customText.LogoText.textSpan(context)
                      ]),
                ),
              ),
              InkWell(
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //       builder: (BuildContext context) =>
                  //           LoginPage(UserType.Client)),
                  // );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) => LoginPage()),
                  );
                },
                child: Card(
                  elevation: 4,
                  child: ListTile(
                    title: Text('Continue as User'),
                    subtitle: Text(
                        'I am a household/office I have waste to dispose/recycle/declust'),
                    // selected: _clientSelected,
                    // onTap: () {
                    //   setState(() {
                    //     _clientSelected = true;
                    //     _vendorSelected = false;
                    //   });
                    // },
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Card(
                elevation: 4,
                child: ListTile(
                  title: Text('Continue as Vendor'),
                  subtitle: Text('I am a waste collector/recycler'),
                  // selected: _vendorSelected,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => LoginPage()),
                    );

                    //  Navigator.of(context).push(MaterialPageRoute(
                    //      builder: (BuildContext context) => SignUpPage(
                    //          _clientSelected
                    //              ? UserType.Client
                    //              : UserType.Vendor)), (Route route) => false);
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.only(top: 30),
              //   child: RaisedButton(
              //     child: Text('Next'),
              //     textColor: Colors.white,
              //     onPressed: () {
              //       //  Navigator.of(context).push(MaterialPageRoute(
              //       //      builder: (BuildContext context) => SignUpPage(
              //       //          _clientSelected
              //       //              ? UserType.Client
              //       //              : UserType.Vendor)), (Route route) => false);
              //     },
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
