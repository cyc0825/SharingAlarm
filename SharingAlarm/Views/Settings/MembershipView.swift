//
//  MembershipView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/11.
//

import SwiftUI

struct MembershipView: View {
    var body: some View {
        VStack {
            VStack(spacing: 10) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(.accent)
                        .cornerRadius(30)
                    HStack {
                        Text("Tester: ")
                            .font(.headline)
                        VStack(alignment: .leading,
                                       spacing: 10) {
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark")
                                        .frame(width: 20,
                                               alignment: .leading)
                                    Text("You can use all features")
                                        .frame(maxWidth: .infinity,
                                               alignment: .leading)
                                }
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark")
                                    .frame(width: 20,
                                           alignment: .leading)
                                Text("You can sent feedback to developer")
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    VStack {
                        Spacer()
                        Text("You are currently a Tester")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(.secondAccent)
                        .cornerRadius(30)
                    HStack {
                        Text("Member: ")
                            .font(.headline)
                        VStack(alignment: .leading,
                                       spacing: 10) {
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark")
                                        .frame(width: 20,
                                               alignment: .leading)
                                    Text("You can set up to 10 Alarms at the same time")
                                        .frame(maxWidth: .infinity,
                                               alignment: .leading)
                                }
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark")
                                    .frame(width: 20,
                                           alignment: .leading)
                                Text("You can add friends and make alarms for them")
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    VStack {
                        Spacer()
                        Button {
                            print("not implemented")
                        } label: {
                            VStack {
                                Text("Choose")
                                    .font(.headline)
                            }
                        }
                        .disabled(true)
                    }
                    .padding()
                }
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(.thirdAccent)
                        .cornerRadius(30)
                    HStack {
                        Text("Premium: ")
                            .font(.headline)
                        VStack(alignment: .leading,
                                       spacing: 10) {
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark")
                                    .frame(width: 20,
                                           alignment: .leading)
                                Text("All features from the Member plan")
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark")
                                    .frame(width: 20,
                                           alignment: .leading)
                                Text("You can set up to unlimited Alarms at the same time")
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark")
                                    .frame(width: 20,
                                           alignment: .leading)
                                Text("You can personalize the alarm ringtone")
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    VStack {
                        Spacer()
                        Button {
                            print("not implemented")
                        } label: {
                            VStack {
                                Text("Choose")
                                    .font(.headline)
                            }
                        }
                        .disabled(true)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Membership Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MembershipView()
}
