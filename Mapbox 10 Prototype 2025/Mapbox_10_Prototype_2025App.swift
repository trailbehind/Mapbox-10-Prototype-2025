//
//  Mapbox_10_Prototype_2025App.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 11/22/24.
//

import SwiftUI
import MapboxMaps

@main
struct Mapbox_10_Prototype_2025App: App {
    init() {
        // Replace Mapbox's default HTTP service with our own implementation, which handles
        // some Gaia-specific special cases like `g://` URLs and offline cache lookups.
        let customHTTPService = MapView.HttpService()
        MapboxMaps.HttpServiceFactory.setUserDefinedForCustom(customHTTPService)
    }
    
    
    var body: some Scene {
        WindowGroup {
            MainMap()
        }
    }
}
