
import 'dart:html';

import 'package:bones_ui/bones_ui.dart';
import 'package:dynamic_call/dynamic_call.dart';
import 'ocean_press_base.dart';
import 'package:social_login_web/facebook_login.dart';

import 'ocean_press_ui.dart';

////////////////////////////////////////////////////////////////////////////////

OceanExpressApp OCEAN_EXPRESS_APP = OceanExpressApp() ;

////////////////////////////////////////////////////////////////////////////////

class LoginState extends State {

  LoginState(DataStorage storage) : super(storage, 'login') ;

  String getUsername() {
    return get('username');
  }

  void setUsername(String username) {
    set('username', username);
  }

}

class OceanExpressApp {

  static String normalizeID(String id) {
    if (id == null) return "" ;
    id = id.trim().toLowerCase().replaceAll( RegExp(r'\W+') , "_") ;
    return id ;
  }

  void configure(String name, OceanAppSystem oceanAppSystem, [String facebookID]) {
    this._name = name ;
    this._id = normalizeID(this._name) ;
    this._system = oceanAppSystem ;
    this._facebookID = facebookID ;
  }

  ///////////////////////////////////////////////////////////////////

  static Element resolveElement( dynamic element ) {
    if (element == null) return null ;

    if ( element is Element ) return element ;

    if ( element is String ) {
      String id = element.trim() ;
      return querySelector(id) ;
    }

    if ( element is Function ) {
      Function f = element ;
      dynamic res = f() ;
      return resolveElement(res) ;
    }

    throw ArgumentError("Can't resolve Element with parameter of type: ${ element.runtimeType }") ;
  }

  void initialize([dynamic uiOutput]) {
    Element outputElem = resolveElement(uiOutput) ;
    _initializeImpl(outputElem) ;
  }

  bool get initialized => _initializedStorage && _initializedUI ;

  void _initializeImpl([Element uiOutput]) {
    _initializeStorage();
    _initializeUI(uiOutput);
  }

  ///////////////////////////////////////////////////////////////////

  String _id = "app" ;
  String get id => _id;

  String _name = "app" ;
  String get name => _name;

  ///////////////////////////////////////////////////////////////////

  String _facebookID ;
  String get facebookID => _facebookID;

  bool get hasFacebookID => _facebookID != null && _facebookID.isNotEmpty ;

  ///////////////////////////////////////////////////////////////////

  bool _initializedUI = false ;

  void _initializeUI(Element uiOutput) {
    if (uiOutput == null) return ;

    if (_initializedUI) return;
    _initializedUI = true;

    _initializeUIImpl(uiOutput) ;
  }

  void _initializeUIImpl(Element uiOutput) {
    var root = OPRoot(uiOutput);
    root.initialize();
  }

  ///////////////////////////////////////////////////////////////////

  DataStorage _dataStorage ;
  DataStorage get dataStorage => _dataStorage;

  LoginState _loginState ;
  LoginState get loginState => _loginState;

  bool _initializedStorage = false ;

  void _initializeStorage() {
    if (_initializedStorage) return ;
    _initializedStorage = true ;

    _dataStorage = DataStorage(_id, DataStorageType.PERSISTENT) ;
    _loginState = LoginState(_dataStorage) ;
  }

  ///////////////////////////////////////////////////////////////////

  OceanAppSystem _system ;
  OceanAppSystem get system => _system;

  BuildElement setupLogoFunction ;

  void setupLogo(Element element, String context) {
    if (setupLogoFunction == null) {
      setupLogoDefault(element, context);
    }
    else {
      setupLogoFunction(element, context) ;
    }
  }

  void setupLogoDefault(Element element, String context) {
    String name = this.name ?? "" ;
    name = name.trim().toUpperCase();
    element.innerHtml = "<b>$name</b>" ;
  }

  Future<bool> initializeMessages(String locale) {
    _initializeImpl();

    OCEAN_PRESS_MESSAGES.onRegisterLocalizedMessages.listen(_onRegisterLocalizedMessages, singletonIdentifier: this) ;
    
    return OCEAN_PRESS_MESSAGES.autoDiscoverLocale(locale) ;
  }
  
