//
//  TabBarController.swift
//  VLBannerExample
//
//  Created by Victor on 13/10/2015.
//  Copyright © 2015 Vmlweb. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController{
	
	override func viewDidLoad(){
		super.viewDidLoad()
		
		//Advert setup
		let advert = VLBanner.shared
		advert.production = false
		advert.defaultView = UILabel(frame: advert.frame)
		let defaultLabel = advert.defaultView as! UILabel
		defaultLabel.text = "Remove This Advert"
		defaultLabel.textAlignment = NSTextAlignment.Center
		defaultLabel.textColor = UIColor.whiteColor()
		defaultLabel.backgroundColor = UIColor.blackColor()
		advert.viewController = self
		self.view.addSubview(advert)
		advert.start()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		//Position advert above tab bar
		VLBanner.shared.layoutSubviews()
		VLBanner.shared.frame.origin.x = 0
		VLBanner.shared.frame.origin.y = self.view.frame.size.height - (self.tabBar.frame.size.height + VLBanner.shared.frame.size.height)
	}
	
}
