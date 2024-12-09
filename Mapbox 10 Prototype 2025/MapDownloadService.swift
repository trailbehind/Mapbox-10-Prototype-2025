//
//  MapDownloadService.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/19/22.
//

import Foundation
import CoreLocation

import Geodesy

class MapDownloadService {
  static let shared = MapDownloadService()!

  let storageDirectory: URL

  private init?() {
    guard let cacheDirectory = try? FileManager.default.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    ) else { return nil }

    self.storageDirectory = cacheDirectory.appendingPathComponent("maps", isDirectory: true)

    do {
      try FileManager.default.createDirectory(at: self.storageDirectory, withIntermediateDirectories: true)
    } catch {
      return nil
    }
  }

  func downloadTask(source: MapSource, bounds: Bounds, zooms: ClosedRange<Int>) -> MapDownloadTask? {
    let templateURL = source.tileURL!
    let destinationPath = self.storageDirectory
      .appendingPathComponent(source.id)
      .appendingPathExtension("mbtiles")
      .path

    let mbtiles: MBTiles

    do {
      mbtiles = try MBTiles.open(path: destinationPath)
    } catch let error as NSError {
      // FIXME errors are not handled
      mbtiles = try! MBTiles.create(path: destinationPath, name: source.id, format: .pbf)
    } catch {
      print(error)
      return nil
    }

    return MapDownloadTask(url: templateURL, scheme: source.scheme, destination: mbtiles, bounds: bounds, zooms: zooms)
  }
}

class MapDownloadTask: NSObject, ProgressReporting {
  let templateURL: TileURLTemplate
  var progress: Progress

  private var queue: OperationQueue
  private var mbtiles: MBTiles

  init(url: TileURLTemplate, scheme: TileServiceScheme, destination: MBTiles, bounds: Bounds, zooms: ClosedRange<Int>) {
    self.queue = OperationQueue()
    self.queue.maxConcurrentOperationCount = 10

    self.templateURL = url
    self.mbtiles = destination

    let tiletree = TileTree(scheme: scheme, bounds: .mercatorSquare, zooms: 0...20)
    let tiles: [TileID] = tiletree.tileIDs(in: bounds, zooms: zooms)!

    progress = Progress(totalUnitCount: Int64(tiles.count))

    // FIXME hardcoded "about 10 seconds remaining"
    progress.setUserInfoObject(10.0, forKey: .estimatedTimeRemainingKey)

    super.init()

    for tile in tiles {
      let url = self.templateURL.toURL(tile: tile)
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      print(url)

      let operation = DownloadOperation(session: URLSession.shared, request: request) { (data, response, error) in
        print("finished downloading \(url.absoluteString) - \(data!.count / 1024) kB")
        self.mbtiles[z: tile.z, x: tile.x, y: tile.y] = data!
      }

      progress.addChild(operation.progress, withPendingUnitCount: 1)
      queue.addOperation(operation)
    }
  }
}

class DownloadOperation: Operation {
  private var task: URLSessionDataTask!
  var progress: Progress { task!.progress }

  enum OperationState {
    case ready
    case executing
    case finished
  }

  private var state : OperationState = .ready {
    willSet {
      self.willChangeValue(forKey: "isExecuting")
      self.willChangeValue(forKey: "isFinished")
    }

    didSet {
      self.didChangeValue(forKey: "isExecuting")
      self.didChangeValue(forKey: "isFinished")
    }
  }

  override var isReady: Bool { return state == .ready }
  override var isExecuting: Bool { return state == .executing }
  override var isFinished: Bool { return state == .finished }

  init(session: URLSession, request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
    super.init()

    task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
      if let completionHandler = completionHandler {
        completionHandler(data, response, error)
      }

      self?.state = .finished
    })
  }

  override func start() {
    if self.isCancelled {
      // operation was cancelled before it started
      state = .finished
      return
    }

    print("downloading \(self.task.originalRequest?.url?.absoluteString ?? "")")

    state = .executing
    self.task.resume()
  }

  override func cancel() {
    super.cancel()
    self.task.cancel()
  }
}
