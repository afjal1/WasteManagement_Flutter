import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:project/models/offering.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/dispose_offering.dart';
import '../models/recycle_offering.dart';
import '../models/decluster_offering.dart';
import '../models/http.dart';
import '../models/transaction.dart';

import '../utils/data.dart';

var client = http.Client();

class MainModel extends Model
    with
        ConnectedModel,
        UserModel,
        OfferingModel,
        PaymentModel,
        TransactionModel {
  // static MainModel mainModel;
  // MainModel(){
  //   if(mainModel == null)
  //     mainModel = this;
  // }
}

class ConnectedModel extends Model {
  User _authenticatedUser;
  ResponseInfo _authResponse;
  Client _client;
  Vendor _vendor;
  bool _isLoading = false;
  bool _gettingLocation = false;
  // https://[PROJECT_ID].firebaseio.com'
  String _dbUrl = "https://waste-mx.firebaseio.com";
  int _httpTimeout = 5;
  List<Transaction> _transactions = List<Transaction>();

  ResponseInfo get authResponse {
    return _authResponse;
  }

  bool get isLoading {
    return _isLoading;
  }

  bool get gettingLocation {
    return _gettingLocation;
  }

  List<Transaction> get transactions {
    return _transactions;
  }

  void toggleLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class UserModel extends ConnectedModel {
  String _apiKey = 'AIzaSyDsh78rw9gd2J7N8j5BNxDhgUagX_PTcuo';

  List<Vendor> _vendors;

  Client get client {
    return _client;
  }

  Vendor get vendor {
    return _vendor;
  }

  User get user {
    return _authenticatedUser;
  }

  List<Vendor> get vendors {
    return _vendors;
  }

  UserType _getUserType(String userTypeString) {
    return userTypeString == 'UserType.Client'
        ? UserType.Client
        : UserType.Vendor;
  }

  /// Automatically authenticates user
  void autoAuthenticate() async {
    toggleLoading(true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool markedForDelete = prefs.getBool("markedForDelete");
    final String idToken = prefs.getString("userIdToken");
    if (markedForDelete) {
      final bool authUserDeleted = await _deleteAuthUser(idToken);
      return;
    }

    final String refreshToken = prefs.getString('userRefreshToken');
    final UserType userType = _getUserType(prefs.getString('userType'));
    // final String expiryTimeString = prefs.getString('expiryTime');
    _authResponse = ResponseInfo(false, 'User not Saved', -1);

    if (refreshToken != null) {
      // print(token);
      // final DateTime now = DateTime.now();
      // final parsedExpiryTime = expiryTimeString == null
      //     ? DateTime.now().subtract(Duration(days: 1))
      //     : DateTime.parse(expiryTimeString);
      // if (parsedExpiryTime.isBefore(now)) {
      final http.Response response = await http
          .post(
              Uri.parse(
                  "https://securetoken.googleapis.com/v1/token?key=$_apiKey"),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'grant_type': 'refresh_token',
                'refresh_token': refreshToken
              }))
          .catchError((error) {
        print(error.toString());
        _isLoading = false;
        notifyListeners();
        _authResponse = ResponseInfo(false, error, -1);
      });
      // .timeout(Duration(seconds: _httpTimeout),
      // onTimeout: (){
      //   _authenticatedUser = null;
      //   _isLoading = false;
      //   notifyListeners();
      // });
      if (response == null) return;
      final Map<String, dynamic> responseData = json.decode(response.body);
      // print(response.body);
      if (responseData.containsKey('idToken')) {
        await _initializeAuthUser(responseData, userType);
        await _saveAuthUser(responseData);
      } else {
        _authResponse = ResponseInfo(true, 'Could not authenticate', -1);
        _authenticatedUser = null;

        toggleLoading(false);
      }
      // }

      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      _authenticatedUser = User(
          id: userId, email: userEmail, token: idToken, userType: userType);

      await _getUserDataOnLogin();
      _authResponse = ResponseInfo(true, 'Successful Authentication', -1);

      toggleLoading(false);
    } else {
      _authResponse = ResponseInfo(true, 'User not created', -1);

      toggleLoading(false);
    }
  }

