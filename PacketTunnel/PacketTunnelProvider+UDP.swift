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
        self.udpConn?.setReadHandler({ (data, err) in
            guard let packet = data else { return }
            if packet[0][0...3].uint32 == ConfigType.IP.rawValue {
                self.udpToTun()
                return
            }
            let protocols = [NSNumber.init(value: AF_INET)]
            let res = self.packetFlow.writePackets(packet, withProtocols: protocols)
            
            self.udpToTun()
        }, maxDatagrams: NSIntegerMax)
    }
    
    func tunToUDP() {
        if #available(iOSApplicationExtension 10.0, *) {
            self.packetFlow.readPacketObjects { (packets) in
                for packet in packets {
                    let packPacket = UInt32(packet.data.count).data + packet.data
                    self.udpConn?.writeDatagram(packPacket, completionHandler: { (err) in
                         NSLog("write error: \(String(describing: err))")
                    })
                }
                self.tunToTCP()
            }
            return
        }
        
        // Fallback on earlier versions
        self.packetFlow.readPackets() { (packets: [Data], protocols: [NSNumber]) in
            self.writeProcotol = protocols
            for data in packets {
                let packet = UInt32(data.count).data + data
                self.udpConn.writeDatagram(packet, completionHandler: { (error: Error?) in
                    guard error == nil else {
                        NSLog("tunToTCP error: \(String(describing: error))")
                        self.udpConn.cancel()
                        return
                    }
                })
            }
            self.tunToTCP()
        }
        
    }
}
