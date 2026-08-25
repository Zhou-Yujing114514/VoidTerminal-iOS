import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct TwoFAView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var secret = ""
    @State private var uri = ""
    @State private var code = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showingSetup = false

    private let api = APIService.shared

    var body: some View {
        NavigationStack {
            Form {
                if appState.currentUser?.totpEnabled == true {
                    Section {
                        Label("已绑定认证器", systemImage: "checkmark.seal.fill")
                            .foregroundColor(Color(hex: "07c160"))
                        Text("可使用认证器验证码直接登录")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Section("关闭两步验证") {
                        TextField("输入验证码以关闭", text: $code)
                            .keyboardType(.numberPad)
                        if !message.isEmpty {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        Button("关闭两步验证") { disable() }
                            .disabled(isLoading)
                    }
                } else if !showingSetup {
                    Section {
                        Button("开启两步验证") { enable() }
                            .disabled(isLoading)
                    }
                    Section {
                        Text("开启后可用 Microsoft Authenticator / Google Authenticator / Authy 扫码，之后即可用动态验证码直接登录。")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    Section("扫码绑定") {
                        if let img = qrImage(from: uri) {
                            Image(uiImage: img)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .frame(maxWidth: .infinity)
                        }
                        Text("密钥：\(secret)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textSelection(.enabled)
                        TextField("输入认证器显示的 6 位验证码", text: $code)
                            .keyboardType(.numberPad)
                        if !message.isEmpty {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        Button("确认绑定") { confirm() }
                            .disabled(isLoading)
                    }
                }
            }
            .navigationTitle("两步验证")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func enable() {
        guard let token = appState.token else { return }
        isLoading = true
        message = ""
        Task {
            do {
                let resp = try await api.enable2FA(token: token)
                await MainActor.run {
                    secret = resp.secret ?? ""
                    uri = resp.uri ?? ""
                    showingSetup = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func confirm() {
        guard let token = appState.token else { return }
        guard !code.isEmpty else { message = "请输入验证码"; return }
        isLoading = true
        message = ""
        Task {
            do {
                try await api.confirm2FA(token: token, code: code)
                await MainActor.run {
                    if var u = appState.currentUser {
                        u.totpEnabled = true
                        appState.currentUser = u
                    }
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func disable() {
        guard let token = appState.token else { return }
        guard !code.isEmpty else { message = "请输入验证码"; return }
        isLoading = true
        message = ""
        Task {
            do {
                try await api.disable2FA(token: token, code: code)
                await MainActor.run {
                    if var u = appState.currentUser {
                        u.totpEnabled = false
                        appState.currentUser = u
                    }
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func qrImage(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
