![Fluffy logo image](https://github.com/suolapeikko/suolapeikko.github.io/blob/master/images/fluffy_logo.png)

## About Fluffy
Fluffy is a macOS menu bar app that manages your kerberos ticket refreshes and optionally allows you to change your kerberos password as well. It uses keychain to store your credentials and then automatically refreshes your ticket periodically and during network changes.

I had a hard time deciding on the app name so what better than the other famous three headed dog... [Fluffy](http://harrypotter.wikia.com/wiki/Fluffy)

## Configuring Fluffy

You can pre-configure Fluffy using terminal or your favorite management tool.

Enable pre-set kerberos identity domain:

`defaults write com.github.suolapeikko.Fluffy kerberos_realm "MYREALM.COM"`

You can optionally enable "Change password" item in the GUI, if you want to change your password through Fluffy (using kerberos):

`defaults write com.github.suolapeikko.Fluffy enable_password_change -bool true`

## Using Fluffy

It's pretty straightforward, just install the app from releases or build and sign your own using the project. It launches an application to your macOS menu bar. Fluffy supports both basic and dark GUI modes. You need to allow Fluffy to use your keychain as it saves your kerberos user account name and password to Keychain.

Menu items basically say it all, see the picture below. Fluffy icon is gray if you do not have valid credentials, and turns black if you do.

![Fluffy menu image](https://github.com/suolapeikko/suolapeikko.github.io/blob/master/images/fluffy_menu.png)

When you enable Single Sign-on for the first time, you must either use `antti` or `antti@MYDOMAIN.COM` format, depending on whether you did or did not enable realm with `defaults write` -command (see Configuring Fluffy -chapter).
