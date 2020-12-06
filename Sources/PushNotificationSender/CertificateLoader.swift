//
//  CertificateLoader.swift
//  SwiftAPNS
//
//  Created by Steven Roebert on 06/12/2020.
//  Copyright © 2020 Steven Roebert. All rights reserved.
//

import Foundation

enum CertificateLoader {
    static func loadCertificate(atPath path: String, passphrase: String) -> (identity: SecIdentity, certificate: SecCertificate)? {
        guard let (keychain, keychainURL) = createTemporaryKeychain() else {
            return nil
        }
        
        defer {
            try? FileManager.default.removeItem(at: keychainURL)
        }
        
        guard let keyData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        
        var options: [CFString: Any] = [:]
        options[kSecImportExportKeychain] = keychain
        options[kSecImportExportPassphrase] = passphrase
        
        var importItems: CFArray?
        
        let importResult = SecPKCS12Import(keyData as CFData, options as CFDictionary, &importItems)
        guard
            importResult == errSecSuccess,
            let items = importItems,
            CFArrayGetCount(items) > 0,
            let dictionary = (items as [AnyObject])[0] as? [CFString: Any]
        else {
            return nil
        }
        
        guard
            let anyIdentity = dictionary[kSecImportItemIdentity] as CFTypeRef?,
            CFGetTypeID(anyIdentity) == SecIdentityGetTypeID()
        else {
            return nil
        }
        
        let identity = anyIdentity as! SecIdentity // swiftlint:disable:this force_cast
        
        var copiedCertificate: SecCertificate?
        let copyResult = SecIdentityCopyCertificate(identity, &copiedCertificate)
        guard
            copyResult == errSecSuccess,
            let certificate = copiedCertificate
        else {
            return nil
        }
        
        return (identity, certificate)
    }
    
    // MARK: - Temporary Keychain
    
    private static var temporaryKeychainURL: URL? {
        let temporaryDirectoryURL = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: URL(fileURLWithPath: ""),
            create: true
        )
        
        return temporaryDirectoryURL?
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("keychain")
    }
    
    private static func createTemporaryKeychain() -> (SecKeychain, URL)? {
        guard let keychainURL = temporaryKeychainURL else {
            return nil
        }
        
        var createdKeychain: SecKeychain?
        let createResult = SecKeychainCreate(
            keychainURL.absoluteString,
            0,
            "",
            false,
            nil,
            &createdKeychain
        )
        
        guard createResult == errSecSuccess, let keychain = createdKeychain else {
            return nil
        }
        
        return (keychain, keychainURL)
    }
}
