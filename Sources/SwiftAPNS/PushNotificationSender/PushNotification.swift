import Foundation

struct PushNotification {
    
    // MARK: - Types
    
    enum Priority: Int {
        case immediate = 10
        case conservePower = 5
    }
    
    enum Kind: String, CaseIterable {
        case alert
        case background
        case voip
        case complication
        case fileprovider
        case mdm
    }
    
    // MARK: - Public Vars
    
    var id: UUID?
    var kind: Kind
    
    var topic: String
    var priority: Priority
    
    var expirationDate: Date?
    var collapseIdentifier: String?
    
    var payload: Data?
    
    // MARK: - Object Lifecycle
    
    init(
        id: UUID? = UUID(),
        kind: Kind = .alert,
        topic: String,
        priority: Priority = .immediate,
        expirationDate: Date? = nil,
        collapseIdentifier: String? = nil,
        payload: Data?
    ) {
        self.id = id
        self.kind = kind
        self.topic = topic
        self.priority = priority
        self.expirationDate = expirationDate
        self.collapseIdentifier = collapseIdentifier
        self.payload = payload
    }
}
