//
//  BottomDrawer.swift
//  chalkhak
//
//  Created by 강구현 on 2/20/25.
//

import SwiftUI

struct BottomDrawer<DrawerContent: View>: View {
    @Binding var isOpen: Bool
    let drawerHeight: CGFloat
    let drawerContent: () -> DrawerContent
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 40, height: 6)
                    .foregroundStyle(Color.white)
                    .padding(.top, 8)
                drawerContent()
            }
            .frame(height: drawerHeight)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .offset(y: isOpen ? 0 : drawerHeight + 100)
            .animation(.easeOut(duration: 0.3), value: isOpen)
        }
        .ignoresSafeArea()
    }
}
