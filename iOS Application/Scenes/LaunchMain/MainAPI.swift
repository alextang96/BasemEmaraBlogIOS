//
//  MainAPI.swift
//  BasemEmara iOS
//
//  Created by Basem Emara on 2020-04-02.
//  Copyright © 2020 Zamzam Inc. All rights reserved.
//

import UIKit.UIDevice
import UIKit.UIViewController

protocol MainInteractorType: InteractorType {
    func fetchMenu(for idiom: UIUserInterfaceIdiom)
}

protocol MainPresenterType: PresenterType {
    func display(menu: [MainAPI.TabItem])
}

protocol MainRenderType: RenderType {
    func rootView(for menu: MainAPI.Menu) -> UIViewController
    func postView(for id: Int) -> UIViewController
}

/// Used to notify the controller was selected from the main controller.
protocol MainSelectable {
    func mainDidSelect()
}

// MARK: - Namespace

enum MainAPI {
    
    enum Menu: Int {
        case home
        case blog
        case favorites
        case search
        case more
    }
    
    struct TabItem: Identifiable {
        let id: Menu
        let title: String
        let imageName: String
    }
}
