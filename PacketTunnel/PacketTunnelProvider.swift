//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by 哔哩哔哩 on 2019/6/21.
//  Copyright © 2019 xizi. All rights reserved.
//

import NetworkExtension
import CocoaLumberjack
import os.log

extension Data {
    var uint32: UInt32 {
        get {
            let i32array = self.withUnsafeBytes {
                UnsafeBufferPointer<UInt32>(start: $0, count: self.count/2).map(UInt32.init(littleEndian:))
            }
            return i32array[0]
        }
    }
}

extension UInt32 {
    public func ipv4() -> String {
        let ip = self
        
        let byte1 = UInt8(ip & 0xff)
        let byte2 = UInt8((ip>>8) & 0xff)
        let byte3 = UInt8((ip>>16) & 0xff)
        let byte4 = UInt8((ip>>24) & 0xff)
        
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
    
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }
    
    var byteArrayLittleEndian: [UInt8] {
        return [
            UInt8((self & 0xFF000000) >> 24),
            UInt8((self & 0x00FF0000) >> 16),
            UInt8((self & 0x0000FF00) >> 8),
            UInt8(self & 0x000000FF)
        ]
    }

}

enum Method: String {
    case Tcp = "tcp"
    case Udp = "udp"
}



class PacketTunnelProvider: NEPacketTunnelProvider {
    
//    lazy var tunThread = Thread.init(target: self, selector: #selector(threadKeepLive), object: nil)
//    lazy var tcpThread = Thread.init(target: self, selector: #selector(threadKeepLive), object: nil)
    
    var writeProcotol: [NSNumber]? = nil
    
    let mtu = 1200
    
//    let endpoint = NWHostEndpoint(hostname:"35.236.153.210", port: "8080")
    var endpoint: NWHostEndpoint!
    var udpConn: NWUDPSession!
    var tcpConn: NWTCPConnection? = nil
    
    var startCompletionHandler: ((Error?) -> Void)? = nil
    
    var serverIP: String? = nil
    var hostIP: String? = nil
    var clientIP: String? = nil

