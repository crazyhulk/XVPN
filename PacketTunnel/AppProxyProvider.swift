//
//  AppProxyProvider.swift
//  PacketTunnel
//
//  Created by 哔哩哔哩 on 2019/8/24.
//  Copyright © 2019 xizi. All rights reserved.
//

import NetworkExtension


class AppProxyProvider: NEAppProxyProvider {
    
    var endpoint = NWHostEndpoint(hostname:"35.236.153.210", port: "8080")
    var tcpConn: NWTCPConnection? = nil
    
    override func startProxy(options: [String : Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        // 连接服务器
        tcpConn = self.createTCPConnection(to: endpoint,
                                           enableTLS: false,
                                           tlsParameters: nil,
                                           delegate: nil)
        startConnection { err in
            completionHandler(nil)
        }
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        return true
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        super.handleAppMessage(messageData, completionHandler: completionHandler)
    }
}

extension AppProxyProvider {
    
    func startConnection(callback:@escaping ((Error?) -> Void)) {
        let req = "CONNECT 35.236.153.210 HTTP/1.1\r\n"
        tcpConn!.write(req.data(using: .utf8)!) { (err) in
            callback(err)
        }
    }
}
