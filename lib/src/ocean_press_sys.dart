import 'dart:html';

import 'package:bones_ui/bones_ui_kit.dart';
import 'package:bones_ui_bootstrap/bones_ui_bootstrap.dart';
import 'package:dynamic_call/dynamic_call.dart';
import 'package:intl_messages/intl_messages.dart';
import 'package:social_login_web/facebook_login.dart';

import 'ocean_press_base.dart';
import 'ocean_press_ui.dart';

final OceanExpressApp OCEAN_PRESS_APP = OceanExpressApp();

/// [State] for login username.
class LoginState extends State {
  LoginState(DataStorage storage) : super(storage, 'login');

  String getUsername() {
    return get('username');
  }

  void setUsername(String username) {
    set('username', username);
  }
}

/// [State] for access tokens. Used for login refresh.
class AccessTokeState extends State {
  AccessTokeState(DataStorage storage) : super(storage, 'access_token');

  String getToken() {
    return get('token');
  }

  void setToken(String username) {
    set('token', username);
  }
}

typedef OceanExpressAppBuilder = void Function(OceanExpressApp app);

/// The Ocean Press Application.
class OceanExpressApp {
  static String normalizeID(String id) {
    if (id == null) return '';
    id = id.trim().toLowerCase().replaceAll(RegExp(r'\W+'), '_');
    return id;
  }

  OceanExpressApp() {
    Bootstrap.load();
  }

  void configure(String name, String version, OceanAppSystem oceanAppSystem,
      {String companyName, String companyURL, String facebookID}) {
    _name = name;
    _version = version;
    _id = normalizeID(_name);
    _system = oceanAppSystem;

    _companyName = companyName;
    _companyURL = companyURL;

    _facebookID = facebookID;
  }

  static Element resolveElement(dynamic element) {
    if (element == null) return null;

    if (element is Element) return element;

    if (element is String) {
      var id = element.trim();
      return querySelector(id);
    }

    if (element is Function) {
      var f = element;
      dynamic res = f();
      return resolveElement(res);
    }

    throw ArgumentError(
        "Can't resolve Element with parameter of type: ${element.runtimeType}");
  }

  void initialize({dynamic uiOutput, OceanExpressAppBuilder appBuilder}) {
    var outputElem = resolveElement(uiOutput);
    _initializeImpl(uiOutput: outputElem, appBuilder: appBuilder);
  }

  bool get initialized => _initializedStorage && _initializedUI;

  void _initializeImpl({Element uiOutput, OceanExpressAppBuilder appBuilder}) {
    _initializeStorage();
    _initializeUI(uiOutput, appBuilder);
  }

  String _id = 'app';

  String get id => _id;

  String _name = 'app';

  String get name => _name;

  String _version;

  String get version => _version;

  set version(String value) {
    _version = value;
  }

  String _companyName;

  String get companyName =>
      _companyName != null && _companyName.isNotEmpty ? _companyName : null;

  String _companyURL;

  String get companyURL =>
      _companyURL != null && _companyURL.isNotEmpty ? _companyURL : null;

  String _facebookID;

  String get facebookID => _facebookID;

  bool get hasFacebookID => _facebookID != null && _facebookID.isNotEmpty;

  bool _initializedUI = false;

  void _initializeUI(Element uiOutput, OceanExpressAppBuilder appBuilder) {
    if (uiOutput == null) return;

    if (_initializedUI) return;
    _initializedUI = true;

    _initializeUIImpl(uiOutput, appBuilder);
  }

  void _initializeUIImpl(Element uiOutput, OceanExpressAppBuilder appBuilder) {
    var root = OPRoot(uiOutput, appBuilder);
    root.initialize();
  }

  DataStorage _dataStorage;
  DataStorage _sessionDataStorage;

  DataStorage get dataStorage => _dataStorage;

  LoginState _loginState;

  LoginState get loginState => _loginState;

  AccessTokeState _accessTokeState;

  AccessTokeState get accessTokeState => _accessTokeState;

  bool _initializedStorage = false;

