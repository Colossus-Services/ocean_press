class Intl {
  static message(String s, {String name, List args, String desc}) {
    String key = name.replaceFirst('message', '');
    key = key.substring(0, 1).toLowerCase() + key.substring(1);

    //print("$key=$s ## $desc") ;

    //print("") ;

    print("String get $name => MESSAGES.msg(\"$key\").build() ;");
  }
}

class Foo {
/*
  String get messageLoginUsername => Intl.message(
      "Username",
      name: "messageLoginUsername",
      args: [],
      desc: "Label of field username for login");

  String get messageLoginPassword => Intl.message(
      "Password",
      name: "messageLoginPassword",
      args: [],
      desc: "Label of field password for login");

  String get messageLoadingFacebookLogin => Intl.message(
      "logging in (Facebook)...",
      name: "messageLoadingFacebookLogin",
      args: [],
      desc: "Loading when click in FB login button");

  String get messageLoadingLogin => Intl.message(
      "logging in...",
      name: "messageLoadingLogin",
      args: [],
      desc: "Loading when click in login button");

  String get messageLoginError => Intl.message(
      "Login error",
      name: "messageLoginError",
      args: [],
      desc: "Message for login error");

  String get messageCreateAccount => Intl.message(
      "Create Account",
      name: "messageCreateAccount",
      args: [],
      desc: "link to create account");


  String get messageButtonLoginWithFB => Intl.message(
      "Login with Facebook",
      name: "messageButtonLoginWithFB",
      args: [],
      desc: "Facebook login button");
*/

/*
  String get messageRegisterTitle => Intl.message(
      "Register",
      name: "messageRegisterTitle",
      args: [],
      desc: "Register title");

  String get messageRegisterName => Intl.message(
      "Name",
      name: "messageRegisterName",
      args: [],
      desc: "Register name");

  String get messageRegisterEmail => Intl.message(
      "E-mail",
      name: "messageRegisterEmail",
      args: [],
      desc: "Register e-mail");

  String get messageRegisterUsername => Intl.message(
      "Username",
      name: "messageRegisterUsername",
      args: [],
      desc: "Register username");

  String get messageRegisterPassword => Intl.message(
      "Password",
      name: "messageRegisterPassword",
      args: [],
      desc: "Register password");

  String get messageButtonRegister => Intl.message(
      "Register",
      name: "messageButtonRegister",
      args: [],
      desc: "Register button");

  String get messageButtonDoLogin => Intl.message(
      "Do log in",
      name: "messageButtonDoLogin",
      args: [],
      desc: "Do log in button");

  String get messageRegisterError => Intl.message(
      "Error registering! Try again later...",
      name: "messageRegisterError",
      args: [],
      desc: "Message for register error");


 */

/*
  static String get messageProfileTitle => Intl.message(
      "PROFILE",
      name: "messageProfileTitle",
      args: [],
      desc: "Profile title");

  static String get messageProfileName => Intl.message(
      "Name",
      name: "messageProfileName",
      args: [],
      desc: "Profile name");

  static String get messageProfileEmail => Intl.message(
      "E-mail",
      name: "messageProfileEmail",
      args: [],
      desc: "Profile e-mail");

  static String get messageProfileUsername => Intl.message(
      "Username",
      name: "messageProfileUsername",
      args: [],
      desc: "Profile username");

  static String get messageProfileLanguage => Intl.message(
      "Language",
      name: "messageProfileLanguage",
      args: [],
      desc: "Profile language");

  static String get messageButtonChangePassword => Intl.message(
      "Change Password",
      name: "messageButtonChangePassword",
      args: [],
      desc: "Change password button");

  static String get messageButtonMyItems => Intl.message(
      "My Items",
      name: "messageButtonMyItems",
      args: [],
      desc: "My items button");

  static String get messageButtonLogout => Intl.message(
      "Logout",
      name: "messageButtonLogout",
      args: [],
      desc: "Logout button");


 */

/*
  static String get messageChangePassTitle => Intl.message(
      "CHANGE PASSWORD",
      name: "messageChangePassTitle",
      args: [],
      desc: "Change password title");

  static String get messageCurrentPassword => Intl.message(
      "Current password",
      name: "messageCurrentPassword",
      args: [],
      desc: "Current password field");

  static String get messageNewPassword => Intl.message(
      "New password",
      name: "messageNewPassword",
      args: [],
      desc: "New password field");

  static String get messageConfirmNewPassword => Intl.message(
      "Confirm new password",
      name: "messageConfirmNewPassword",
      args: [],
      desc: "Confirm new password field");

  static String get messageSaveNewPassword => Intl.message(
      "Save New Password",
      name: "messageSaveNewPassword",
      args: [],
      desc: "Save new password button");

  static String get messageSavePassError => Intl.message(
      "Error saving password! Check current password.",
      name: "messageSavePassError",
      args: [],
      desc: "Message for saving password error");


 */

  static String get messageRealyWantToLogout =>
      Intl.message("Do you really want to leave?",
          name: "messageReallyWantToLogout",
          args: [],
          desc: "Logout confirm message");

  static String get messageButtonLogout => Intl.message("Logout",
      name: "messageButtonLogout", args: [], desc: "Logout button");

  static String get messageButtonBack => Intl.message("Back",
      name: "messageButtonBack", args: [], desc: "Back button");
}

void main() {
  Foo o = Foo();

  /*
  o.messageLoginUsername;
  o.messageLoginPassword;
  o.messageLoadingFacebookLogin;
  o.messageLoadingLogin;
  o.messageLoginError;
  o.messageCreateAccount;
  */

  //o.messageButtonLoginWithFB;

  /*
  o.messageRegisterTitle ;
  o.messageRegisterName ;
  o.messageRegisterEmail ;
  o.messageRegisterUsername ;
  o.messageRegisterPassword ;
  o.messageButtonRegister ;
  o.messageButtonDoLogin ;
  o.messageRegisterError ;
   */

  /*
  Foo.messageProfileTitle ;
  Foo.messageProfileName ;
  Foo.messageProfileEmail ;
  Foo.messageProfileUsername;
  Foo.messageProfileLanguage;
  Foo.messageButtonChangePassword;
  Foo.messageButtonMyItems;
  Foo.messageButtonLogout;

   */

  /*
  Foo.messageChangePassTitle ;
  Foo.messageCurrentPassword;
  Foo.messageNewPassword;
  Foo.messageConfirmNewPassword;
  Foo.messageSaveNewPassword;
  Foo.messageSavePassError;


   */

  Foo.messageRealyWantToLogout;
  Foo.messageButtonLogout;
  Foo.messageButtonBack;
}
