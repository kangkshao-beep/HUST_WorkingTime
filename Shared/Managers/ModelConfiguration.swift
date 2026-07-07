
//
//  ModelConfiguration.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation
import SwiftData

// Shared model container singleton for app and widget extension.
@MainActor
public class SharedModelContainer {
    public static let shared = SharedModelContainer()

    public let container: ModelContainer
    public private(set) var lastInitializationErrorDescription: String?

    private init() {
        let result = Self.createModelContainer()
        container = result.container
        lastInitializationErrorDescription = result.errorDescription
    }

    private static func createModelContainer() -> (container: ModelContainer, errorDescription: String?) {
        let schema = Schema([
            ClockEntry.self,
            Break.self,
            Project.self,
            ProjectTask.self,
            Workplace.self,
            BreakWindow.self,
            AttendanceStorageRecord.self
        ])

        let appGroupConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.com.tsubuzaki.WorkingHour"),
            cloudKitDatabase: .private("iCloud.com.tsubuzaki.WorkingHour")
        )

        do {
            return (try ModelContainer(for: schema, configurations: [appGroupConfiguration]), nil)
        } catch {
            let appGroupError = error.localizedDescription
            log("CloudKit/App Group SwiftData container failed: \(appGroupError)", prefix: "persistence")

            let localConfiguration = ModelConfiguration(schema: schema)
            do {
                return (
                    try ModelContainer(for: schema, configurations: [localConfiguration]),
                    "CloudKit 或 App Group SwiftData 初始化失败，已切换到本机本地存储：\(appGroupError)"
                )
            } catch {
                let localError = error.localizedDescription
                log("Local SwiftData container failed: \(localError)", prefix: "persistence")

                let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return (
                        try ModelContainer(for: schema, configurations: [inMemoryConfiguration]),
                        "持久化存储初始化失败，当前仅使用内存存储：\(localError)"
                    )
                } catch {
                    preconditionFailure("Unable to create even an in-memory SwiftData container: \(error)")
                }
            }
        }
    }
}
