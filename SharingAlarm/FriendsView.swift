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
    @State private var hasNewFriendRequests = false
    
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
            .onAppear{
                searchRequest()
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing: Button(action: {
                showingAddFriend = true
            }) {
                if viewModel.friendRequests.count > 0 {
                    Image(systemName: "plus.circle")
                } else {
                    Image(systemName: "plus")
                }
            })
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
        }
    }
    
    func searchRequest() {
        guard UserDefaults.standard.value(forKey: "uid") != nil else { return }
        let predicate = NSPredicate(format: "receiverID == %@", UserDefaults.standard.value(forKey: "uid") as! String)
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard record["senderID"] != nil else {
                    print("SenderID is nil")
                    return
                }
                print(record["senderID"]!, "Succeed")
                viewModel.fetchUsernames(for: record["senderID"] as! String) { name in
                    viewModel.friendRequests.append(FriendRequest(recordID: recordID, senderID: record["senderID"] as! String, senderName: name))
                }
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
//                DispatchQueue.main.async {
//                    viewModel.friendRequests = newResults
//                }
            case .failure(let error):
                print("Query failed with error: \(error.localizedDescription)")
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FriendsViewModel
    @State private var name = ""

    @State private var searchQuery = ""
    @State private var searchResults: [CKRecord] = []
    @State private var animatePop = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by name or UID", text: $searchQuery)
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
                            Text(record["uid"] as? String ?? "No uid")
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
                
                TabView {
                    ForEach(viewModel.friendRequests.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(viewModel.friendRequests[index].senderName)
                                    .font(.headline)
                                    .bold()
                                Text(viewModel.friendRequests[index].senderID)
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                            Spacer()
                            Divider()
                                .padding(.vertical)
                            VStack {
                                Button(action: {
                                    withAnimation {
                                        animatePop = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            animatePop = false
                                            print(index)
                                            viewModel.removeFriendRequest(viewModel.friendRequests[index]) { result in
                                                switch result {
                                                case .success():
                                                    print("Request removed successfully.")
                                                    viewModel.addFriendship(fromRequest: viewModel.friendRequests[index], receiverID: UserDefaults.standard.value(forKey: "uid") as! String) { result in
                                                        switch result {
                                                        case .success():
                                                            print("Friendship added successfully.")
                                                            viewModel.friendRequests.remove(at: index)
                                                        case .failure(let error):
                                                            print("Failed to add friendship: \(error.localizedDescription)")
                                                        }
                                                    }
                                                case .failure(let error):
                                                    print("Failed to remove request: \(error.localizedDescription)")
                                                    viewModel.friendRequests.remove(at: index)
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    Text("Accept")
                                        .foregroundColor(.white)
                                }
                                Divider()
                                Button(action: {
                                    withAnimation {
                                        animatePop = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Ensure this matches animation duration
                                            animatePop = false
                                            viewModel.removeFriendRequest(viewModel.friendRequests[index]) { result in
                                                if case .failure(let error) = result {
                                                    print("Failed to remove request: \(error.localizedDescription)")
                                                } else {
                                                    print("Request declined successfully.")
                                                    viewModel.friendRequests.remove(at: index)
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    Text("Decline")
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(width: 100)
                        }
                        .scaleEffect(animatePop ? 1.1 : 1.0) // Slightly enlarge the card when animatePop is true
                        .animation(.easeInOut(duration: 0.2), value: animatePop)
                        .padding()
                        .frame(width: UIScreen.main.bounds.width * 5 / 6, alignment: .leading)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height / 10)
            }
            .navigationBarTitle("Add Friends", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func searchFriends(query: String) {
        let predicate = NSPredicate(format: "uid BEGINSWITH %@", query)
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
        print("Friend request sent to: \(userRecord["uid"] as? String ?? "Unknown")")
    }
}

#Preview{
    AddFriendView(viewModel: FriendsViewModel())
}
