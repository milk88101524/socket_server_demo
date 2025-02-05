//
//  SocketServer.swift
//  socket_server_demo
//
//  Created by Han on 2025/2/4.
//

import Foundation
import Network

class SocketServer: ObservableObject {
    var listener: NWListener?
    @Published var logs: [String] = []
    var connections: [NWConnection] = []

    func startServer(port: UInt16) {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            appendLog("❌ 監聽失敗: \(error)")
            return
        }

        listener?.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.appendLog("✅ Server 啟動，監聽 Port \(port)")
                case .failed(let error):
                    self.appendLog("❌ Server 啟動失敗: \(error)")
                default:
                    break
                }
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.appendLog("🔗 新的客戶端已連線")
            }
            self.connections.append(connection)
            self.receive(from: connection)
            connection.start(queue: .global())
        }

        listener?.start(queue: .global())
    }

    func receive(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let message = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    self.appendLog("📩 收到訊息: \(message)")
                }
                self.send(message: "\(message)", to: connection)
            }

            if isComplete || error != nil {
                DispatchQueue.main.async {
                    self.appendLog("🔴 連線已關閉")
                }
                connection.cancel()
            } else {
                self.receive(from: connection)
            }
        }
    }
    
    func send(message: String, to connection: NWConnection) {
        let data = message.data(using: .utf8) ?? Data()
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.appendLog("❌ 發送錯誤: \(error)")
                }
            } else {
                DispatchQueue.main.async {
                    self.appendLog("📤 已發送: \(message)")
                }
            }
        })
    }
    
    func getLocalIP() -> String {
        var address: String = "無法取得 IP"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                if let interface = ptr?.pointee {
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    if addrFamily == UInt8(AF_INET) {
                        let name = String(cString: interface.ifa_name)
                        if name == "en0" { // en0 是 Wi-Fi 介面
                            var addr = interface.ifa_addr.pointee
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                           &hostname, socklen_t(hostname.count),
                                           nil, 0, NI_NUMERICHOST) == 0 {
                                address = String(cString: hostname)
                            }
                        }
                    }
                }
                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }


    private func appendLog(_ log: String) {
        logs.append(log)
    }
}

