//
//  MapView.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/4/22.
//

import UIKit
import SwiftUI
import CoreLocation

import MapboxMaps

// Represents the camera position on the map
struct Camera {
  var center: CLLocationCoordinate2D
  var zoom: CGFloat
}

/// `MapView` is a SwiftUI wrapper around Mapbox's UIKit-based `MapboxMaps.MapView`.
struct MapView: UIViewRepresentable {
  // The MapView has a binding to a Camera struct representing the current
  // camera position. It reacts to external changes to this value (updating
  // the map) and also publishes internal changes (updating the bound value).
  @Binding private var camera: Camera

  // The map style to load
  private var styleURI: StyleURI

  // Whether or not to show 3D terrain
  private var showTerrain = true

  // This is a chainable method to set the value of showTerrain
  func showTerrain(_ value: Bool) -> Self {
    var updated = self
    updated.showTerrain = value
    return updated
  }

  init(camera: Binding<Camera>, style: String) {
    _camera = camera
    self.styleURI = MapboxMaps.StyleURI(rawValue: style)!
  }

  // SwiftUI View structs, like this one, get recreated many times over the lifecycle
  // of the graphical user interface element they represent. A UIViewRepresentable,
  // however, gets to create a Coordinator which will live for the entire time that
  // the view is on-screen (between the onAppear and onDisappear events). It's a good
  // place to store state that needs to be persisted during this lifetime.
  func makeCoordinator() -> Self.Coordinator {
    return Self.Coordinator(camera: $camera)
  }

  // After SwiftUI calls makeCoordinator(), it calls this method to make a UIView. It
  // adds this UIView to the view heirarchy for us, and it'll pass the view into our
  // updateUIView method later on, so we don't need to store it ourselves.
  func makeUIView(context: UIViewRepresentableContext<MapView>) -> MapboxMaps.MapView {
    let options = MapboxMaps.MapInitOptions(styleURI: styleURI)
    let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)

    // Set up the Coordinator to respond to events from this MapView. It'll be
    // responsible for detecting when the user pans or zooms and updating the
    // camera accordingly.
    context.coordinator.mapView = mapView

    // Some operations, like adding layers, need to be deferred until the initial
    // style loading is completed.
      mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
      // Add sky layer
      var skyLayer = SkyLayer(id: "sky-layer")
      skyLayer.skyType = .constant(.atmosphere)
      skyLayer.skyAtmosphereSun = .constant([0.0, 0.0])
      skyLayer.skyAtmosphereSunIntensity = .constant(15.0)

      // We make the sky layer 'persistent' so that it survives across style reloads
      try! mapView.mapboxMap.style.addPersistentLayer(skyLayer)

