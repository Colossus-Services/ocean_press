
import 'dart:async';
import 'dart:html';

import 'package:bones_ui/bones_ui.dart';
import "package:intl_messages/intl_messages.dart";
import 'package:social_login_web/facebook_login.dart';
import 'ocean_press_base.dart';

import 'ocean_press_sys.dart';


final int _topSpace = 60 ;

////////////////////////////////////////////////////////////////////////////////

class OPRoot extends UIRoot implements GlobalUserListener {
  OPRoot(Element container) : super(container, classes: 'ss-root');

  @override
  Future<bool> initializeLocale(String locale) {
    return OCEAN_PRESS_APP.initializeMessages(locale) ;
  }

  @override
  Future<bool> isReady() {
    return OCEAN_PRESS_APP.loginState.onLoad.listenAsFuture() ;
  }

  @override
  void configure() {

    onInitialize.listen( (u) => _doLoginResume() ) ;

    //UIConsole.displayButton();

    disableZooming() ;

    content.classes.add("ss-root") ;

    OCEAN_PRESS_APP.initFacebookLogin() ;

    GlobalUser.listeners.add(this);
    GlobalUser.resumeLoginFunction = _resumeLogin ;

    if ( UINavigator.isOffline && !GlobalUser.isLogged() ) {
      _navigationBeforeResumeLogin = UINavigator.currentNavigation ;
      UINavigator.navigateTo("offline");
    }
    else if ( !UINavigator.hasRoute ) {
      UINavigator.navigateTo( OCEAN_PRESS_APP.homeRoute );
    }

  }

  void _doLoginResume() {
    if ( OCEAN_PRESS_APP.usesLogin ) {
      GlobalUser.resumeLogin();
    }
  }

  Navigation _navigationBeforeResumeLogin ;

  Future<UserLogin> _resumeLogin() {
    var currentRoute = UINavigator.currentRoute ;
    if (currentRoute != 'offline') {
      var initialNav = UINavigator.initialNavigation ;
      _navigationBeforeResumeLogin = initialNav ?? Navigation(currentRoute) ;
    }

    UIConsole.log("_navigationBeforeResumeLogin: $_navigationBeforeResumeLogin") ;
    OCEAN_PRESS_APP.system.loginResume(_processLoginResume);
    return null ;
  }

  String get homeRoute => OCEAN_PRESS_APP.homeRoute ;

  set homeRoute(String route) {
    OCEAN_PRESS_APP.homeRoute = route ;
  }

  void _processLoginResume(UserLogin user) {
    if ( user != null ) {
      var navigationBeforeResumeLogin = _navigationBeforeResumeLogin;
      UIConsole.log("Login resumed! Go to: $navigationBeforeResumeLogin") ;
      UINavigator.navigate(navigationBeforeResumeLogin) ;
    }
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    if ( user != null ) {
      var initialNav = UINavigator.initialNavigation ;

      if ( initialNav != null ) {
          UINavigator.navigate(initialNav) ;
      }
      else {
        UINavigator.navigateTo(homeRoute) ;
      }
    }
    else {
      UINavigator.navigateTo("login") ;
    }
  }

  @override
  UIComponent renderContent() {
    return OPMain(content) ;
  }

  @override
  UIComponent renderMenu() {
    return OPMenu(content) ;
  }

}

class OPMenu extends UIComponent implements GlobalUserListener {
  OPMenu(Element parent) : super(parent, classes: 'ss-menu');

  @override
  void configure() {
    GlobalUser.listeners.add(this) ;
  }

