//
//  MapView+HttpService.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/11/22.
//

import Foundation
import MapboxMaps

extension MapView {
  /// This HTTP Service implementation is intended to replace the default HTTP service that Mapbox uses.
  ///
  /// It provides additional functionality, such as rewriting the `g://` URLs we use in our MapSources to normal `http://` URLs.
  /// In the future, logic for retrieving tiles that have been downloaded for offline use will also go here.
  class HttpService: HttpServiceInterface {
    func setInterceptorForInterceptor(_ interceptor: HttpServiceInterceptorInterface?) {
      // TODO
    }

    func setMaxRequestsPerHostForMax(_ max: UInt8) {
      // TODO
    }

    func cancelRequest(forId id: UInt64, callback: @escaping ResultCallback) {
      // TODO
    }

    func supportsKeepCompression() -> Bool {
      // TODO
      return false
    }

    func download(for options: DownloadOptions, callback: @escaping DownloadStatusCallback) -> UInt64 {
      // TODO

      // This method is intended to implement local file downloading (by requesting the resource
      // described by `options.request` and saving it to a file at `options.localPath`.

      // I've left it unimplemented for now because it appears that Mapbox never actually calls it.
      return 0
    }

    func request(for request: HttpRequest, callback: @escaping HttpResponseCallback) -> UInt64 {
      // Mapbox calls this method to retrieve resources (including StyleJSONs, TileJSONs,
      // spritesheets, fonts, and tiles) from remote HTTP servers.

      // By supplying our own implementation of this, we can implement our own custom
      // behaviors, including:
      //   - rewriting the `g://` URLs found in our map stylesheets with real URLs (using
      //     the information in mapSourcesV2.json)
      //   - checking if tiles have been downloaded already for offline use before getting
      //     them from the server.

      var url = URL(string: request.url)!

      // if URL starts with g://, rewrite it as an https:// URL
      if url.scheme == "g" {
        // FIXME lots of unsafe force-unwrapping here
        let key = String(url.host!)
        let mapSource = MapSourcesService.shared.sources[key]!
        let tileURLTemplate = mapSource.tileURL!
        let components = url.pathComponents.suffix(3).map { Int($0)! }
        let tileID = TileID(z: components[0], x: components[1], y: components[2])

        // check if tile is avaiable in offline downloads
        // TODO this should be abstracted into an OfflineTileStore or something
        let mbtilesPath = MapDownloadService.shared.storageDirectory
          .appendingPathComponent(key)
          .appendingPathExtension("mbtiles")
          .path

        if let mbtiles = try? MBTiles.open(path: mbtilesPath) {
          if let tile = mbtiles[z: tileID.z, x: tileID.x, y: tileID.y] {
            // the tile exists in the offline cache; construct a fake HTTP response
            // in order to hand the tile data back to Mapbox
            let headers = [
              "content-type": "application/x-protobuf",
              "content-encoding": "gzip",
            ]
            let data = HttpResponseData(headers: headers, code: 200, data: tile)
            let response = HttpResponse(request: request, result: .success(data))
            callback(response)
            return 0 // FIXME what should we return here? task isn't cancellable since it's already done.
          }
        }

        // not in offline storage; prepare to request from tile servers
        url = tileURLTemplate.toURL(tile: tileID)
      }

      var urlRequest = URLRequest(url: url)
      let methodMap: [HttpMethod: String] = [
        .get: "GET",
        .head: "HEAD",
        .post: "POST"
      ]

      urlRequest.httpMethod          = methodMap[request.method]!
      urlRequest.httpBody            = request.body
      urlRequest.allHTTPHeaderFields = request.headers

      let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        let result: Result<HttpResponseData, HttpRequestError>

        if let error = error {
          // Map NSURLError to HttpRequestError
          let requestError = HttpRequestError(type: .otherError, message: error.localizedDescription)
          result = .failure(requestError)
        } else if let response = response as? HTTPURLResponse, let data = data {
          // store HTTP response headers in a dictionary
          var headers: [String: String] = [:]
          for (key, value) in response.allHeaderFields {
            guard let key = key as? String, let value = value as? String else { continue }

            // Mapbox expects header names to be lowercase
            headers[key.lowercased()] = value
          }

          // Create an HttpResponseData containing the headers dictionary, status code, and body
          let responseData = HttpResponseData(headers: headers, code: Int64(response.statusCode), data: data)
          result = .success(responseData)
        } else {
          let requestError = HttpRequestError(type: .otherError, message: "Invalid response")
          result = .failure(requestError)
        }

        let response = HttpResponse(request: request, result: result)
        callback(response)
      }

      task.resume()

      // Handle used to cancel requests
      return UInt64(task.taskIdentifier)
    }
  }
}
