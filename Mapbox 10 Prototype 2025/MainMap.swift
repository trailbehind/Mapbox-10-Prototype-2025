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

    @State private var currentDownloads: [MapDownloadTask] = []
    
    var body: some View {
        VStack {
            MapView(camera: $camera, style: style.rawValue)
                .showTerrain(showTerrain)
                .edgesIgnoringSafeArea([.all])
            VStack {
              // The slider is bound to the camera's zoom property. When the bound value changes,
              // SwiftUI will call updateUIView(_:context:) on the child MapView, which reads
              // the new value and updates the underyling Mapbox map.

              // The MapView also has a binding to the camera state. When the users interacts
              // with the map (e.g. panning or pinching to zoom), the MapView's coordinator will
              // respond to those events and update the camera. That means that other parts of
              // the app (such as this Text view) can inspect the camera state without knowing
              // anything about the underlying Mapbox map implementation.
              Slider(value: $camera.zoom, in: 0...20)
              Text(String(format: "current zoom: %.1f", camera.zoom))

              // This picker lets you choose which map style you want. It's bound to the `style`
              // state variable which is passed to the MapView.
              Picker(selection: $style, label: Text("Map Style")) {
                Text("Gaia Topo").tag(Style.gaiaTopo)
                Text("Gaia Winter").tag(Style.gaiaWinter)
              }.pickerStyle(.segmented)

              // Likewise, when showTerrain changes, the MapView's updateUIView(_:context:) method
              // will be called. It's responsible for updating the underlying Mapbox map to the
              // desired state.
              Toggle("Terrain", isOn: $showTerrain)

              // Here's a demo of offline tile downloading. Currently the bounding box and list of
              // map sources is hardcoded here, but could also be selectable through the UI.
              Button("Download offline maps for Mount Rainier NP") {
                for sourceID in ["gaiaosmv3", "contoursfeetz12", "landcover", "gaiashadedrelief"] {
                  let source = MapSourcesService.shared.sources[sourceID]!
                  let bounds = Bounds(west: -121.92, south: 46.72, east: -121.50, north: 47.00) // Mount Rainier National Park (approx)
                  let downloadTask = MapDownloadService.shared.downloadTask(source: source, bounds: bounds, zooms: 0...12)!
                  currentDownloads.append(downloadTask)
                }
              }

              // Show progress bars for any tile downloads that are in progress
              if currentDownloads.count > 0 {
                VStack {
                  ForEach(currentDownloads, id: \.templateURL.rawValue) { download in
                    if #available(iOS 14.0, *) {
                      ProgressView(download.progress)
                    } else {
                      Text("Downloading...")
                    }
                  }
                }
              }

            }
            .padding()
        }
    }
}

#Preview {
    MainMap()
}
