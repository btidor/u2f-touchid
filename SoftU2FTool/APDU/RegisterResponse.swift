//
//  RegisterResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct RegisterResponse: APDUResponseDataProtocol {
    static let status = APDUTrailer.Status.NoError
    
    let publicKey:   Data
    let keyHandle:   Data
    let certificate: Data
    let signature:   Data
    
    init(publicKey pk: Data, keyHandle kh: Data, certificate cert: Data, signature sig: Data) {
        publicKey = pk
        keyHandle = kh
        certificate = cert
        signature = sig
    }
    
    init(raw: Data) throws {
        let reader = DataReader(data: raw)
        
        do {
            // reserved byte
            let _:UInt8 = try reader.read()
            
            publicKey = try reader.readData(MemoryLayout<U2F_EC_POINT>.size)
            
            let khLen:UInt8 = try reader.read()
            keyHandle = try reader.readData(Int(khLen))
            
            // peek at cert to figure out its length
            let certLen = try RegisterResponse.certLength(fromData: reader.rest)
            certificate = try reader.readData(certLen)
            
            signature = reader.rest
        } catch DataReader.DRError.End {
            throw APDUError.BadSize
        }
    }
    
    var raw: Data {
        let writer = DataWriter()
        
        writer.write(UInt8(0x05))
        writer.writeData(publicKey)
        writer.write(UInt8(keyHandle.count))
        writer.writeData(keyHandle)
        writer.writeData(certificate)
        writer.writeData(signature)
        
        return writer.buffer
    }
    
    // Parse a DER formatted X509 certificate from the beginning of a datum and return its length.
    static func certLength(fromData d: Data) throws -> Int {
        var size: Int = 0
        if SelfSignedCertificate.parseX509(d, consumed: &size) {
            return size
        } else {
            throw APDUError.BadCert
        }
    }
}