  @override
  render() {
    var logoDiv = createDivInline();
    OCEAN_PRESS_APP.setupLogo(logoDiv, "menu") ;
    UINavigator.navigateOnClick(logoDiv, OCEAN_PRESS_APP.homeRoute );
    logoDiv.style.verticalAlign = 'middle';

    OPMenuLoginButton loginButton = OPMenuLoginButton(content) ;

    List<OPSection> sections = OCEAN_PRESS_APP.getSections().where( (s) => s.isAccessible() && s.visibleInMenu ).toList() ;

    DivElement sectionsDiv ;
    String sectionsDivSeparator ;

    DivElement divMenuIcon ;
    OPMenuPanel menuPanel ;

    if ( sections.length > 2 ) {
      divMenuIcon = createMenuIcon(27, 20, 4);
      menuPanel = OPMenuPanel(content, sections) ;
      divMenuIcon.onClick.listen( (e) => menuPanel.showPanel() );
    }
    else if ( sections.isNotEmpty ) {
      sectionsDiv = _buildSectionsInline(sections) ;
      sectionsDivSeparator = "&nbsp; &nbsp;" ;
    }

    return [divMenuIcon, "&nbsp; &nbsp;" ,logoDiv, "&nbsp; &nbsp;" , sectionsDiv , sectionsDivSeparator, loginButton, "&nbsp;", menuPanel];
  }

  DivElement createMenuIcon(int width, int height, [int topMargin]) {
    if (topMargin == null || topMargin < 0) topMargin = 0 ;

    var dimStyle = "width: ${width}px ; height: ${height/5}px" ;

    var divMenu = createDivInline('''
    <div style="width: ${width} ; height: ${height}" class="ss-menu-icon">
      <div style=" width: ${width}px ; height: ${topMargin}px"></div>
      <div style="$dimStyle" class="ss-menu-icon-line"></div>
      <div style="$dimStyle"></div>
      <div style="$dimStyle" class="ss-menu-icon-line"></div>
      <div style="$dimStyle"></div>
      <div style="$dimStyle" class="ss-menu-icon-line"></div>
      <div style="$dimStyle"></div>
    </div>
    ''') ;

    return divMenu;
  }

  DivElement _buildSectionsInline(List<OPSection> sections) {
    var div = createDivInline();

    int i = 0 ;
    for (var section in sections) {
      if ( !section.isAccessible() ) continue ;

      if (i > 0) {
        var sep = SpanElement()
          ..text = " | " ;
        div.children.add( sep ) ;
      }

      var sect = SpanElement()
        ..text = section.name ;
      div.children.add( sect ) ;

      UINavigator.navigateOnClick( sect , section.route ) ;

      i++ ;
    }

    return div ;
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    refresh();
  }

}

class OPMenuPanel extends UIComponent {

  final List<OPSection> _sections ;

  OPMenuPanel(Element parent, this._sections) : super(parent);

  @override
  void configure() {
    hide();

    UINavigator.onNavigate.listen( (route) => refresh() ) ;
  }

  fixPanelPos() {
    var topMenuHeight = parent.offsetHeight;
    if (topMenuHeight != null && topMenuHeight > 0) {
      print("Set MENU Panel pos: $topMenuHeight");
      content.style.top = "${topMenuHeight}px";
    }
  }

  void showPanel() {
    fixPanelPos();
    show();
  }

  void closePanel() {
    hide();
  }

  @override
  render() {
    var divMenuParent = createHTML('''
    <div class="ss-menu-panel-parent">
    </div>
    ''') ;

    var divMenuPanel = createMenuPanel(200, _sections);

    divMenuPanel.onMouseLeave.listen( (e) => closePanel() );
    divMenuPanel.onTouchLeave.listen( (e) => closePanel() );
    divMenuParent.onClick.listen( (e) => closePanel() );
    window.onResize.listen( (e) => fixPanelPos() );

    divMenuParent.children.add(divMenuPanel);

    return divMenuParent ;
  }

  DivElement createMenuPanel(int width, List<OPSection> sections) {
    var dimStyle = "width: ${width}px" ;

    String sectionsHTML = "" ;

    for (var section in sections) {
      String itemClass = section.isCurrentRoute ? "ss-menu-panel-item-selected" : "ss-menu-panel-item" ;

      sectionsHTML += '''
      <div style="$dimStyle" class="$itemClass" navigate="${ section.route }">${ section.name }</div>
      <div style="$dimStyle ; height: 5px"></div>
      ''';
    }

    var divMenuPanel = createHTML('''
    <div style="width: ${width}px;" class="ss-menu-panel">
      $sectionsHTML
    </div>
    ''') ;

    return divMenuPanel;
  }


}

