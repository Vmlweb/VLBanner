//
//  TableViewController.swift
//  VLBannerExample
//
//  Created by Victor on 13/10/2015.
//  Copyright © 2015 Vmlweb. All rights reserved.
//

import UIKit

class TableViewControler: UITableViewController{
	
	//Advert spacing
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		//Add padding to bottom of tableView
		self.tableView.contentInset.bottom = VLBanner.shared.frame.size.height
		self.tableView.scrollIndicatorInsets.bottom = self.tableView.contentInset.bottom
	}
}
