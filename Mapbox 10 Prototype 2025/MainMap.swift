//
//  MainMap.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/4/22.
//

import SwiftUI
import CoreLocation


// Here's an example of how to use our SwiftUI `MapView` wrapper.
// Things to note:
//   - this file doesn't import MapboxMaps; it knows nothing about Mapbox's APIs

enum Style: String {
  case gaiaTopo = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiatopo-feet.json"
  case gaiaWinter = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiawinter-feet.json"
    case mapboxOutdoors = "mapbox://styles/mapbox/outdoors-v11"
}

struct MainMap: View {
    // In this example, the view defines its own state, but this could also be stored
    // in a ViewModel.
    @State private var camera = Camera(
        center: CLLocationCoordinate2D(latitude: 47.42, longitude: -121.425), zoom: 12)
    @State private var style = Style.gaiaTopo
    @State private var showTerrain = false

    
    var body: some View {
        VStack {
            MapView(camera: $camera, style: style.rawValue)
                .showTerrain(showTerrain)
                .edgesIgnoringSafeArea([.all])
            Toggle("Terrain", isOn: $showTerrain)
                          .padding()
        }
    }
}

#Preview {
    MainMap()
}
