import Foundation

struct PushNotification {
    
    // MARK: - Types
    
    enum Priority: Int {
        case immediate = 10
        case conservePower = 5
    }
    
    enum `Type`: String {
        case alert
        case background
        case voip
        case complication
        case fileprovider
        case mdm
    }
    
    // MARK: - Public Vars
    
    var id: UUID?
    var type: Type
    
    var topic: String
    var priority: Priority
    
    var expirationDate: Date?
    var collapseIdentifier: String?
    
    var payload: Data
    
    // MARK: - Object Lifecycle
    
    init(
        id: UUID? = UUID(),
        type: Type = .alert,
        topic: String,
        priority: Priority = .immediate,
        expirationDate: Date? = nil,
        collapseIdentifier: String? = nil,
        payload: Data
    ) {
        self.id = id
        self.type = type
        self.topic = topic
        self.priority = priority
        self.expirationDate = expirationDate
        self.collapseIdentifier = collapseIdentifier
        self.payload = payload
    }
    
    init<T: Encodable>(
        id: UUID? = UUID(),
        type: Type = .alert,
        topic: String,
        priority: Priority = .immediate,
        expirationDate: Date? = nil,
        collapseIdentifier: String? = nil,
        payload: T
    ) throws {
        let payloadData = try JSONEncoder().encode(payload)
        
        self.init(
            id: id,
            type: type,
            topic: topic,
            priority: priority,
            expirationDate: expirationDate,
            collapseIdentifier: collapseIdentifier,
            payload: payloadData
        )
    }
}