  void _initializeStorage() {
    if (_initializedStorage) return;
    _initializedStorage = true;

    _dataStorage = DataStorage(_id, DataStorageType.PERSISTENT);
    _sessionDataStorage = DataStorage(_id, DataStorageType.SESSION);

    _loginState = LoginState(_dataStorage);
    _accessTokeState = AccessTokeState(_sessionDataStorage);
  }

  OceanAppSystem _system;

  OceanAppSystem get system => _system;

  BuildElement setupLogoFunction;

  void setupLogo(Element element, String context) {
    if (setupLogoFunction == null) {
      setupLogoDefault(element, context);
    } else {
      setupLogoFunction(element, context);
    }
  }

  void setupLogoDefault(Element element, String context) {
    var name = this.name ?? '';
    name = name.trim().toUpperCase();
    element.innerHtml = '<b>$name</b>';
  }

  Future<bool> initializeMessages(String locale) {
    _initializeImpl();

    OCEAN_PRESS_MESSAGES.onRegisterLocalizedMessages
        .listen(_onRegisterLocalizedMessages, singletonIdentifier: this);

    messages
        .where((e) => e != null)
        .forEach((e) => e.autoDiscoverLocale(locale));

    return OCEAN_PRESS_MESSAGES.autoDiscoverLocale(locale);
  }

  void _onRegisterLocalizedMessages(String locale) {
    if (OCEAN_PRESS_MESSAGES.currentLocale.code == locale) {
      UIRoot.getInstance().refresh();
    }
  }

  final Set<Future<bool>> readyEvents = {};

  final Set<IntlMessages> messages = {};

  void initFacebookLogin() {
    if (!hasFacebookID) return;
    _initializeImpl();

    FacebookLogin.init(_facebookID, validateFacebookLogin);
  }

  Future<bool> validateFacebookLogin(FBUserLogin user) {
    _initializeImpl();
    return Future.value(true);
  }

  bool _canResumeLogin = true;

  bool get canResumeLogin => _canResumeLogin;

  set canResumeLogin(bool value) {
    _canResumeLogin = value ?? false;
  }

  bool _usesLogin = true;

  bool get usesLogin => _usesLogin;

  set usesLogin(bool value) {
    _usesLogin = value ?? false;
  }

  bool _usernameAsEmail = true;

  bool get usernameAsEmail => _usernameAsEmail;

  set usernameAsEmail(bool value) {
    _usernameAsEmail = value ?? false;
  }

  bool _canCreateAccount = true;

  bool get canCreateAccount => _canCreateAccount;

  set canCreateAccount(bool value) {
    _canCreateAccount = value ?? false;
  }

  bool _canChangePassword = true;

  bool get canChangePassword => _canChangePassword;

  set canChangePassword(bool value) {
    _canChangePassword = value ?? false;
  }

  String _homeRoute = 'home';

  String get homeRoute => _homeRoute ?? 'home';

  set homeRoute(String route) {
    if (route != null) route = route.trim();
    _homeRoute = route.isNotEmpty ? route : null;
  }

  Map<String, OPSection> sections = {};

  void registerSection(OPSection section, [bool home]) {
    var route = section.route;
    if (route == null) {
      throw ArgumentError("Section route can't be null: $section");
    }

    sections[route] = section;

    if (home != null && home) {
      _homeRoute = route;
    }
  }

  List<String> getSectionsRoutes() {
    return List.from(sections.keys);
  }

  List<String> getSectionsNames() {
    return List.from(sections.values.map((s) => s.name));
  }

  List<OPSection> getSections() {
    return List.from(sections.values);
  }

  List<OPSection> getAccessibleSections([bool onlyVisibleInMenu]) {
    onlyVisibleInMenu ??= false;
    return getSections()
        .where(
            (s) => s.isAccessible() && (!onlyVisibleInMenu || s.visibleInMenu))
        .toList();
  }

  OPSection getSection(String route, Element parent) {
    var section = sections[route];
    if (section == null) return null;
    section.setParent(parent);
    return section;
  }

  DynCallHttpClient _restClient;

