import 'dart:html';

import 'package:bones_ui/bones_ui_kit.dart';
import 'package:intl_messages/intl_messages.dart';

IntlMessages OCEAN_PRESS_MESSAGES = IntlMessages.package('/ocean_press/')
  ..registerResourceDiscover(IntlResourceDiscover(
      'package:ocean_press/i18n/ocean_press-msgs-', '.intl'));

/// Ocean Press Button.
class OPButton extends UIButtonBase {
  final String text;

  final String fontSize;

  OPButton(Element parent, this.text,
      {String navigate,
      Map<String, String> navigateParameters,
      Map<String, String> Function() navigateParametersProvider,
      dynamic classes,
      bool small = false,
      this.fontSize})
      : super(parent,
            navigate: navigate,
            navigateParameters: navigateParameters,
            navigateParametersProvider: navigateParametersProvider,
            classes: classes) {
    configureClasses(classes, [
      small ? 'btn btn-secondary ui-button-small' : 'btn btn-primary ui-button'
    ]);
  }

  @override
  String renderButton() {
    if (disabled) {
      content.style.opacity = '0.7';
    } else {
      content.style.opacity = null;
    }

    if (fontSize != null) {
      return "<span style='font-size: $fontSize'>$text</span>";
    } else {
      return text;
    }
  }

  void setWideButton() {
    content.style.width = '80%';
    content.style.maxWidth = '400px';
  }

  void setNormalButton() {
    content.style.width = null;
    content.style.maxWidth = null;
  }
}

/// Ocean Press Button to Capture an Photo.
class OPButtonCapturePhoto extends UICapture {
  final String text;

  final String fontSize;

  OPButtonCapturePhoto(Element parent, this.text,
      {String navigate,
      Map<String, String> navigateParameters,
      Map<String, String> Function() navigateParametersProvider,
      dynamic classes,
      bool small = false,
      this.fontSize})
      : super(parent, CaptureType.PHOTO,
            navigate: navigate,
            navigateParameters: navigateParameters,
            navigateParametersProvider: navigateParametersProvider,
            classes: classes) {
    configureClasses(classes, [small ? 'ui-button-small' : 'ui-button']);
  }

  @override
  String renderButton() {
    if (disabled) {
      content.style.opacity = '0.7';
    } else {
      content.style.opacity = null;
    }

    if (fontSize != null) {
      return "<span style='font-size: $fontSize'>$text</span>";
    } else {
      return text;
    }
  }

  void setWideButton() {
    content.style.width = '80%';
  }

  void setNormalButton() {
    content.style.width = null;
  }
}

/// Ocean Press Loading element.
class OPLoading extends UIComponent {
  MessageBuilder msgLoading = OCEAN_PRESS_MESSAGES.msg('loading');

  String _text;

  int topMargin;

  OPLoading(Element parent, {String text, bool show = true, this.topMargin})
      : _text = text,
        super(parent, inline: true) {
    if (!show) hide();
  }

  @override
  OPLoading clone() => OPLoading(null, text: text, topMargin: topMargin);

  String get text => _text ?? msgLoading.build();

  SpanElement _loadingText;

  @override
  dynamic render() {
    content.style.verticalAlign = 'middle';

    var divTopMargin = '';
    if (topMargin != null && topMargin > 0) {
      divTopMargin =
          "<div style='display: inline-block; margin: ${topMargin}px 0 0 0'></div>";
    }

    String html;

    if (hasText) {
      html = """
      $divTopMargin
      <div style='display: inline-block; text-align: center;'><div class='spinner-border m-1 ui-loader' style='display: inline-block;'></div><br/><span id='_loadingText' class='ui-loader-text' style='display: inline-block; text-align: center;'>$text</span></div>
      """;
    } else {
      html = """
      $divTopMargin
      <div style='display: inline-block; text-align: center;'><div class='spinner-border m-1 ui-loader' style='display: inline-block;'></div></div>
      """;
    }

    return html;
  }

  bool get hasText => _text != null && _text.isNotEmpty;

  @override
  void posRender() {
    _loadingText = content.querySelector('#_loadingText');
  }

  void setLoadingText(String text) {
    _loadingText.text = _text = text;
  }

  String getLoadingText() {
    return text;
  }
}

typedef NameProvider = String Function();

/// Ocean Section.
abstract class OPSection {
  void setParent(Element parent);

  /// Route of the section.
  String get route;

  /// Returns [true] if the route of this section is the current route.
  bool get isCurrentRoute;

  /// Returns the name of the section.
  String get name;

  /// Returns the current title of the section.
  String get currentTitle => name;

  /// If [true] will hide this section from the menu.
  bool get hideFromMenu;