      // Run an initial update. Subsequent calls to updateUIView will happen automatically
      // when SwiftUI detects that this view needs redrawing.
      updateUIView(mapView, context: context)
    }

    return mapView
  }

  // When this View is reconfigured externally (like if the camera or showTerrain values
  // are changed), SwiftUI will call updateUIView(), passing in the UIView and Coordinator
  // we created earlier. It's our job to update the UIView to reflect the new desired state.
  func updateUIView(_ mapView: MapboxMaps.MapView, context: Context) {
    // Create a MapboxMaps CameraState equivalent to the current Camera
    var cameraState = mapView.cameraState
    cameraState.center = self.camera.center
    cameraState.zoom = self.camera.zoom

    // If the new camera state doesn't equal the current one, update the map
    if cameraState != mapView.cameraState {
      // When setting the camera, we need to temporarily disable the coordinator's observers.
      // If we didn't do this, the SwiftUI state would be modified during view update, which
      // causes undefined behavior.
      context.coordinator.performWithoutObservation {
        mapView.mapboxMap.setCamera(to: CameraOptions(cameraState: cameraState, anchor: nil))
      }
    }

    // if the style URI has changed, load the new map style
    if styleURI != mapView.mapboxMap.style.uri {
      mapView.mapboxMap.loadStyleURI(styleURI) { _ in
        // after the style finishes loading, update the terrain settings if needed
        updateTerrain(mapView, context: context)
          updateWaypoints(mapView: mapView)
      }
    } else {
      // if no style reload is necessary, just update the terrain settings immediately
      updateTerrain(mapView, context: context)
        updateWaypoints(mapView: mapView)

    }
  }
    
    
    func updateWaypoints(mapView: MapboxMaps.MapView) {
        let centerCoordinate = mapView.cameraState.center
        let zoomLevel = Int(mapView.cameraState.zoom.rounded())

        let currentTileID = MathHelper.getTileID(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude, zoom: zoomLevel)

        let visibleWaypoints = WaypointDataSource.shared.getWaypointsForTile(tileID: currentTileID)
        print("Visible Waypoints: \(visibleWaypoints.count)")
        
        let sourceId = "waypoints"
        let layerId = "waypoint-layer"
        let waypointImageName = "pin" // Name of the image asset

        // Load the image asset
        if let waypointImage = UIImage(named: waypointImageName) {
            do {
                if !mapView.mapboxMap.style.imageExists(withId: waypointImageName) {
                    try mapView.mapboxMap.style.addImage(waypointImage, id: waypointImageName)
                }
            } catch {
                print("Failed to add image to style: \(error)")
            }
        } else {
            print("Image \(waypointImageName) not found.")
        }
        //may not be necessary or may need adjusting, Android ha sonly min and max zoom, took these from TF
        let tileOptions = TileOptions(tolerance: 0.375, tileSize: 256, buffer: 1, clip: true, wrap: false)
        let options = CustomGeometrySourceOptions(
            fetchTileFunction: { tileID in
                print("Tile ID: x\(tileID.x), y\(tileID.y), z\(tileID.z)")
                do {
                    try mapView.mapboxMap.style.setCustomGeometrySourceTileData(
                        forSourceId: sourceId,
                        tileId: tileID,
                        features: visibleWaypoints
                    )
                } catch {
                    print("Error setting custom geometry source tile data: \(error)")
                }
            },
            cancelTileFunction: { _ in },
            tileOptions: TileOptions()
        )

        do {
            try mapView.mapboxMap.style.addCustomGeometrySource(withId: sourceId, options: options)

            var symbolLayer = SymbolLayer(id: layerId)
            symbolLayer.source = sourceId
            symbolLayer.iconImage = .constant(.name(waypointImageName))
            symbolLayer.iconAllowOverlap = .constant(true)
            symbolLayer.iconSize = .constant(1.0)
            symbolLayer.iconAnchor = .constant(.center)
            symbolLayer.iconOffset = .constant([0, 0])

            // Use the "id" property in the textField
            symbolLayer.textField = .constant("{id}")
            symbolLayer.textSize = .constant(12.0)
            symbolLayer.textColor = .constant(.init(.black))
            symbolLayer.textOffset = .constant([0, 2])

            try mapView.mapboxMap.style.addLayer(symbolLayer)

            print("Waypoints and symbol layer with random colors added successfully.")
        } catch {
            print("Error adding waypoints or symbol layer: \(error)")
        }
    }
    


    
  // This is a helper function for updateUIView() above
  private func updateTerrain(_ mapView: MapboxMaps.MapView, context: Context) {
    do {
      if showTerrain && !mapView.mapboxMap.style.sourceExists(withId: "mapbox-dem") {
        // Add terrain
        var demSource = RasterDemSource()
        demSource.url = "mapbox://mapbox.mapbox-terrain-dem-v1"
        // 514 specifies padded DEM tile and provides better performance than 512 tiles
        demSource.tileSize = 514
        demSource.maxzoom = 14.0
        try mapView.mapboxMap.style.addSource(demSource, id: "mapbox-dem")

        var terrain = Terrain(sourceId: "mapbox-dem")
        terrain.exaggeration = .constant(1.5)

        try mapView.mapboxMap.style.setTerrain(terrain)
      } else if !showTerrain && mapView.mapboxMap.style.sourceExists(withId: "mapbox-dem") {
        mapView.mapboxMap.style.removeTerrain()
        try mapView.mapboxMap.style.removeSource(withId: "mapbox-dem")
      }
    } catch {
      print(error)
    }
  }
}

extension MapView {
  /// Here's our custom `Coordinator` implementation.
  final class Coordinator {
    /// It holds a binding to the camera
    @Binding private var camera: Camera
    private var cancelable: Cancelable?

    var mapView: MapboxMaps.MapView! {
      didSet {
        cancelable?.cancel()
        cancelable = nil

        // The Coordinator subscribes to the Mapbox map view's events and responds
        // to them as appropriate. For example, when the .cameraChanged event fires,
        // it reads the new camera state from the map and updates the bound Camera
        // to reflect it.
          cancelable = mapView.mapboxMap.onEvery(event: .cameraChanged) { [unowned self] (event) in
          notify(for: event)
        }
      }
    }

    init(camera: Binding<Camera>) {
      _camera = camera
    }

    deinit {
      cancelable?.cancel()
    }

    private var ignoreNotifications = false

    func performWithoutObservation(_ block: () -> Void) {
      ignoreNotifications = true
      block()
      ignoreNotifications = false
    }

    private func notify(for event: MapEvent<NoPayload>) {
      guard !ignoreNotifications else { return }
        camera.center = mapView.cameraState.center
        camera.zoom = mapView.cameraState.zoom
    }
  }
}


