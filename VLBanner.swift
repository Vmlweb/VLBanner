//
//  VLBanner.swift
//  UkuleleTabs
//
//  Created by Victor on 01/09/2015.
//  Copyright (c) 2015 Vmlweb. All rights reserved.
//

import UIKit
import iAd
import CryptoSwift
import AdSupport
import StoreKit

//Delegate
protocol VLBannerAdvertDelegate{
	func advertDefaultAction(advert: VLBanner)
	func advertViewDidLoadAd(advert: VLBanner)
	func advertView(advert: VLBanner, didFailToReceiveAdWithError error: NSError)
	func advertViewActionShouldBegin(advert: VLBanner)
	func advertViewActionDidFinish(advert: VLBanner)
}
protocol VLBannerPurchaseDelegate{
	func purchaseIAPSuccessful(advert: VLBanner, transaction: SKPaymentTransaction)
	func purchaseIAPRestored(advert: VLBanner, transaction: SKPaymentTransaction)
	func purchaseIAPFailed(advert: VLBanner, didFailToPurchaseWithError error: NSError)
}

//Main Banner
class VLBanner: UIView, ADBannerViewDelegate, GADBannerViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver{
	static let shared = VLBanner() //Singleton Class
	
	//Delegates
	var advertDelegate: VLBannerAdvertDelegate?
	var purchaseDelegate: VLBannerPurchaseDelegate?
	
	//Vars
	var production = false //If true real adverts are serve
	var adUnitID: String? //AdMob publisher identifier
	var viewController: UIViewController?{ //View controller to present AdMob and IAP modal view onto
		didSet{
			
			//View controller changed while admob is presented
			if adMob != nil && viewController != nil && oldValue != viewController{
				adMob!.rootViewController = viewController
			}
		}
	}
	var defaultView: UIView? //Label displayed when no advert is visible
	var iapIdentifier: String? //In app purchase identifier used when purchasing remove adverts
	var iapProductCallback: ((error: NSError?, product: SKProduct?) -> Void)? //Request to get product information before purchasing
	var iapPurchased = NSUserDefaults.standardUserDefaults().boolForKey("VLBanner") ?? false{ //If true the advert has been removed
		didSet{
			if oldValue != iapPurchased{
				
				//Update local stored version upon remove advert purchased
				NSUserDefaults.standardUserDefaults().setBool(iapPurchased, forKey: "VLBanner")
				NSUserDefaults.standardUserDefaults().synchronize()
				
				//Restart current advert
				stop()
				start()
			}
		}
	}
	var isPresenting = false //Statuses whether the advert is being viewed currently
	var userInfo: AnyObject? //Misc data to be stored with the object, useful for storing SKProduct object once loaded
	
	//Advert Views
	var iAd: ADBannerView?
	var adMob: GADBannerView?
	var defaultAd: UIView?
	
	//Advert start/stop deamons
	func start(){
		
		//Check if advert removal has been purchased if not start up
		if !iapPurchased{
			initDefaultAd()
			initiAd()
		}
	}
	func stop(){
		deinitiAd()
		deinitAdMob()
		deinitDefaultAd()
	}
	func pause(){
		deinitiAd()
		deinitAdMob()
	}
	func resume(){
		if !iapPurchased{
			initiAd()
		}
	}
	
