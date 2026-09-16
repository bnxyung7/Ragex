import Foundation
import Combine
import SwiftUI

public struct LiveAnnouncement: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let message: String
    public let tag: String
    public let tagColor: String
    public let timestamp: String
    public let linkURL: String?
    public let linkTitle: String?
    public let isImportant: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        tag: String = "ACTUALIZACIÓN",
        tagColor: String = "purple",
        timestamp: String = "Hoy",
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isImportant: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.tag = tag
        self.tagColor = tagColor
        self.timestamp = timestamp
        self.linkURL = linkURL
        self.linkTitle = linkTitle
        self.isImportant = isImportant
    }
}

public class AnnouncementService: ObservableObject {
    public static let shared = AnnouncementService()
    
    @Published public var announcements: [LiveAnnouncement] = []
    @Published public var latestAnnouncement: LiveAnnouncement?
    @Published public var isFetching: Bool = false
    @Published public var lastRefreshed: Date? = nil
    @Published public var readAnnouncementIDs: Set<String> = []
    
    private let apiURL = "https://xkeyapi.onrender.com/api/announcements"
    private var timer: AnyCancellable?
    private let readStorageKey = "com.x.readAnnouncements"
    
    private init() {
        loadReadIDs()
        loadDefaultAnnouncements()
        startPeriodicSync()
        Task {
            await fetchAnnouncements()
        }
    }
    
    public var hasUnreadAnnouncements: Bool {
        guard let latest = latestAnnouncement else { return false }
        return !readAnnouncementIDs.contains(latest.id)
    }
    
    public func startPeriodicSync() {
        timer?.cancel()
        timer = Timer.publish(every: 45, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchAnnouncements()
                }
            }
    }
    
    @MainActor
    public func fetchAnnouncements() async {
        isFetching = true
        defer { isFetching = false }
        
        do {
            guard let url = URL(string: apiURL) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                struct APIAnnouncementsResponse: Codable {
                    let success: Bool?
                    let announcements: [LiveAnnouncement]?
                    let data: [LiveAnnouncement]?
                }
                
                let decoded = try JSONDecoder().decode(APIAnnouncementsResponse.self, from: data)
                let items = decoded.announcements ?? decoded.data ?? []
                if !items.isEmpty {
                    self.announcements = items
                    self.latestAnnouncement = items.first
                    self.lastRefreshed = Date()
                    return
                }
            }
        } catch {
            // Fallback gracefully
        }
        
        loadDefaultAnnouncements()
        self.lastRefreshed = Date()
    }
    
    public func markAsRead(id: String) {
        readAnnouncementIDs.insert(id)
        saveReadIDs()
    }
    
    public func markAllAsRead() {
        for a in announcements {
            readAnnouncementIDs.insert(a.id)
        }
        saveReadIDs()
    }
    
    private func loadDefaultAnnouncements() {
        let defaults: [LiveAnnouncement] = [
            LiveAnnouncement(
                id: "ann-ff-dual-v2",
                title: "🔥 Soporte Free Fire & Free Fire MAX",
                message: "Integración dual completada. Ahora puedes inyectar y gestionar parches tanto para Free Fire (Normal) como para Free Fire MAX de manera independiente con tasa de refresco ultra rápida.",
                tag: "NUEVO",
                tagColor: "purple",
                timestamp: "En Tiempo Real",
                linkURL: "https://wa.me/18099289722",
                linkTitle: "Canal Oficial",
                isImportant: true
            ),
            LiveAnnouncement(
                id: "ann-bypass-security",
                title: "🛡️ Bypass & Protección Anti-Ban Activa",
                message: "Los algoritmos de seguridad de Project X están actualizados para las últimas versiones del juego. Conserva tu clave activa para garantizar la protección en tiempo real.",
                tag: "SEGURIDAD",
                tagColor: "emerald",
                timestamp: "Servidor Online",
                linkURL: nil,
                linkTitle: nil,
                isImportant: true
            ),
            LiveAnnouncement(
                id: "ann-whatsapp-support",
                title: "💎 Renovaciones y Soporte Directo 24/7",
                message: "¿Necesitas soporte técnico, nuevas keys o renovaciones de tu membresía? Nuestro equipo oficial está disponible a través de WhatsApp.",
                tag: "OFICIAL",
                tagColor: "amber",
                timestamp: "24/7 Activo",
                linkURL: "https://wa.me/18099289722?text=Hola,%20deseo%20información%20sobre%20Project%20X%20iOS",
                linkTitle: "Contactar por WhatsApp",
                isImportant: false
            ),
            LiveAnnouncement(
                id: "ann-design-obsidian",
                title: "⚡ Diseño Obsidian Black & Cyber Violet",
                message: "La interfaz fue refinada con acabado Obsidian Glass, sin consumo excesivo de batería y navegación fluida entre pestañas.",
                tag: "MEJORA",
                tagColor: "blue",
                timestamp: "Optimizado",
                linkURL: nil,
                linkTitle: nil,
                isImportant: false
            )
        ]
        
        self.announcements = defaults
        self.latestAnnouncement = defaults.first
    }
    
    private func loadReadIDs() {
        if let stored = UserDefaults.standard.array(forKey: readStorageKey) as? [String] {
            readAnnouncementIDs = Set(stored)
        }
    }
    
    private func saveReadIDs() {
        UserDefaults.standard.set(Array(readAnnouncementIDs), forKey: readStorageKey)
    }
}
