//
//  UnsplashService.swift
//  WanderBite
//
//  Created by Afina R. Vinci on 11/9/25.
//

import Foundation

final class UnsplashService {
    static let shared = UnsplashService()
    
    enum UnsplashServiceError: Error, LocalizedError {
        case invalidURL
        case requestFailed(statusCode: Int)
        case missingAccessKey
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Failed to construct a valid URL."
            case .requestFailed(let statusCode):
                return "Request failed with status code \(statusCode)."
            case .missingAccessKey:
                return "Unsplash Access Key is missing. Please add your Access Key."
            }
        }
    }
    
    /// TODO: Insert your Unsplash Access Key here.
    /// For production, consider storing this securely (e.g., Info.plist, Secrets file, or environment variable).
    private let accessKey = UnsplashKey.accessKey
    
    private init() {}
    
    /// Searches Unsplash for the first photo matching the query.
    /// - Parameter query: The search query string.
    /// - Returns: A URL to the photo image (preferring `small` over `regular` size), or nil if no results.
    func searchFirstPhoto(query: String) async throws -> URL? {
        guard !accessKey.isEmpty && accessKey != "<INSERT_YOUR_UNSPLASH_ACCESS_KEY_HERE>" else {
            throw UnsplashServiceError.missingAccessKey
        }
        
        var components = URLComponents(string: "https://api.unsplash.com/search/photos")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "page", value: "1")
        ]
        
        guard let url = components?.url else {
            throw UnsplashServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw UnsplashServiceError.requestFailed(statusCode: statusCode)
        }
        
        let decoded = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
        
        guard let photo = decoded.results.first else {
            return nil
        }
        
        if let smallURL = URL(string: photo.urls.small) {
            return smallURL
        } else if let regularURL = URL(string: photo.urls.regular) {
            return regularURL
        } else {
            return nil
        }
    }
}

extension UnsplashService {
    func searchFirstPhotos(for queries: [String]) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL?.self) { group in
            for q in queries {
                group.addTask {
                    try await self.searchFirstPhoto(query: q)
                }
            }
            
            var urls: [URL] = []
            for try await result in group {
                if let url = result {
                    urls.append(url)
                }
            }
            return urls
        }
    }
}