    override func startTunnel(options: [String : NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        guard
            let server = options?["ServerAddress"] as? String,
            let port = options?["port"] as? String
//            var method = options?["method"] as? String
            else { return }
        var method = "udp"
//        tcpThread.start()
//        tunThread.start()
        startCompletionHandler = completionHandler
        
        endpoint = NWHostEndpoint(hostname:server, port: port)
        // 连接服务器
        switch method {
        case Method.Tcp.rawValue:
            tcpConn = self.createTCPConnection(to: endpoint,
                                               enableTLS: false,
                                               tlsParameters: nil,
                                               delegate: nil)
            configIP { (hostIP, clientIP) in
                self.setupTunnelNetworkSettings(hostIP: hostIP, clientIP: clientIP)
            }
        case Method.Udp.rawValue:
            endpoint = NWHostEndpoint(hostname:server, port: "8081")
            udpConn = self.createUDPSession(to: endpoint, from: nil)
            udpConfigIP { (hip, cip) in
                self.setupTunnelNetworkSettings(hostIP: hip, clientIP: cip, method: .Udp)
            }
        default:
            ()
        }


        // 监听 tcp 连接状态
//        tcpConn!.addObserver(self, forKeyPath: "state", options: .initial, context: nil)
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        super.stopTunnel(with: reason, completionHandler: completionHandler)
        stopVpn()
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
    
    @objc func threadKeepLive() {
        RunLoop.current.add(NSMachPort(), forMode: RunLoop.Mode.common)
        RunLoop.current.run()
    }
}

extension PacketTunnelProvider {
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // 只关心 state 字段变化
        guard keyPath == "state" else { return }
        
        print("conn state: \(tcpConn?.state)")
        
        switch tcpConn?.state ?? .disconnected {
        case .connected:
            print("connected")
//            handshake()
        case .disconnected:
            print("disconnected")
            notifyError(tcpConn!.error)
        case .cancelled:
            stopVpn()
            tcpConn!.removeObserver(self, forKeyPath:"state", context: nil)
            tcpConn = nil
        case .connecting:
            print("connecting")
        default:
            break
        }
    }
    
    func stopVpn() {
        print("stoping vpn")
        
        let vpnManager = NETunnelProviderManager()
    
        vpnManager.connection.stopVPNTunnel()
        
        vpnManager.loadFromPreferences { (error:Error?) in
            guard error == nil else {
                print("load vpn preferences error: \(String(describing: error))")
                return
            }
            
            print("stop vpn due to server side close")
            vpnManager.connection.stopVPNTunnel()
        }
    }
    
    // 通知系统隧道创建状态
    func notifyError(_ error: Error?) {
        startCompletionHandler?(tcpConn?.error)
        
        if error != nil {
            startCompletionHandler = nil
            tcpConn = nil
        }
    }
    
    
    func setupTunnelNetworkSettings(hostIP: String, clientIP: String, method: Method = .Tcp) {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: hostIP)

        // 设置隧道本地 ip
        let ipSettings = NEIPv4Settings(addresses: [clientIP], subnetMasks: ["255.255.255.0"])
        // 设置所有流量走隧道
        ipSettings.includedRoutes = [ NEIPv4Route.default() ]
        ipSettings.excludedRoutes = [NEIPv4Route.init(destinationAddress: hostIP, subnetMask: "255.255.255.255")]
        
        settings.ipv4Settings = ipSettings
//        settings.tunnelOverheadBytes = NSNumber(1500)
        settings.mtu = NSNumber.init(value: mtu)

        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
        
        self.setTunnelNetworkSettings(settings) { (error: Error?) -> Void in
            guard error == nil else {
                self.notifyError(error)
                return
            }
            switch method {
            case .Tcp:
                self.tcpToTun()
                self.tunToTCP()
            case .Udp:
                self.udpToTun()
                self.tunToUDP()
            }
            
            // 通知系统隧道创建成功
            self.notifyError(nil)
        }
    }
    
    @objc func tunToTCP() {
        if #available(iOSApplicationExtension 10.0, *) {
            self.packetFlow.readPacketObjects { (packets) in
                for packet in packets {
                    let packPacket = UInt32(packet.data.count).data + packet.data
                    self.tcpConn?.write(packPacket, completionHandler: { (err) in
                        NSLog("write error: \(String(describing: err))")
                    })
                }
                self.tunToTCP()
            }
            return
        } else {
            // Fallback on earlier versions
            self.packetFlow.readPackets() { (packets: [Data], protocols: [NSNumber]) in
                self.writeProcotol = protocols
                for data in packets {
                    let packet = UInt32(data.count).data + data
                    self.tcpConn!.write(packet) { (error: Error?) in
                        guard error == nil else {
                            NSLog("tunToTCP error: \(String(describing: error))")
                            self.tcpConn?.cancel()
                            return
                        }
                    }
                }
                
                self.tunToTCP()
            }
        }
    }
    
    @objc func tcpToTun() {
        self.tcpConn?.readLength(4, completionHandler: { (headerData, headerErr) in
            guard let count = headerData?.uint32, headerErr == nil else {
                return
            }

            self.tcpConn?.readLength(Int(count), completionHandler: { (pdata: Data?, error: Error?) in
                NSLog("tcpToTun, len: %d", pdata?.count ?? -1)
                NSLog("receive:\(pdata! as NSData)")
                guard error == nil, let packet = pdata else {
                    NSLog("tcpToRun read error: \(String(describing: error))")

                    self.stopVpn()
                    self.tcpConn?.cancel()
                    return
                }

                let protocols = [NSNumber.init(value: AF_INET)]
                let res = self.packetFlow.writePackets([packet], withProtocols: protocols)

                if res == false {
                    NSLog("write tun failed")
                }

                self.tcpToTun()
            })
        })
    }
    
}

