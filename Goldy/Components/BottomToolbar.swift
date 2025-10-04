//
//  CustomBottomBar.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

// MARK: - Custom Bottom Toolbar (Your Design)
struct BottomToolbar: View {
    var onBackTapped: () -> Void = {}
    var onMenuTapped: () -> Void = {}
    var onAddTapped: () -> Void = {}
    var onMessageTapped: () -> Void = {}
    var onProfileTapped: () -> Void = {}
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
            
            HStack(spacing: 40) {
                Button(action: onBackTapped) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Button(action: onMenuTapped) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
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
                .offset(y: -15)
                
                Button(action: onMessageTapped) {
                    Image(systemName: "bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Button(action: onProfileTapped) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image("profile")
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
        .frame(height: 100)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.93, blue: 0.85).edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Text("SAVE FOR LATER")
                    .font(.custom("DelaGothicOne-Regular", size: 24))
                    .underline()
                    .padding(.bottom, 130)
                
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
