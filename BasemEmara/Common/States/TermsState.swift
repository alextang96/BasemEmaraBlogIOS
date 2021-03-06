//
//  TermsState.swift
//  BasemEmara iOS
//
//  Created by Basem Emara on 2020-05-31.
//  Copyright © 2020 Zamzam Inc. All rights reserved.
//

import Foundation.NSNotification
import SwiftyPress
import ZamzamUI

class TermsState: StateRepresentable {
    
    private(set) var allTerms: [Int: TermsDataViewModel] = [:] {
        willSet {
            guard newValue != allTerms, #available(iOS 13, *) else { return }
            combineSend()
        }
        
        didSet {
            guard oldValue != allTerms else { return }
            notificationPost(for: \Self.allTerms)
        }
    }
}

// MARK: - Action

enum TermsAction: Action {
    case mergeTerms([TermsDataViewModel])
}

// MARK: - Reducer

extension TermsState {
    
    func callAsFunction(_ action: TermsAction) {
        switch action {
        case .mergeTerms(let items):
            allTerms.merge(items.map { ($0.id, $0) }) { $1 }
        }
    }
}

// MARK: - SwiftUI

#if canImport(SwiftUI)
import Combine

@available(iOS 13, *)
extension TermsState: ObservableObject {}
#endif
