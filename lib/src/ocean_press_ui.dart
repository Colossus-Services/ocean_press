import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:bones_ui/bones_ui.dart';
import 'package:bones_ui_bootstrap/bones_ui_bootstrap.dart';
import 'package:intl_messages/intl_messages.dart';
import 'package:social_login_web/facebook_login.dart';

import 'ocean_press_base.dart';
import 'ocean_press_sys.dart';

int UI_MAIN_CONTENT_TOP_MARGIN = 78;

class OPRoot extends UIRoot implements GlobalUserListener {
  final OceanExpressAppBuilder appBuilder;

  OPRoot(Element container, this.appBuilder)
      : super(container, classes: 'w-100 ui-root') {
    Bootstrap.load();
  }

  @override
  void onInitialized() {
    if (appBuilder != null) {
      appBuilder(OCEAN_PRESS_APP);
    }
  }

  @override
  Future<bool> initializeLocale(String locale) {
    return OCEAN_PRESS_APP.initializeMessages(locale);
  }

  @override
  Future<bool> onPrefDefineLocale(String locale) async {
    if (OCEAN_PRESS_APP.messages.isEmpty) {
      return true;
    }

    var list = OCEAN_PRESS_APP.messages
        .where((e) => e != null)
        .map((e) => e.autoDiscoverLocale(locale))
        .toList();

    await Future.wait(list);
    return true;
  }

  @override
  Future<bool> isReady() async {
    var bootstrapLoadFuture = Bootstrap.load();
    var storageReadyFuture = OCEAN_PRESS_APP.loginState.onLoad.listenAsFuture();
    var eventsReadyFuture = Future.wait(OCEAN_PRESS_APP.readyEvents);
    var messagesDiscoveredFuture =
        Future.wait(OCEAN_PRESS_APP.messages.map((m) => m.autoDiscover()));

    var bootstrapLoaded = await bootstrapLoadFuture;
    if (!bootstrapLoaded) return false;

    var storageReady = await storageReadyFuture;
    if (!storageReady) return false;

    var eventsReady = await eventsReadyFuture;
    if (eventsReady.isNotEmpty && !isAllEqualsInList(eventsReady, true))
      return false;

    var messagesDiscovered = await messagesDiscoveredFuture;
    if (messagesDiscovered.isNotEmpty &&
        !isAllEqualsInList(messagesDiscovered, true)) return false;

    return true;
  }

  @override
  void configure() {
    onInitialize.listen((u) => _doLoginResume());

    //UIConsole.displayButton();

    disableZooming();

    content.classes.add('ui-root');

    OCEAN_PRESS_APP.initFacebookLogin();

    GlobalUser.listeners.add(this);
    GlobalUser.resumeLoginFunction = _resumeLogin;

    if (UINavigator.isOffline && !GlobalUser.isLogged()) {
      _navigationBeforeResumeLogin = UINavigator.currentNavigation;
      UINavigator.navigateTo('offline');
    } else if (!UINavigator.hasRoute) {
      UINavigator.navigateTo(OCEAN_PRESS_APP.homeRoute);
    }
  }

  void _doLoginResume() {
    if (OCEAN_PRESS_APP.usesLogin && OCEAN_PRESS_APP.canResumeLogin) {
      GlobalUser.resumeLogin();
    }
  }

  Navigation _navigationBeforeResumeLogin;

  Future<UserLogin> _resumeLogin() {
    var currentRoute = UINavigator.currentRoute;
    if (currentRoute != 'offline') {
      var initialNav = UINavigator.initialNavigation;
      _navigationBeforeResumeLogin = initialNav ?? Navigation(currentRoute);
    }

    UIConsole.log(
        '_navigationBeforeResumeLogin: $_navigationBeforeResumeLogin');
    OCEAN_PRESS_APP.system.loginResume(_processLoginResume);
    return null;
  }

  String get homeRoute => OCEAN_PRESS_APP.homeRoute;

  set homeRoute(String route) {
    OCEAN_PRESS_APP.homeRoute = route;
  }

  void _processLoginResume(UserLogin user) {
    if (user != null) {
      var navigationBeforeResumeLogin = _navigationBeforeResumeLogin;
      UIConsole.log('Login resumed! Go to: $navigationBeforeResumeLogin');
      UINavigator.navigate(navigationBeforeResumeLogin);
    }
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    if (user != null) {
      var initialNav = UINavigator.initialNavigation;

      if (initialNav != null) {
        UINavigator.navigate(initialNav);
      } else {
        UINavigator.navigateTo(homeRoute);
      }
    } else {
      UINavigator.navigateTo('login');
    }
  }