class OPMenuLoginButton extends UIButton implements GlobalUserListener {
  OPMenuLoginButton(Element parent) : super(parent, classes: 'ss-login-button');

  @override
  void configure() {
    GlobalUser.listeners.add(this) ;
  }

  @override
  void onClickEvent(event, List params) {

    if ( GlobalUser.isLogged() ) {
      UINavigator.navigateTo("profile");
    }
    else {
      UINavigator.navigateTo("login");
    }

    refresh();
  }

  @override
  renderButton() {

    if ( GlobalUser.isLogged() ) {
      var user = GlobalUser.user ;

      var name = user.name;
      var loginType = user.loginType;

      if (user is FBUserLogin) {
        return "<div style='display: inline-block ; padding-bottom: 4px ; vertical-align: middle'><img class='ss-login-button-img' title='${ name } (LOGIN: ${ loginType })' border='1' width='20' height='20' src='${ user.pictureURL }'></div>";
      }
      else {
        var nameInitial = user.nameInitial;
        return "<div class='ss-login-button-initial' style='width: 20px ; height: 20px ; font-size: 95% ; font-weight: bold ; text-align: center ; line-height: 1.43em' title='$name (LOGIN: $loginType)'>$nameInitial</div>";
      }
    }
    else {
      //return "<div style='display: inline-block ; padding-bottom: 4px ; vertical-align: middle'><img class='ss-login-button-img' border='1' width='20' height='20' src='images/user-login.png'></div>";
      return "";
    }

  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    UIConsole.log("onGlobalUserLogin: $user") ;
    refresh();
  }

}

class OPMain extends UINavigableContent {

  static List<String> getStandardRoutes() {
    return ['home','login','register','profile','changepass','logout','offline'] ;
  }

  static List<String> getRoutes() {
    List<String> sectionsRoutes = OCEAN_PRESS_APP.getSectionsRoutes() ;

    List<String> routes = List.from( getStandardRoutes() ) ;
    routes.addAll(sectionsRoutes) ;

    return routes ;
  }

  OPMain(Element parent) : super(parent, getRoutes(), classes: 'ss-main', topMargin: _topSpace);

  @override
  renderRoute(String route, Map<String, String> parameters) {
    if (route == 'login') {
      if ( !OCEAN_PRESS_APP.usesLogin ) {
        route = OCEAN_PRESS_APP.homeRoute ;

        var currentRoute = UINavigator.currentRoute ;
        if (currentRoute == 'login') {
          UINavigator.navigateTo(route, currentRouteParameters) ;
        }
      }
    }
    else if (route == 'home') {
      route = OCEAN_PRESS_APP.homeRoute ;
    }

    content.classes.removeWhere((c) => c.startsWith("ss-main-bg")) ;

    int bg = 1 ;

    scrollToTop();

    UIComponent component ;

    if (route == "home") {
      component = OPHome(content) ;
    }
    else if (route == "login") {
      bg = 2 ;
      component = OPHomeLogin(content) ;
    }
    else if (route == "register") {
      component = OPRegister(content) ;
    }
    else if (route == "profile") {
      component = OPProfile(content) ;
    }
    else if (route == "changepass") {
      component = OPChangePass(content) ;
    }
    else if (route == "logout") {
      component = OPLogout(content) ;
    }
    else if (route == "offline") {
      component = OPOffline(content) ;
    }
    else {
      component = OCEAN_PRESS_APP.getSection(route, content) ;
      if (component != null) {
        component.clear();
      }
    }

    content.classes.add("ss-main-bg$bg") ;

    scrollToTopAsync(500) ;

    if (component == null) return null ;
    return [component] ;
  }

}

class OPHomeLogin extends UIContent {
  OPHomeLogin(Element parent) : super(parent, classes: 'ss-login');

  @override
  bool isAccessible() {
    return !GlobalUser.isLogged() ;
  }

  @override
  String deniedAccessRoute() {
    return "home";
  }

  @override
  void configure() {
    content.style
      ..width = '100%'
    ;
  }