  void _onRegisterLocalizedMessages(String locale) {
    if ( OCEAN_PRESS_MESSAGES.currentLocale.code == locale ) {
      UIRoot.getInstance().refresh();
    }
  }

  void initFacebookLogin() {
    if ( !hasFacebookID ) return ;
    _initializeImpl();

    FacebookLogin.init(_facebookID, validateFacebookLogin) ;
  }

  Future<bool> validateFacebookLogin(FBUserLogin user) {
    _initializeImpl();
    return Future.value(true) ;
  }

  bool _usesLogin = true ;

  bool get usesLogin => _usesLogin;

  set usesLogin(bool value) {
    _usesLogin = value ?? false ;
  }

  bool _canCreateAccount = true ;

  bool get canCreateAccount => _canCreateAccount;

  set canCreateAccount(bool value) {
    _canCreateAccount = value ?? false ;
  }

  bool _canChangePassword = true ;


  bool get canChangePassword => _canChangePassword;

  set canChangePassword(bool value) {
    _canChangePassword = value ?? false ;
  }

  String _homeRoute = 'home' ;
  String get homeRoute => _homeRoute ?? 'home' ;

  set homeRoute(String route) {
    if (route != null) route = route.trim() ;
    _homeRoute = route.isNotEmpty ? route : null ;
  }

  Map<String, OPComponent> sections = {} ;

  void registerSection(OPComponent section, [bool home]) {
    var route = section.route;
    if (route == null) throw ArgumentError("Section route can't be null: $section") ;

    sections[ route ] = section ;

    if (home != null && home) {
      this._homeRoute = route;
    }
  }

  List<String> getSectionsRoutes() {
    return List.from( sections.keys ) ;
  }

  List<String> getSectionsNames() {
    return List.from( sections.values.map( (s) => s.name ) ) ;
  }

  List<OPComponent> getSections() {
    return List.from( sections.values ) ;
  }

  OPComponent getSectionComponent(String route, Element parent) {
    var section = sections[route] ;
    if (section == null) return null ;
    section.setParent(parent) ;
    return section ;
  }

  DynCallHttpClient _restClient ;

  DynCallHttpClient getHttpClient() {
    if (_restClient != null) return _restClient ;
    var restClient = DynCallHttpClient( getWSURL() ).autoChangeAuthorizationToBearerToken("X-Access-Token");
    _restClient = restClient ;
    return restClient ;
  }