  @override
  UIComponent renderContent() {
    return OPMain(content);
  }

  @override
  UIComponent renderMenu() {
    return OPMenu(content);
  }

  @override
  void buildAppStatusBar() {
    if (!isMobileAppStatusBarTranslucent()) return;

    var statusDiv = DivElement()..classes.add('ui-app-status-bar');

    statusDiv.style
      ..position = 'fixed'
      ..left = '0px'
      ..top = '-200px'
      ..width = '100%'
      ..height = '200px'
      ..zIndex = '99999999';

    document.body.children.add(statusDiv);
  }
}

class OPMenu extends UIComponent implements GlobalUserListener {
  OPMenu(Element parent)
      : super(parent,
            inline: false,
            classes:
                'navbar navbar-expand-md navbar-dark fixed-top bg-dark shadow-lg');

  static final EventStream<OPMenu> onResize = EventStream();

  @override
  Element createContentElement(bool inline) {
    return Element.nav();
  }

  @override
  void configure() {
    GlobalUser.listeners.add(this);
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    refresh();
  }

  @override
  dynamic render() {
    var showLogo = UINavigator.currentRoute != 'login' ||
        OCEAN_PRESS_APP.navBarLogoOnLogin;

    var logo = showLogo ? _buildLogo() : null;

    var toggler = _buildToggler();

    var items = _buildItems();

    return [logo, toggler, items];
  }

  DOMElement _buildToggler() {
    var button = $button(
        classes: 'navbar-toggler',
        type: 'button',
        attributes: {
          'data-toggle': 'collapse',
          'data-target': '#navbarCollapse',
          'aria-controls': 'navbarCollapse',
          'aria-expanded': 'false',
          'aria-label': 'Toggle navigation'
        },
        content: $span(classes: 'navbar-toggler-icon'));

    return button;
  }

  DOMElement _buildItems() {
    var items = $divHTML('''
      <div class="navbar-collapse collapse p-1" id="navbarCollapse">
        <ul class="navbar-nav mr-auto">
        </ul>
      </div>
    ''');

    var ul = items.select<DOMElement>('ul');

    print('UL> $ul');

    var sections = OCEAN_PRESS_APP.getAccessibleSections(true);

    print('SECTIONS>>>> $sections');

    for (var section in sections) {
      var active = section.isCurrentRoute ? 'active' : '';

      ul.addHTML('''
          <li class="nav-item $active">
            <a class="nav-link" href="#${section.route}">${section.name} <span class="sr-only">(*)</span></a>
          </li>
      ''');
    }

    var loggedUser = _buildLoggedUser();

    if (loggedUser != null) {
      items.add(loggedUser);
    }

    return items;
  }

  Element _buildLogo() {
    var logoDiv = createDivInline();
    OCEAN_PRESS_APP.setupLogo(logoDiv, 'menu');
    logoDiv.classes.add('navbar-brand');

    UINavigator.navigateOnClick(logoDiv, OCEAN_PRESS_APP.homeRoute);

    return logoDiv;
  }

  UISVG _buildLoggedUser() {
    if (!GlobalUser.isLogged()) return null;

    var computedStyle = getComputedStyle(classes: 'text-info');
    var color = computedStyle.color;

    var user = GlobalUser.user;

    var iconName = 'person-fill';

    var iconPath = BootstrapIcons.getIconPath(iconName);

    var svg =
        UISVG(null, iconPath, width: '1.5em', color: color, title: user.name);

    Bootstrap.enableTooltipOnRender(svg);

    svg.content.onClick.listen((e) {
      UINavigator.navigateTo('profile');
    });

    return svg;
  }
}

class OPMenuLoginButton extends UIButton implements GlobalUserListener {
  OPMenuLoginButton(Element parent)
      : super(parent, classes: ['ui-login-button', '!ui-button']);

  @override
  void configure() {
    GlobalUser.listeners.add(this);
  }

  @override
  void onClickEvent(event, List params) {
    if (GlobalUser.isLogged()) {
      UINavigator.navigateTo('profile');
    } else {
      UINavigator.navigateTo('login');
    }

    refresh();
  }

