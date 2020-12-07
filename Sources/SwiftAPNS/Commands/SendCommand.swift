import Foundation
import ArgumentParser

struct SendCommand: ParsableCommand {
    
    // MARK: - Error
    
    private enum CommandError: Error, CustomStringConvertible {
        case invalidPriorty
        case invalidKind
        case invalidEnvironment
        case couldNotLoadPayloadFile
        case missingPayload
        case invalidToken
        case invalidExpiration
        case couldNotCreateTemporaryKeychain
        case couldNotLoadCertificateFile
        case invalidCertificate
        case emptyCertificatePassphrase
        case invalidCertificatePassphrase
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
            case .invalidExpiration:
                return "The expiration should be a valid integer."
            case .couldNotCreateTemporaryKeychain:
                return "Could not create a temporary file, which is needed for loading the certificate."
            case .couldNotLoadCertificateFile:
                return "The file passed in for certificate-path could not be loaded."
            case .invalidCertificate:
                return "The passed certificate file is invalid."
            case .emptyCertificatePassphrase:
                return "The passphrase passed for the certificate file cannot be empty."
            case .invalidCertificatePassphrase:
                return "The passphrase passed for the certificate file is invalid."
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
    
    // MARK: - Payload
    
    struct PayloadOptions: ParsableArguments {
        @Option(name: .customLong("message"), help: "The message of the push notification.")
        var payloadMessage: String?
        
        @Option(help: "The path to a JSON file to send as the payload.")
        var payloadPath: String?
        
        @Option(name: .customLong("payload"), help: "A JSON object to send as the payload.")
        var payloadJSON: String?
        
        mutating func validate() throws {
            if let payloadPath = payloadPath {
                do {
                    payloadJSON = try String(contentsOf: URL(fileURLWithPath: payloadPath))
                } catch {
                    throw CommandError.couldNotLoadPayloadFile
                }
            } else if let payloadMessage = payloadMessage {
                let escapedPayloadMessage = payloadMessage
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                payloadJSON = "{\"aps\":{\"alert\":\"\(escapedPayloadMessage)\",\"sound\":\"default\"}}"
            }
            
            guard payloadJSON != nil else {
                throw CommandError.missingPayload
            }
        }
    }
    
    // MARK: - Properties
    
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "apns",
            abstract: "Send push notifications using APNS.",
            version: "0.2.0"
        )
    }
    
    @OptionGroup
    var payload: PayloadOptions
    
    @Option(help: "The APNS environment to send the push notification to (development or production).", transform: {
        guard let environment = PushNotificationSender.Environment(rawValue: $0) else {
            throw CommandError.invalidEnvironment
        }
        return environment
    })
    var environment: PushNotificationSender.Environment = .production
    
    @Option(help: "The topic (bundle id) for the push notification.")
    var topic: String
    
    @Option(help: "The priority for the push notification (5 or 10).", transform: {
        guard
            let integer = Int($0),
            let priority = PushNotification.Priority(rawValue: integer)
        else {
            throw CommandError.invalidPriorty
        }
        return priority
    })
    var priority: PushNotification.Priority = .immediate
    
    @Option(name: .customLong("type"), help: "The push notification type.", transform: {
        guard let type = PushNotification.Kind(rawValue: $0) else {
            throw CommandError.invalidKind
        }
        return type
    })
    var kind: PushNotification.Kind = .alert
    
    @Option(help: "The collapse identifier for the push notification.")
    var collapseIdentifier: String?
    
    @Option(name: .customLong("expiration"), help: "The push notification expiration time in seconds.", transform: {
        guard let seconds = Int($0) else {
            throw CommandError.invalidExpiration
        }
        return Date(timeIntervalSinceNow: TimeInterval(seconds))
    })
    var expirationDate: Date?
    
    @Option(help: "The device token to send the push notification to.")
    var deviceToken: String
    
    @Option(help: "The path to the p12 PN certificate.")
    var certificatePath: String
    
    @Option(help: "The passphrase for the p12 PN certificate.")
    var certificatePassphrase: String
    
    // MARK: - ParsableCommand

    mutating func run() throws {
        let notification = PushNotification(
            kind: kind,
            topic: topic,
            priority: priority,
            expirationDate: expirationDate,
            collapseIdentifier: collapseIdentifier,
            payload: payload.payloadJSON?.data(using: .utf8)
        )
        
        do {
            let sender = try PushNotificationSender(
                certificatePath: certificatePath,
                passphrase: certificatePassphrase
            )
            
            try sender.send(
                notification,
                to: deviceToken,
                environment: environment
            )
        } catch PushNotificationSender.SendError.invalidToken {
            throw CommandError.invalidToken
        } catch PushNotificationSender.SendError.couldNotCreateTemporaryKeychain {
            throw CommandError.couldNotCreateTemporaryKeychain
        } catch PushNotificationSender.SendError.couldNotLoadCertificateFile {
            throw CommandError.couldNotLoadCertificateFile
        } catch PushNotificationSender.SendError.invalidCertificate {
            throw CommandError.invalidCertificate
        } catch PushNotificationSender.SendError.emptyCertificatePassphrase {
            throw CommandError.emptyCertificatePassphrase
        } catch PushNotificationSender.SendError.invalidCertificatePassphrase {
            throw CommandError.invalidCertificatePassphrase
        } catch PushNotificationSender.SendError.urlError(_) {
            throw CommandError.connectionError
        } catch PushNotificationSender.SendError.responseError(let responseCode, let response) {
            throw CommandError.responseError(responseCode, response)
        }
    }
}
