
GeoLogger
=========

GeoLogger is a sample iOS app that lets you log your current location (overrideable) as seen on a Google Map. You may also edit them later.

This makes use of [Google Maps SDK for iOS](https://developers.google.com/maps/).

You will need to put in your API credentials in `PrefixHeader.pch`. If you don't already have them, you can generate your credentials from the [Google Developer Console](https://console.developers.google.com). 

This was tested against iOS 9 but there shouldn't be any problems building this for earlier versions.

Installation
------------
This project makes use of the Google Maps SDK and the awesome [AFNetworking](http://github.com/afnetworking/afnetworking) via [CocoaPods](http://cocoapods.org). Just run `pod install` prior to building then open the resulting `GeoLogger.xcworkspace`.

&copy; 2014 The Chill Mill, Inc and Marco Cabazal


License
-------
GeoLogger is licensed under the MIT license. See [LICENSE](LICENSE.md) for details.
