//
//  TabBarController.swift
//  BlogSmart
//
//  Created by Raunaq Malhotra on 8/7/23.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if User.current == nil {
            updateTabBarVisibility(shouldHideTabBar: true)
        } else {
            updateTabBarVisibility(shouldHideTabBar: false)
        }
    }
    
    // Function to update tab bar visibility based on the variable value
    func updateTabBarVisibility(shouldHideTabBar : Bool) {
            tabBar.isHidden = shouldHideTabBar
    }
}