  @override
  dynamic renderButton() {
    if (GlobalUser.isLogged()) {
      var user = GlobalUser.user;

      var name = user.name;
      var loginType = user.loginType;

      if (user is FBUserLogin) {
        return "<div style='display: inline-block ; padding-bottom: 4px ; vertical-align: middle'><img class='ui-login-button-img' alt='${name} (LOGIN: ${loginType})' title='${name} (LOGIN: ${loginType})' width='20' height='20' src='${user.pictureURL}'></div>";
      } else {
        var nameInitial = user.nameInitial;
        return "<div class='ui-login-button-initial' style='width: 20px ; height: 20px ; font-size: 95% ; font-weight: bold ; text-align: center ; line-height: 1.43em' title='$name (LOGIN: $loginType)'>$nameInitial</div>";
      }
    } else {
      //return "<div style='display: inline-block ; padding-bottom: 4px ; vertical-align: middle'><img class='ui-login-button-img' border='1' width='20' height='20' src='images/user-login.png'></div>";
      return '';
    }
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    UIConsole.log('onGlobalUserLogin: $user');
    refresh();
  }
}

class OPMain extends UINavigableContent {
  static List<String> getStandardRoutes() {
    return [
      'home',
      'login',
      'register',
      'profile',
      'changepass',
      'logout',
      'offline'
    ];
  }

  static List<String> getRoutes() {
    var sectionsRoutes = OCEAN_PRESS_APP.getSectionsRoutes();

    var routes = List<String>.from(getStandardRoutes());
    routes.addAll(sectionsRoutes);

    return routes;
  }

  String get messageCopyrightAllRightsReserved =>
      OCEAN_PRESS_MESSAGES.msg('copyrightAllRightsReserved').build();

  OPMain(Element parent)
      : super(parent, getRoutes(),
            classes: 'w-100 text-center ui-main',
            topMargin: UI_MAIN_CONTENT_TOP_MARGIN);

  @override
  void configure() {
    OPMenu.onResize.listen((e) {
      if (topMargin != UI_MAIN_CONTENT_TOP_MARGIN) {
        topMargin = UI_MAIN_CONTENT_TOP_MARGIN;
        refresh();
      }
    });
  }

  @override
  dynamic renderRoute(String route, Map<String, String> parameters) {
    if (route == 'login') {
      if (!OCEAN_PRESS_APP.usesLogin) {
        route = OCEAN_PRESS_APP.homeRoute;

        var currentRoute = UINavigator.currentRoute;
        if (currentRoute == 'login') {
          UINavigator.navigateTo(route, parameters: currentRouteParameters);
        }
      }
    } else if (route == 'home') {
      route = OCEAN_PRESS_APP.homeRoute;
    }

    content.classes.removeWhere((c) => c.startsWith('ui-main-bg'));

    var bg = 1;

    scrollToTop();

    OPRouteBreadcrumb routeBreadcrumb;
    UIComponent component;

    var section = OCEAN_PRESS_APP.getSection(route, content);
    var sectionComponent = section as UIComponent;

    if (sectionComponent != null) {
      routeBreadcrumb = OPRouteBreadcrumb(content, [
        {section.route: section.name}
      ]);

      sectionComponent.clear();
      component = sectionComponent;
    } else if (route == 'home') {
      component = OPHome(content);
    } else if (route == 'login') {
      bg = 2;
      component = OPHomeLogin(content);
    } else if (route == 'register') {
      bg = 2;
      component = OPRegister(content);
    } else if (route == 'profile') {
      bg = 2;
      component = OPProfile(content);
    } else if (route == 'changepass') {
      bg = 2;
      component = OPChangePass(content);
    } else if (route == 'logout') {
      bg = 2;
      component = OPLogout(content);
    } else if (route == 'offline') {
      bg = 2;
      component = OPOffline(content);
    }

    if (component is OPPopUpSection) {
      var popUpSection = component as OPPopUpSection;
      routeBreadcrumb = OPRouteBreadcrumb(content, [
        {popUpSection.route: popUpSection.routeLabel}
      ]);
    }

    if (component is OPSection) {
      var opSection = component as OPSection;
      currentTitle = opSection.currentTitle;
    } else {
      currentTitle = route;
    }

    content.classes.add('ui-main-bg$bg');

    scrollToTopDelayed(500);

    var footer = _buildFooter();

    if (component == null) return [footer];

    var divFinalSpace = createDivInline();
    divFinalSpace.style.width = '100%';
    divFinalSpace.style.height = '100px';

    return [routeBreadcrumb, component, divFinalSpace, footer];
  }