  @override
  renderContent() {
    var login = SSLogin(content) ;

    var footDiv = DivElement();
    footDiv.classes.add('ss-login-footer');
    footDiv.innerHtml = '&nbsp;';

    return [login, footDiv] ;
  }

}

class SSLogin extends UIContent {
  SSLogin(Element parent) : super(parent, classes: 'ss-login');

  @override
  renderContent() {
    String html = isSmallScreen() ? '' : '<p>' ;

    var loginContent = SSLoginContent(content) ;
    return [html,loginContent] ;
  }

}

class SSLoginContent extends UIContent implements GlobalUserListener {
  SSLoginContent(Element parent) : super(parent, classes: 'ss-content');

  @override
  void configure() {
    GlobalUser.listeners.add(this);
  }

  String get messageWelcomeLogin => OCEAN_PRESS_MESSAGES.msg("welcomeLogin").build() ;
  String get messageLoginOr => OCEAN_PRESS_MESSAGES.msg("loginOr").build() ;
  String get messageButtonLogin => OCEAN_PRESS_MESSAGES.msg("buttonLogin").build() ;
  String get messageLoginUsername => OCEAN_PRESS_MESSAGES.msg("loginUsername").build() ;
  String get messageLoginPassword => OCEAN_PRESS_MESSAGES.msg("loginPassword").build() ;
  String get messageLoadingFacebookLogin => OCEAN_PRESS_MESSAGES.msg("loadingFacebookLogin").build() ;
  String get messageLoadingLogin => OCEAN_PRESS_MESSAGES.msg("loadingLogin").build() ;
  String get messageLoginError => OCEAN_PRESS_MESSAGES.msg("loginError").build() ;
  String get messageCreateAccount => OCEAN_PRESS_MESSAGES.msg("createAccount").build() ;

  @override
  renderContent() {

    String htmlTitle = """
    <span style='font-weight: bolder ; font-size: 100%'>$messageWelcomeLogin</span>
    <p>
    """ ;

    var buttonFacebook = SSButtonFB(content)
      ..id = 'buttonFB'
      ..onClick.listen(_onClickFBLogin)
    ;

    var loadingFB = OPLoading(content, messageLoadingFacebookLogin)
      ..id = 'loadingFB'
      ..hide()
    ;

    var username = OCEAN_PRESS_APP.loginState.getUsername() ;

    if ( username != null && RegExp("^FB\\d+\$").hasMatch(username) ) username = null ;

    var inputTable = UIInputTable(content, [
      InputConfig('username', messageLoginUsername, type: 'email', value: username),
      InputConfig('password', messageLoginPassword, type: 'password', attributes: {'onEventKeyPress': 'Enter:login'})
    ])
      ..id = 'inputs'
    ;

    var buttonLogin = OPButton(content, messageButtonLogin)
      ..id = 'buttonLogin'
      ..onClick.listen(_onClickLogin)
    ;

    var loading = OPLoading(content, messageLoadingLogin)
      ..id = 'loading'
      ..hide()
    ;

    var buttonCreateAccount ;

    if ( OCEAN_PRESS_APP.canCreateAccount ) {
      buttonCreateAccount = OPButton(content, messageCreateAccount, small: true, fontSize: "80%")
        ..id = 'buttonCreateAccount'
        ..onClick.listen(_onClickCreateAccount)
      ;
    }

    var htmlLoginError = "<br><div field='msgLoginError' hidden><span class='ss-text-red' style='font-size: 85%'><br>$messageLoginError</span></div>" ;

    var labelLanguage = createDivInline(
        """
      <span style='font-size: 80%'>$messageIdiom: &nbsp;</span>
      """)
    ;

    var selLanguage = UIRoot.getInstance().buildLanguageSelector(_onLanguageSelection) ;
    selLanguage.style.fontSize = '70%';

    if ( !OCEAN_PRESS_APP.hasFacebookID ) {
      buttonFacebook = null ;
      loadingFB = null ;
    }

    return [htmlTitle, buttonFacebook, loadingFB, '<hr>', inputTable, '<p>', buttonCreateAccount, '&nbsp;&nbsp;&nbsp;&nbsp;', buttonLogin, loading, htmlLoginError, '<hr>', labelLanguage, selLanguage] ;
  }

