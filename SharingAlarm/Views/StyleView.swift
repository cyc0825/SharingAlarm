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
    
    private let minWidth = CGFloat(70)
    @State private var width = CGFloat(70)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 35)
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
          .font(.system(size: 30, weight: .regular, design: .rounded))
          .foregroundColor(Color.thirdAccent)
          .frame(width: 60, height: 60)
          .background(RoundedRectangle(cornerRadius: 30).fill(.white))
          .padding(5)
          .opacity(isShown ? 1 : 0)
          .scaleEffect(isShown ? 1 : 0.01)
      }
    
}

struct BackgroundComponent: View {
    
    var body: some View {
        ZStack(alignment: .leading)  {
            RoundedRectangle(cornerRadius: 35)
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

class AvatarGenerator {

    static func generateAvatar(for name: String, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let initials = getInitials(from: name)
        let backgroundColor = UIColor.gray
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Draw background circle
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            backgroundColor.setFill()
            circlePath.fill()
            
            // Draw initials
            let initialsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.4, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let initialsSize = initials.size(withAttributes: initialsAttributes)
            let initialsRect = CGRect(x: (size.width - initialsSize.width) / 2,
                                      y: (size.height - initialsSize.height) / 2,
                                      width: initialsSize.width,
                                      height: initialsSize.height)
            initials.draw(in: initialsRect, withAttributes: initialsAttributes)
        }
        
        return image
    }
    
    private static func getInitials(from name: String) -> String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).map { String($0.first ?? Character(" ")) }
        return initials.joined().uppercased()
    }
    
    private static func generateRandomColor() -> UIColor {
        let hue = CGFloat(arc4random_uniform(256)) / 255.0
        let saturation: CGFloat = 0.5 + CGFloat(arc4random_uniform(128)) / 255.0
        let brightness: CGFloat = 0.7 + CGFloat(arc4random_uniform(128)) / 255.0
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
}