  dynamic _buildFooter() {
    var companyName = OCEAN_PRESS_APP.companyName;
    if (companyName == null) return null;

    var year = getDateTimeNow().year;

    var companyURL = OCEAN_PRESS_APP.companyURL;

    var company = companyURL != null
        ? '<a href="$companyURL" target="_blank">$companyName</a>'
        : companyName;

    return createHTML(''' 
    <footer class="footer d-none d-lg-block">
      <div class="container">
        <span class="text-muted">Copyright © $year $company - $messageCopyrightAllRightsReserved</span>
      </div>
    </footer>
    ''');
  }
}

class OPHomeLogin extends UIContent {
  OPHomeLogin(Element parent) : super(parent, classes: 'w100 ui-login');

  @override
  bool isAccessible() {
    return !GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return 'home';
  }

  @override
  void configure() {
    content.style..width = '100%';
  }

  @override
  dynamic renderContent() {
    var login = OPLogin(content);

    var footDiv = DivElement();
    footDiv.classes.add('ui-login-footer');
    footDiv.innerHtml = '&nbsp;';

    var loginFooter = OCEAN_PRESS_APP.loginFooter;

    if (loginFooter != null) {
      footDiv.children.clear();
      loginFooter.setParent(footDiv);
    }

    return [login, footDiv];
  }
}

class OPLogin extends UIContent {
  OPLogin(Element parent)
      : super(parent, classes: 'w-100 p-3 text-center  ui-login');

  @override
  dynamic renderContent() {
    var html = isSmallScreen() ? '' : '<p>';

    var loginContent = OPLoginContent(content);

    var loginBottomContent = OCEAN_PRESS_APP.loginBottomContent;

    var separator = loginBottomContent != null ? '<p>&nbsp;<p>' : null;

    return [html, loginContent, separator, loginBottomContent];
  }
}

class OPLoginContent extends UIContent implements GlobalUserListener {
  OPLoginContent(Element parent)
      : super(parent, classes: 'content shadow p-3 mb-5 rounded ui-content');

  @override
  void configure() {
    GlobalUser.listeners.add(this);
  }

  String get messageWelcomeLogin =>
      OCEAN_PRESS_MESSAGES.msg('welcomeLogin').build();

  String get messageLoginOr => OCEAN_PRESS_MESSAGES.msg('loginOr').build();

  String get messageButtonLogin =>
      OCEAN_PRESS_MESSAGES.msg('buttonLogin').build();

  String get messageLoginUsername =>
      OCEAN_PRESS_MESSAGES.msg('loginUsername').build();

  String get messageLoginPassword =>
      OCEAN_PRESS_MESSAGES.msg('loginPassword').build();

  String get messageLoadingFacebookLogin =>
      OCEAN_PRESS_MESSAGES.msg('loadingFacebookLogin').build();

  String get messageLoadingLogin =>
      OCEAN_PRESS_MESSAGES.msg('loadingLogin').build();

  String get messageLoginError =>
      OCEAN_PRESS_MESSAGES.msg('loginError').build();

  String get messageCreateAccount =>
      OCEAN_PRESS_MESSAGES.msg('createAccount').build();

