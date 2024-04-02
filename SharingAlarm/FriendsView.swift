//
//  FriendsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import CloudKit

struct FriendsView: View {
    @StateObject var viewModel = FriendsViewModel()
    @State private var showingAddFriend = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.friends.isEmpty {
                    Text("Tap the add button and add your friends.")
                        .padding()
                } else {
                    List(viewModel.friends) { friend in
                        Text(friend.name)
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing: Button(action: {
                showingAddFriend = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
        }
    }
}

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FriendsViewModel
    @State private var name = ""

    @State private var searchQuery = ""
    @State private var searchResults: [CKRecord] = []
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by name or email", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Search") {
                    searchFriends(query: searchQuery)
                }
                .padding()
                
                List(searchResults, id: \.recordID) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record["name"] as? String ?? "Unknown Name")
                                .font(.headline)
                            Text(record["email"] as? String ?? "No Email")
                                .font(.subheadline)
                        }
                        Spacer()
                        Button(action: {
                            // Trigger the friend request action
                            sendFriendRequest(to: record)
                        }) {
                            Text("Request")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationBarTitle("Add Friends", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func searchFriends(query: String) {
        let predicate = NSPredicate(format: "email BEGINSWITH %@", query)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        var newResults: [CKRecord] = []
        
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                newResults.append(record)
            case .failure(let error):
                print("Failed to fetch record: \(error.localizedDescription)")
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success(let cursor):
                if let cursor = cursor {
                    print("Additional data available with cursor: \(cursor)")
                } else {
                    print("Fetched all data. No additional data to fetch.")
                }
                DispatchQueue.main.async {
                    self.searchResults = newResults
                }
            case .failure(let error):
                print("Query failed with error: \(error.localizedDescription)")
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func sendFriendRequest(to userRecord: CKRecord) {
        // Implement the logic to send a friend request.
        // This might involve creating a new record in a "FriendRequests" record type
        // and setting the appropriate fields such as requesterId, requesteeId, etc.
        print("Friend request sent to: \(userRecord["email"] as? String ?? "Unknown")")
    }
}

#Preview{
    FriendsView(viewModel: FriendsViewModel())
}