  void _onLanguageSelection() {
    refresh();
  }


  @override
  void action(String action) {
    _onClickLogin(null) ;
  }

  List<UIComponent> _getFBLoginComponents() {
    return getRenderedUIComponentsByIds(['buttonFB', 'loadingFB']);
  }

  List<UIComponent> _getLoginComponents() {
    return getRenderedUIComponentsByIds(['buttonLogin', 'loading']);
  }

  void _hideLoadings() {
    var loadingFB = getRenderedUIComponentById('loadingFB');
    var loading = getRenderedUIComponentById('loading');

    if (loadingFB != null) loadingFB.hide();
    if (loading != null) loading.hide();
  }

  void _onClickCreateAccount(MouseEvent e) {
    UINavigator.navigateTo("register");
  }

  bool _clickedLoginFB = false ;

  void _onClickFBLogin(MouseEvent e) {
    _clickedLoginFB = true ;

    for (var elem in _getFBLoginComponents()) {
      elem.hide() ;
    }

    getRenderedUIComponentById('loadingFB').show();

    OCEAN_PRESS_APP.system.doFacebookLogin();

  }

  bool _clickedLogin = false ;

  void _onClickLogin(MouseEvent e) {
    _clickedLogin = true ;

    for (var elem in _getLoginComponents()) {
      elem.hide() ;
    }

    getRenderedUIComponentById('loading').show();

    var fields = getFields();

    var username = fields['username'];
    var pass = fields['password'];

    OCEAN_PRESS_APP.system.login(username, pass, onGlobalUserLogin);
    
  }

  @override
  void onGlobalUserLogin(UserLogin user) {
    if (!_clickedLoginFB && !_clickedLogin) return ;

    UIConsole.log("SSLogin.onGlobalUserLogin> $user") ;

    if (user == null) {
      for (UIComponent elem in joinLists( _getFBLoginComponents() , _getLoginComponents() )) {
        elem.show();
      }

      getFieldElement("msgLoginError").hidden = false ;
    }

    _hideLoadings();
  }

}

class SSButtonFB extends OPButton {

  static String get messageButtonLoginWithFB => OCEAN_PRESS_MESSAGES.msg("buttonLoginWithFB").build() ;

  SSButtonFB(Element parent) : super(parent, messageButtonLoginWithFB, classes: ['ss-button-fb' , '!ss-button', '!ss-button-small'] );

}


class OPRegister extends UIContent {
  OPRegister(Element parent) : super(parent, classes: ['ss-content','ss-register']);

  @override
  bool isAccessible() {
    return !GlobalUser.isLogged() ;
  }

  @override
  String deniedAccessRoute() {
    return "home";
  }

  String get messageRegisterTitle => OCEAN_PRESS_MESSAGES.buildMsg("registerTitle") ;
  String get messageRegisterName => OCEAN_PRESS_MESSAGES.buildMsg("registerName") ;
  String get messageRegisterEmail => OCEAN_PRESS_MESSAGES.buildMsg("registerEmail") ;
  String get messageRegisterUsername => OCEAN_PRESS_MESSAGES.buildMsg("registerUsername") ;
  String get messageRegisterPassword => OCEAN_PRESS_MESSAGES.buildMsg("registerPassword") ;
  String get messageButtonRegister => OCEAN_PRESS_MESSAGES.buildMsg("buttonRegister") ;
  String get messageButtonDoLogin => OCEAN_PRESS_MESSAGES.buildMsg("buttonDoLogin") ;
  String get messageRegisterError => OCEAN_PRESS_MESSAGES.buildMsg("registerError") ;

  UIInputTable infosTable ;

