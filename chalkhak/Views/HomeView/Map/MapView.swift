//
//  MapView.swift
//  chalkhak
//
//  Created by 강구현 on 1/17/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @Binding var isDrawerOpen: Bool
    @Binding var drawerContent: any View
    
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Text("hi")
    }
}
