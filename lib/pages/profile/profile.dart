import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:convert';

import '../../scoped_models/main.dart';
import '../../models/user.dart';

import '../../widgets/custom_text.dart' as customText;

import './profile_edit.dart';
import './profile_pic_view.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Container _buildProfile(BuildContext context, MainModel model) {
    //   print(json.encode(model.client.toMap()));
    return Container(
      margin: EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(bottom: 18),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => ProfilePicViewPage()));
              },
              child: Hero(
                tag: 'profile_pic',
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.png'),
                  radius: 70,
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 18),
            child: Column(
              children: <Widget>[
                customText.HeadlineText(
                  text: 'Untitled',
                  textColor: Colors.black,
                ),
                // Container(
                //   padding:
                //       EdgeInsets.symmetric(vertical: 3, horizontal: 9),
                //   margin: EdgeInsets.symmetric(
                //     vertical: 7,
                //   ),
                //   decoration: BoxDecoration(
                //       color: Theme.of(context).primaryColor,
                //       borderRadius: BorderRadius.circular(10)),
                //   child: Text(
                //     'Verified',
                //     style: TextStyle(color: Colors.white),
                //   ),
                // ),
                // Text('Last Login: 1min'),
                /*Row(
                children: <Widget>[
                  Text('250,000')
                ],
              )*/
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 18),
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text('Email'),
                  subtitle: Text('xyz@gmail.com'),
                ),
                Divider(),
                ListTile(
                  title: Text('Phone number'),
                  subtitle: Text('123456789'),
                ),
                Divider(),
                ListTile(
                  title: Text('Account type'),
                  subtitle: Text('Individual'),
                ),
                Divider(),
                ListTile(
                  title: Text('Location'),
                  subtitle: 'model.client.address' == 'null'
                      ? Text(
                          'No Address',
                          style: TextStyle(color: Colors.red),
                        )
                      : Text('address'),
                ),
                Divider(),
                // ListTile(
                //   title: Text('Simple Ads'),
                //   subtitle: Text('Unlimited'),
                // ),
                // Divider(),
                ListTile(
                  title: Text('Featured Ads'),
                  subtitle: Text('Unlimited'),
                ),
                Divider(),
                ListTile(
                  title: Text('Expiration Date'),
                  subtitle: Text('None'),
                ),
                Divider(),
                ListTile(
                  title: Text('3.493.939'),
                  subtitle: Text('Unlimited'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return ProfileEditPage();
              })).then((done) {
                final SnackBar snackBar = SnackBar(
                  content: Text(
                      done ? 'Profile updated' : 'Could not update Profile'),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                );
                Scaffold.of(context).showSnackBar(snackBar);
              });
            },
          )
        ],
      ),
      body: Container(
        width: deviceWidth,
        child: SingleChildScrollView(
          child: ScopedModelDescendant<MainModel>(
            builder: (BuildContext context, Widget child, MainModel model) {
              return _buildProfile(context, model);
            },
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.add),
      //   foregroundColor: Colors.white,
      //   onPressed: () {},
      // ),
    );
  }
}