  @override
  renderContent() {

    String html1 = """
    <div class='ss-title'>$messageRegisterTitle</div>
    <p>
    """ ;

    this.infosTable = UIInputTable(content,[
      InputConfig('name', messageRegisterName),
      InputConfig('email', messageRegisterEmail, type: 'email'),
      InputConfig('username', messageRegisterUsername),
      InputConfig('password', messageRegisterPassword, type: 'password', attributes: {'onEventKeyPress': 'Enter:register'})
    ], "ss-input-error");

    var buttonRegister = OPButton(content, messageButtonRegister)
      ..setWideButton()
      ..onClick.listen(_register)
    ;

    var buttonLogin = OPButton(content, messageButtonDoLogin, small: true, fontSize: "80%")
      ..navigate("login")
    ;

    var htmlRegisterError = "<br><div field='messageRegisterError' hidden><span class='ss-text-red' style='font-size: 85%'><br>$messageRegisterError</span></div>" ;

    return [html1, '<hr>', infosTable, '<p>', buttonRegister, htmlRegisterError, '<hr><p>', buttonLogin] ;
  }


  @override
  void action(String action) {
    _register(null) ;
  }

  void _register(MouseEvent e) {
    UIConsole.log("Register") ;

    if ( !infosTable.checkFields() ) {
      return ;
    }

    var name = infosTable.getField("name");
    var email = infosTable.getField("email");
    var username = infosTable.getField("username");
    var pass = infosTable.getField("password");

    OCEAN_PRESS_APP.system.register(name , email, username, pass, _registeredUser);

  }

  void _registeredUser(UserLogin user) {
    UIConsole.log("_registeredUser> $user") ;

    if ( user == null ) {
      getFieldElement("messageRegisterError").hidden = false ;
    }
  }

}

class OPProfile extends UIContent {
  OPProfile(Element parent) : super(parent, classes: 'ss-content');

  @override
  bool isAccessible() {
    return GlobalUser.isLogged() ;
  }

  @override
  String deniedAccessRoute() {
    return "login";
  }

  String get messageProfileTitle => OCEAN_PRESS_MESSAGES.msg("profileTitle").build() ;
  String get messageProfileName => OCEAN_PRESS_MESSAGES.msg("profileName").build() ;
  String get messageProfileEmail => OCEAN_PRESS_MESSAGES.msg("profileEmail").build() ;
  String get messageProfileUsername => OCEAN_PRESS_MESSAGES.msg("profileUsername").build() ;
  String get messageProfileLanguage => OCEAN_PRESS_MESSAGES.msg("profileLanguage").build() ;
  String get messageButtonChangePassword => OCEAN_PRESS_MESSAGES.msg("buttonChangePassword").build() ;
  String get messageButtonMyItems => OCEAN_PRESS_MESSAGES.msg("buttonMyItems").build() ;
  String get messageButtonLogout => OCEAN_PRESS_MESSAGES.msg("buttonLogout").build() ;

  @override
  renderContent() {

    String html1 = """
    <div class='ss-title'>$messageProfileTitle</div>
    <p>
    """ ;

    var selLanguage = UIRoot.getInstance().buildLanguageSelector(refresh) ;

    var user = GlobalUser.user;

    var infosTable = UIInfosTable(content, {
      messageProfileName: user.name,
      messageProfileEmail: user.email,
      messageProfileUsername: user.username,
      messageProfileLanguage: selLanguage ,
    });

    var html2 ;

    var buttonChangePass ;

    if ( OCEAN_PRESS_APP.canChangePassword ) {
      html2 = "<p><hr><p>" ;

      buttonChangePass = OPButton(content, messageButtonChangePassword)
        ..navigate("changepass")
        ..setWideButton()
      ;
    }
    else {
      html2 = "<p>" ;
    }

    /*
    var buttonMyItems = OPButton(content, messageButtonMyItems)
      ..navigate("myitems")
      ..setWideButton()
    ;
     */

    var buttonLogout = OPButton(content, messageButtonLogout)
      ..navigate("logout")
      ..setWideButton()
    ;

    return [html1, infosTable, html2, buttonChangePass, '<p>', /*buttonMyItems,*/ '<p><hr><p>', buttonLogout] ;
  }

  @override
  void posRender() {

    SelectElement selectElement = content.querySelector("select") ;

    selectElement.onChange.listen((e) {
      var locale = selectElement.selectedOptions[0].value ;
      print("selected: $locale") ;
      UIRoot.getInstance().setPreferredLocale(locale);
      refresh();
    });

  }

}

