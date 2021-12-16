import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:project/book_vendor_image.dart';
import 'package:project/models/dispose_offering.dart';
import '../scoped_models/main.dart';

import '../widgets/custom_text.dart' as customText;

import '../utils/responsive.dart';

// import './book_vendor_success.dart';
// import './book_vendor_fail.dart';
import './edit_price.dart';
import './wallet/wallet.dart';

class BookVendorPage extends StatefulWidget {
  final String wasteType;
  BookVendorPage(this.wasteType);

  @override
  State<StatefulWidget> createState() {
    return _BookVendorPageState();
  }
}

class _BookVendorPageState extends State<BookVendorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final double _inputRadius = 10;

  final Map<String, dynamic> _formData = {
    'location': '',
    'numberOfBins': '',
    'image': ''
  };
  String _wastePrice = '0.0';
  String _numOfBins = '0';
  final int rate = 100; //? bin price

  List<File> _imageFiles = List<File>();

  TextEditingController _controller = TextEditingController();
  TextEditingController _locationFieldController = TextEditingController();

  void _onChange() {
    String text = _controller.text;
    print(text + ' ' + _numOfBins);
    if (text.isNotEmpty && (text != _numOfBins)) {
      // print(text);
      _numOfBins = text;
      setState(() {
        _wastePrice = (double.parse(text) * rate).toString();
      });
    }
  }

  @override
  void initState() {
    _controller.addListener(_onChange);
    super.initState();
  }

  //! merge into one widget <--> book_recycler
  void _setImage(File image) {
    _formData['image'] = image;
  }

  // void _getImage(BuildContext context, ImageSource source) {
  //   ImagePicker.pickImage(source: source, maxWidth: 400).then((File image) {
  //     setState(() {
  //       _imageFiles.insert(0, image);
  //     });
  //     Navigator.pop(context);

  //     Timer(Duration(milliseconds: 500), () {
  //       _scrollController.animateTo(
  //         _scrollController.position.maxScrollExtent,
  //         duration: new Duration(milliseconds: 200),
  //         curve: Curves.easeOut,
  //       );
  //     });
  //   });
  // }

  void _openImagePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: getSize(context, 230),
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: <Widget>[
                customText.TitleText(
                  text: 'Add Image',
                  textColor: Colors.black,
                ),
                SizedBox(
                  height: 10,
                ),
                ListTile(
                  leading: Icon(Icons.camera),
                  title: Text('Use Camera'),
                  onTap: () {
                    //    _getImage(context, ImageSource.camera);
                  },
                ),
                SizedBox(
                  width: 5,
                ),
                ListTile(
                  leading: Icon(Icons.picture_in_picture),
                  title: Text('Select from Gallery'),
                  onTap: () {
                    //     _getImage(context, ImageSource.gallery);
                  },
                )
              ],
            ),
          );
        });
  }

  void _editPrice(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) => EditPricePage(_wastePrice)))
        .then((price) {
      if (price != null) {
        setState(() {
          _wastePrice = price;
        });
      }
    });
  }

  Column _buildImages(double _fieldsGap, BuildContext context) {
    return Column(
      children: List.generate(
          _imageFiles.length,
          (int index) => Dismissible(
                key: UniqueKey(),
                onDismissed: (dir) {
                  setState(() {
                    _imageFiles.removeAt(index);
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: _fieldsGap),
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 5)
                  ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: <Widget>[
                        Image.file(
                          _imageFiles[index],
                          fit: BoxFit.cover,
                          height: 300,
                          width: MediaQuery.of(context).size.width,
                          alignment:
                              Alignment.topCenter, //! can change to center
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_red_eye,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                BookVendorImagePage(
                                                    _imageFiles[index])));
                                  },
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _imageFiles.removeAt(index);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
    );
  }

  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final double _fieldsGap = 20;
    final List<String> _wasteTypes = [
      'Household waste',
      'Office waste',
      'Sewage',
      'Liquid Waste'
    ];
    String _wasteType = _wasteTypes[0];

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Offer'),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: <Widget>[
                customText.TitleText(
                  text: 'Schedule Pickup',
                  textColor: Colors.black,
                ),
                SizedBox(
                  height: 20,
                ),
                customText.BodyText(
                  text: widget.wasteType,
                  textColor: Theme.of(context).primaryColor,
                ),
                SizedBox(
                  height: 20,
                ),
                Form(
                  key: _formKey,
                  child: Column(
//                crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildWasteLocationField(),
                      SizedBox(
                        height: _fieldsGap,
                      ),
                      // DropdownButtonFormField<String>(
                      //   decoration: InputDecoration(
                      //       border: OutlineInputBorder(
                      //           borderRadius: BorderRadius.circular(10)
                      //       )
                      //   ),
                      //   value: _wasteType,
                      //   items: _wasteTypes.map<DropdownMenuItem<String>>((String wasteType) => DropdownMenuItem(
                      //     value: wasteType,
                      //     child: Text(wasteType),
                      //   )).toList(),
                      //   onChanged: (String newValue){
                      //     setState(() {
                      //       _wasteType = newValue;
                      //       print(_wasteType);
                      //     });
                      //   },
                      // ),
                      // SizedBox(height: _fieldsGap,),
                      TextFormField(
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.delete_outline),
                            labelText: 'Weight',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(_inputRadius))),
                        controller: _controller,
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: false, signed: false),
                        validator: (String value) {
                          if (value.isEmpty) {
                            return 'This field is required';
                          } else if (double.parse(value) <= 0) {
                            return 'Value must be greater than 0';
                          }
                        },
                        onSaved: (String value) {
                          _formData['numberOfBins'] = value;
                        },
                      ),
                      SizedBox(
                        height: _fieldsGap,
                      ),
                      Container(
                        padding: EdgeInsets.only(right: getSize(context, 10)),
                        alignment: Alignment.centerRight,
                        child: customText.BodyText(
                          text: 'Rate ${rate.toString()} per Kg',
                          textColor: Colors.black,
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      OutlineButton(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        borderSide: BorderSide(width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_inputRadius),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Price: NGN ' + _wastePrice),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editPrice(context);
                              },
                            )
                          ],
                        ),
                        // onPressed: () {
                        //   _editPrice(context);
                        // },
                      ),
                      SizedBox(
                        height: _fieldsGap,
                      ),
                      _imageFiles.length == 0
                          ? Text(
                              'No Image(s)',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            )
                          : _buildImages(_fieldsGap, context),
                      SizedBox(
                        height: _fieldsGap,
                      ),
                      OutlineButton(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        borderSide: BorderSide(width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_inputRadius),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Add Image: ${_imageFiles.length}'),
                            IconButton(
                              icon: Icon(Icons.camera),
                              onPressed: () {
                                _openImagePicker(context);
                              },
                            )
                          ],
                        ),
                        onPressed: () {
                          _openImagePicker(context);
                        },
                      ),
                      SizedBox(
                        height: _fieldsGap,
                      ),
                      ScopedModelDescendant(
                        builder: (BuildContext context, Widget child,
                            MainModel model) {
                          return model.isLoading
                              ? CircularProgressIndicator()
                              : RaisedButton(
                                  child: customText.BodyText(
                                    text: 'Create Offer',
                                    textColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    // if (_formKey.currentState.validate()) {
                                    //   _formKey.currentState.save();
                                    //   model
                                    //       .addDisposeOffering(
                                    //           DisposeOffering(
                                    //               name: widget.wasteType,
                                    //               price: _wastePrice,
                                    //               rate: rate.toString(),
                                    //               numberOfBins:
                                    //                   _formData['numberOfBins'],
                                    //               clientId: model.client.id,
                                    //               clientName: 'new',
                                    //               clientLocation:
                                    //                   _formData['location'],
                                    //               date: DateTime.now()
                                    //                   .toIso8601String()),
                                    //           _imageFiles)
                                    //       .then((bool offeringAdded) {
                                    //     model.toggleOfferingPayable(true);
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                WalletPage(model, true)));
                                    //  });
                                    //   Navigator.of(context).pushReplacement(
                                    //       MaterialPageRoute(
                                    //           builder: (BuildContext context) =>
                                    //               WalletPage(model, true)));
                                    // } else {
                                    //   _scrollController.animateTo(
                                    //     0,
                                    //     duration:
                                    //         new Duration(milliseconds: 200),
                                    //     curve: Curves.easeOut,
                                    //   );
                                    // }
                                  },
                                );
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildWasteLocationField() {
    return TextFormField(
      controller: _locationFieldController,
      decoration: InputDecoration(
          prefixIcon: Icon(Icons.location_on),
          labelText: 'Waste location',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_inputRadius)),
          suffixIcon: ScopedModelDescendant<MainModel>(
            builder: (BuildContext context, Widget child, MainModel model) {
              return model.gettingLocation
                  ? Container(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(),
                    )
                  : Builder(
                      builder: (BuildContext context) => GestureDetector(
                        child: Icon(Icons.my_location),
                        onTap: () {
                          model.getLocation().then((String location) {
                            if (location.length == 0)
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "Can't obtain location at the moment"),
                                  duration: Duration(seconds: 3)));
                            setState(() {
                              _locationFieldController.text = location;
                            });
                          });
                        },
                      ),
                    );
            },
          )),
      validator: (String value) {
        if (value.isEmpty) {
          return 'Please enter a valid location';
        }
      },
      onSaved: (String value) {
        _formData['location'] = value;
      },
    );
  }
}
