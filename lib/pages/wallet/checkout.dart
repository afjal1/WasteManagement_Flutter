// import 'package:flutter/material.dart';
// import 'package:scoped_model/scoped_model.dart';
// import 'package:project/pages/wallet/verify_payment.dart';
// import 'package:project/scoped_models/main.dart';

// class CheckoutPage extends StatefulWidget {
//   final String authorizationUrl;
//   final double amount;

//   CheckoutPage(this.authorizationUrl, this.amount);

//   @override
//   _CheckoutPageState createState() => _CheckoutPageState();
// }

// class _CheckoutPageState extends State<CheckoutPage> {
//   FlutterWebviewPlugin _flutterWebviewPlugin = FlutterWebviewPlugin();

//   @override
//   void initState() {
//     // _flutterWebviewPlugin.onUrlChanged.listen((onData){
//     //   print("url changed");
//     //   print(onData);
//     // });

//     // _flutterWebviewPlugin.onProgressChanged.listen((onData){
//     //   print("progress changed");
//     //   print(onData);
//     // });

//     // _flutterWebviewPlugin.onStateChanged.listen((onData){
//     //   print("state changed");
//     //   print(onData);
//     // });

//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WebviewScaffold(
//       url: widget.authorizationUrl,
//       withJavascript: true,
//       appBar: AppBar(
//         title: Text("Checkout"),
//       ),
//       persistentFooterButtons: <Widget>[
//         Container(
//           margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//             child: ScopedModelDescendant<MainModel>(
//               builder: (BuildContext context, Widget child, MainModel model){
//                 return FloatingActionButton.extended(
//                   foregroundColor: Colors.white,
//                   label: Text("Proceed"),
//                   icon: Icon(Icons.arrow_forward_ios),
//                   onPressed: (){
//                     Navigator.of(context).pushReplacement(MaterialPageRoute(
//                       builder: (BuildContext context) => VerifyPaymentPage(model, widget.amount)
//                     ));
//                   },
//                 );
//               },
//             ),
//         )
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _flutterWebviewPlugin.dispose();

//     super.dispose();
//   }
// }