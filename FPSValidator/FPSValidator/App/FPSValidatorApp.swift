import SwiftUI

@main
struct FPSValidatorApp: App {
    @StateObject private var viewModel = FPSGeneratorViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}