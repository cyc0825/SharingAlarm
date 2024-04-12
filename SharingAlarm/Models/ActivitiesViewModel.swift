//
//  ActivitiesViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import Foundation

struct Activity {
    var from: Date
    var to: Date
    var participants: [User]
}

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    
    init() {
        self.activities.append(Activity(from: Date(), to: Date(), participants: []))
    }
    
    func fetchActivity(){}
    
    func addActivity(){}
    
    func removeActivity(){}
}