  /// If [true] will be visible in the menu.
  bool get visibleInMenu;

  /// If returns [true] this sections is accessible in the current context.
  ///
  /// Useful to block sections that requires login.
  bool isAccessible();

  /// Route to forward when access is denied.
  String deniedAccessRoute();

  /// Resolve a dynamic [name]: can be a [Function] or a [String].
  String resolveName(dynamic name) {
    return resolveDynamicName(name, route);
  }

  /// Static function to resolve a dynamic [name].
  ///
  /// [def] The default name if [name] is invalid.
  static String resolveDynamicName(dynamic name, [String def]) {
    if (name == null) return def;

    if (name is String) {
      return name;
    } else if (name is NameProvider) {
      try {
        var n = name();
        if (n != null) {
          return n;
        } else {
          return def;
        }
      } catch (e, s) {
        print(e);
        print(s);
      }
    }

    return '$name';
  }
}

/// Ocean Press Section based in [UIContent].
abstract class OPContentSection extends UIContent implements OPSection {
  String _route;

  dynamic _name;

  bool _hideFromMenu;

  String _deniedAccessRoute;

  FunctionTest _isAccessible;

  OPContentSection(
      {String route,
      dynamic name,
      bool hideFromMenu,
      String deniedAccessRoute,
      FunctionTest isAccessible,
      dynamic classes})
      : super(DivElement(), classes: classes, renderOnConstruction: false) {
    _route = route;
    _name = name ?? route;
    _hideFromMenu = hideFromMenu ?? false;
    _deniedAccessRoute = deniedAccessRoute ?? 'home';
    _isAccessible = isAccessible;
  }

  @override
  String get route => _route;

  @override
  bool get isCurrentRoute => UINavigator.currentRoute == route;

  @override
  String get name {
    if (_name == null) return route;

    if (_name is String) return _name;

    String name;
    if (_name is Function) {
      name = _name();
    }

    return name ?? route;
  }

  @override
  bool get hideFromMenu => _hideFromMenu;

  @override
  bool get visibleInMenu => !_hideFromMenu;

  @override
  bool isAccessible() {
    return _isAccessible != null ? _isAccessible() : true;
  }

  @override
  String deniedAccessRoute() {
    return _deniedAccessRoute;
  }

  @override
  String get currentTitle => name;

  @override
  String resolveName(dynamic name) {
    return OPSection.resolveDynamicName(name, route);
  }
}

/// Ocean Press Section based in [UIExplorer].
class OPExplorerSection extends OPContentSection implements OPSection {
  final dynamic explorerModel;

  OPExplorerSection(this.explorerModel,
      {String route,
      dynamic name,
      bool hideFromMenu,
      String deniedAccessRoute,
      FunctionTest isAccessible,
      dynamic classes})
      : super(
            route: route,
            name: name,
            hideFromMenu: hideFromMenu,
            deniedAccessRoute: deniedAccessRoute,
            isAccessible: isAccessible,
            classes: ['text-left', ...?classes]);

  @override
  dynamic renderContent() {
    return UIExplorer(content, explorerModel);
  }

  @override
  String get currentTitle => name;

  @override
  String resolveName(name) {
    return OPSection.resolveDynamicName(name, route);
  }
}

/// Ocean Press Section based in [UIControlledComponent].
abstract class OPControlledSection extends UIControlledComponent
    implements OPSection {
  String _route;

  dynamic _name;

  bool _hideFromMenu;

  String _deniedAccessRoute;

  FunctionTest _isAccessible;

  OPControlledSection(dynamic loadingContent, dynamic errorContent,
      {String route,
      dynamic name,
      bool hideFromMenu,
      String deniedAccessRoute,
      FunctionTest isAccessible,
      ControllerPropertiesType controllersPropertiesType,
      dynamic classes})
      : super(null, loadingContent, errorContent,
            controllersPropertiesType: controllersPropertiesType,
            classes: classes) {
    _route = route;
    _name = name ?? route;
    _hideFromMenu = hideFromMenu ?? false;
    _deniedAccessRoute = deniedAccessRoute;
    _isAccessible = isAccessible;
  }

  @override
  String get route => _route;

  @override
  bool get isCurrentRoute => UINavigator.currentRoute == route;

  @override
  String get name => resolveName(_name);

  @override
  String get currentTitle => name;

  @override
  bool get hideFromMenu => _hideFromMenu;

  @override
  bool get visibleInMenu => !_hideFromMenu;

  @override
  bool isAccessible() {
    return _isAccessible != null ? _isAccessible() : true;
  }

  @override
  String deniedAccessRoute() {
    return _deniedAccessRoute;
  }
}

bool isSmallScreen() {
  return window.innerWidth <= 600;
}