  DynCallHttpClient getHttpClient() {
    if (_restClient != null) return _restClient;

    var restClient = DynCallHttpClient(getWSURL())
      ..crossSiteWithCredentials = true
      ..autoChangeAuthorizationToBearerToken('X-Access-Token')
      ..authorizationResolutionInterceptor = _onResolvedAuthorization;

    _restClient = restClient;

    return restClient;
  }

  void _onResolvedAuthorization(Authorization authorization) {
    var credential = authorization.tryResolvedCredential;
    if (credential != null && credential is BearerCredential) {
      var token = credential.token;
      accessTokeState.setToken(token);
    }
  }

  String getWSURL() {
    return _system.getWSBaseURL();
  }

  ////////

  bool _navBarBlur = false;

  bool get navBarBlur => _navBarBlur;

  set navBarBlur(bool value) {
    _navBarBlur = value ?? false;
  }

  bool _navBarLogoOnLogin = true;

  bool get navBarLogoOnLogin => _navBarLogoOnLogin;

  set navBarLogoOnLogin(bool value) {
    _navBarLogoOnLogin = value ?? true;
  }

  bool _loginShowWelcomeMessage = true;

  bool get loginShowWelcomeMessage => _loginShowWelcomeMessage;

  set loginShowWelcomeMessage(bool value) {
    _loginShowWelcomeMessage = value ?? true;
  }

  UIComponent _loginFooter;

  UIComponent get loginFooter => _loginFooter;

  set loginFooter(UIComponent value) => _loginFooter = value;

  UIComponent _loginBottomContent;

  UIComponent get loginBottomContent => _loginBottomContent;