  @override
  dynamic renderContent() {
    var divLogo = _buildLogo();

    var emptyLogo = divLogo.children.isEmpty;
    var showWelcomeMessage = OCEAN_PRESS_APP.loginShowWelcomeMessage;

    String htmlTitle;
    if (showWelcomeMessage || emptyLogo) {
      var divLogoSeparator = emptyLogo ? '' : '<p><p>';

      htmlTitle = """
      $divLogoSeparator
      <span style='font-weight: bolder ; font-size: 100%'>$messageWelcomeLogin</span>
      <p>
      """;
    } else {
      htmlTitle = '''
      <p>
      ''';
    }

    var buttonFacebook;
    var loadingFB;

    if (OCEAN_PRESS_APP.hasFacebookID) {
      buttonFacebook = OPButtonFB(content)
        ..id = 'buttonFB'
        ..onClick.listen(_onClickFBLogin);

      loadingFB = OPLoading(content, text: messageLoadingFacebookLogin)
        ..id = 'loadingFB'
        ..hide();
    }

    var username = OCEAN_PRESS_APP.loginState.getUsername();

    if (username != null && RegExp('^FB\\d+\$').hasMatch(username))
      username = null;

    var inputTable = UIInputTable(content, [
      InputConfig('username', messageLoginUsername,
          type: 'email', value: username),
      InputConfig('password', messageLoginPassword,
          type: 'password', attributes: {'onEventKeyPress': 'Enter:login'})
    ])
      ..id = 'inputs';

    var buttonLogin = OPButton(content, messageButtonLogin)
      ..id = 'buttonLogin'
      ..onClick.listen(_onClickLogin);

    var loading = OPLoading(content, text: messageLoadingLogin)
      ..id = 'loading'
      ..hide();

    var buttonCreateAccount;

    if (OCEAN_PRESS_APP.canCreateAccount) {
      buttonCreateAccount =
          OPButton(content, messageCreateAccount, small: true, fontSize: '80%')
            ..id = 'buttonCreateAccount'
            ..onClick.listen(_onClickCreateAccount);
    }

    var htmlLoginError =
        "<br><div field='msgLoginError' hidden><span class='ui-text-alert' style='font-size: 85%'><br>$messageLoginError</span></div>";

    var labelLanguage = createDivInline("""
      <span style='font-size: 80%'>$messageIdiom: &nbsp;</span>
      """);

    var selLanguage =
        UIRoot.getInstance().buildLanguageSelector(_onLanguageSelection);
    selLanguage.style.fontSize = '70%';

    return [
      divLogo,
      htmlTitle,
      buttonFacebook,
      loadingFB,
      '<hr>',
      inputTable,
      '<p>',
      buttonCreateAccount,
      '&nbsp;&nbsp;&nbsp;&nbsp;',
      buttonLogin,
      loading,
      htmlLoginError,
      '<hr>',
      labelLanguage,
      selLanguage,
      '<p>'
    ];
  }

  Element _buildLogo() {
    var logoDiv = createDivInline();
    OCEAN_PRESS_APP.setupLogo(logoDiv, 'login');
    return logoDiv;
  }

  void _onLanguageSelection() {
    refresh();
  }

  @override
  void action(String action) {
    _onClickLogin(null);
  }

  List<UIComponent> _getFBLoginComponents() {
    return getRenderedUIComponentsByIds(['buttonFB', 'loadingFB']);
  }

  List<UIComponent> _getLoginComponents() {
    return getRenderedUIComponentsByIds(['buttonLogin', 'loading']);
  }

  List<Element> _getLoginElements() {
    return content.querySelectorAll('#buttonLogin');
  }

  void _hideLoadings() {
    var loadingFB = getRenderedUIComponentById('loadingFB');
    var loading = getRenderedUIComponentById('loading');

    if (loadingFB != null) loadingFB.hide();
    if (loading != null) loading.hide();
  }

  void _onClickCreateAccount(MouseEvent e) {
    UINavigator.navigateTo('register');
  }

  bool _clickedLoginFB = false;

  void _onClickFBLogin(MouseEvent e) {
    _clickedLoginFB = true;

    for (var elem in _getFBLoginComponents()) {
      elem.hide();
    }

    getRenderedUIComponentById('loadingFB').show();

    OCEAN_PRESS_APP.system.doFacebookLogin();
  }

  bool _clickedLogin = false;

  void _onClickLogin(MouseEvent e) {
    _clickedLogin = true;

    for (var elem in _getLoginComponents()) {
      elem.hide();
    }

    for (var elem in _getLoginElements()) {
      elem.hidden = true;
    }

    getRenderedUIComponentById('loading').show();

    var fields = getFields();

    var username = fields['username'];
    var pass = fields['password'];

    OCEAN_PRESS_APP.system.login(username, pass, onGlobalUserLogin);
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    if (!_clickedLoginFB && !_clickedLogin) return;

    UIConsole.log('SSLogin.onGlobalUserLogin> $user');

    if (user == null) {
      for (UIComponent elem
          in joinLists(_getFBLoginComponents(), _getLoginComponents())) {
        elem.show();
      }

      getFieldElement('msgLoginError').hidden = false;
    }

    _hideLoadings();
  }
}

class OPButtonFB extends OPButton {
  static String get messageButtonLoginWithFB =>
      OCEAN_PRESS_MESSAGES.msg('buttonLoginWithFB').build();

