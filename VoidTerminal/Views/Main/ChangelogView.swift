import SwiftUI

// MARK: - 更新日志
struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss

    private struct VersionLog {
        let version: String
        let date: String
        let badge: String
        let badgeColor: String
        let items: [String]
    }

    private let logs: [VersionLog] = [
        VersionLog(
            version: "v2.0.0",
            date: "2026-09-13",
            badge: "最新",
            badgeColor: "07c160",
            items: [
                "安全加固：Token 改用 Keychain 安全存储（仅本设备、不上 iCloud）",
                "好友、群聊、聊天记录本地使用 AES-256-GCM 加密",
                "默认使用 HTTPS / WSS 加密连接",
                "新增图片双层缓存（内存+磁盘），图片不再重复加载",
                "新增网络状态实时监控",
                "新增更新日志页面",
                "适配相机权限说明"
            ]
        ),
        VersionLog(
            version: "v1.0",
            date: "首次发布",
            badge: "初始",
            badgeColor: "6b7280",
            items: [
                "虚空终端 iOS 客户端首个版本",
                "支持大厅聊天、私聊、群聊",
                "支持好友系统和朋友圈",
                "支持图片消息、消息撤回、两步验证",
                "支持群主管理和站长管理",
                "支持头像更换、主题切换、字体调节"
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vtBG.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(logs.indices, id: \.self) { idx in
                            let log = logs[idx]
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text(log.version)
                                        .font(.vt(size: 18, weight: .bold))
                                        .foregroundColor(.vtText)
                                    if !log.badge.isEmpty {
                                        Text(log.badge)
                                            .font(.vt(size: 10, weight: .semibold))
                                            .foregroundColor(.vtText)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: log.badgeColor))
                                            .cornerRadius(4)
                                    }
                                    Spacer()
                                    Text(log.date)
                                        .font(.vt(size: 12))
                                        .foregroundColor(.vtTextDim)
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(log.items.indices, id: \.self) { i in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                                .font(.vt(size: 14))
                                                .foregroundColor(Color(hex: log.badgeColor))
                                            Text(log.items[i])
                                                .font(.vt(size: 13))
                                                .foregroundColor(.vtText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.vtPanel)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vtBorder, lineWidth: 1))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("更新日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Color(hex: "07c160"))
                }
            }
        }
    }
}
