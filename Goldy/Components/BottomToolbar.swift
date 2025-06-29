//
//  CustomBottomBar.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

// MARK: - Custom Bottom Toolbar (Your Design)
struct BottomToolbar: View {
    // Actions for each button
    var onBackTapped: () -> Void = {}
    var onMenuTapped: () -> Void = {}
    var onAddTapped: () -> Void = {}
    var onMessageTapped: () -> Void = {}
    var onProfileTapped: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Black background with rounded top corners
            Rectangle()
                .fill(Color.black)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
            
            HStack(spacing: 40) {
                // Back button
                Button(action: onBackTapped) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Menu button
                Button(action: onMenuTapped) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Add button (center, larger)
                Button(action: onAddTapped) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .offset(y: -15) // Raise it slightly above the toolbar
                
                // Message button
                Button(action: onMessageTapped) {
                    Image(systemName: "bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Profile button
                Button(action: onProfileTapped) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image("profile") // Replace with your actual profile image name
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 36, height: 36)
                        )
                }
            }
            .padding(.top, 30)
            .padding(.horizontal, 20)
        }
        .frame(height: 100) // Adjust height as needed
    }
}

// Extension to apply rounded corners to specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Example usage in a view
struct ContentView: View {
    var body: some View {
        ZStack {
            // Your content here
            Color(red: 0.97, green: 0.93, blue: 0.85).edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Save For Later text
                Text("SAVE FOR LATER")
                    .font(.custom("DelaGothicOne-Regular", size: 24))
                    .underline()
                    .padding(.bottom, 130) // Space for the toolbar
                
                // Bottom toolbar
                BottomToolbar()
            }
        }
    }
}

// Preview
struct BottomToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
