# VLBanner
iAd, AdMob and IAP wrapper for iOS

## Features
  * iPhone and iPad compatability
  * iAd and AdMob support
  * IAP to remove advert

## Installation

1) Link these frameworks to your project.
```bash
AdSupport
StoreKit
```

2) Add these lines to your Podfile.
```bash
pod 'CryptoSwift'
pod 'Google/Analytics'
pod 'Google/AdMob'
```

3) Add VLBanner.h to the build settings your target under:
"Swift Compiler - Code Generation" -> "Objective -C Bridging Header" 

## Getting Started

```swift
let advert = VLBanner.shared
advert.adUnitID = "ca-app-pub-xxxxxxxxx/xxxxxxxxx" //Insert your AdMob identifier here
advert.production = true //Choose whether test or production adverts are shown
advert.viewController = self //View controller to present modal adverts
self.view.addSubview(advert)
advert.start() //Begin advert cycle
```

The banner will resize itself as needed to display its content.
Constraints can be used to auto resize superviews and ui elements to fit onto the banner.

## Default View

You can specify a custom view to be displayed when there are no adverts to present.
```swift
let advert = VLBanner.shared
advert.defaultView = UILabel(frame: advert.frame)
let defaultLabel = advert.defaultView as! UILabel
defaultLabel.text = "Remove This Advert"
defaultLabel.font = UIFont(name: "Helvetica Bold", size: 20)
defaultLabel.textAlignment = NSTextAlignment.Center
defaultLabel.backgroundColor = UIColor.blackColor()
defaultLabel.textColor = UIColor.whiteColor()
```

## Advert Delegate

You can use the protocol `VLBannerPurchaseDelegate` to be notified of advert changes.
```swift
let advert = VLBanner.shared
advert.advertDelegate = self
```

You then have access to the following methdods.
```swift
func advertDefaultAction(advert: VLBanner) //Default view was pressed
func advertViewDidLoadAd(advert: VLBanner) //iAd or AdMob was loaded into view
func advertView(advert: VLBanner, didFailToReceiveAdWithError error: NSError) //iAd or AdMob returned an error
func advertViewActionShouldBegin(advert: VLBanner) //Modal advert presented from user click
func advertViewActionDidFinish(advert: VLBanner) //Modal advert finished presenting
```

## In App Purchasing

You can use an in app purchase to enable the user to pay for the adverts removal.
```swift
let advert = VLBanner.shared
advert.iapIdentifier = "com.myapp.iap.adverts" //IAP identifier from iTunes Connect
advert.purchaseDelegate = self
```

Once the IAP has been setup you can use the following methods to start an IAP transaction.
```swift
let advert = VLBanner.shared
advert.purchaseRemoveAdverts()
advert.restoreRemoveAdverts()
```
If the transaction has been successful the banner will automaticlly hide itself and store its state in `NSUserDefaults`. You can access this value via the `VLBanner.shared.iapPurchased` boolean property. (true is removed)

You can then use the following `VLBannerPurchaseDelegate` methods to be notified of IAP changes.
```swift
func purchaseIAPSuccessful(advert: VLBanner, transaction: SKPaymentTransaction)
func purchaseIAPRestored(advert: VLBanner, transaction: SKPaymentTransaction)
func purchaseIAPFailed(advert: VLBanner, didFailToPurchaseWithError error: NSError)
```

## Get IAP Information

You can request an `SKProduct` object from the banner to obtain IAP information.
```swift
let advert = VLBanner.shared
advert.requestProduct { (error, product) -> Void in
 guard let product = product else{ return }
 guard let defaultLabel = advert.defaultView as? UILabel else{ return }
  
 //Format price to string
	let formatter = NSNumberFormatter()
	formatter.numberStyle = .CurrencyStyle
	formatter.locale = product.priceLocale
	defaultLabel.text = "Remove This Advert \(formatter.stringFromNumber(product.price)!)"
}
```
You can use the `VLBanner.shared.userInfo` property to store the `SKProduct` if it is required elsewhere.
