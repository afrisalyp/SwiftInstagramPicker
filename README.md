# SwiftInstagramPicker

## Installation

SwiftInstagramPicker is packaged as a Swift framework. Currently this is the simplest way to add it to your app:

* Drag Instagram Picker.xcodeproj to your project in the Project Navigator.
* Select your project and then your app target. Open the Build Phases panel.
* Expand the Target Dependencies group, and add InstagramPicker framework.
* import InstagramPicker whenever you want to use InstagramPicker.

## How to
### Setting URL Schemes
<p align="center">
  <img src="Assets/OAuthSwift-icon.png?raw=true" alt="OAuthSwift"/>
</p>
Replace oauth-swift by your redirect url scheme

#### Handle URL in AppDelegate
```swift
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        applicationHandleOpenURL(url)
        return true
    }
    
    @available(iOS 9.0, *)
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        applicationHandleOpenURL(url)
        return true
    }
    
    func applicationHandleOpenURL(url: NSURL) {
        OAuthSwift.handleOpenURL(url)
    }
```

#### Pick Instagram Image
```swift
    @IBAction func pick(sender: UIButton) {
        let controller: PhotoLibraryViewController = PhotoLibraryViewController(clientId: "clientid", clientSecret: "clientsecret", redirectUrl: "oauth-swift://oauth-callback/instagram", redirectUrlScheme: "oauth-swift")
        controller.onSelectionComplete = selectionComplete
        controller.present(self, animated: true)
    }

    func selectionComplete(media: IGMedia?) {
        print("media url = \(media?.url)")
    }
```
