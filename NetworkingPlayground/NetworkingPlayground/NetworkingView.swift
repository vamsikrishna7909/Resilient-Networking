//
//  NetworkingView.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 9/2/25.
//

import SwiftUI

struct NetworkingView: View {
    @StateObject private var vm = NetworkingViewModel(log: "", logger: ConsoleLogger(), client: HTTPClient())
    var body: some View {
        
        VStack(alignment: .center, spacing: 16) {
            Text("Resilient Networking")
                .font(.title3)
                .bold()
            Spacer()
            
            HStack {
                Button("GET /todos/1 (deduped)") {
                    vm.log = ""
                    vm.fetchDeduped()
                }
                .padding()
                .background(.green)
                .cornerRadius(30)
                
                Button("POST /todos (retry+idempotent)") {
                    vm.log = ""
                    vm.createTodoWithRetry()
                }
                .padding()
                .background(.orange)
                .cornerRadius(30)
            }
            
            Spacer()
            ScrollView {
                Text(vm.log)
                    .frame(minWidth: 300, minHeight: 300)
                    .multilineTextAlignment(.leading)
                    .background(Color.gray.opacity(0.1))
                    .foregroundStyle(Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NetworkingView()
}
