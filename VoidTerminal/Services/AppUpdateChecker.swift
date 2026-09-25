import Foundation
import UIKit

/// App 更新信息
struct AppUpdateInfo: Codable {
    let version: String
    let url: String
    let notes: String?

    var isNewerThanCurrent: Bool {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return version.compare(current, options: .numeric) == .orderedDescending
    }
}

/// App 自动更新检查器
class AppUpdateChecker {
    static let shared = AppUpdateChecker()

    private let versionURL = "https://qgs.kdns.fr/downloads/voidterminal/version.json"
    private var lastCheckDate: Date?

    private init() {}

    /// 检查更新（静默，不弹窗）
    func checkSilently(completion: @escaping (AppUpdateInfo?) -> Void) {
        // 每天只检查一次
        if let last = lastCheckDate, Date().timeIntervalSince(last) < 86400 {
            completion(nil)
            return
        }
        lastCheckDate = Date()

        guard let url = URL(string: versionURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            do {
                let info = try JSONDecoder().decode(AppUpdateInfo.self, from: data)
                DispatchQueue.main.async {
                    completion(info.isNewerThanCurrent ? info : nil)
                }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }

    /// 手动检查更新（弹窗提示）
    func checkAndPrompt(from viewController: UIViewController) {
        guard let url = URL(string: versionURL) else { return }

        let alert = UIAlertController(title: "检查更新", message: "正在检查...", preferredStyle: .alert)
        viewController.present(alert, animated: true)

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    if let data = data,
                       let info = try? JSONDecoder().decode(AppUpdateInfo.self, from: data) {
                        if info.isNewerThanCurrent {
                            self.showUpdateAlert(info: info, from: viewController)
                        } else {
                            let ok = UIAlertController(title: "已是最新版本", message: "当前版本 \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")", preferredStyle: .alert)
                            ok.addAction(UIAlertAction(title: "确定", style: .default))
                            viewController.present(ok, animated: true)
                        }
                    } else {
                        let fail = UIAlertController(title: "检查失败", message: error?.localizedDescription ?? "无法连接到更新服务器", preferredStyle: .alert)
                        fail.addAction(UIAlertAction(title: "确定", style: .default))
                        viewController.present(fail, animated: true)
                    }
                }
            }
        }.resume()
    }

    /// 显示更新弹窗
    func showUpdateAlert(info: AppUpdateInfo, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "发现新版本 \(info.version)",
            message: info.notes ?? "点击下载更新",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "下载更新", style: .default) { _ in
            self.downloadAndShareIPA(url: info.url, version: info.version, from: viewController)
        })
        alert.addAction(UIAlertAction(title: "稍后再说", style: .cancel))
        viewController.present(alert, animated: true)
    }

    /// 下载 IPA 并弹出分享菜单
    private func downloadAndShareIPA(url: String, version: String, from viewController: UIViewController) {
        guard let downloadURL = URL(string: url) else { return }

        let progress = UIAlertController(title: "下载中", message: "0%", preferredStyle: .alert)
        viewController.present(progress, animated: true)

        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, response, error in
            DispatchQueue.main.async {
                progress.dismiss(animated: true) {
                    if let localURL = localURL, error == nil {
                        // 移动到临时目录，保持 .ipa 后缀
                        let tempDir = FileManager.default.temporaryDirectory
                        let destURL = tempDir.appendingPathComponent("VoidTerminal-\(version).ipa")
                        do {
                            if FileManager.default.fileExists(atPath: destURL.path) {
                                try FileManager.default.removeItem(at: destURL)
                            }
                            try FileManager.default.moveItem(at: localURL, to: destURL)
                            let activityVC = UIActivityViewController(
                                activityItems: [destURL],
                                applicationActivities: nil
                            )
                            activityVC.popoverPresentationController?.sourceView = viewController.view
                            activityVC.popoverPresentationController?.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                            viewController.present(activityVC, animated: true)
                        } catch {
                            self.showError("下载失败: \(error.localizedDescription)", from: viewController)
                        }
                    } else {
                        self.showError("下载失败: \(error?.localizedDescription ?? "未知错误")", from: viewController)
                    }
                }
            }
        }
        task.resume()
    }

    private func showError(_ message: String, from viewController: UIViewController) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alert, animated: true)
    }
}