  String getWSURL() {
    return _system.getWSBaseURL() ;
  }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract class OceanAppSystem {

  final bool _development ;

  OceanAppSystem( [ this._development = false ] );

  bool get development => _development;

  bool _preservePassword = false ;

  bool get preservePassword => _preservePassword;

  set preservePassword(bool value) {
    _preservePassword = value ?? false ;
  }

  final DynCall<dynamic,UserLogin> callLogin = DynCall<dynamic,UserLogin>( ['username','pass'] , DynCallType.JSON , (dynamic userJson) => UserLogin.parse(userJson, _userInstantiator) , true ) ;

  Future<UserLogin> login(String username, String pass, void Function(UserLogin user) onUserLogin) {
    return callLogin.call( {'username': username, 'pass': pass} , (user, params) => _processLogin(user, params, onUserLogin) )  ;
  }

  final DynCall<dynamic,UserLogin> callLoginResume = DynCall<dynamic,UserLogin>( [] , DynCallType.JSON , (dynamic userJson) => UserLogin.parse(userJson, _userInstantiator) , true ) ;

  Future<UserLogin> loginResume(void Function(UserLogin user) onLoginResume) {
    return callLoginResume.call( {} , (user, params) => _processLogin(user, params, onLoginResume) ) ;
  }

  final DynCall<bool,bool> callLogout = DynCall<bool,bool>( ['username'] , DynCallType.BOOL , null, true ) ;

  Future<bool> logout() {
    String username = GlobalUser.user.username ;
    return callLogout.call( {'username': username} , (ok, params) => GlobalUser.logout() ) ;
  }

  String _lastLoginUsername ;
  String get lastLoginUsername => _lastLoginUsername;

  String _lastLoginPassword ;
  String get lastLoginPassword => _lastLoginPassword;

  UserLogin _processLogin(UserLogin user, Map<String,dynamic> parameters, ProcessLoginFunction processFunction) {
    if ( user != null ) {
      _lastLoginUsername = user.username ;

      if ( preservePassword && parameters != null ) {
        var pass = parameters['pass'] ?? parameters['password'] ;
        _lastLoginPassword = pass ;
      }
    }

    user = GlobalUser.processLoginResponse(user, _userInstantiator);

    if ( user != null ) {
      OCEAN_EXPRESS_APP.loginState.setUsername( GlobalUser.user.username ) ;

      if (processFunction != null) processFunction( GlobalUser.user ) ;
      return GlobalUser.user ;
    }
    else {
      if (processFunction != null) processFunction( null ) ;
      return null ;
    }
  }

  static UserLogin _userInstantiator(UserLogin user) {
    if ( user.accountType == "FACEBOOK" ) {
      //return new FBUserLogin.other(user) ;
      throw("FB Login Unsupported") ;
    }
    else {
      return user ;
    }
  }

  Future<bool> doFacebookLogin() ;

  final DynCall<dynamic,UserLogin> callRegister = DynCall<dynamic,UserLogin>( ['name', 'email', 'username', 'password'] , DynCallType.JSON , (dynamic userJson) => UserLogin.parse(userJson, _userInstantiator) ) ;

  Future<UserLogin> register(String name, String email, String username, String pass, void Function(UserLogin user) onRegisteredUser) {
    return callRegister.call( {'name': name, 'email': email, 'username': username, 'password': pass} , (user, params) => _processRegister(user, onRegisteredUser) ) ;
  }

  static UserLogin _processRegister(UserLogin user, ProcessRegisterFunction processFunction) {
    if (user != null) {
      user = GlobalUser.processLoginResponse(user, _userInstantiator);

      if ( user != null ) {
        OCEAN_EXPRESS_APP.loginState.setUsername( GlobalUser.user.username ) ;

        if (processFunction != null) processFunction( GlobalUser.user ) ;
        return GlobalUser.user ;
      }
    }

    if (processFunction != null) processFunction( null ) ;
    return null ;
  }

  final DynCall<bool,bool> callChangePassword = DynCall( ['username','currentPass','newPass'] , DynCallType.BOOL) ;

  Future<bool> changePassword(String username, String currentPass, String newPass) {
    return callChangePassword.call( {'username': username, 'currentPass': currentPass, 'newPass': newPass} )  ;
  }

  /////////////////////////////////////////////////////////

  String getWSHost() {
    if ( development && isLocalhostHref() ) {
      return "localhost" ;
    }
    else if ( development && isIPHref() ) {
      return getHrefHost() ;
    }
    else {
      return getWSDomain() ;
    }
  }

  String getWSDomain() ;
  int getWSPort(String host) ;
  String getWSPath(String host) ;

  bool isWSSecure(String host, int port) {
    if ( host == "localhost" || isIP(host) ) return false ;
    return port == 443 || port.toString().endsWith("3") ;
  }


  String getWSBaseURL() {
    var wsHost = getWSHost();
    var wsPort = getWSPort(wsHost);
    var wsPath = getWSPath(wsHost);

    if (wsHost == null) wsHost = getHrefHost() ;
    if (wsPort == null) wsPort = getHrefPort() ;
    if (wsPath == null) wsPath = "" ;

    if ( wsPath.startsWith('/') ) wsPath = wsPath.substring(1) ;

    var wsSecure = isWSSecure(wsHost, wsPort);

    if (wsSecure && wsPort == 443) {
      return "https://$wsHost/$wsPath" ;
    }
    else if (!wsSecure && wsPort == 80) {
      return "http://$wsHost/$wsPath" ;
    }
    else {
      String scheme = wsSecure ? "https" : "http" ;
      return "$scheme://$wsHost:$wsPort/$wsPath" ;
    }
  }

  DynCallHttpClient getRestClient() {
    return OCEAN_EXPRESS_APP.getHttpClient() ;
  }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef void BuildElement(Element element, String context) ;

typedef void ProcessLoginFunction(UserLogin user) ;
typedef void ProcessRegisterFunction(UserLogin user) ;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
