import SwiftUI
import TipKit

struct testbedApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView()
        }
    }
  
  init() {
    try? Tips.configure()
  }
}

struct PopoverTip1: Tip {
    var title: Text {
        Text("Test title 1").foregroundStyle(.indigo)
    }

    var message: Text? {
        Text("Test message 1")
    }
}

struct PopoverTip2: Tip {
    var title: Text {
        Text("Test title 2").foregroundStyle(.indigo)
    }

    var message: Text? {
        Text("Test message 2")
    }
}

struct TestView: View {
    private let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
  
    @State private var counter = 1
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Counter value: \(counter)").popoverTip(PopoverTip1())
            Spacer()
            Text("Counter value multiplied by 2: \(counter * 2)")
                .foregroundStyle(.tertiary)
                .popoverTip(PopoverTip2())
            Spacer()
        }
        .padding()
    }
}

#Preview {
    TestView()
}
