//
//  HomeView.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import SwiftUI

enum Tab {
    case map, addPost, account, notifications
}

struct HomeView: View {
    @State private var isDrawerOpen = false
    @State private var drawerContent: any View = EmptyView()
    
    @State private var selectedTab: Tab = .account
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    Group {
                        LazyView(MapView(isDrawerOpen: $isDrawerOpen, drawerContent: $drawerContent))
                            .tag(Tab.map)
                        
                        LazyView(AddPostView(tab: $selectedTab))
                            .tag(Tab.addPost)
                        
                        LazyView(NotificationsView(isDrawerOpen: $isDrawerOpen, drawerContent: $drawerContent))
                            .tag(Tab.notifications)
                        
                        LazyView(AccountView())
                            .tag(Tab.account)
                    }
                    .toolbar(.hidden, for: .tabBar)
                    .toolbarBackground(.hidden, for: .tabBar)
                }
                
                VStack {
                    Spacer()
                    tabBar
                }
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarHidden(true)
        }
    }
    
    var tabBar: some View {
        HStack {
            Spacer()
            
            Button (action: {
                selectedTab = .map
            }){
                VStack(alignment: .center) {
                    Image(systemName: selectedTab == .map ? "house.fill" : "house")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22)
                }
            }
            .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button (action: {
                selectedTab = .addPost
            }) {
                VStack(alignment: .center) {
                    Image(systemName: selectedTab == .addPost ? "plus.app.fill" : "plus.app")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22)
                }
            }
            .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button (action: {
                selectedTab = .notifications
            }) {
                VStack(alignment: .center) {
                    Image(systemName: selectedTab == .notifications ? "bell.fill": "bell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22)
                }
            }
            .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button (action: {
                selectedTab = .account
            }) {
                VStack(alignment: .center) {
                    Image(systemName: selectedTab == .account ? "person.fill" : "person")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22)
                }
            }
            .foregroundStyle(Color.primary)
            
            Spacer()
        }
        .padding(.vertical)
        .frame(height: 62)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        .padding(.horizontal, 40)
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

#Preview {
    HomeView()
}