  set loginBottomContent(UIComponent value) => _loginBottomContent = value;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract class OceanAppSystem {
  final bool _development;

  OceanAppSystem([this._development = false]);

  bool get development => _development;

  bool _preservePassword = false;

  bool get preservePassword => _preservePassword;

  set preservePassword(bool value) {
    _preservePassword = value ?? false;
  }

  final DynCall<dynamic, UserLogin> callLogin = DynCall<dynamic, UserLogin>(
      ['username', 'pass'], DynCallType.JSON,
      outputFilter: (dynamic userJson) =>
          UserLogin.parse(userJson, _userInstantiator),
      allowRetries: true);

  Future<UserLogin> login(
      String username, String pass, void Function(UserLogin user) onUserLogin) {
    return callLogin.call({'username': username, 'pass': pass},
        (user, params) => _processLogin(user, params, onUserLogin));
  }

  final DynCall<dynamic, UserLogin> callLoginResume =
      DynCall<dynamic, UserLogin>([], DynCallType.JSON,
          outputFilter: (dynamic userJson) =>
              UserLogin.parse(userJson, _userInstantiator),
          allowRetries: true);

  Future<UserLogin> loginResume(void Function(UserLogin user) onLoginResume) {
    return callLoginResume
        .call({}, (user, params) => _processLogin(user, params, onLoginResume));
  }

  final DynCall<bool, bool> callLogout =
      DynCall<bool, bool>(['username'], DynCallType.BOOL, allowRetries: true);

  Future<bool> logout() {
    var username = GlobalUser.user.username;
    return callLogout
        .call({'username': username}, (ok, params) => GlobalUser.logout());
  }

  String _lastLoginUsername;

  String get lastLoginUsername => _lastLoginUsername;

  String _lastLoginPassword;

  String get lastLoginPassword => _lastLoginPassword;

  UserLogin _processLogin(UserLogin user, Map<String, dynamic> parameters,
      ProcessLoginFunction processFunction) {
    if (user != null) {
      _lastLoginUsername = user.username;

      if (preservePassword && parameters != null) {
        var pass = parameters['pass'] ?? parameters['password'];
        _lastLoginPassword = pass;
      }
    }

    user = GlobalUser.processLoginResponse(user, _userInstantiator);

    if (user != null) {
      OCEAN_PRESS_APP.loginState.setUsername(GlobalUser.user.username);

      if (processFunction != null) processFunction(GlobalUser.user);
      return GlobalUser.user;
    } else {
      if (processFunction != null) processFunction(null);
      return null;
    }
  }

  static UserLogin _userInstantiator(UserLogin user) {
    if (user.accountType == 'FACEBOOK') {
      //return new FBUserLogin.other(user) ;
      throw ('FB Login Unsupported');
    } else {
      return user;
    }
  }

  Future<bool> doFacebookLogin() {
    return Future.value(false);
  }

  final DynCall<dynamic, UserLogin> callRegister = DynCall<dynamic, UserLogin>(
      ['name', 'email', 'username', 'password'], DynCallType.JSON,
      outputFilter: (dynamic userJson) =>
          UserLogin.parse(userJson, _userInstantiator));

  Future<UserLogin> register(String name, String email, String username,
      String pass, void Function(UserLogin user) onRegisteredUser) {
    return callRegister.call(
        {'name': name, 'email': email, 'username': username, 'password': pass},
        (user, params) => _processRegister(user, onRegisteredUser));
  }

  static UserLogin _processRegister(
      UserLogin user, ProcessRegisterFunction processFunction) {
    if (user != null) {
      user = GlobalUser.processLoginResponse(user, _userInstantiator);

      if (user != null) {
        OCEAN_PRESS_APP.loginState.setUsername(GlobalUser.user.username);

        if (processFunction != null) processFunction(GlobalUser.user);
        return GlobalUser.user;
      }
    }

    if (processFunction != null) processFunction(null);
    return null;
  }

  final DynCall<bool, bool> callChangePassword =
      DynCall(['username', 'currentPass', 'newPass'], DynCallType.BOOL);

  Future<bool> changePassword(
      String username, String currentPass, String newPass) {
    return callChangePassword.call(
        {'username': username, 'currentPass': currentPass, 'newPass': newPass});
  }

  /////////////////////////////////////////////////////////

  String getWSHost() {
    if (development && isUriBaseLocalhost()) {
      return 'localhost';
    } else if (development && isUriBaseIP()) {
      return getUriBaseHost();
    } else {
      return getWSDomain();
    }
  }

  String getWSDomain();

  int getWSPort(String host);

  String getWSPath(String host);

  bool isWSSecure(String host, int port) {
    if (host == 'localhost' || isIPAddress(host)) return false;
    return port == 443 || port.toString().endsWith('3');
  }

  String getWSBaseURL() {
    var wsHost = getWSHost();
    var wsPort = getWSPort(wsHost);
    var wsPath = getWSPath(wsHost);

    wsHost ??= getUriBaseHost();
    wsPort ??= getUriBasePort();
    wsPath ??= '';

    if (wsPath.startsWith('/')) wsPath = wsPath.substring(1);

    var wsSecure = isWSSecure(wsHost, wsPort);

    if (wsSecure && wsPort == 443) {
      return 'https://$wsHost/$wsPath';
    } else if (!wsSecure && wsPort == 80) {
      return 'http://$wsHost/$wsPath';
    } else {
      var scheme = wsSecure ? 'https' : 'http';
      return '$scheme://$wsHost:$wsPort/$wsPath';
    }
  }

  DynCallHttpClient getRestClient() {
    return OCEAN_PRESS_APP.getHttpClient();
  }
}

typedef BuildElement = void Function(Element element, String context);

typedef ProcessLoginFunction = void Function(UserLogin user);
typedef ProcessRegisterFunction = void Function(UserLogin user);

String buildCopyrightFooterMessage(String copyrightHolder,
    {String holderURL, int initialYear}) {
  var copyrightAllRightsReserved =
      OCEAN_PRESS_MESSAGES.msg('copyrightAllRightsReserved').build();

  var year = DateTime.now().year;
  initialYear ??= year;

  var yearStr = year > initialYear ? '$initialYear-$year' : '$year';

  if (holderURL != null) {
    return 'Copyright © $yearStr <a href="$holderURL" target="_blank">$copyrightHolder</a> - $copyrightAllRightsReserved';
  } else {
    return 'Copyright © $yearStr $copyrightHolder - $copyrightAllRightsReserved';
  }
}
