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
    
    var grid = false

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
        let totalPoints = 1000
        if grid {
            for row in 0..<gridDimension {
                for col in 0..<gridDimension {
                    let latitude = startLatitude + (Double(row) * spacing)
                    let longitude = startLongitude + (Double(col) * spacing)
                    
                    let waypoint = Waypoint(id: row * gridDimension + col, latitude: latitude, longitude: longitude)
                    generatedWaypoints.append(waypoint)
                }
            }
        } else {
            for i in 0..<totalPoints {
                let latitude = startLatitude + Double.random(in: -spacing...spacing)
                let longitude = startLongitude + Double.random(in: -spacing...spacing)
                let waypoint = Waypoint(id: i, latitude: latitude, longitude: longitude)
                generatedWaypoints.append(waypoint)
            }
        }
        

        print("Generated waypoint count: \(generatedWaypoints.count)")
        return generatedWaypoints
    }


    func updateWaypoints(mapView: MapboxMaps.MapView) {
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

        let options = CustomGeometrySourceOptions(
            fetchTileFunction: { tileID in
                do {
                    let visibleWaypoints = WaypointDataSource.shared.getWaypointsForTile(tileID: tileID)
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
            //jmTODO: icon overlap not working, do we need clustering logic
            symbolLayer.iconAllowOverlap = .constant(false)
            symbolLayer.iconSize = .constant(1.0)
            symbolLayer.iconAnchor = .constant(.center)
            symbolLayer.iconOffset = .constant([0, 0])

            // Use the "id" property in the textField
            symbolLayer.textField = .constant("{id}")
            symbolLayer.textSize = .constant(12.0)
            symbolLayer.textColor = .constant(.init(.black))
            symbolLayer.textOffset = .constant([0, 2])

            try mapView.mapboxMap.style.addLayer(symbolLayer)

        } catch {
            print("Error adding waypoints or symbol layer: \(error)")
        }
    }
}

class WaypointDataSource {
    static let shared = WaypointDataSource()
    
    func getWaypointsForTile(tileID: CanonicalTileID) -> [Feature] {
        let waypoints = WaypointManager.shared.waypoints
        return waypoints.compactMap { waypoint in
            var tileBounds = Math.boundsFromTile(tileID)
            
            // Instead of buffer bounds, TF sets TileOptions in CustomGeometrySource Options as below
            //        let tileOptions = TileOptions(tolerance: 0.375, tileSize: 256, buffer: 1, clip: true, wrap: false)
            tileBounds = Math.bufferBounds(bounds: tileBounds, buffer: 1 / 256)
            if tileBounds.contains(latitude: waypoint.latitude, longitude: waypoint.longitude) {
                let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
                let point = Point(coordinate)
                var feature = Feature(geometry: .point(point))
                let idAsString = String(waypoint.id)
                feature.properties = ["id": .string(idAsString)]
                return feature
            } else {
                return nil
            }
        }
    }
}

class Math {
    static func boundsFromTile(_ tile: CanonicalTileID) -> BoundingBox {
        let tilesAtThisZoom = 1 << tile.z
        let width = 360.0 / Double(tilesAtThisZoom)
        
        let southwestLongitude = -180 + (Double(tile.x) * width)
        let northeastLongitude = southwestLongitude + width
        
        let latHeightMerc = 1.0 / Double(tilesAtThisZoom)
        let topLatMerc = Double(tile.y) * latHeightMerc
        let bottomLatMerc = topLatMerc + latHeightMerc
        
        let southwestLatitude = (180 / .pi) * (2 * atan(exp(.pi * (1 - (2 * bottomLatMerc)))) - (.pi / 2))
        let northeastLatitude = (180 / .pi) * (2 * atan(exp(.pi * (1 - (2 * topLatMerc)))) - (.pi / 2))
        
        return BoundingBox(
            northeastLatitude: northeastLatitude,
            northeastLongitude: northeastLongitude,
            southwestLatitude: southwestLatitude,
            southwestLongitude: southwestLongitude
        )
    }
    
    static func bufferBounds(bounds: BoundingBox, buffer: CGFloat) -> BoundingBox {
        let xSpan = abs(bounds.northeastLongitude - bounds.southwestLongitude)
        let ySpan = abs(bounds.northeastLatitude - bounds.southwestLatitude)
        
        let bufferedNortheastLongitude = min(bounds.northeastLongitude + xSpan * Double(buffer), 180)
        let bufferedSouthwestLongitude = max(bounds.southwestLongitude - xSpan * Double(buffer), -180)
        let bufferedNortheastLatitude = min(bounds.northeastLatitude + ySpan * Double(buffer), 90)
        let bufferedSouthwestLatitude = max(bounds.southwestLatitude - ySpan * Double(buffer), -90)
        
        return BoundingBox(
            northeastLatitude: bufferedNortheastLatitude,
            northeastLongitude: bufferedNortheastLongitude,
            southwestLatitude: bufferedSouthwestLatitude,
            southwestLongitude: bufferedSouthwestLongitude
        )
    }


    
}

struct BoundingBox {
    let northeastLatitude: Double
    let northeastLongitude: Double
    let southwestLatitude: Double
    let southwestLongitude: Double

    func contains(latitude: Double, longitude: Double) -> Bool {
        return latitude >= southwestLatitude &&
               latitude <= northeastLatitude &&
               longitude >= southwestLongitude &&
               longitude <= northeastLongitude
    }
}

