import Foundation

import ConsoleKit

final class SendSimplePushNotificationCommand: Command {
    struct Signature: CommandSignature {
        @Option(name: "message", help: "The message of the push notification.")
        var message: String?
        
        @Option(name: "topic", help: "The topic (bundle id) for the push notification.")
        var topic: String?
        
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
        let message = signature.message ?? "Test message"
        
        guard let certificatePath = signature.certificatePath else {
            throw CommandError.missingRequiredArgument("certificate-path")
        }
        
        guard let certificatePassphrase = signature.certificatePassphrase else {
            throw CommandError.missingRequiredArgument("certificate-passphrase")
        }
        
        let sender = PushNotificationSender(
            certificatePath: certificatePath,
            passphrase: certificatePassphrase
        )
        
        guard let topic = signature.topic else {
            throw CommandError.missingRequiredArgument("topic")
        }
        
        guard let deviceToken = signature.deviceToken else {
            throw CommandError.missingRequiredArgument("deviceToken")
        }
        
        let notification = try PushNotification(
            topic: topic,
            payload: [
                "aps": [
                    "alert": message,
                    "sound": "default"
                ]
            ]
        )
        
        try sender.send(
            notification,
            to: deviceToken,
            environment: .production
        )
    }
}
