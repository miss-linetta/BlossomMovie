//
//  YoutubeSearchResponse.swift
//  BlossomMovie
//
//  Created by admin on 03.02.2026.
//

import Foundation

struct YoutubeSearchResponse: Codable {
    let items: [ItemProperties]?
}

struct ItemProperties: Codable {
    let id: IdProperties?
}

struct IdProperties: Codable {
    let videoId: String?
}
