//
//  File.swift
//  Basem Emara
//
//  Created by Basem Emara on 2018-10-21.
//  Copyright © 2018 Zamzam Inc. All rights reserved.
//

import UIKit
import SwiftyPress
import ZamzamCore

final class ShortcutPlugin: ApplicationPlugin {
    private var launchedShortcutItem: UIApplicationShortcutItem?
    
    @Inject private var deepLinkModule: DeepLinkModuleType
    private lazy var router: DeepLinkRoutable = deepLinkModule.component()
}

extension ShortcutPlugin {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem else {
            return true
        }
        
        launchedShortcutItem = shortcutItem
        return false //Prevent "performActionForShortcutItem" from being called
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let shortcut = launchedShortcutItem else { return }
        performShortcutAction(for: shortcut)
        launchedShortcutItem = nil //Reset for next use
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(performShortcutAction(for: shortcutItem))
    }
}

private extension ShortcutPlugin {
    
    /// Handle actions performed by home screen shortcuts
    /// - Returns: A Boolean value indicating whether or not the shortcut action succeeded.
    @discardableResult
    func performShortcutAction(for shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let shortcutItemType = ShortcutItemType(for: shortcutItem) else {
            return false
        }
        
        switch shortcutItemType {
        case .favorites:
            router.showFavorites()
        case .contact:
            router.sendFeedback()
        }
        
        return true
    }
}

private extension ShortcutPlugin {
    
    enum ShortcutItemType: String {
        case favorites
        case contact
        
        init?(for shortcutItem: UIApplicationShortcutItem) {
            guard let type = shortcutItem.type
                .components(separatedBy: ".").last else {
                    return nil
            }
            
            self.init(rawValue: type)
        }
    }
}