  OPButtonFB(Element parent)
      : super(parent, messageButtonLoginWithFB,
            classes: ['ui-button-fb', '!ui-button', '!ui-button-small']);
}

class OPRegister extends UIContent {
  OPRegister(Element parent)
      : super(parent, classes: ['ui-content', 'ui-register']);

  @override
  bool isAccessible() {
    return !GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return 'home';
  }

  String get messageRegisterTitle =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerTitle');

  String get messageRegisterName =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerName');

  String get messageRegisterEmail =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerEmail');

  String get messageRegisterUsername =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerUsername');

  String get messageRegisterPassword =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerPassword');

  String get messageButtonRegister =>
      OCEAN_PRESS_MESSAGES.buildMsg('buttonRegister');

  String get messageButtonDoLogin =>
      OCEAN_PRESS_MESSAGES.buildMsg('buttonDoLogin');

  String get messageRegisterError =>
      OCEAN_PRESS_MESSAGES.buildMsg('registerError');

  UIInputTable infosTable;

  @override
  dynamic renderContent() {
    var html1 = """
    <div class='ui-title'>$messageRegisterTitle</div>
    <p>
    """;

    var inputs = [
      InputConfig('name', messageRegisterName),
      InputConfig('email', messageRegisterEmail, type: 'email'),
      InputConfig('username', messageRegisterUsername),
      InputConfig('password', messageRegisterPassword,
          type: 'password', attributes: {'onEventKeyPress': 'Enter:register'})
    ];

    if (OCEAN_PRESS_APP.usernameAsEmail) {
      inputs.removeWhere((i) => i.fieldName == 'username');
    }

    infosTable =
        UIInputTable(content, inputs, inputErrorClass: 'ui-input-error');

    var buttonRegister = OPButton(content, messageButtonRegister)
      ..setWideButton()
      ..onClick.listen(_register);

    var buttonLogin =
        OPButton(content, messageButtonDoLogin, small: true, fontSize: '80%')
          ..navigate('login');

    var htmlRegisterError =
        "<br><div field='messageRegisterError' hidden><span class='ui-text-alert' style='font-size: 85%'><br>$messageRegisterError</span></div>";

    return [
      html1,
      '<hr>',
      infosTable,
      '<p>',
      buttonRegister,
      htmlRegisterError,
      '<hr><p>',
      buttonLogin
    ];
  }

  @override
  void action(String action) {
    _register(null);
  }

  void _register(MouseEvent e) {
    UIConsole.log('Register');

    if (!infosTable.checkFields()) {
      return;
    }

    var name = infosTable.getField('name');
    var email = infosTable.getField('email');
    var username = infosTable.getField('username');
    var pass = infosTable.getField('password');

    if (OCEAN_PRESS_APP.usernameAsEmail) {
      username = email;
    }

    OCEAN_PRESS_APP.system
        .register(name, email, username, pass, _registeredUser);
  }

  void _registeredUser(UserLogin user) {
    UIConsole.log('_registeredUser> $user');

    if (user == null) {
      getFieldElement('messageRegisterError').hidden = false;
    }
  }
}

class OPRouteBreadcrumb extends UIComponent {
  String get messageHome => OCEAN_PRESS_MESSAGES.msg('home').build();

  LinkedHashMap<String, String> _routes;

  OPRouteBreadcrumb(Element parent, dynamic routes) : super(parent) {
    // ignore: prefer_collection_literals
    _routes = LinkedHashMap();

    if (routes is List) {
      routes.forEach(_addToRoutes);
    } else if (routes is Map) {
      for (var entry in routes.entries) {
        _addEntryToRoutes(entry.key, entry.value);
      }
    }

    var homeRoute = OCEAN_PRESS_APP.homeRoute;

    if (!_routes.containsKey(homeRoute)) {
      // ignore: prefer_collection_literals
      var _routes2 = LinkedHashMap<String, String>();
      _routes2[homeRoute] = messageHome;

      _routes2.addAll(_routes);

      _routes = _routes2;
    }
  }

  void _addEntryToRoutes(dynamic route, dynamic label) {
    var routeStr = parseString(route);
    var labelStr = parseString(label);
    if (!_routes.containsKey(route)) {
      _routes[routeStr] = labelStr;
    }
  }

