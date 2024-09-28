//
//  Ringtone.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/27.
//

import FirebaseFirestore

struct Ringtone: Hashable, Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var filename: String
    var price: Int
}

var RingtoneList: [Ringtone] = [
    Ringtone(id: "1001", name: "Classic", filename: "Classic.caf", price: 0),
    Ringtone(id: "1002", name: "Harmony", filename: "Harmony.caf", price: 0),
    Ringtone(id: "2001", name: "Oversimplified", filename: "Oversimplified.caf", price: 50),
    Ringtone(id: "2002", name: "RiseOfPhoenix", filename: "RiseOfPhoenix.caf", price: 20),
    Ringtone(id: "2003", name: "Propaganda", filename: "Propaganda.caf", price: 50),
    Ringtone(id: "2004", name: "SymphonyOfTheSoul", filename: "SymphonyOfTheSoul.caf", price: 100),
]
