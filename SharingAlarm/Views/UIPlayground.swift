
import SwiftUI

struct UIPlayView: View {
    @State var isShowEdit: Bool = false
    @State var selectedAlarm: Alarm?
    var alarms: [Alarm]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 15) {
                ForEach(alarms) { alarm in
                    TinyAlarmCard(alarm: alarm)
                        .onTapGesture {
                            selectedAlarm = alarm
                            isShowEdit = true
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 5)
        .sheet(isPresented: $isShowEdit) {
            if let selectedAlarm {
                EditAlarmView(
                    isPresented: $isShowEdit,
                    viewModel: AlarmsViewModel(),
                    alarm: selectedAlarm
                )
            }
        }
    }
}

#Preview {
    UIPlayView(alarms: [Alarm(time: Date.distantFuture, sound: "", alarmBody: "test", repeatInterval: "none"),
                        Alarm(time: Date.distantFuture, sound: "", alarmBody: "test", repeatInterval: "none")])
}