  void _addToRoutes(dynamic e) {
    if (e is Map) {
      var route = e.keys.first;
      var label = e[route];
      _addEntryToRoutes(route, label);
    } else if (e is List) {
      _addEntryToRoutes(e[0], e[1]);
    } else if (e is Pair) {
      _addEntryToRoutes(e.aAsString, e.bAsString);
    } else if (e is String) {
      var parts = e.split(RegExp(r'[:,;\s]+'));
      _addEntryToRoutes(parts[0], parts[2]);
    }
  }

  @override
  Element createContentElement(bool inline) {
    return createHTML(''' 
    <nav aria-label="breadcrumb"></nav>
    ''');
  }

  @override
  dynamic render() {
    var html = '''
      <ol class="breadcrumb">
    ''';

    var currentRoute = UINavigator.currentRoute;

    for (var entry in _routes.entries) {
      var route = entry.key;
      var label = entry.value;

      var active = currentRoute == route;

      if (active) {
        html +=
            ' <li class="breadcrumb-item active" aria-current="page">$label</li> \n';
      } else {
        html +=
            ' <li class="breadcrumb-item"><a href="#$route">$label</a></li> \n';
      }
    }

    html += '''
      </ol>
    ''';

    return html;
  }
}

class OPProfile extends UIContent implements OPPopUpSection {
  OPProfile(Element parent)
      : super(parent, classes: 'card w-80 p-3 text-center shadow ui-content');

  @override
  String get route => 'profile';

  @override
  String get routeLabel => messageProfileTitle;

  @override
  bool isAccessible() {
    return GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return 'login';
  }

  String get messageProfileTitle =>
      OCEAN_PRESS_MESSAGES.msg('profileTitle').build();

  String get messageProfileName =>
      OCEAN_PRESS_MESSAGES.msg('profileName').build();

  String get messageProfileEmail =>
      OCEAN_PRESS_MESSAGES.msg('profileEmail').build();

  String get messageProfileUsername =>
      OCEAN_PRESS_MESSAGES.msg('profileUsername').build();

  String get messageProfileLanguage =>
      OCEAN_PRESS_MESSAGES.msg('profileLanguage').build();

  String get messageButtonChangePassword =>
      OCEAN_PRESS_MESSAGES.msg('buttonChangePassword').build();

  String get messageButtonMyItems =>
      OCEAN_PRESS_MESSAGES.msg('buttonMyItems').build();

  String get messageButtonLogout =>
      OCEAN_PRESS_MESSAGES.msg('buttonLogout').build();

  @override
  dynamic renderContent() {
    var html1 = """
    <div class='card-title ui-title'>$messageProfileTitle</div>
    <p>
    """;

    var selLanguage = UIRoot.getInstance().buildLanguageSelector(refresh);

    var user = GlobalUser.user;

    var infos = {
      messageProfileName: user.name,
      messageProfileEmail: user.email,
      messageProfileUsername: user.username,
      messageProfileLanguage: selLanguage,
    };

    if (OCEAN_PRESS_APP.usernameAsEmail) {
      infos.removeWhere((k, v) => k == messageProfileUsername);
    }

    var infosTable = UIInfosTable(content, infos);

    var html2;

    var buttonChangePass;

    if (OCEAN_PRESS_APP.canChangePassword) {
      html2 = '<p><hr><p>';

      buttonChangePass = OPButton(content, messageButtonChangePassword)
        ..navigate('changepass')
        ..setWideButton();
    } else {
      html2 = '<p>';
    }

    /*
    var buttonMyItems = OPButton(content, messageButtonMyItems)
      ..navigate("myitems")
      ..setWideButton()
    ;
     */

    var buttonLogout = OPButton(content, messageButtonLogout)
      ..navigate('logout')
      ..setWideButton();

    return [
      html1,
      '<p>',
      infosTable,
      html2,
      buttonChangePass,
      '<p>',
      /*buttonMyItems,*/
      '<p><hr><p>',
      buttonLogout
    ];
  }

  @override
  void posRender() {
    SelectElement selectElement = content.querySelector('select');

    selectElement.onChange.listen((e) {
      var locale = selectElement.selectedOptions[0].value;
      print('selected: $locale');
      UIRoot.getInstance().setPreferredLocale(locale);
      refresh();
    });
  }
}

class OPChangePass extends UIContent {
  OPChangePass(Element parent) : super(parent, classes: 'ui-content');

  @override
  bool isAccessible() {
    return GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return 'login';
  }

  String get messageChangePassTitle =>
      OCEAN_PRESS_MESSAGES.msg('changePassTitle').build();

