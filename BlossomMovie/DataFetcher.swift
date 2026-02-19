//
//  DataFetcher.swift
//  BlossomMovie
//
//  Created by admin on 29.01.2026.
//

import Foundation

let apiConfig = APIConfig.shared
let tmdbBaseURL = apiConfig?.tmdbBaseURL
let tmdbAPIKey = apiConfig?.tmdbAPIKey
let youtubeSearchURL = apiConfig?.youtubeSearchURL
let youtubeAPIKey = apiConfig?.youtubeAPIKey

struct DataFetcher {
    func fetchTitles(for media: String, by type: String, with title: String? = nil) async throws -> [Title] {
        let fetchTitlesURL = try buildURL(media: media, type: type, searchPhrase: title)
        
        guard let fetchTitlesURL = fetchTitlesURL else {
            throw NetworkError.urlBuildFailed
        }
        
        print(fetchTitlesURL)
        
        var titles = try await fetchAndDecode(url: fetchTitlesURL, type: TMDBAPIObject.self).results
        
        Constants.addPosterPath(to: &titles)
        
        return titles
    }
    
    func fetchVideoId(for title: String) async throws -> String {
        guard let baseSearchURL = youtubeSearchURL else {
            throw NetworkError.missingConfig
        }
        
        guard let searchAPIKey = youtubeAPIKey else {
            throw NetworkError.missingConfig
        }
        
        let trailerSearch = title + YoutubeURLStrings.space.rawValue + YoutubeURLStrings.trailer.rawValue
        
        guard var urlComponents = URLComponents(string: baseSearchURL) else {
            throw NetworkError.urlBuildFailed
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "part", value: "id"),
            URLQueryItem(name: YoutubeURLStrings.queryShorten.rawValue, value: trailerSearch),
            URLQueryItem(name: YoutubeURLStrings.key.rawValue, value: searchAPIKey),
            URLQueryItem(name: "type", value: "video")
        ]
        
        guard let fetchVideoURL = urlComponents.url else {
            throw NetworkError.urlBuildFailed
        }
        
        return try await fetchAndDecode(url: fetchVideoURL, type: YoutubeSearchResponse.self, convertFromSnakeCase: false).items?.first?.id?.videoId ?? ""
    }
    
    
    func fetchAndDecode<T: Decodable>(url: URL, type: T.Type, convertFromSnakeCase: Bool = true) async throws -> T {

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        guard let response = urlResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.badURLResponse(underlyingError: NSError(
                domain: "DataFetcher",
                code: (urlResponse as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP Response"]) )
        }

        let decoder = JSONDecoder()

        if convertFromSnakeCase {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
        }

        return try decoder.decode(type, from: data)
    }
    
    private func buildURL(media: String, type: String, searchPhrase: String? = nil) throws -> URL? {
        guard let baseURL = tmdbBaseURL else {
            throw NetworkError.missingConfig
        }
        
        guard let apiKey = tmdbAPIKey else {
            throw NetworkError.missingConfig
        }
        
        var path: String
        
        if type == "trending" {
            path = "3/\(type)/\(media)/day"
        } else if type == "top_rated" || type == "upcoming" {
            path = "3/\(media)/\(type)"
        } else if type == "search" {
            path = "3/\(type)/\(media)"
        } else {
            throw NetworkError.urlBuildFailed
        }
        
        var urlQueryItems = [
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        if let searchPhrase {
            urlQueryItems.append(URLQueryItem(name: "query", value: searchPhrase))
        }
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw NetworkError.urlBuildFailed
        }
        
        urlComponents.path += "/" + path
        urlComponents.queryItems = urlQueryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.urlBuildFailed
        }
        return url
    }
}
