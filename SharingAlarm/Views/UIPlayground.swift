import SwiftUI

struct TestView: View {
    
    @State var handPostionOffset = 0.0
    @State var isPressing = false
    @State var isGameOver = false
    @State var presentGameOverModal = false
    @State var score = 0
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            HStack {
                Button("Reset") {
                    timer = Timer
                        .publish(every: 0.1, on: .main, in: .common)
                        .autoconnect()
                    withAnimation {
                        handPostionOffset = 0
                    }
                    score = 0
                    isGameOver = false
                }.buttonStyle(.borderedProminent)
                    .padding()
                
                Text(isGameOver ? "GAME OVER" : "Score \(score)")
            }
            
            Image(systemName: "fireplace")
                .resizable()
                .imageScale(.large)
                .frame(width: 200, height: 200)
                .scaledToFit()
                .foregroundColor(.red)
            Spacer()
            
            Image(systemName: "hand.wave.fill")
                .resizable()
                .imageScale(.large)
                .frame(width: 50, height: 50)
                .scaledToFit()
                .offset(y: -handPostionOffset)
            
            Text("Hold Me")
                .onLongPressGesture(minimumDuration: 0.9, maximumDistance: 50) {
                    isGameOver = true
                    presentGameOverModal = true
                } onPressingChanged: { isPressing in
                    self.isPressing = isPressing
                    
                    if !isPressing {
                        timer.upstream.connect().cancel()
                    }
                }
        }
        .onReceive(timer) { timer in
            if isPressing {
                withAnimation(.linear) {
                    handPostionOffset += 43
                }
                score += 1
            }
        }
        .sheet(isPresented: $presentGameOverModal, content: {
            Text("GAME OVER")
                .font(.largeTitle)
        })
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