class OPChangePass extends UIContent {
  OPChangePass(Element parent) : super(parent, classes: 'ss-content');

  @override
  bool isAccessible() {
    return GlobalUser.isLogged();
  }

  @override
  String deniedAccessRoute() {
    return "login" ;
  }

  String get messageChangePassTitle => OCEAN_PRESS_MESSAGES.msg("changePassTitle").build() ;
  String get messageCurrentPassword => OCEAN_PRESS_MESSAGES.msg("currentPassword").build() ;
  String get messageNewPassword => OCEAN_PRESS_MESSAGES.msg("newPassword").build() ;
  String get messageConfirmNewPassword => OCEAN_PRESS_MESSAGES.msg("confirmNewPassword").build() ;
  String get messageSaveNewPassword => OCEAN_PRESS_MESSAGES.msg("saveNewPassword").build() ;
  String get messageSavePassError => OCEAN_PRESS_MESSAGES.msg("savePassError").build() ;

  UIInputTable infosTable ;

  @override
  renderContent() {

    String html1 = """
    <div class='ss-title'>$messageChangePassTitle</div>
    <p>
    """ ;

    this.infosTable = UIInputTable(content,[
      InputConfig('current_password', messageCurrentPassword, type: 'password'),
      InputConfig('password', messageNewPassword, type: 'password'),
      InputConfig('password_confirm', messageConfirmNewPassword, type: 'password', attributes: {'onEventKeyPress': 'Enter:register'})
    ], "ss-input-error");

    var buttonSavePass = OPButton(content, messageSaveNewPassword)
    //..setWideButton()
      ..onClick.listen(_savePass)
    ;

    var htmlSaveError = "<br><div field='messageError' hidden><span class='ss-text-red' style='font-size: 85%'><br>$messageSavePassError</span></div>" ;

    return [html1, infosTable, '<p>', buttonSavePass, htmlSaveError] ;
  }

  void _savePass(dynamic evt) {
    UIConsole.log("Save Pass") ;

    if ( !infosTable.checkFields() ) {
      return ;
    }

    var pass = infosTable.getField("password");
    var passConfirm = infosTable.getField("password_confirm");

    if ( pass != passConfirm ) {
      infosTable.highlightField("password_confirm") ;
      return ;
    }

    var currentPass = infosTable.getField("current_password");

    OCEAN_PRESS_APP.system.changePassword(GlobalUser.user.username , currentPass, pass).then( _onSavedPass ) ;

  }

  void _onSavedPass(bool ok) {
    if (ok) {
      UINavigator.navigateTo("profile") ;
    }
    else {
      getFieldElement("messageError").hidden = false ;
    }
  }

}

class OPLogout extends UIContent {
  OPLogout(Element parent) : super(parent, classes: 'ss-content');

  String get messageReallyWantToLogout => OCEAN_PRESS_MESSAGES.msg("reallyWantToLogout").build() ;
  String get messageButtonLogout => OCEAN_PRESS_MESSAGES.msg("buttonLogout").build() ;
  String get messageButtonBack => OCEAN_PRESS_MESSAGES.msg("buttonBack").build() ;

  @override
  renderContent() {

    String html = """
    $messageReallyWantToLogout
    <p>
    """ ;

    var buttonLogout = OPButton(content, messageButtonLogout)
      ..setWideButton()
      ..onClick.listen(_click)
    ;

    var buttonBack = OPButton(content, messageButtonBack, small: true)
      ..navigate("<")
    ;

    return [html, buttonLogout, '<p>', buttonBack] ;
  }

  void _click(MouseEvent event) {
    OCEAN_PRESS_APP.system.logout();
  }

}

class OPOffline extends UIContent {
  OPOffline(Element parent) : super(parent, topMargin: _topSpace);

  @override
  renderContent() {

    String html = "OFFLINE" ;

    return [html] ;
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
    return "login" ;
  }

  @override
  renderContent() {

    String html = "HOME" ;

    return [html] ;
  }

}

////////////////////////////////////////////////////////////////////////////////
