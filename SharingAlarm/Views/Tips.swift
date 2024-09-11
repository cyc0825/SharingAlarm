//
//  Tips.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/8.
//

import TipKit

struct FriendsTip: Tip {
    var title: Text {
        Text("Add someone to your friends").foregroundStyle(.accent)
    }

    var message: Text? {
        Text("Tap the add button and add your friends.")
    }
    
    var image: Image? {
        Image(systemName: "plus")
    }
}

struct GroupsTip: Tip {
    var title: Text {
        Text("Create a group").foregroundStyle(.accent)
    }

    var message: Text? {
        Text("Tap the button and create your groups.")
    }
    
    var image: Image? {
        Image(systemName: "calendar.badge.plus")
    }
}

struct EconomyTip: Tip {
    var title: Text {
        Text("Earn and Spend Coins").foregroundStyle(.accent)
    }

    var message: Text? {
        Text("You will earn coins by responding to alarms within 30 seconds. Coins can be used to buy more ringtones, or to buy other features.")
    }
    
    var image: Image? {
        Image(systemName: "seal.fill")
    }
}
