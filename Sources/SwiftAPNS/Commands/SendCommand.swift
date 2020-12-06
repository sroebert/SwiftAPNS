import Foundation
import ConsoleKit

final class SendCommand: Command {
    
    // MARK: - Types
    
    private enum CommandError: Error, CustomStringConvertible {
        case invalidPriorty
        case invalidKind
        case invalidEnvironment
        case couldNotLoadPayloadFile
        case missingPayload
        case invalidToken
        case connectionError
        case responseError(Int?, String?)
        
        var description: String {
            switch self {
            case .invalidPriorty:
                return "Priority must be either 5 or 10."
            case .invalidKind:
                let types = PushNotification.Kind
                    .allCases
                    .map { $0.rawValue }
                    .joined(separator: ", ")
                return "Type must be one of the following values: \(types)."
            case .invalidEnvironment:
                return "Environment must be either development or production."
            case .couldNotLoadPayloadFile:
                return "Failed to read payload file."
            case .missingPayload:
                return "Either message, payload-path or payload has to be specified."
            case .invalidToken:
                return "The device token is invalid."
            case .connectionError, .responseError(nil, nil):
                return "Could not connect to the APNS server."
            case .responseError(let statusCode?, let message?):
                return "Failed to send push notification (\(statusCode)):\n\(message)"
            case .responseError(nil, let message?):
                return "Failed to send push notification:\n\(message)"
            case .responseError(let statusCode?, nil):
                return "Failed to send push notification (\(statusCode))."
            }
        }
    }
    
    // MARK: - Command
    
    struct Signature: CommandSignature {
        @Option(name: "message", help: "The message of the push notification.")
        var message: String?
        
        @Option(name: "payload-path", help: "The path to a JSON file to send as the payload.")
        var payloadPath: String?
        
        @Option(name: "payload", help: "A JSON object to send as the payload.")
        var payload: String?
        
        @Option(name: "environment", help: "The APNS environment to send the push notification to (development or production).")
        var environment: String?
        
        @Option(name: "topic", help: "The topic (bundle id) for the push notification.")
        var topic: String?
        
        @Option(name: "priority", help: "The priority for the push notification (5 or 10).")
        var priority: Int?
        
        @Option(name: "type", help: "The push notification type.")
        var kind: String?
        
        @Option(name: "collapse-identifier", help: "The collapse identifier for the push notification.")
        var collapseIdentifier: String?
        
        @Option(name: "expiration", help: "The push notification expiration time in seconds.")
        var expiration: Int?
        
        @Option(name: "device-token", help: "The device token to send the push notification to.")
        var deviceToken: String?
        
        @Option(name: "certificate-path", help: "The path to the p12 PN certificate.")
        var certificatePath: String?
        
        @Option(name: "certificate-passphrase", help: "The passphrase for the p12 PN certificate.")
        var certificatePassphrase: String?

        init() { }
    }

    var help: String {
        "Send a simply push notification"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let notification = try createNotification(from: signature)
        let sender = try createSender(from: signature)
        let deviceToken = try requireOption(signature.$deviceToken)
        let environment = try getEnvironment(from: signature)
        
        do {
            try sender.send(
                notification,
                to: deviceToken,
                environment: environment
            )
        } catch PushNotificationSender.SendError.invalidToken {
            throw CommandError.invalidToken
        } catch PushNotificationSender.SendError.urlError(_) {
            throw CommandError.connectionError
        } catch PushNotificationSender.SendError.responseError(let responseCode, let response) {
            throw CommandError.responseError(responseCode, response)
        }
    }
    
    // MARK: - Private
    
    private func getKind(from signature: Signature) throws -> PushNotification.Kind {
        guard let kindValue = signature.kind else {
            return .alert
        }
        
        guard let kind = PushNotification.Kind(rawValue: kindValue) else {
            throw CommandError.invalidKind
        }
        
        return kind
    }
    
    private func getPriority(from signature: Signature) throws -> PushNotification.Priority {
        guard let priorityValue = signature.priority else {
            return .immediate
        }
        
        guard let priority = PushNotification.Priority(rawValue: priorityValue) else {
            throw CommandError.invalidPriorty
        }
        
        return priority
    }
    
    private func getEnvironment(from signature: Signature) throws -> PushNotificationSender.Environment {
        guard let environmentValue = signature.environment else {
            return .production
        }
        
        guard let environment = PushNotificationSender.Environment(rawValue: environmentValue) else {
            throw CommandError.invalidEnvironment
        }
        
        return environment
    }
    
    private func getPayloadData(from signature: Signature) throws -> Data {
        if let payloadPath = signature.payloadPath {
            do {
                return try Data(contentsOf: URL(fileURLWithPath: payloadPath))
            } catch {
                throw CommandError.couldNotLoadPayloadFile
            }
        }
        
        if let payload = signature.payload {
            return payload.data(using: .utf8) ?? Data()
        }
        
        if let message = signature.message {
            return try JSONEncoder().encode([
                "aps": [
                    "alert": message,
                    "sound": "default"
                ]
            ])
        }
        
        throw CommandError.missingPayload
    }
    
    private func requireOption<T>(_ option: Option<T>) throws -> T {
        guard let value = option.wrappedValue else {
            throw ConsoleKit.CommandError.missingRequiredArgument(option.name)
        }
        return value
    }
    
    private func createNotification(from signature: Signature) throws -> PushNotification {
        let kind = try getKind(from: signature)
        let topic = try requireOption(signature.$topic)
        let priority = try getPriority(from: signature)
        let payload = try getPayloadData(from: signature)
        
        return PushNotification(
            kind: kind,
            topic: topic,
            priority: priority,
            expirationDate: signature.expiration.map {
                Date(timeIntervalSinceNow: TimeInterval($0))
            },
            collapseIdentifier: signature.collapseIdentifier,
            payload: payload
        )
    }
    
    private func createSender(from signature: Signature) throws -> PushNotificationSender {
        let certificatePath = try requireOption(signature.$certificatePath)
        let certificatePassphrase = try requireOption(signature.$certificatePassphrase)
        
        return PushNotificationSender(
            certificatePath: certificatePath,
            passphrase: certificatePassphrase
        )
    }
}
