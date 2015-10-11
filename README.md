# VLBanner
iAd, AdMob and IAP wrapper for iOS

## Features
  * iPhone and iPad compatability
  * iAd and AdMob support
  * IAP to remove advert
  * Remove advert purchase restoration
  
## Installation

1) Add the following frameworks to your project.
```bash
AdSupport
StoreKit
```

2) Add the following frameworks to your Podfile.
```bash
pod 'CryptoSwift'
pod 'Google/Analytics'
pod 'Google/AdMob'
```

3) Add VLBanner.h to the build settings your target under:
"Swift Compiler - Code Generation" -> "Objective -C Bridging Header" 

## Initialization

```swift
let advert = VLBanner.shared
advert.adUnitID = "ca-app-pub-xxxxxxxxx/xxxxxxxxx" //Insert your AdMob identifier here
advert.production = true //Choose whether test or production adverts are shown
advert.viewController = self //View controller to present modal adverts
self.view.addSubview(advert)
advert.start() //Begin advert cycle
```

## In App Purchasing


## Advert Delegate

## IAP Delegate
