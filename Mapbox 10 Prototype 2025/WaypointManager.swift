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
    
    static func waypointToFeature(waypoint: Waypoint) -> Feature {
        // Convert Waypoint latitude and longitude to CLLocationCoordinate2D
        let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
        
        // Initialize and return the Feature object using the coordinate
        let point = Point(coordinate)
        var feature = Feature(geometry: .point(point))
        feature.properties = ["id": .string(String(waypoint.id))]
        return feature
    }
}

class WaypointManager {
    static let shared = WaypointManager()

    var waypoints: [Waypoint] = []

    private init() {
        waypoints = fetchWaypoints() // Simulate fetching from CoreData
    }
    
    private func fetchWaypoints() -> [Waypoint] {
        var generatedWaypoints: [Waypoint] = []
        
        // Define starting point, spacing, and grid dimensions
        let startLatitude = 47.42
        let startLongitude = -121.425
        let spacing = 0.1       // Distance between waypoints
        let gridDimension = 10  // Number of waypoints per row and column

        for row in 0..<gridDimension {
            for col in 0..<gridDimension {
                let latitude = startLatitude + (Double(row) * spacing)
                let longitude = startLongitude + (Double(col) * spacing)
                
                let waypoint = Waypoint(id: row * gridDimension + col, latitude: latitude, longitude: longitude)
                generatedWaypoints.append(waypoint)
            }
        }

        print("Generated waypoint count: \(generatedWaypoints.count)")
        return generatedWaypoints
    }

//
//    private func fetchWaypoints() -> [Waypoint] {
//        var generatedWaypoints: [Waypoint] = []
//        
//        var startLatitude = 47.42
//        var startLongitude = -121.425
//        
//        let spacing = 0.1
//        
//        for i in 0..<100 {
//            let latitude = startLatitude + Double.random(in: -spacing...spacing)
//            let longitude = startLongitude + Double.random(in: -spacing...spacing)
////            let latitude = startLatitude + spacing
////            let longitude = startLongitude + spacing
//            
//            let waypoint = Waypoint(id: i, latitude: latitude, longitude: longitude)
//            generatedWaypoints.append(waypoint)
//        }
//        print("Generated waypoint count: \(generatedWaypoints.count)")
//        return generatedWaypoints
//        
//    }
    
    
    func updateWaypoints(mapView: MapboxMaps.MapView) {
        let visibleRegion = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
        let boundingBox = BoundingBox(minLatitude: visibleRegion.southwest.latitude,
                                      maxLatitude: visibleRegion.northeast.latitude,
                                      minLongitude: visibleRegion.southwest.longitude,
                                      maxLongitude: visibleRegion.northeast.longitude)

        let visibleWaypoints = WaypointDataSource.shared.getWaypointsForViewport(visibleRegion: boundingBox)
        
//        let centerCoordinate = mapView.cameraState.center
//        let zoomLevel = Int(mapView.cameraState.zoom.rounded())
//
//        let currentTileID = Math.getTileID(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude, zoom: zoomLevel)
//
//        let visibleWaypoints = WaypointDataSource.shared.getWaypointsForTile(tileID: currentTileID)
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
        //may not be necessary or may need adjusting, Android has only min and max zoom, took these from TF
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
}

struct TileID {
    let x: Int
    let y: Int
    let zoom: Int
}

class WaypointDataSource {
    static let shared = WaypointDataSource()
    
    func getWaypointsForTile(tileID: TileID) -> [Feature] {
        let waypoints = WaypointManager.shared.waypoints
        return waypoints.compactMap { waypoint in
            // Calculate the tileID for the waypoint
            let waypointTileID = Math.getTileID(latitude: waypoint.latitude, longitude: waypoint.longitude, zoom: tileID.zoom)
            
            // Check if the waypoint is within the correct tile bounds
            if waypointTileID.x == tileID.x && waypointTileID.y == tileID.y {
                // Create and return a Feature object if the waypoint matches the tile
                let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
                let point = Point(coordinate)
                var feature = Feature(geometry: .point(point))
                let idAsString = String(waypoint.id)
                feature.properties = ["id": .string(idAsString)]
                return feature
            } else {
                // Return nil if the waypoint does not belong to the given tile
                return nil
            }
        }
    }
    
    func getWaypointsForViewport(visibleRegion: BoundingBox) -> [Feature] {
        return WaypointManager.shared.waypoints.filter { waypoint in
            visibleRegion.contains(latitude: waypoint.latitude, longitude: waypoint.longitude)
        }
        .map {
            Waypoint.waypointToFeature(waypoint: $0)
        }
    }
}

class Math {
    static func getTileID(latitude: Double, longitude: Double, zoom: Int) -> TileID {
        let n = pow(2.0, Double(zoom))
        let x = Int((longitude + 180.0) / 360.0 * n)
        let y = Int((1.0 - log(tan(latitude * .pi / 180.0) + 1.0 / cos(latitude * .pi / 180.0)) / .pi) / 2.0 * n)
        return TileID(x: x, y: y, zoom: zoom)
    }
}

struct BoundingBox {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    func contains(latitude: Double, longitude: Double) -> Bool {
        return latitude >= minLatitude &&
               latitude <= maxLatitude &&
               longitude >= minLongitude &&
               longitude <= maxLongitude
    }
}

