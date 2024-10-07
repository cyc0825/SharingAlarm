//
//  Tips.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/8.
//

import TipKit

@available(iOS 17.0, *)
struct FriendsTip: Tip {
    var title: Text {
        Text("Add someone to your friends").foregroundStyle(.accent)
    }

    var message: Text? {
        Text("Tap the add button and add your friends using your friends' userIDs.")
    }
    
    var image: Image? {
        Image(systemName: "plus")
    }
}

@available(iOS 17.0, *)
struct GroupsTip: Tip {
    var title: Text {
        Text("Create a group").foregroundStyle(.accent)
    }

    var message: Text? {
        Text("Tap the button and create your groups, but before you create a group, you need to first add one friend.")
    }
    
    var image: Image? {
        Image(systemName: "calendar.badge.plus")
    }
}

@available(iOS 17.0, *)
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