  Future _initializeAuthUser(responseData, UserType userType) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    _authenticatedUser = User(
        id: responseData['localId'],
        email: responseData['email'],
        token: responseData['idToken'],
        profileId: pref.getString("userProfileId"),
        userType: userType,
        markedForDelete: pref.getBool("userMarkedForDelete") ?? false);
  }

  Future _saveAuthUser(responseData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear(); //! comment out
    prefs.setString('userIdToken', _authenticatedUser.token);
    prefs.setString("userRefreshToken", responseData["refreshToken"]);
    prefs.setString('userEmail', _authenticatedUser.email);
    prefs.setString('userId', _authenticatedUser.id);
    prefs.setString('userType', _authenticatedUser.userType.toString());
    prefs.setString("userProfileId", _authenticatedUser.profileId);
    prefs.setBool("userMarkedForDelete", _authenticatedUser.markedForDelete);

    // final DateTime now = DateTime.now();
    // // responseData['expiresIn'];
    // final DateTime expiryTime =
    //     now.add(Duration(seconds: int.parse(responseData["expiresIn"])));
    // prefs.setString('expiryTime', expiryTime.toIso8601String());
  }

  Future _saveUserProfileData(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    data.forEach((key, value) {
      prefs.setString(key, value.toString());
    });
  }

  // Future _deleteUserData(Map<String, dynamic> data) async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   data.forEach((key, value) {
  //     //todo: delete
  //   });
  // }

  /// gets user data either from the cloud or from disk
  Future<bool> _getUserDataOnLogin() async {
    http.Response response = await http.get(Uri.parse(
        '$_dbUrl/clients/${_authenticatedUser.profileId}.json?auth=${_authenticatedUser.token}'));

    Map<String, dynamic> responseData = json.decode(response.body);
    if (responseData == null) {
      await _deleteAuthUser(_authenticatedUser.token);
      return false;
    }

    await _initializeUser(responseData);

    return true;
  }

  Future<bool> _initializeUser(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    data["clientId"] = _authenticatedUser.profileId;

    if (_authenticatedUser.userType == UserType.Client) {
      if (prefs.getString(Datakeys.clientId) != _authenticatedUser.profileId) {
        _client = Client.fromMap(data);
      } else {
        String pos = prefs.getString(Datakeys.clientPos);
        _client = Client(
            id: prefs.getString(_authenticatedUser.profileId),
            name: prefs.getString(Datakeys.clientName),
            pos: json.decode(pos == null ? "[0,0]" : pos).map<double>((x) {
              return double.parse(x.toString());
            }).toList(),
            phone: prefs.getString(Datakeys.clientPhone),
            username: prefs.getString(Datakeys.clientUsername),
            address: prefs.getString(Datakeys.clientAddress),
            dateCreated: prefs.getString(Datakeys.clientDateCreated));
        // print(_client.pos);
      }
    } else {
      if (prefs.getString(Datakeys.vendorId) != data["vendorId"]) {
        http.Response response = await http.get(Uri.parse(
            '$_dbUrl/vendors/${_vendor.id}.json?auth=${_authenticatedUser.token}'));
        Map<String, dynamic> responseData = json.decode(response.body);
        // print(responseData);
        Vendor.fromMap(responseData);
      } else {
        _vendor = Vendor(
            id: prefs.getString(Datakeys.vendorId),
            name: prefs.getString(Datakeys.vendorName),
            phone: prefs.getString(Datakeys.vendorPhone),
            pos: json.decode(prefs.getString(Datakeys.vendorPos)),
            companyName: prefs.getString(Datakeys.vendorCompanyName),
            companyAddress: prefs.getString(Datakeys.vendorCompanyAddress),
            username: prefs.getString(Datakeys.vendorUsername),
            address: prefs.getString(Datakeys.vendorAddress),
            dateCreated: prefs.getString(Datakeys.vendorDateCreated));
      }
    }
    return true;
  }

  /// saves user to firebase and on disk immediately after signup
  Future<bool> _saveUserOnSignUp(
      Map<String, dynamic> userData, String collectionName) async {
    try {
      // Geolocator geolocator = Geolocator();
      // Position position = await geolocator.getCurrentPosition(
      //     desiredAccuracy: LocationAccuracy.high);

      // List<double> pos =
      //     position == null ? null : [position.latitude, position.longitude];
      // userData[collectionName.substring(0, collectionName.length - 1) + "Pos"] =
      //     pos;

      final http.Response response = await http.post(
          Uri.parse(
              "$_dbUrl/$collectionName.json?auth=${_authenticatedUser.token}"),
          body: json.encode(userData));
      if (response.statusCode != 200 && response.statusCode != 201) {
        _authenticatedUser.markedForDelete = true;
        return false;
      }

      _authenticatedUser.profileId = jsonDecode(response.body)["name"];
      // String idString = _authenticatedUser.userType == UserType.Client ? "clientId" : "vendorId";
      // userData[idString] = jsonDecode(response.body)["name"];

      await _initializeUser(userData);

      await _saveUserProfileData(
          vendor == null ? _client.toMap() : _vendor.toMap());

      return true;
    } catch (error) {
      print(error);

      return false;
    }
  }

  Future<bool> updateUser(String collectionName,
      {Client client, Vendor vendor}) async {
    toggleLoading(true);

    try {
      final http.Response response = await http.put(
          Uri.parse(
              "$_dbUrl/$collectionName/${collectionName == 'clients' ? _client.id : _vendor.id}.json?auth=${_authenticatedUser.token}"),
          body: json.encode(vendor == null ? client.toMap() : vendor.toMap()));

      if (response.statusCode != 200 && response.statusCode != 201) {
        toggleLoading(false);
        return false;
      }

      if (collectionName == "clients") {
        _client = client;
        print(json.encode(_client.toMap()));
      } else {
        _vendor = vendor;
      }

      // final Map<String, dynamic> responseData = json.decode(response.body);
      // userData['id'] = responseData['name'];
      await _saveUserProfileData(
          vendor == null ? client.toMap() : vendor.toMap());

      toggleLoading(false);
      return true;
    } catch (error) {
      print(error);

      toggleLoading(false);
      return false;
    }
  }

  Future<bool> _deleteAuthUser(String idToken) async {
    final http.Response deleteResponse = await http.post(
        Uri.parse(
            "https://www.googleapis.com/identitytoolkit/v3/relyingparty/deleteAccount?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}));

    Map<String, dynamic> deleteResponseData = jsonDecode(deleteResponse.body);
    if (deleteResponseData.containsKey("kind")) {
      _authenticatedUser = null;
    } else {
      return false;
    }
    return true;
  }

  Future<Map<String, dynamic>> signup(String email, String password,
      {Client client, Vendor vendor}) async {
    // final Map<String, dynamic> authData =
    toggleLoading(true);

    final http.Response response = await http.post(
        Uri.parse(
            "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=${_apiKey}"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'email': email, 'password': password, 'returnSecureToken': true}));

    // _isLoading = false;
    // notifyListeners();
    // final bool paystackCustomerCreated = await MainModel.mainModel.createPaystackCustomer();
    // if(!paystackCustomerCreated){
    //   toggleLoading(false);
    //   return {'success': false, 'message': "Something wrong happened, Please try again"};
    // }

    // print(response.body);
    final Map<String, dynamic> responseData = json.decode(response.body);
    bool success = false;
    String message = 'Authentication Success';
    if (responseData.containsKey('idToken')) {
      bool userAdded = false;
      if (vendor == null) {
        await _initializeAuthUser(responseData, UserType.Client);
        userAdded = await _saveUserOnSignUp(client.toMap(), 'clients');
      } else {
        await _initializeAuthUser(responseData, UserType.Vendor);
        userAdded = await _saveUserOnSignUp(vendor.toMap(), 'vendors');
      }
      success = userAdded;

      if (userAdded) {
        _saveAuthUser(responseData);
      } else {
        await _deleteAuthUser(responseData['idToken']);
      }

      if (!success) message = 'Failed to upload user data';
    } else {
      switch (responseData['error']['message']) {
        case 'EMAIL_EXISTS':
          message = 'Your email already exists';
          break;

        case 'INVALID_EMAIL':
          message = 'Your email is invalid';
          break;

        default:
          message = 'Something went wrong';
          print(responseData['error']['message']);
          break;
      }
    }

    toggleLoading(false);
    return {'success': success, 'message': message};
  }

  /// Log user in
  Future<Map<String, dynamic>> login(
      String email, String password, UserType userType) async {
    toggleLoading(true);

    http.Response response;

    try {
      response = await http.post(
          Uri.parse(
              "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$_apiKey"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));
    } catch (err) {
      print(err);
      toggleLoading(false);
      return {'success': false, 'message': "Could not connect", 'code': -1};
    }

    // FirebaseUser user = await FirebaseAuth.instance.signInWithEmailAndPassword(
    //   email: email,
    //   password: password
    // );
    // .catchError((e){
    //   print(e);
    //   // print(e['message']);
    //   // print(json.encode(e));
    // });

    print(json.encode(user.toString()));

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool success = false;
    String message = 'Authentication Failed';
    int code = -1;
    if (responseData.containsKey('idToken')) {
      // if(user.){
      await _initializeAuthUser(responseData, userType);
      if (_authenticatedUser.markedForDelete) {
        final bool userDeleted = await _deleteAuthUser(responseData['idToken']);
        return userDeleted
            ? {
                'success': success,
                'message': 'Your email is not registered',
                'code': 0
              }
            : {'success': success, 'message': message, 'code': code};
      }
      await _saveAuthUser(responseData);
      bool userDataLoaded =
          await _getUserDataOnLogin(); //! prevent login if data not saved locally

      if (userDataLoaded)
        success = true;
      else {
        message = "User does not exist, Please sign up";
        code = 0;
      }
    } else {
      switch (responseData['error']['message']) {
        case 'EMAIL_NOT_FOUND':
          message = 'Your email is not registered';
          code = 0;
          break;

        case 'INVALID_PASSWORD':
          message = 'Your password is invalid';
          code = 1;
          break;

        case 'USER_DISABLED':
          message = 'Your account has been disabled';
          code = 2;
          break;

        default:
          message = 'Something went wrong';
          print(responseData['error']['message']);
          break;
      }
    }

    toggleLoading(false);

    return {'success': success, 'message': message, 'code': code};
  }

  Future<bool> logout() async {
    _authenticatedUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
    return true;
  }

  void fetchVendors() {
    _isLoading = true;
    notifyListeners();

    http.get(Uri.parse('$_dbUrl/vendors.json')).then((http.Response response) {
      final List<Vendor> fetchedVendorList = [];
      final Map<String, dynamic> vendorListData = json.decode(response.body);
      if (vendorListData != null) {
        vendorListData.forEach((String vendorId, dynamic vendorData) {
          final Vendor product = Vendor(
            id: vendorId,
            name: vendorData['name'],
            companyName: vendorData[Datakeys.vendorCompanyName],
            companyAddress: vendorData[Datakeys.vendorCompanyAddress],
            phone: vendorData['phone'],
            username: vendorData['username'],
            address: vendorData['address'],
            dateCreated: vendorData['dateCreated'],
            rating: vendorData['rating'],
            rate: vendorData['rate'],
            verified: vendorData['verified'],
          );
          fetchedVendorList.add(product);
        });
        _vendors = fetchedVendorList;
      }
      _isLoading = false;
      notifyListeners();
    }).timeout(Duration(seconds: _httpTimeout), onTimeout: () {
      _isLoading = false;
      notifyListeners();
    });
  }
}

