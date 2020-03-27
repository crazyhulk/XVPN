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
            NSLog("Get udp datagram from server")
            
            guard let packet = data else { return }
            if packet[0][0...3].uint32 == ConfigType.IP.rawValue {
                return
            }
            let length = packet.count
            var protocols:[NSNumber] = []
            for i in 0...length {
                protocols.append(NSNumber.init(value: AF_INET))
            }
            let res = self.packetFlow.writePackets(packet, withProtocols: protocols)
        }, maxDatagrams: 65535)
    }
    
    func tunToUDP() {
        if #available(iOSApplicationExtension 10.0, *) {
            self.packetFlow.readPacketObjects { (packets) in
                
                var data: [Data] = []
                for packet in packets {
//                    let packPacket = UInt32(packet.data.count).data + packet.data
                    let packPacket = packet.data
                    data.append(packPacket)
//                    self.udpConn.writeDatagram(packPacket, completionHandler: { (err) in
//                        if err == nil {
//                            NSLog("write data:\(packPacket as? NSData)" )
//                        } else {
//                            NSLog("write error: \(String(describing: err))")
//                        }
//                    })
                }
//                self.tunToUDP()
                self.udpConn.writeMultipleDatagrams(data) { (err) in
                    self.tunToUDP()
                }
            }
//            return
        } else {
            // Fallback on earlier versions
            self.packetFlow.readPackets() { (packets: [Data], protocols: [NSNumber]) in
                self.writeProcotol = protocols
                for data in packets {
    //                let packet = UInt32(data.count).data + data
                    let packet = data
                    self.udpConn.writeDatagram(packet, completionHandler: { (error: Error?) in
                        guard error == nil else {
                            NSLog("tunToTCP error: \(String(describing: error))")
                            self.udpConn.cancel()
                            return
                        }
                    })
                }
                self.tunToUDP()
            }
        }
        
    }
}
