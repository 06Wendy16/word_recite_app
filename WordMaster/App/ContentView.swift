import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(AppState.Tab.home)
            
            ArticleListView()
                .tabItem {
                    Label("短文", systemImage: "book.fill")
                }
                .tag(AppState.Tab.articles)
            
            AddWordView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(AppState.Tab.add)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(AppState.Tab.profile)
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