class PaymentModel extends ConnectedModel {
  String _paystackKey = "sk_test_5b529119ae8d6edb4b42e831eb3b072526ad6c0a";
  String _url = "https://api.paystack.co/";
  String _transactionAuthorizationUrl;
  String _transactionReference;
  bool _transactionSuccess = false;

  double _walletBalance;

  PaystackSubAccount _paystackSubAccount;

  String get transactionAuthorizationUrl {
    return _transactionAuthorizationUrl;
  }

  double get walletBalance {
    return _walletBalance;
  }

  bool get transactionSuccess {
    return _transactionSuccess;
  }

  /// create new paystack customer
  Future<bool> createPaystackCustomer() async {
    toggleLoading(true);

    http.Response response;

    try {
      response = await http.post(Uri.parse("$_url/customer"),
          headers: {
            "Authorization": "Bearer $_paystackKey",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "email": _authenticatedUser.email,
            "first_name": _client.name ?? _vendor.name
          }));
    } catch (err) {
      print(err);
      toggleLoading(false);
      return false;
    }

    print(response.body);

    Map<String, dynamic> customerData = jsonDecode(response.body);
    if (customerData["status"]) {
      _walletBalance = await fetchWalletBalance();
    }

    toggleLoading(false);
    return customerData["status"];
  }

  /// fetch paystack customer
  Future<bool> fetchPaystackCustomer() async {
    http.Response response = await http.get(
      Uri.parse("$_url/customer/${_authenticatedUser.email}"),
      headers: {
        "Authorization": "Bearer $_paystackKey",
        // "Content-Type": "application/json"
      },
    );

    print(response.body);
    Map<String, dynamic> customerData = jsonDecode(response.body);
    if (customerData["status"]) {
      // todo: sum up all transactions to get wallet total
    }

    return customerData["status"];
  }

  //? SUB-ACCOUNTS

  /// create new paystack sub-account
  Future<bool> createPaystackSubAccount(
      String accountNumber, String bankName) async {
    toggleLoading(true);

    http.Response response = await http.post(Uri.parse("$_url/subaccount"),
        headers: {
          "Authorization": "Bearer $_paystackKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "business_name": _client == null
              ? _vendor.companyName
              : "${_client.name} Waste MX",
          "settlement_bank": accountNumber,
          "account_number": bankName,
          "percentage_charge": 3
        }));

    toggleLoading(false);

    Map<String, dynamic> subAccountData = jsonDecode(response.body);
    if (subAccountData["status"]) {
      if (_client != null)
        _client.subAccountCode = subAccountData["data"]["subaccount_code"];
      else
        _vendor.subAccountCode = subAccountData["data"]["subaccount_code"];
    }

    return subAccountData["status"];
  }

  /// update paystack sub-account
  Future<bool> updatePaystackSubAccount(
      PaystackSubAccount paystackSubAccount) async {
    toggleLoading(true);

    http.Response response = await http.put(
        Uri.parse(
            "$_url/subaccount/${_client == null ? _client.subAccountCode : _vendor.subAccountCode}"),
        headers: {
          "Authorization": "Bearer $_paystackKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode(paystackSubAccount.toMap()));

    toggleLoading(false);

    Map<String, dynamic> subAccountData = jsonDecode(response.body);

    return subAccountData["status"];
  }

  /// fetch paystack sub-account
  Future<bool> fetchPaystackSubAccount() async {
    toggleLoading(true);

    http.Response response = await http.get(
        Uri.parse(
            "$_url/subaccount/${_client == null ? _client.subAccountCode : _vendor.subAccountCode}"),
        headers: {
          "Authorization": "Bearer $_paystackKey",
          // "Content-Type": "application/json"
        });

    toggleLoading(false);

    Map<String, dynamic> subAccountData = jsonDecode(response.body);
    _paystackSubAccount = PaystackSubAccount.fromMap(subAccountData);

    return subAccountData["status"];
  }

  //? TRANSACTIONS

  /// intialiaze transaction with paystack
  Future<bool> initializePaystackTransaction(double amount) async {
    toggleLoading(true);

    print(amount);

    http.Response response = await http.post(
        Uri.parse("$_url/transaction/initialize"),
        headers: {
          "Authorization": "Bearer $_paystackKey",
          "Content-Type": "application/json"
        },
        body:
            jsonEncode({"amount": amount, "email": _authenticatedUser.email}));

    toggleLoading(false);

    print(response.body);
    Map<String, dynamic> transactionData = jsonDecode(response.body);

    if (transactionData["status"] == true) {
      _transactionAuthorizationUrl =
          transactionData["data"]["authorization_url"];
      _transactionReference = transactionData["data"]["reference"];
    }

    return transactionData["status"];
  }

  Future<String> verifyPaystackTransaction() async {
    toggleLoading(true);

    http.Response response = await http.get(
      Uri.parse("$_url/transaction/verify/$_transactionReference"),
      headers: {
        "Authorization": "Bearer $_paystackKey",
      },
    );

    print(response.body);
    Map<String, dynamic> transactionData = jsonDecode(response.body);

    bool walletUpdated = false;

    if (transactionData["status"] == true) {
      print(transactionData["data"]["status"]);
      if (transactionData["data"]["status"] == "success") {
        _transactionSuccess = true;
        //! make sure that this process completes: very crucial
        //todo: make sure that this process completes: very crucial
        walletUpdated = await updateWalletBalance(
            transactionData["data"]["amount"].toDouble() / 100);
      } else {
        _transactionSuccess = false;
      }
    }

    toggleLoading(false);

    return transactionData["data"]["gateway_response"];
  }

  Future creditMXWallet(double amount, details) async {}

  //? WALLET BALANCE

  ///fetch user wallet balance
  Future<double> fetchWalletBalance() async {
    String url =
        "$_dbUrl/clients/${_authenticatedUser.profileId}.json?auth=${_authenticatedUser.token}";

    http.Response response = await http.get(Uri.parse(url));

    Map<String, dynamic> responseData = json.decode(response.body);
    print(responseData);
    double _walletBalance = responseData["walletBalance"] ?? 0;

    return _walletBalance;
  }

  ///update user wallet balance
  Future<bool> updateWalletBalance(double amount) async {
    double _walletBalance = await fetchWalletBalance();

    _walletBalance += amount;
    var userData = _vendor == null ? _client.toMap() : _vendor.toMap();
    userData["walletBalance"] = _walletBalance;

    http.Response response = await http.put(
        Uri.parse(
            '$_dbUrl/${_vendor == null ? "clients" : "vendors"}/${_vendor == null ? _client.id : _vendor.id}.json?auth=${_authenticatedUser.token}'),
        body: jsonEncode(userData));

    var responseData = jsonDecode(response.body);
    return responseData != null && responseData.keys.toList()[0] != null;
  }
}

class OfferingModel extends ConnectedModel {
  Map<String, List> _offerings = Map<String, List>();
  String _currentOfferingType;
  double _currentOfferingAmount;
  bool _offeringPayable = false;

  Map<String, List> get allOfferings {
    return Map.from(_offerings);
  }

  String get currentOfferingType {
    return _currentOfferingType;
  }

  double get currentOfferingAmount {
    return _currentOfferingAmount;
  }

  bool get offeringPayable {
    return _offeringPayable;
  }

  toggleOfferingPayable(bool value) {
    _offeringPayable = value;
  }

  Future<String> getLocation() async {
    _gettingLocation = true;
    notifyListeners();

    // try {
    //   // Geolocator geolocator = Geolocator();
    //   // Position position = await geolocator.getCurrentPosition(
    //   //     desiredAccuracy: LocationAccuracy.high);
    //   // // .timeout(Duration(seconds: 10), onTimeout: (){
    //   // //   print('get location timeout');
    //   // // });
    //   // print(position.longitude);
    //   // if (position == null) {
    //   //   _gettingLocation = false;
    //   //   notifyListeners();
    //      return '';
    //   }

    // String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&location_type=ROOFTOP&result_type=street_address&key=YOUR_API_KEY";
    // List<Placemark> placemark =
    //     await geolocator.placemarkFromPosition(position);
    // .catchError((error){
    //   print(error);
    // });
    // .timeout(Duration(seconds: 5), onTimeout: (){
    //   print('get location placement timeout');
    // });
    // if (placemark == null) {
    //   _gettingLocation = false;
    //   notifyListeners();
    //   return '';
    // }

    _gettingLocation = false;
    notifyListeners();
    // print('position: ' + position.latitude.toString());

    // Placemark p = placemark[0];

    //   return '${p.thoroughfare}, ${p.postalCode}, ${p.locality}, ${p.administrativeArea}, ${p.country}';
    // } catch (e) {
    //   print(e.toString());
    //   _gettingLocation = false;
    //   notifyListeners();
    //   return '';
    // }
  }

  Future<UploadImageData> uploadImage(File image, {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            "https://us-central1-waste-mx.cloudfunctions.net/storeImage"));
    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    imageUploadRequest.files.add(file);
    if (imagePath != null) {
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }
    imageUploadRequest.headers['Authorization'] =
        'Bearer ${_authenticatedUser.token}';
    try {
      final responseStream = await imageUploadRequest.send();
      final response = await http.Response.fromStream(responseStream);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Something went wrong');
        print(json.decode(response.body));
        return null;
      }
      final responseData = json.decode(response.body);
      return UploadImageData(
          imageUrl: responseData['imageUrl'],
          imagePath: responseData['imagePath']);
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<List<UploadImageData>> uploadImages(List<File> imageFiles) async {
    // print(imageFiles[0].uri);
    final List<UploadImageData> uploadImageData = new List(imageFiles.length);

    for (int i = 0; i < imageFiles.length; i++) {
      UploadImageData uploadImageDataOne = await uploadImage(imageFiles[i]);
      // print(uploadImageDataOne);
      uploadImageData.add(uploadImageDataOne);
    }

    return uploadImageData;
  }

  Future<List<Vendor>> fetchClosestVendors() async {
    toggleLoading(true);
    final response = await http.post(
        Uri.parse(
            "https://us-central1-waste-mx.cloudfunctions.net/fetchClosestVendors"),
        body: json.encode({'pos': _client.pos}),
        headers: {
          'Authorization': 'Bearer ${_authenticatedUser.token}',
          'Content-Type': 'application/json'
        });
    print(response.body);
    List<Vendor> _closestVendors = List<Vendor>();
    Map<String, dynamic> _closestVendorsData = json.decode(response.body);
    _closestVendorsData.forEach((String key, dynamic value) {
      print(key);
      value.forEach((String key, dynamic vendorData) {
        print(key);
        _closestVendors.add(Vendor(
            id: key,
            name: vendorData[Datakeys.vendorName],
            username: vendorData[Datakeys.vendorUsername],
            phone: vendorData[Datakeys.vendorPhone],
            address: vendorData[Datakeys.vendorAddress],
            dateCreated: vendorData[Datakeys.vendorDateCreated],
            pos: vendorData[Datakeys.vendorPos].map<double>((x) {
              return double.parse(x.toString());
            }).toList(),
            verified: vendorData[Datakeys.vendorVerified],
            rating: vendorData[Datakeys.vendorRating],
            rate: vendorData[Datakeys.vendorRate],
            distance: vendorData["distance"]));
      });
    });
    // toggleLoading(false);
    _isLoading = false;
    return _closestVendors;
  }

  //! join the 3 methods below
  Future<bool> addDeclusterOffering(
      DeclusterOffering offering, List<File> imageFiles) async {
    _isLoading = true;
    notifyListeners();
    final List uploadImageData = new List(imageFiles.length);
    final List _uploadImageUrls = new List(imageFiles.length);
    final List _uploadImagePaths = new List(imageFiles.length);
    // imageFiles.forEach((File imageFile) {
    //   uploadImageData.add(await uploadImage(imageFile));
    // });
    for (int i = 0; i < imageFiles.length; i++) {
      uploadImageData[i] = await uploadImage(imageFiles[i]);
      _uploadImageUrls[i] = uploadImageData[i]['imageUrl'];
      _uploadImagePaths[i] = uploadImageData[i]['imagePath'];
    }

    if (uploadImageData == null) {
      print('Upload Failed');
      return false;
    }

    _currentOfferingAmount = double.parse(offering.price);

    final Map<String, dynamic> offeringData = {
      'name': offering.name,
      'imageUrls': _uploadImageUrls,
      'price': offering.price,
      'rate': offering.rate,
      // 'weight': offering.weight,
      Datakeys.clientName: offering.clientName,
      'clientLocation': offering.clientLocation,
      'userId': _authenticatedUser.id,
      'imagePath': _uploadImagePaths,
    };

    try {
      final http.Response response = await http.post(
          Uri.parse(
              '$_dbUrl/recycle_offerings.json?auth=${_authenticatedUser.token}'),
          body: json.encode(offeringData));
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      //? save uploaded offering locally
      final RecycleOffering newDisposeOffering = RecycleOffering(
        id: responseData['name'],
        name: offering.name,
        imageUrls: _uploadImageUrls,
        price: offering.price,
        rate: offering.rate,
        // weight: offering.weight,
        clientName: offering.clientName,
        clientLocation: offering.clientLocation,
        userId: _authenticatedUser.id,
        imagePaths: _uploadImagePaths,
      );
      _offerings['Decluster Offerings'].add(newDisposeOffering);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      print(error);
      return false;
    }
  }

  Future<bool> addRecycleOffering(
      RecycleOffering offering, List<File> imageFiles) async {
    _isLoading = true;
    notifyListeners();
    final List uploadImageData = new List(imageFiles.length);
    final List _uploadImageUrls = new List(imageFiles.length);
    final List _uploadImagePaths = new List(imageFiles.length);
    // imageFiles.forEach((File imageFile) {
    //   uploadImageData.add(await uploadImage(imageFile));
    // });
    for (int i = 0; i < imageFiles.length; i++) {
      uploadImageData[i] = await uploadImage(imageFiles[i]);
      _uploadImageUrls[i] = uploadImageData[i]['imageUrl'];
      _uploadImagePaths[i] = uploadImageData[i]['imagePath'];
    }

    if (uploadImageData == null) {
      print('Upload Failed');
      return false;
    }

    _currentOfferingAmount = double.parse(offering.price);

    final Map<String, dynamic> offeringData = {
      'name': offering.name,
      'imageUrls': _uploadImageUrls,
      'price': offering.price,
      'rate': offering.rate,
      'weight': offering.weight,
      Datakeys.clientName: offering.clientName,
      'clientLocation': offering.clientLocation,
      'userId': _authenticatedUser.id,
      'imagePath': _uploadImagePaths,
    };

    try {
      final http.Response response = await http.post(
          Uri.parse(
              '$_dbUrl/recycle_offerings.json?auth=${_authenticatedUser.token}'),
          body: json.encode(offeringData));
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      //? save uploaded offering locally
      final RecycleOffering newDisposeOffering = RecycleOffering(
        id: responseData['name'],
        name: offering.name,
        imageUrls: _uploadImageUrls,
        price: offering.price,
        rate: offering.rate,
        weight: offering.weight,
        clientName: offering.clientName,
        clientLocation: offering.clientLocation,
        userId: _authenticatedUser.id,
        imagePaths: _uploadImagePaths,
      );
      _offerings['Recycle Offerings'].add(newDisposeOffering);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      print(error);
      return false;
    }
  }

  Future<bool> addDisposeOffering(
      DisposeOffering offering, List<File> imageFiles) async {
    toggleLoading(true);

    List<UploadImageData> uploadImageData = await uploadImages(imageFiles);
    if (uploadImageData == null) {
      print('Upload Failed');
      return false;
    }
    offering.imageData = uploadImageData;

    _currentOfferingAmount = double.parse(offering.price);

    _offerings[OfferingType.dispose] = [];
    try {
      final http.Response response = await http.post(
          Uri.parse(
              '$_dbUrl/dispose_offerings.json?auth=${_authenticatedUser.token}'),
          body: json.encode(offering.toMap()));
      if (response.statusCode != 200 && response.statusCode != 201) {
        toggleLoading(false);

        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      //todo: save uploaded offering locally
      offering.id = responseData["name"];

      _currentOfferingType = OfferingType.dispose;
      _offerings[OfferingType.dispose].insert(0, offering);

      toggleLoading(false);
      return true;
    } catch (error) {
      print(error);

      toggleLoading(false);
      return false;
    }
  }

  void fetchOfferings() async {
    toggleLoading(true);

    http.Response response1 = await http.get(Uri.parse(
        '$_dbUrl/dispose_offerings.json?auth=${_authenticatedUser.token}'));
    // print(response1.body);
    // http.Response response2 = await http.get('$_dbUrl/recycle_offerings.json?auth=${_authenticatedUser.token}');

    final List<DisposeOffering> disposeOfferings = [];
    final Map<String, dynamic> offeringsData = json.decode(response1.body);
    if (offeringsData != null) {
      offeringsData.forEach((String offeringId, dynamic offeringData) {
        final DisposeOffering offering = DisposeOffering.fromMap(offeringData);
        disposeOfferings.add(offering);
      });
      _offerings['Dispose Offerings'] = disposeOfferings;
    }

    toggleLoading(false);
  }

  //TODO: implement update
  //TODO: implement delete
  //? make sure to add ?auth=<idToken> in the urls
}

class TransactionModel extends ConnectedModel {
  /// add new [Transaction]
  Future<bool> addTransaction(Transaction transaction) async {
    toggleLoading(true);

    http.Response response = await http.post(
        Uri.parse(
            "$_dbUrl/transactions/${_authenticatedUser.profileId}.json?auth=${_authenticatedUser.token}"),
        body: jsonEncode(transaction.toMap()));

    if (response.statusCode != 200 && response.statusCode != 201) {
      toggleLoading(false);
      return false;
    }

    _transactions.add(transaction);
    toggleLoading(false);
    return true;
  }

  /// fetch all [Transactions] associated with user
  Future<bool> fetchTransactions() async {
    toggleLoading(true);

    http.Response response = await http.get(Uri.parse(
        "$_dbUrl/transactions/${_authenticatedUser.profileId}.json?auth=${_authenticatedUser.token}"));
    if (response.statusCode != 200 && response.statusCode != 201) {
      toggleLoading(false);
      return false;
    }

    List<Map<String, dynamic>> responseData = jsonDecode(response.body);
    _transactions = []; // reset transactions
    responseData.forEach((Map<String, dynamic> data) {
      _transactions.add(Transaction.fromMap(data));
    });

    toggleLoading(false);
    return true;
  }

  /// move pending [Transaction] amount to [Escrow]
  Future<bool> addEscrow(Escrow escrow) async {
    toggleLoading(true);

    http.Response response = await http.post(
        Uri.parse(
            "$_dbUrl/escrows/${_authenticatedUser.profileId}.json?auth=${_authenticatedUser.token}"),
        body: jsonEncode(escrow.toMap()));

    if (response.statusCode != 200 && response.statusCode != 201) {
      toggleLoading(false);
      return false;
    }

    // _escrows.add(escrow);
    toggleLoading(false);
    return true;
  }
}

/*
class TransactionModel extends ConnectedModel{
  Wallet _wallet;
  String _authEmail = "test4@skyblazar.com";
  String _walletToken;

  Wallet get wallet{
    return _wallet;
  }

  String _kurepayUrl = "https://wallet.kurepay.com/api/v2";
  Future registerWallet([bool toggle = true]) async{
    if(toggle) toggleLoading(true);

    Random _random = Random.secure();
    String _password = String.fromCharCodes(List.generate(12, (index){
      return _random.nextInt(33)+89;
    }));

    Map<String, dynamic> data = {
      "fullname": _client.name,
      "email": _authEmail, // _authenticatedUser.email,
      "password": _password,
      "activateEmail": 1,
      "refId": 861699
    };
    String dataString = jsonEncode(data);
    print(dataString);

    http.Response response = await http.post("$_kurepayUrl/auth/register", body: dataString,
    headers: {
      "Content-Type": "application/json",
    });
    print(response.body);

    if(json.decode(response.body)["status"] == false) return;

    FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: "KurePayPassword", value: _password);
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString("pbackup", _password);

    http.Response dbWalletResponse = await http.post("$_dbUrl/wallets/${_authenticatedUser.id}.json", 
      body: json.encode(data));

    Map<String, dynamic> responseData = json.decode(dbWalletResponse.body);
    _wallet = Wallet(
      id: responseData['name'],
      fullname: _client.name,
      email: _authEmail,// _authenticatedUser.email,
    );

    toggleLoading(false);
  }

  Future loginWallet() async{
    toggleLoading(true);

    FlutterSecureStorage storage = FlutterSecureStorage();
    String _password = await storage.read(key: "KurePayPassword");
    print(_password);
    if(_password == null) return registerWallet(false);

    Map<String, dynamic> data = {
      "email": _authEmail,// _authenticatedUser.email,
      "password": _password
    };

    http.Response response = await http.post("$_kurepayUrl/auth/login", body: json.encode(data), headers: {
      "Content-Type": "application/json",
    });
    print(response.body);
    Map<String, dynamic> responseData = jsonDecode(response.body);
    _walletToken = responseData["token"];
    // _wallet = Wallet(
    //   fullname: responseData["fullname"],
    //   email: responseData["email"],
    //   refId: responseData["refId"]
    // );

    http.Response dashboardResponse = await http.get("$_kurepayUrl/dashboard",
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_walletToken"
    });
    print(dashboardResponse.body);
    Map<String, dynamic> dashboardData = jsonDecode(dashboardResponse.body)["data"];
    _wallet = Wallet(
      fullname: responseData["fullname"],
      email: responseData["email"],
      refId: responseData["refId"],
      balance: dashboardData["balance"],
      transactions: dashboardData["transactions"],
      localCurrency: dashboardData["localCurrency"]
    );
    toggleLoading(false);
  }

  Future creditWallet(double amount, CardDetails _cardDetails) async {
    toggleLoading(true);
    http.Response response = await http.post("https://payment.kurepay.com/api/charge-card",
    body: jsonEncode({
      "customerEmail": _authEmail,
      "reference": DateTime.now().toIso8601String(),
      "number": "50785078507850784",
      "expiry_month": "11",
      "expiry_year": "19",
      "cvv": "844",
      "pin": "0000",
      "unit_cost": "1200",
      "customerFirstName": "King",
      "customerLastName": "Test",
      "phone": "+2348181818181",
      "item": "Credit Wallet",
      "description": "Add money to KurePay wallet for WasteMX"
    }), //_cardDetails.toMap()
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_walletToken"
    });
    print(response.body);
    toggleLoading(false);
  }
}
*/
