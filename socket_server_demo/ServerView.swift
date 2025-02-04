//
//  ServerView.swift
//  socket_server_demo
//
//  Created by Han on 2025/2/4.
//

import SwiftUI

struct ServerView: View {
    @StateObject private var server = SocketServer()
    @State private var port: String = "1001"

    var body: some View {
        VStack {
            Text("Socket Server")
                .font(.largeTitle)
                .padding([.horizontal, .top])
//            Text("本機 IP: \(server.getLocalIP())")
//                .font(.headline)
//                .padding(.horizontal)
            HStack {
                TextField("輸入 Port", text: $port)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)

                Button("啟動 Server") {
                    if let portNumber = UInt16(port) {
                        server.startServer(port: portNumber)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(server.logs, id: \.self) { log in
                        Text(log)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ServerView()
}