  String get messageCurrentPassword =>
      OCEAN_PRESS_MESSAGES.msg('currentPassword').build();

  String get messageNewPassword =>
      OCEAN_PRESS_MESSAGES.msg('newPassword').build();

  String get messageConfirmNewPassword =>
      OCEAN_PRESS_MESSAGES.msg('confirmNewPassword').build();

  String get messageSaveNewPassword =>
      OCEAN_PRESS_MESSAGES.msg('saveNewPassword').build();

  String get messageSavePassError =>
      OCEAN_PRESS_MESSAGES.msg('savePassError').build();

  UIInputTable infosTable;

  @override
  dynamic renderContent() {
    var routeBreadcrumb = OPRouteBreadcrumb(content, [
      {'changepass': messageChangePassTitle}
    ]);

    var currentUsername = GlobalUser.user != null
        ? '<span style="font-size: 90%">(${GlobalUser.user.username})</span>'
        : '';

    var html1 = """
    <div class='ui-title'>$messageChangePassTitle</div>
    $currentUsername
    <p>
    """;

    infosTable = UIInputTable(
        content,
        [
          InputConfig('current_password', messageCurrentPassword,
              type: 'password'),
          InputConfig('password', messageNewPassword, type: 'password'),
          InputConfig('password_confirm', messageConfirmNewPassword,
              type: 'password',
              attributes: {'onEventKeyPress': 'Enter:register'})
        ],
        inputErrorClass: 'ui-input-error');

    var buttonSavePass = OPButton(content, messageSaveNewPassword)
      //..setWideButton()
      ..onClick.listen(_savePass);

    var htmlSaveError =
        "<br><div field='messageError' hidden><span class='ui-text-alert' style='font-size: 85%'><br>$messageSavePassError</span></div>";

    return [
      routeBreadcrumb,
      html1,
      infosTable,
      '<p>',
      buttonSavePass,
      htmlSaveError
    ];
  }

  void _savePass(dynamic evt) {
    UIConsole.log('Save Pass');

    if (!infosTable.checkFields()) {
      return;
    }

    var pass = infosTable.getField('password');
    var passConfirm = infosTable.getField('password_confirm');

    if (pass != passConfirm) {
      infosTable.highlightField('password_confirm');
      return;
    }

    var currentPass = infosTable.getField('current_password');

    OCEAN_PRESS_APP.system
        .changePassword(GlobalUser.user.username, currentPass, pass)
        .then(_onSavedPass);
  }

  void _onSavedPass(bool ok) {
    if (ok) {
      UINavigator.navigateTo('profile');
    } else {
      getFieldElement('messageError').hidden = false;
    }
  }
}

abstract class OPPopUpSection {
  String get route;

  String get routeLabel;
}

class OPLogout extends UIContent implements OPPopUpSection {
  OPLogout(Element parent)
      : super(parent,
            classes: 'content w-80 p-3 text-center shadow ui-content');

  static String get messageReallyWantToLogout =>
      OCEAN_PRESS_MESSAGES.msg('reallyWantToLogout').build();

  static String get messageButtonLogout =>
      OCEAN_PRESS_MESSAGES.msg('buttonLogout').build();

  static String get messageButtonBack =>
      OCEAN_PRESS_MESSAGES.msg('buttonBack').build();

  @override
  String get route => 'logout';

  @override
  String get routeLabel => messageButtonLogout;

  @override
  dynamic renderContent() {
    var html1 = '''
    $messageReallyWantToLogout
    <p>
    ''';

    var buttonLogout = OPButton(content, messageButtonLogout)
      ..setWideButton()
      ..onClick.listen(_click);

    var buttonBack = OPButton(content, messageButtonBack, small: true)
      ..navigate('<');

    return [html1, buttonLogout, '<p>', buttonBack];
  }

  void _click(MouseEvent event) {
    OCEAN_PRESS_APP.system.logout();
  }
}

class OPOffline extends UIContent {
  OPOffline(Element parent) : super(parent);

  @override
  dynamic renderContent() {
    var html = 'OFFLINE';

    return [html];
  }
}

class OPHome extends UIContent {
  OPHome(Element parent) : super(parent);

  @override
  bool isAccessible() {
    return GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return 'login';
  }

  @override
  dynamic renderContent() {
    var html = 'HOME';

    return [html];
  }
}
