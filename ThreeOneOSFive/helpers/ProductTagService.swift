import Foundation
import SwiftUI

/// Service to fetch and cache product tags from server
@MainActor
class ProductTagService: ObservableObject {
    static let shared = ProductTagService()
    
    @Published var tags: [ProductTag] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    private let baseURL: String
    private let cacheKey = "cached_product_tags"
    private let cacheTimestampKey = "cached_product_tags_timestamp"
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        // Use same base URL as KeyAPIService
        if let adminURL = UserDefaults.standard.string(forKey: "admin_panel_url"), !adminURL.isEmpty {
            self.baseURL = adminURL
        } else {
            self.baseURL = "https://ragex.deno.dev"
        }
        
        loadCachedTags()
    }
    
    /// Fetch product tags from server
    func fetchTags() async {
        // Check if cache is still valid
        if let lastUpdate = lastUpdated,
           Date().timeIntervalSince(lastUpdate) < cacheValidityInterval,
           !tags.isEmpty {
            print("[ProductTags] Using cached tags (age: \(Int(Date().timeIntervalSince(lastUpdate)))s)")
            return
        }
        
        isLoading = true
        
        do {
            guard let url = URL(string: "\(baseURL)/api/products/tags") else {
                print("[ProductTags] ❌ Invalid URL")
                isLoading = false
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProductTags] ❌ Invalid response")
                isLoading = false
                return
            }
            
            print("[ProductTags] Response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("[ProductTags] ❌ HTTP error: \(httpResponse.statusCode)")
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            struct TagsResponse: Codable {
                let success: Bool
                let tags: [ProductTag]
            }
            
            let response = try decoder.decode(TagsResponse.self, from: data)
            
            if response.success {
                self.tags = response.tags
                self.lastUpdated = Date()
                cacheTags()
                print("[ProductTags] ✅ Loaded \(response.tags.count) product tags")
            } else {
                print("[ProductTags] ❌ API returned success=false")
            }
            
        } catch {
            print("[ProductTags] ❌ Error fetching tags: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get tag for a specific product ID
    func getTag(for productId: String) -> ProductTag? {
        return tags.first { $0.productId == productId }
    }
    
    /// Get tag status for a product (returns .safe if not found)
    func getTagStatus(for productId: String) -> ProductTagStatus {
        return getTag(for: productId)?.tag ?? .safe
    }
    
    /// Check if a product is safe to use
    func isSafe(_ productId: String) -> Bool {
        return getTagStatus(for: productId) == .safe
    }
    
    /// Check if a product is in test mode
    func isTest(_ productId: String) -> Bool {
        return getTagStatus(for: productId) == .test
    }
    
    /// Check if a product is banned
    func isBanned(_ productId: String) -> Bool {
        return getTagStatus(for: productId) == .banned
    }
    
    /// Force refresh tags from server
    func refresh() async {
        lastUpdated = nil // Invalidate cache
        await fetchTags()
    }
    
    // MARK: - Cache Management
    
    private func cacheTags() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tags)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            print("[ProductTags] 💾 Tags cached")
        } catch {
            print("[ProductTags] ❌ Failed to cache tags: \(error)")
        }
    }
    
    private func loadCachedTags() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date else {
            print("[ProductTags] No cached tags found")
            return
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(timestamp)
        if age > cacheValidityInterval {
            print("[ProductTags] Cache expired (age: \(Int(age))s)")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let cachedTags = try decoder.decode([ProductTag].self, from: data)
            self.tags = cachedTags
            self.lastUpdated = timestamp
            print("[ProductTags] ✅ Loaded \(cachedTags.count) cached tags (age: \(Int(age))s)")
        } catch {
            print("[ProductTags] ❌ Failed to load cached tags: \(error)")
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        tags = []
        lastUpdated = nil
        print("[ProductTags] Cache cleared")
    }
}
