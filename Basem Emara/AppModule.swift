//
//  AppConfiguration.swift
//  Basem Emara
//
//  Created by Basem Emara on 2018-10-21.
//  Copyright © 2018 Zamzam Inc. All rights reserved.
//

import Foundation
import SwiftyPress
import ZamzamCore

struct AppModule: SwiftyPressModule {
    private let environment: Environment = {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }()
    
    func componentStore() -> ConstantsStore {
        ConstantsMemoryStore(
            environment: environment,
            itunesName: "basememara",
            itunesID: "1021806851",
            baseURL: {
                let string: String
                switch environment {
                case .development:
                    string = "https://basememara.com"
                case .staging:
                    string = "https://staging1.basememara.com"
                case .production:
                    string = "https://basememara.com"
                }
                
                guard let url = URL(string: string) else {
                    fatalError("Could not determine base URL of server.")
                }
                
                return url
            }(),
            baseREST: "wp-json/swiftypress/v5",
            wpREST: "wp-json/wp/v2",
            email: "contact@basememara.com",
            privacyURL: "https://basememara.com/privacy/?mobileembed=1",
            disclaimerURL: nil,
            styleSheet: "https://basememara.com/wp-content/themes/metro-pro/style.css",
            googleAnalyticsID: "UA-60131988-2",
            featuredCategoryID: 64,
            defaultFetchModifiedLimit: 25,
            taxonomies: ["category", "post_tag", "series"],
            postMetaKeys: ["_series_part"],
            logFileName: "basememara"
        ) as ConstantsStore
    }
    
    func componentStore() -> PreferencesStore {
        PreferencesDefaultsStore(
            defaults: {
                UserDefaults(
                    suiteName: {
                        switch environment {
                        case .development, .staging:
                            return "group.io.zamzam.Basem-Emara-staging"
                        case .production:
                            return "group.io.zamzam.Basem-Emara"
                        }
                    }()
                ) ?? .standard
            }()
        ) as PreferencesStore
    }

    func componentStore() -> SeedStore {
        SeedFileStore(
            forResource: "seed.json",
            inBundle: .main
        ) as SeedStore
    }

    func component() -> Theme {
        AppTheme() as Theme
    }
}
