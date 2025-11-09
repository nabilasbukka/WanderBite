//
//  UnsplashPhoto.swift
//  WanderBite
//
//  Created by Afina R. Vinci on 11/9/25.
//

import Foundation

struct UnsplashPhoto: Decodable {
    struct URLs: Decodable {
        let small: String
        let regular: String
    }
    let urls: URLs
}

/// A model representing the search response from the Unsplash API.
struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

struct UnsplashKey {
    private init() {}
    static let accessKey: String = "k1C2z0QjBOyKVtyW8Axi9QGHBuEWlooTbpFSPHX6Zt0"
    static let secretKey: String = "5dJZarQRCG4HqgGJzsGpn6RV5op8d5C8FT7e4TxNW4Q"
}
