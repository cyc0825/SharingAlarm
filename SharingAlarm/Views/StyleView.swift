//
//  StyleView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/5.
//
import SwiftUI

struct FloatingFriendRequestsView: View {
    var body: some View {
        VStack {
            // Your friend requests content here
        }
        .frame(height: UIScreen.main.bounds.height / 5)
        .background(BlurView(style: .systemMaterial))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct LargeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.secondary)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct DropdownMenu: View {
    @Binding var isExpanded: Bool
    @Binding var selectedOption: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(selectedOption.isEmpty ? "Select an option" : selectedOption)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }

            if isExpanded {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation {
                            isExpanded = false
                            selectedOption = option
                            onSelect(option)
                        }
                    }) {
                        Text(option)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct DraggingComponent: View {
    @Binding var isLocked: Bool
    var onClose: () -> Void
    
    let maxWidth: CGFloat
    
    private let minWidth = CGFloat(60)
    @State private var width = CGFloat(60)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(Color.accentColor)
            .frame(width: width)
            .overlay(
                ZStack {
                    image(name: "alarm.waves.left.and.right", isShown: isLocked)
                    image(name: "alarm", isShown: !isLocked)
                },
                alignment: .trailing
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard isLocked else { return }
                        if value.translation.width > 0 {
                            width = min(max(value.translation.width + minWidth, minWidth), maxWidth)
                        }
                    }
                    .onEnded { value in
                        guard isLocked else { return }
                        if width < maxWidth {
                            width = minWidth
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            withAnimation(.spring().delay(0.5)) {
                                isLocked = false
                            }
                            onClose()
                        }
                    }
            )
            .animation(.spring(response: 0, dampingFraction: 1, blendDuration: 0), value: width)
    }
    
    private func image(name: String, isShown: Bool) -> some View {
        Image(systemName: name)
          .font(.system(size: 20, weight: .regular, design: .rounded))
          .foregroundColor(Color.thirdAccent)
          .frame(width: 50, height: 50)
          .background(RoundedRectangle(cornerRadius: 25).fill(.white))
          .padding(5)
          .opacity(isShown ? 1 : 0)
          .scaleEffect(isShown ? 1 : 0.01)
      }
    
}

struct BackgroundComponent: View {
    
    var body: some View {
        ZStack(alignment: .leading)  {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.accentColor.opacity(0.4))
            
            Text("Slide to Close")
                .font(.footnote)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
    }
    
}

class SheetHostingController<Content: View>: UIViewController {
    var rootView: Content

    init(rootView: Content) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.modalPresentationStyle = .pageSheet
        present(hostingController, animated: true, completion: nil)
    }
}