	//iAd Init
	func initiAd(){
		iAd = ADBannerView(adType: ADAdType.Banner)
		iAd!.frame = self.frame
		iAd!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight] //Allows ad to resize to superview
		iAd!.delegate = self
	}
	func deinitiAd(){
		
		//Remove all traces of ad
		if iAd != nil{
			iAd!.delegate = nil
			iAd!.removeFromSuperview()
			iAd = nil
		}
	}
	
	//AdMob Init
	func initAdMob(){
		adMob = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
		if viewController != nil{
			adMob!.rootViewController = viewController!
		}
		adMob!.frame = self.frame
		adMob!.delegate = self
		adMob!.adUnitID = self.adUnitID
		adMob!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight] //Allows ad to resize to superview
		
		//Load request for production or testing
		let request = GADRequest()
		if !production{
			request.testDevices = [ kGADSimulatorID ]
			
			//Make the current device serve test adverts by generating a AdMob Device ID
			let md5Device = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString.md5()
			request.testDevices.append(md5Device)
		}
		adMob!.loadRequest(request)
	}
	func deinitAdMob(){
		
		//Remove all traces of ad
		if adMob != nil{
			adMob!.delegate = nil
			adMob!.removeFromSuperview()
			adMob = nil
		}
	}
	
	//House Init
	func initDefaultAd(){
		
		//Use house label
		if let label = defaultView{
			defaultAd = label
			defaultAd!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight] //Allows ad to resize to superview
			defaultAd!.frame = self.frame
			self.addSubview(defaultAd!)
			layoutSubviews()
		}else{
			defaultAd = UIView(frame: self.frame)
			defaultAd?.backgroundColor = UIColor.redColor()
		}
	}
	func deinitDefaultAd(){
		
		//Remove all traces of ad
		if defaultAd != nil{
			defaultAd!.removeFromSuperview()
			defaultAd = nil
		}
	}
	
	//iAd Delegate
	func bannerViewDidLoadAd(banner: ADBannerView!) {
		
		//Show ad when loaded
		if let advert = iAd{
			if iAd!.superview == nil{
				deinitAdMob()
				self.addSubview(advert)
			}
			layoutSubviews();
			
			//Delegate
			if let delegate = advertDelegate{
				delegate.advertViewDidLoadAd(self)
			}
		}
	}
	func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
		deinitiAd()
		initAdMob()
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertView(self, didFailToReceiveAdWithError: error)
		}
	}
	func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
		isPresenting = true
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertViewActionShouldBegin(self)
		}
		
		return true
	}
	func bannerViewActionDidFinish(banner: ADBannerView!) {
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertViewActionDidFinish(self)
		}
		
		//Refresh
		isPresenting = false
		layoutSubviews()
	}
	
	//AdMob Delegate
	func adViewDidReceiveAd(bannerView: GADBannerView!) {
		
		//Show ad when loaded
		if let advert = adMob{
			if advert.superview == nil{
				deinitiAd()
				self.addSubview(advert)
			}
			layoutSubviews()
			
			//Delegate
			if let delegate = advertDelegate{
				delegate.advertViewDidLoadAd(self)
			}
		}
	}
	func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
		deinitAdMob()
		initiAd()
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertView(self, didFailToReceiveAdWithError: error)
		}
	}
	func adViewWillPresentScreen(bannerView: GADBannerView!) {
		isPresenting = true
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertViewActionShouldBegin(self)
		}
	}
	func adViewDidDismissScreen(bannerView: GADBannerView!) {
		
		//Delegate
		if let delegate = advertDelegate{
			delegate.advertViewActionDidFinish(self)
		}
		
		isPresenting = false
		layoutSubviews()
	}
	
	//View init
	override func willMoveToSuperview(newSuperview: UIView?) {
		super.willMoveToSuperview(newSuperview)
		self.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight] //Allows self to autoresie to superview
	}
	
	//Resize all frames to suite orientation and screen dimentions
	override func layoutSubviews() {
		super.layoutSubviews()
		
		//Stop frame from ajusting when presenting an advert which isn't current orientation
		if isPresenting{
			return
		}
		
		//Send default to back
		if let advert = defaultAd{
			self.sendSubviewToBack(advert)
		}
		
		//Set width
		if let superview = self.superview{
			self.frame.size.width = superview.frame.size.width
		}
		
		//iAd
		if iAd != nil{
			
			//Set height
			if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
				self.frame.size.height = 66
			}else{
				if UIDevice.currentDevice().orientation.isLandscape.boolValue{
					self.frame.size.height = 32
				}else{
					self.frame.size.height = 50
				}
			}
			
			//Set frame
			iAd!.frame.origin = CGPointZero
			iAd!.frame.size = self.frame.size
			
			return
		}
		
		//AdMob
		if adMob != nil{
			
			//Set height
			if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
				self.frame.size.height = 90
			}else{
				if UIDevice.currentDevice().orientation.isLandscape.boolValue{
					self.frame.size.height = 32
				}else{
					self.frame.size.height = 50
				}
			}
			
			//Set frame
			adMob!.frame.size = self.frame.size
			adMob!.frame.origin = CGPointZero
			
			//Set orientation
			if UIDevice.currentDevice().orientation.isLandscape.boolValue{
				adMob!.adSize = kGADAdSizeSmartBannerLandscape
			}else{
				adMob!.adSize = kGADAdSizeSmartBannerPortrait
			}
			
			return
		}
		
		//DefaultAd
		if defaultAd != nil{
			
			//Set height
			if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
				self.frame.size.height = 66
			}else{
				if UIDevice.currentDevice().orientation.isLandscape.boolValue{
					self.frame.size.height = 32
				}else{
					self.frame.size.height = 50
				}
			}
			
			//Set frame
			defaultAd!.frame.origin = CGPointZero
			defaultAd!.frame.size = self.frame.size
			
			return
		}
		
		//Nothing to display
		self.frame.size.height = 0
	}
	
	//Run callback for default advert if clicked
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		var visible = true
		
		//Check iAd
		if let advert = iAd{
			if advert.window != nil{
				visible = false
			}
		}
		
		//Check AdMob
		if let advert = adMob{
			if advert.window != nil{
				visible = false
			}
		}
		
		//Isn't presenting an advert
		if visible{
			if let delegate = advertDelegate{
				delegate.advertDefaultAction(self)
			}
		}
	}
	
	//In App Purchase
	func purchaseRemoveAdverts(){
		
		//Check if payments are allowed
		if SKPaymentQueue.canMakePayments(){
			requestProduct(nil)
		}else{
			
			//Delegate
			if let delegate = purchaseDelegate{
				let error = NSError(domain: "com.vmlweb.ukuleletabs", code: 50, userInfo:
					[NSLocalizedDescriptionKey: "Product could not be purchased"]
				)
				delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
			}
		}
	}
	func restoreRemoveAdverts(){
		
		//Check if payments are allowed
		if SKPaymentQueue.canMakePayments(){
			
			//Initiate payment for product ad observer
			SKPaymentQueue.defaultQueue().addTransactionObserver(self)
			SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
			
		}else{
			
			//Delegate
			if let delegate = purchaseDelegate{
				let error = NSError(domain: "com.vmlweb.ukuleletabs", code: 50, userInfo:
					[NSLocalizedDescriptionKey: "Product could not be purchased"]
				)
				delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
			}
		}
	}
	
	//StoreKit Request Delegate
	func requestProduct(callback: ((error: NSError?, product: SKProduct?) -> Void)?){
		iapProductCallback = callback
		
		if let identifier = iapIdentifier{
			
			//Make request for product
			let productRequest = SKProductsRequest(productIdentifiers: NSSet(object: identifier) as! Set<String>)
			productRequest.delegate = self
			productRequest.start()
			
		}else{
			
			//Make error
			let error = NSError(domain: "com.vmlweb.ukuleletabs", code: 50, userInfo:
				[NSLocalizedDescriptionKey: "Missing product identifier"]
			)
			
			//Callback
			if let callback = iapProductCallback{
				callback(error: error, product: nil)
				iapProductCallback = nil
			}else{
				
				//Delegate
				if let delegate = purchaseDelegate{
					delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
				}
			}
		}
	}
	func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
		
		//Pick correct product from validated by comparing identifier
		for prod in response.products{
			if prod.productIdentifier == iapIdentifier{
				
				//Callback
				if let callback = iapProductCallback{
					callback(error: nil, product: prod)
					iapProductCallback = nil
				}else{
					
					//Initiate payment for product ad observer
					SKPaymentQueue.defaultQueue().addTransactionObserver(self)
					SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: prod))
				}
				
				return
			}
		}
		
		//Make error
		let error = NSError(domain: "com.vmlweb.ukuleletabs", code: 50, userInfo:
			[NSLocalizedDescriptionKey: "Product could not be found in store response"]
		)
		
		//Callback
		if let callback = iapProductCallback{
			callback(error: error, product: nil)
			iapProductCallback = nil
		}else{
			
			//Delegate
			if let delegate = purchaseDelegate{
				delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
			}
		}
	}
	func request(request: SKRequest, didFailWithError error: NSError) {
		
		//Callback
		if let callback = iapProductCallback{
			callback(error: error, product: nil)
			iapProductCallback = nil
		}else{
			
			//Delegate
			if let delegate = purchaseDelegate{
				delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
			}
		}
	}
	
	//Payment Observer
	func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
		
		//Loop through each transaction
		for trans in transactions{
			if trans.payment.productIdentifier == iapIdentifier{
				
				//Item purchase was successful
				if trans.transactionState == .Purchased || trans.transactionState == .Restored{
					
					//Complete transaction and hide adverts
					self.iapPurchased = true
					layoutSubviews()
					
					//Delegate
					if let delegate = purchaseDelegate{
						if trans.transactionState == .Purchased{
							delegate.purchaseIAPSuccessful(self, transaction: trans)
						}else if trans.transactionState == .Restored{
							delegate.purchaseIAPRestored(self, transaction: trans)
						}
					}
					
					//Remove observer and finish
					SKPaymentQueue.defaultQueue().finishTransaction(trans)
					SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
				}
				
				//Item purchase failed unexpectedly
				if trans.transactionState == .Failed{
					
					//Delegate
					if let delegate = purchaseDelegate{
						delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: trans.error!)
					}
					
					//Remove observer and finish
					SKPaymentQueue.defaultQueue().finishTransaction(trans)
					SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
				}
			}
		}
	}
	func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
		
		//Delegate
		if let delegate = purchaseDelegate{
			delegate.purchaseIAPFailed(self, didFailToPurchaseWithError: error)
		}
	}
}