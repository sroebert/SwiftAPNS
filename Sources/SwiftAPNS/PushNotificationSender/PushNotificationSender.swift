import Foundation

class PushNotificationSender: NSObject, URLSessionDelegate {
    
    // MARK: - Types
    
    enum Environment: String {
        case development
        case production
        
        fileprivate var host: String {
            switch self {
            case .development:
                return "api.development.push.apple.com"
            case .production:
                return "api.push.apple.com"
            }
        }
    }
    
    enum SendError: Error {
        case invalidToken
        case urlError(Error)
        case responseError(Int?, String?)
    }
    
    // MARK: - Public Vars
    
    // MARK: - Private Vars
    
    private var session: URLSession! // swiftlint:disable:this implicitly_unwrapped_optional
    
    private let identity: SecIdentity?
    private let certificate: SecCertificate?
    
    // MARK: - Object Lifecycle
    
    init(certificatePath: String, passphrase: String) {
        if let result = CertificateLoader.loadCertificate(atPath: certificatePath, passphrase: passphrase) {
            identity = result.identity
            certificate = result.certificate
        } else {
            identity = nil
            certificate = nil
        }
        
        super.init()
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let identity = identity, let certificate = certificate else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let credential = URLCredential(
            identity: identity,
            certificates: [certificate],
            persistence: .forSession
        )
        completionHandler(.useCredential, credential)
    }
    
    // MARK: - Send
    
    private func setupRequest(
        for notification: PushNotification,
        to deviceToken: String,
        environment: Environment = .production
    ) throws -> URLRequest {
        guard let url = URL(string: "https://\(environment.host)/3/device/\(deviceToken)") else {
            throw SendError.invalidToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.setValue(notification.kind.rawValue, forHTTPHeaderField: "apns-push-type")
        request.setValue("\(notification.priority.rawValue)", forHTTPHeaderField: "apns-priority")
        request.setValue(notification.topic, forHTTPHeaderField: "apns-topic")
        
        if let id = notification.id {
            request.setValue(id.uuidString, forHTTPHeaderField: "apns-id")
        }
        
        if let expirationDate = notification.expirationDate {
            request.setValue(String(Int(expirationDate.timeIntervalSince1970)), forHTTPHeaderField: "apns-expiration")
        }
        
        if let collapseIdentifier = notification.collapseIdentifier {
            request.setValue(collapseIdentifier, forHTTPHeaderField: "apns-collapse-id")
        }
        
        request.httpBody = notification.payload
        
        return request
    }
    
    public func send(_ notification: PushNotification, to deviceToken: String, environment: Environment = .production) throws {
        let request = try setupRequest(
            for: notification,
            to: deviceToken,
            environment: environment
        )
        let semaphore = DispatchSemaphore(value: 0)
        
        var data: Data?
        var response: HTTPURLResponse?
        var error: Error?
        let task = session.dataTask(with: request) { taskData, taskResponse, taskError in
            
            data = taskData
            response = taskResponse as? HTTPURLResponse
            error = taskError
            
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        if let error = error {
            throw SendError.urlError(error)
        } else if response?.statusCode != 200 {
            throw SendError.responseError(
                response?.statusCode,
                data.flatMap { String(data: $0, encoding: .utf8) }
            )
        }
    }
}
