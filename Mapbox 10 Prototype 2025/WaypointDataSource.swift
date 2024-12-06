//
//  WaypointDataSource.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 12/6/24.
//

import MapboxMaps
import Foundation


class WaypointDataSource {
    static let shared = WaypointDataSource()
    
    func getWaypointsForTile(tileID: CanonicalTileID, mapView: MapboxMaps.MapView) -> [Feature] {
        let startTime = Date()
        let waypoints = WaypointManager.shared.waypoints
        var imageNamesToLoad = Set<String>()  // Track required images
        
        let features: [Feature] = waypoints.compactMap { waypoint in
            var tileBounds = Math.boundsFromTile(tileID)
            
            // In the current project, WaypointDataSource adds a buffer to the tile bounds like this:
            // tileBounds = Math.bufferBounds(bounds: tileBounds, buffer: 1 / 256)
            // but I think we can use TileOptions instead (see addWaypointsLayer method)
            if tileBounds.contains(latitude: waypoint.latitude, longitude: waypoint.longitude) {
                imageNamesToLoad.insert(waypoint.image)
                return Waypoint.waypointToFeature(waypoint: waypoint)
            } else {
                return nil
            }
        }
        
        loadImagesForCurrentTile(imageNames: imageNamesToLoad, mapView: mapView)
        print("Got \(features.count) waypoints for tile z/x/y \(tileID.z)/\(tileID.x)/\(tileID.y) in \(fabs(startTime.timeIntervalSinceNow)) seconds")
        return features
   
    }
    
    func loadImagesForCurrentTile(imageNames: Set<String>, mapView: MapboxMaps.MapView) {
        let startTime = Date()
        
        imageNames.forEach { loadImage($0, mapView: mapView) }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("Loaded \(imageNames.count) images for current tile in \(elapsedTime) seconds.")
    }
    
    private func loadImage(_ name: String, mapView: MapboxMaps.MapView) {
        if let waypointImage = UIImage(named: name) {
            do {
                if !mapView.mapboxMap.style.imageExists(withId: name) {
                    try mapView.mapboxMap.style.addImage(waypointImage, id: name) //MB10: In v11 this would be mapView.mapboxMap.addImage
                }
            } catch {
                print("Failed to add image to style: \(error)")
            }
        } else {
            print("Image \(name) not found.")
        }
    }
}
