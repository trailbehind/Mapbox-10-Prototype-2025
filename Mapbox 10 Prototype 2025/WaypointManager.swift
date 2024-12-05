//
//  WaypointManager.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 12/2/24.
//

import MapboxMaps

struct Waypoint {
    var id: Int
    var latitude: Double
    var longitude: Double
    var image: String
    
    static func waypointToFeature(waypoint: Waypoint) -> Feature {
        let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
        let point = Point(coordinate)
        var feature = Feature(geometry: .point(point))
        feature.properties = [
                "id": .string(String(waypoint.id)),
                "icon": .string(waypoint.image)
            ]
        return feature
    }
}

class WaypointManager {
    static let shared = WaypointManager()
    private let defaultImageName = "pin"

    var waypoints: [Waypoint] = []
    
    var grid = false

    private init() {
        waypoints = fetchWaypoints() // Simulate fetching from CoreData
    }
    
    private func fetchWaypoints() -> [Waypoint] {
        var generatedWaypoints: [Waypoint] = []
        
        let startLatitude = 47.42
        let startLongitude = -121.425
        let spacing = 0.1
        let gridDimension = 10
        let totalPoints = 1000
        if grid {
            for row in 0..<gridDimension {
                for col in 0..<gridDimension {
                    let latitude = startLatitude + (Double(row) * spacing)
                    let longitude = startLongitude + (Double(col) * spacing)
                    
                    let waypoint = Waypoint(id: row * gridDimension + col, latitude: latitude, longitude: longitude, image: randomMarkerImage())
                    generatedWaypoints.append(waypoint)
                }
            }
        } else {
            for i in 0..<totalPoints {
                let latitude = startLatitude + Double.random(in: -spacing...spacing)
                let longitude = startLongitude + Double.random(in: -spacing...spacing)
                let waypoint = Waypoint(id: i, latitude: latitude, longitude: longitude, image: randomMarkerImage())
                generatedWaypoints.append(waypoint)
            }
        }
        print("Generated waypoint count: \(generatedWaypoints.count)")
        return generatedWaypoints
    }


    func addWaypointsLayer(mapView: MapboxMaps.MapView) {
        let sourceId = "waypoints"
        let layerId = "waypoint-layer"

        loadImageAssets(mapView: mapView)

        let options = CustomGeometrySourceOptions(
            fetchTileFunction: { tileID in
                do {
                    let waypoints = WaypointDataSource.shared.getWaypointsForTile(tileID: tileID)
                    try mapView.mapboxMap.style.setCustomGeometrySourceTileData(
                        forSourceId: sourceId,
                        tileId: tileID,
                        features: waypoints
                    )
                } catch {
                    print("Error setting custom geometry source tile data: \(error)")
                }
            },
            cancelTileFunction: { _ in },
            tileOptions: TileOptions()
        )

        do {
            if !mapView.mapboxMap.style.sourceExists(withId: sourceId) {
                try mapView.mapboxMap.style.addCustomGeometrySource(withId: sourceId, options: options)
                
                var symbolLayer = SymbolLayer(id: layerId)
                symbolLayer.source = sourceId
                symbolLayer.iconImage = .expression(Exp(.get) { "icon" })
                //jmTODO: icon overlap not working, do we need clustering logic
                symbolLayer.iconAllowOverlap = .constant(false)
                symbolLayer.iconSize = .constant(1.0)
                symbolLayer.iconAnchor = .constant(.center)
                symbolLayer.iconOffset = .constant([0, 0])
                symbolLayer.textField = .constant("{id}")
                symbolLayer.textSize = .constant(12.0)
                symbolLayer.textColor = .constant(.init(.black))
                symbolLayer.textOffset = .constant([0, 2])
                
                try mapView.mapboxMap.style.addLayer(symbolLayer)
            }

        } catch {
            print("Error adding waypoints or symbol layer: \(error)")
        }
    }
    
    private func randomMarkerImage() -> String {
        return MarkerDecoration.allCases.randomElement()?.rawValue ?? defaultImageName
    }
    
    private func loadImageAssets(mapView: MapboxMaps.MapView) {
        let startTime = Date()
        
        MarkerDecoration.allCases.forEach { loadImage($0.rawValue, mapView: mapView) }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("Loaded all image assets in \(elapsedTime) seconds.")
    }

    
    private func loadImage(_ name: String, mapView: MapboxMaps.MapView) {
        if let waypointImage = UIImage(named: name) {
            do {
                if !mapView.mapboxMap.style.imageExists(withId: name) {
                    try mapView.mapboxMap.style.addImage(waypointImage, id: name)
                }
            } catch {
                print("Failed to add image to style: \(error)")
            }
        } else {
            print("Image \(name) not found.")
        }
    }
}

class WaypointDataSource {
    static let shared = WaypointDataSource()
    
    func getWaypointsForTile(tileID: CanonicalTileID) -> [Feature] {
        let startTime = Date()
        let waypoints = WaypointManager.shared.waypoints
        let features: [Feature] = waypoints.compactMap { waypoint in
            var tileBounds = Math.boundsFromTile(tileID)
            
            // Instead of buffer bounds, TF sets TileOptions in CustomGeometrySource Options as below
            //        let tileOptions = TileOptions(tolerance: 0.375, tileSize: 256, buffer: 1, clip: true, wrap: false)
            tileBounds = Math.bufferBounds(bounds: tileBounds, buffer: 1 / 256)
            if tileBounds.contains(latitude: waypoint.latitude, longitude: waypoint.longitude) {
                return Waypoint.waypointToFeature(waypoint: waypoint)
            } else {
                return nil
            }
        }
        print("Got \(features.count) waypoints for tile z/x/y \(tileID.z)/\(tileID.x)/\(tileID.y) in \(fabs(startTime.timeIntervalSinceNow)) seconds")
        return features
   
    }
}




