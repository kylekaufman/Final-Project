//
//  ProfileView.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 2/27/25.
//


import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showGuestLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section (New)
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(isDarkMode ? .purple : .orange)
                            Text("Dark Mode")
                        }
                    }
                    .onChange(of: isDarkMode) { _, newValue in
                        setAppAppearance(darkMode: newValue)
                    }
                }
                // Profile Picture Section
                Section(header: Text("Profile Picture")) {
                    HStack {
                        Spacer()
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let imageURL = authManager.currentUser?.profilePictureURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    Button("Change Photo") {
                        showingImagePicker = true
                    }
                }
                
                // User Info Section (Only show fields that exist)
                Section(header: Text("User Information")) {
                    if let user = authManager.currentUser {
                        if !user.firstName.isEmpty {
                            Text("First Name: \(user.firstName)")
                        }
                        if !user.lastName.isEmpty {
                            Text("Last Name: \(user.lastName)")
                        }
                        if !user.phoneNumber.isEmpty {
                            Text("Phone: \(user.phoneNumber)")
                        }
                        Text("Email: \(user.email)") // Always show email
                        
                        if let userData = authManager.userSwiftDataModel, user.role == .guest {
                            Text("Account Type: Guest")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("No user data available")
                            .foregroundColor(.gray)
                    }
                }
                
                // Editable Details Section
                Section(header: Text("Edit Personal Details")) {
                    TextField("First Name", text: $firstName)
                        .submitLabel(.next)
                    TextField("Last Name", text: $lastName)
                        .submitLabel(.next)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .submitLabel(.done)
                }
                
                // Actions Section
                Section {
                    Button("Save Changes") {
                        // Update user profile information logic would go here
                    }
                    .disabled(firstName.isEmpty && lastName.isEmpty && phone.isEmpty)
                    
                    Button("Logout") {
                        // Show confirmation alert for guest users
                        if let user = authManager.currentUser, user.role == .guest {
                            showGuestLogoutConfirmation = true
                        } else {
                            // Regular logout for non-guest users
                            authManager.logout()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                if let user = authManager.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    phone = user.phoneNumber
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    selectedImage = image
                }
            }
            .alert("Logout Confirmation", isPresented: $showGuestLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                
                Button("Logout", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Your guest account data will be permanently deleted. This action cannot be undone.")
            }
        }
    }
    
    // Function to set app appearance
    private func setAppAppearance(darkMode: Bool) {
        // Use the AppearanceManager to apply the setting
        AppearanceManager.shared.setDarkMode(darkMode)
    }
}

// MARK: - ImagePicker (Unchanged)
struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Previews
#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .modelContainer(for: [UserData.self, StockItem.self])
}
