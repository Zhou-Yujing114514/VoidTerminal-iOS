import SwiftUI

@main
struct VoidTerminalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme == .dark ? .dark : .light)
        }
    }
}

// MARK: - App State
final class AppState: ObservableObject {
    @Published var token: String? {
        didSet {
            if let token = token {
                UserDefaults.standard.set(token, forKey: "vt_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "vt_token")
            }
        }
    }
    @Published var currentUser: User?
    @Published var theme: Theme = .dark {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "vt_theme") }
    }
    @Published var fontSize: FontSize = .md {
        didSet {
            UserDefaults.standard.set(fontSize.rawValue, forKey: "vt_font")
            NotificationCenter.default.post(name: .fontSizeChanged, object: nil)
        }
    }
    @Published var isAdmin: Bool = false {
        didSet { UserDefaults.standard.set(isAdmin, forKey: "vt_is_admin") }
    }
    @Published var hallName: String = "公共大厅"
    @Published var maxOnline: Int = 0

    private let ws = WebSocketService.shared
    private let api = APIService.shared

    enum Theme: String { case dark, light }
    enum FontSize: String { case sm, md, lg, xl }

    init() {
        self.token = UserDefaults.standard.string(forKey: "vt_token")
        if let themeStr = UserDefaults.standard.string(forKey: "vt_theme"),
           let t = Theme(rawValue: themeStr) { self.theme = t }
        self.isAdmin = UserDefaults.standard.bool(forKey: "vt_is_admin")
        if let fontStr = UserDefaults.standard.string(forKey: "vt_font"),
           let f = FontSize(rawValue: fontStr) { self.fontSize = f }
        // 监听WebSocket推送的状态更新
        NotificationCenter.default.addObserver(forName: .adminStatusUpdate, object: nil, queue: .main) { [weak self] notif in
            self?.isAdmin = notif.object as? Bool ?? false
        }
        NotificationCenter.default.addObserver(forName: .hallRenamed, object: nil, queue: .main) { [weak self] notif in
            if let name = notif.object as? String { self?.hallName = name }
        }
        NotificationCenter.default.addObserver(forName: .maxOnlineUpdate, object: nil, queue: .main) { [weak self] notif in
            self?.maxOnline = notif.object as? Int ?? 0
        }
        // M6: 服务器地址更改后重新登录
        NotificationCenter.default.addObserver(forName: .serverConfigChanged, object: nil, queue: .main) { [weak self] _ in
            self?.logout()
        }
    }

    func restoreSession() async {
        guard let token = token else { return }
        for attempt in 0..<3 {
            do {
                let me = try await api.me(token: token)
                await MainActor.run { self.currentUser = me }
                return
            } catch {
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                await MainActor.run { self.token = nil }
            }
        }
    }

    func logout() {
        ws.disconnect()
        token = nil
        currentUser = nil
        isAdmin = false
        let defaults = UserDefaults.standard
        ["vt_friends", "vt_groups", "vt_global_msgs", "vt_dm_msgs", "vt_group_msgs", "vt_current_uid"].forEach {
            defaults.removeObject(forKey: $0)
        }
        Task { await api.logout() }
    }
}
