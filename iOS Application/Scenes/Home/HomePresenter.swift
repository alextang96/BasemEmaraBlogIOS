//
//  HomeRender.swift
//  BasemEmara iOS
//
//  Created by Basem Emara on 2019-05-24.
//  Copyright © 2019 Zamzam Inc. All rights reserved.
//

struct HomePresenter<Store: StoreRepresentable>: HomePresentable where Store.StateType == HomeState {
    private let store: Store
    
    init(store: Store) {
        self.store = store
    }
}

extension HomePresenter {
    
    func display(profile: HomeAPI.Profile) {
        store.action(.loadProfile(profile))
    }
    
    func display(menu: [HomeAPI.MenuSection]) {
        store.action(.loadMenu(menu))
    }
    
    func display(social: [HomeAPI.SocialItem]) {
        store.action(.loadSocial(social))
    }
}
