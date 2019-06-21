//
//  ViewController.swift
//  XVPN
//
//  Created by 哔哩哔哩 on 2019/6/19.
//  Copyright © 2019 xizi. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {
    
    @IBOutlet weak var connectButton: UIButton!
    
    lazy var vpnManager: NETunnelProviderManager = {
        let manager = NETunnelProviderManager()
        let providerProtocol = NETunnelProviderProtocol()
        providerProtocol.providerBundleIdentifier = self.tunnelBundleId
        providerProtocol.serverAddress = "35.236.153.210"
        
        manager.protocolConfiguration = providerProtocol
        manager.localizedDescription = "VPN"
        return manager
    }()
    
    let tunnelBundleId = "com.xizi.mobilevpn.PacketTunnel"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: vpnManager.connection, queue: OperationQueue.main, using: { [unowned self] (notification) -> Void in
            self.VPNStatusDidChange(notification)
        })
        
        initVPNTunnelProviderManager()
    }

    @IBAction func connectAction(_ sender: UIButton) {
        self.vpnManager.loadFromPreferences { (error:Error?) in
            if let error = error {
                print(error)
            }
            
            if sender.title(for: .normal) == "Connect" {
                do {
                    try self.vpnManager.connection.startVPNTunnel()
                } catch let err {
                    print(err)
                }
            } else {
                self.vpnManager.connection.stopVPNTunnel()
            }
        }
    }
    
    @IBAction func disconnectAction(_ sender: Any) {
        self.connectButton.setTitle("Connect", for: .normal)
        self.vpnManager.connection.stopVPNTunnel()
    }
}

extension ViewController {
    
    private func initVPNTunnelProviderManager() {
        NETunnelProviderManager.loadAllFromPreferences {
            (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            
            if let error = error {
                print(error)
                return
            }
            
            if let savedManagers = savedManagers {
                if savedManagers.count > 0 {
                    self.vpnManager = savedManagers[0]
                }
            }
            
            self.vpnManager.loadFromPreferences() { (error:Error?) in
                if let error = error {
                    print(error)
                    return
                }
                
//                let providerProtocol = NETunnelProviderProtocol()
//                providerProtocol.providerBundleIdentifier = self.tunnelBundleId
//                providerProtocol.serverAddress = "西厢 VPN"
//                providerProtocol.providerConfiguration = [
//                    "1": "1"
//                ]
//
//                self.vpnManager.protocolConfiguration = providerProtocol
//                self.vpnManager.localizedDescription = "西厢 VPN"
                self.vpnManager.isEnabled = true
                
                
                self.vpnManager.saveToPreferences() { (error:Error?) in
                    guard error == nil else {
                        NSLog("save preference error: \(String(describing: error))")
                        return
                    }
                    self.VPNStatusDidChange(nil)
                }
            }
        }
    }
    
    func VPNStatusDidChange(_ notification: Notification?) {
        switch self.vpnManager.connection.status {
        case .connecting:
            connectButton.setTitle("Disconnect", for: .normal)
        case .connected:
            connectButton.setTitle("Disconnect", for: .normal)
        case .disconnecting:
            print("Disconnecting...")
        case .disconnected:
            print("Disconnected...")
            connectButton.setTitle("Connect", for: .normal)
        case .invalid:
            print("Invliad")
        case .reasserting:
            print("Reasserting...")
        @unknown default:
            ()
        }
    }
    
    
}
