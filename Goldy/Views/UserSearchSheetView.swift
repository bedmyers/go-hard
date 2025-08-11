//
//  UserSearchSheetView.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import Foundation
import SwiftUI

struct UserSearchSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: UserSearchViewModel
    var currentUserId: Int
    var onSelect: (User) -> Void

    @State private var query = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search name or email", text: $query)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .onChange(of: query) { newValue in
                        viewModel.searchUsers(query: newValue, token: UserDefaults.standard.string(forKey: "authToken") ?? "")
                    }

                List {
                    ForEach(viewModel.results.filter { $0.id != currentUserId }, id: \.id) { user in
                        Button {
                            var userWithAvatar = user
                            userWithAvatar.avatarImageName = generateAvatarName(for: user)
                            onSelect(userWithAvatar)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(user.name).bold()
                                Text(user.email).font(.caption).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Add a Party")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func generateAvatarName(for user: User) -> String {
        let avatarOptions = ["profile1", "profile2", "profile3", "profile4"]
        return avatarOptions.randomElement() ?? "profile1"
    }
}
