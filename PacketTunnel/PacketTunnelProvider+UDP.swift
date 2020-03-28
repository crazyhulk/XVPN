//
//  PacketTunnelProvider+UDP.swift
//  PacketTunnel
//
//  Created by 哔哩哔哩 on 2020/3/25.
//  Copyright © 2020 xizi. All rights reserved.
//

import Foundation

extension PacketTunnelProvider {
    
    func udpToTun() {
        self.udpConn.setReadHandler({ (data, err) in
            guard let packet = data else { return }
            if packet[0][0...3].uint32 == ConfigType.IP.rawValue {
                return
            }
            
            let protocols:[NSNumber] = [NSNumber].init(repeating: NSNumber.init(value: AF_INET), count: packet.count)
            _ = self.packetFlow.writePackets(packet, withProtocols: protocols)
        }, maxDatagrams: 65535)
    }
    
    func tunToUDP() {
        if #available(iOSApplicationExtension 10.0, *) {
            self.packetFlow.readPacketObjects { (packets) in
                var data: [Data] = []
                _ = packets.map { data.append($0.data) }
                self.udpConn.writeMultipleDatagrams(data) { (err) in
                    self.tunToUDP()
                }
            }
//            return
        } else {
            // Fallback on earlier versions
            self.packetFlow.readPackets() { (packets: [Data], protocols: [NSNumber]) in
                self.udpConn.writeMultipleDatagrams(packets) { (err) in
                    guard err == nil else {
                        NSLog("writeMultipleDatagrams:\(String(describing: err))")
                        self.tunToUDP()
                        return
                    }
                    
                    self.tunToUDP()
                }
            }
        }
        
    }
}
