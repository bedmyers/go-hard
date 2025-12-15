//
//  CloudinaryService.swift
//  Goldy
//
//  Created by Blair Myers on 12/11/25.
//

import Foundation
import SwiftUI
import PhotosUI

class CloudinaryService {
    static let shared = CloudinaryService()
    
    private let cloudName = "di9y5xpno"
    private let uploadPreset = "go_hard_unsigned"
    
    private var uploadURL: URL {
        URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
    }
    
    private init() {}
    
    // MARK: - Upload Single Image
    
    func uploadImage(_ imageData: Data) async throws -> String {
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Add folder
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("go-hard\r\n".data(using: .utf8)!)
        
        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Cloudinary error: \(errorBody)")
            throw CloudinaryError.uploadFailed(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(CloudinaryResponse.self, from: data)
        print("✅ Image uploaded: \(result.secureUrl)")
        return result.secureUrl
    }
    
    // MARK: - Upload Multiple Images
    
    func uploadImages(_ images: [Data]) async throws -> [String] {
        var urls: [String] = []
        
        for imageData in images {
            let url = try await uploadImage(imageData)
            urls.append(url)
        }
        
        return urls
    }
    
    // MARK: - Load from PhotosPickerItem
    
    func loadImageData(from item: PhotosPickerItem) async throws -> Data {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw CloudinaryError.loadFailed
        }
        
        // Compress if needed (max 1MB for fast uploads)
        if let uiImage = UIImage(data: data) {
            if let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                return compressed
            }
        }
        
        return data
    }
}

// MARK: - Response Model

struct CloudinaryResponse: Codable {
    let secureUrl: String
    let publicId: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case secureUrl = "secure_url"
        case publicId = "public_id"
        case width
        case height
    }
}

// MARK: - Errors

enum CloudinaryError: LocalizedError {
    case invalidResponse
    case uploadFailed(Int)
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from image server"
        case .uploadFailed(let code):
            return "Image upload failed (error \(code))"
        case .loadFailed:
            return "Failed to load image from photos"
        }
    }
}
