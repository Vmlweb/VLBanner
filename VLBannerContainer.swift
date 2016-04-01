//
//  ContainerController.swift
//  UkuleleTabs
//
//  Created by Victor on 08/09/2015.
//  Copyright (c) 2015 Vmlweb. All rights reserved.
//

import UIKit

class VLBannerContainer: UIViewController{
	
	var subControllers = [UIViewController]()
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		for subController in subControllers{
			if VLBanner.shared.iapPurchased{
				subController.view.frame.size.height = self.view.frame.size.height
			}else{
				subController.viewWillLayoutSubviews()
			}
		}
	}
}