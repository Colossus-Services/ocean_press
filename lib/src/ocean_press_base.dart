
import 'dart:html';

import 'package:bones_ui/bones_ui.dart';
import 'package:intl_messages/intl_messages.dart';
import 'package:ocean_press/ocean_press.dart';

IntlMessages OCEAN_PRESS_MESSAGES = IntlMessages.package('/ocean_press/')
                        ..registerResourceDiscover(IntlResourceDiscover('package:ocean_press/i18n/ocean_press-msgs-','.intl')) ;

////////////////////////////////////////////////////////////////////////////////

class OPButton extends UIButton {
  final String text ;
  final String fontSize ;

  OPButton(Element parent, this.text, {String navigate, Map<String,String> navigateParameters, Map<String,String> navigateParametersProvider(), dynamic classes, bool small = false, this.fontSize}) : super(parent, navigate: navigate, navigateParameters: navigateParameters, navigateParametersProvider: navigateParametersProvider, classes: classes) {
    configureClasses( classes , [ small ? 'ui-button-small' : 'ui-button' ] ) ;
  }

  @override
  String renderButton() {
    if (disabled) {
      content.style.opacity = '0.7' ;
    }
    else {
      content.style.opacity = null ;
    }

    if (fontSize != null) {
      return "<span style='font-size: $fontSize'>$text</span>" ;
    }
    else {
      return text ;
    }
  }

  void setWideButton() {
    content.style.width = '80%';
  }

  void setNormalButton() {
    content.style.width = null ;
  }

}

class OPLoading extends UIComponent {

  MessageBuilder msgLoading = OCEAN_PRESS_MESSAGES.msg("loading") ;

  String _text ;
  int topMargin ;

  OPLoading(Element parent, { String text, bool show = true, this.topMargin }) : _text = text , super(parent, inline: true) {
    if (!show) hide();
  }

  @override
  OPLoading clone() => OPLoading(null, text: text, topMargin: topMargin);

  String get text => _text != null ? _text : msgLoading.build() ;

  SpanElement _loadingText ;

  @override
  dynamic render() {

    content.style.verticalAlign = 'middle';

    var divTopMargin = '';
    if (topMargin != null && topMargin > 0) {
      divTopMargin = "<div style='display: inline-block; margin: ${topMargin}px 0 0 0'></div>" ;
    }

    String html ;

    if ( hasText ) {
      html = """
      $divTopMargin
      <div style='display: inline-block; text-align: center;'><div class='ui-loader' style='display: inline-block;'></div><br/><span id='_loadingText' class='ui-loader-text' style='display: inline-block; text-align: center;'>$text</span></div>
      """;
    }
    else {
      html = """
      $divTopMargin
      <div style='display: inline-block; text-align: center;'><div class='ui-loader' style='display: inline-block;'></div></div>
      """;
    }

    return html;
  }

  bool get hasText => _text != null && _text.isNotEmpty ;

  void posRender() {
    this._loadingText = content.querySelector("#_loadingText") ;
  }

  void setLoadingText(String text) {
    _loadingText.text = _text = text ;
  }

  String getLoadingText() {
    return text ;
  }

}


abstract class OPSection {

  setParent(Element parent) ;

  String get route ;
  bool get isCurrentRoute ;

  String get name ;

  bool get hideFromMenu ;
  bool get visibleInMenu ;

  bool isAccessible() ;

  String deniedAccessRoute() ;

}

abstract class OPContentSection extends UIContent implements OPSection {
  String _route ;
  String _name ;
  bool _hideFromMenu ;
  String _deniedAccessRoute ;
  FunctionTest _isAccessible ;

  OPContentSection( { String route, String name , bool hideFromMenu, String deniedAccessRoute , FunctionTest isAccessible , dynamic classes } ) : super( DivElement() , classes: classes ) {
    this._route = route ;
    this._name = name ?? route ;
    this._hideFromMenu = hideFromMenu ?? false ;
    this._deniedAccessRoute = deniedAccessRoute ;
    this._isAccessible = isAccessible ;
  }

  String get route => _route;
  bool get isCurrentRoute => UINavigator.currentRoute == route ;

  String get name => _name ?? route ;

  bool get hideFromMenu => _hideFromMenu;
  bool get visibleInMenu => !_hideFromMenu;

  @override
  bool isAccessible() {
    return _isAccessible != null ? _isAccessible() : true ;
  }

  @override
  String deniedAccessRoute() {
    return this._deniedAccessRoute ;
  }

}

class OPExplorerSection extends OPContentSection implements OPSection {

  final dynamic explorerModel ;

  OPExplorerSection( this.explorerModel, { String route, String name , bool hideFromMenu, String deniedAccessRoute , FunctionTest isAccessible , dynamic classes } ) : super( route: route , name: name , hideFromMenu: hideFromMenu, deniedAccessRoute: deniedAccessRoute, isAccessible: isAccessible, classes: classes ) ;

  @override
  dynamic renderContent() {
    return UIExplorer(content, explorerModel);
  }

}

abstract class OPControlledSection extends UIControlledComponent implements OPSection {
  String _route ;
  String _name ;
  bool _hideFromMenu ;
  String _deniedAccessRoute ;
  FunctionTest _isAccessible ;

  OPControlledSection( dynamic loadingContent, dynamic errorContent, { String route, String name , bool hideFromMenu, String deniedAccessRoute , FunctionTest isAccessible , dynamic classes } ) : super( null , loadingContent, errorContent , classes: classes ) {
    this._route = route ;
    this._name = name ?? route ;
    this._hideFromMenu = hideFromMenu ?? false ;
    this._deniedAccessRoute = deniedAccessRoute ;
    this._isAccessible = isAccessible ;
  }

  String get route => _route;
  bool get isCurrentRoute => UINavigator.currentRoute == route ;

  String get name => _name ?? route ;

  bool get hideFromMenu => _hideFromMenu;
  bool get visibleInMenu => !_hideFromMenu;

  @override
  bool isAccessible() {
    return _isAccessible != null ? _isAccessible() : true ;
  }
  @override
  String deniedAccessRoute() {
    return this._deniedAccessRoute ;
  }


  @override
  MapProperties getControllersProperties() {
    return MapProperties.fromStringProperties( UINavigator.currentNavigation.parameters ) ;
  }

}

/////////////////////////////////////////////////////////////////////////////////////

bool isSmallScreen() {
  return window.innerWidth <= 600 ;
}

///////////
