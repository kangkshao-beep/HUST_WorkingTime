
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
    private static let appGroupIdentifier = "group.com.tsubuzaki.WorkingHour"
    private static let cloudKitContainerIdentifier = "iCloud.com.tsubuzaki.WorkingHour"

    public static let shared = SharedModelContainer()

    public let container: ModelContainer
    public private(set) var lastInitializationErrorDescription: String?

    private init() {
        let result = Self.createModelContainer()
        container = result.container
        lastInitializationErrorDescription = result.errorDescription
    }

    private static func createModelContainer() -> (container: ModelContainer, errorDescription: String?) {
        #if os(macOS) || os(watchOS)
        let schema = Schema([
            AttendanceStorageRecord.self
        ])
        #else
        let schema = Schema([
            ClockEntry.self,
            Break.self,
            Project.self,
            ProjectTask.self,
            Workplace.self,
            BreakWindow.self,
            AttendanceStorageRecord.self
        ])
        #endif

        let hasAppGroupConfiguration =
            Bundle.main.object(forInfoDictionaryKey: "AttendanceAppGroupEnabled") as? Bool == true
        let hasCloudKitConfiguration =
            Bundle.main.object(forInfoDictionaryKey: "AttendanceCloudKitEnabled") as? Bool == true
        let hasAppGroupContainer = hasAppGroupConfiguration && FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil

        if hasAppGroupContainer && hasCloudKitConfiguration {
            let appGroupConfiguration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )

            do {
                return (try ModelContainer(for: schema, configurations: [appGroupConfiguration]), nil)
            } catch {
                let appGroupError = error.localizedDescription
                let fallbackReason = String(
                    localized: "CloudKit 或 App Group SwiftData 初始化失败，已切换到本机本地存储：\(appGroupError)"
                )
                log("CloudKit/App Group SwiftData container failed: \(appGroupError)", prefix: "persistence")
                return createLocalModelContainer(
                    schema: schema,
                    fallbackReason: fallbackReason
                )
            }
        }

        if hasAppGroupContainer {
            let appGroupOnlyConfiguration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .none
            )
            let missingCloudKitMessage = String(
                localized: "CloudKit entitlement 不可用，当前使用 App Group 本地存储。请检查 \(cloudKitContainerIdentifier) 配置。"
            )

            do {
                return (
                    try ModelContainer(for: schema, configurations: [appGroupOnlyConfiguration]),
                    missingCloudKitMessage
                )
            } catch {
                let appGroupError = error.localizedDescription
                log("App Group SwiftData container failed: \(appGroupError)", prefix: "persistence")
                return createLocalModelContainer(
                    schema: schema,
                    fallbackReason: missingCloudKitMessage + " \(appGroupError)"
                )
            }
        }

        let missingAppGroupMessage = missingAppGroupFallbackMessage(
            hasConfiguration: hasAppGroupConfiguration,
            hasCloudKitConfiguration: hasCloudKitConfiguration
        )
        log(missingAppGroupMessage, prefix: "persistence")
        return createLocalModelContainer(schema: schema, fallbackReason: missingAppGroupMessage)
    }

    private static func missingAppGroupFallbackMessage(
        hasConfiguration: Bool,
        hasCloudKitConfiguration: Bool
    ) -> String {
        var missingCapabilities: [String] = []
        if !hasConfiguration {
            missingCapabilities.append(String(localized: "App Group 配置"))
        } else {
            missingCapabilities.append(String(localized: "App Group 容器"))
        }
        if !hasCloudKitConfiguration {
            missingCapabilities.append(String(localized: "CloudKit 配置"))
        }

        let capabilityList = missingCapabilities.joined(separator: String(localized: "、"))
        return String(localized: "\(capabilityList) 不可用，已切换到本机本地存储。")
    }

    private static func createLocalModelContainer(
        schema: Schema,
        fallbackReason: String
    ) -> (container: ModelContainer, errorDescription: String?) {
        let localConfiguration = ModelConfiguration(schema: schema)
        do {
            return (
                try ModelContainer(for: schema, configurations: [localConfiguration]),
                fallbackReason
            )
        } catch {
            let localError = error.localizedDescription
            log("Local SwiftData container failed: \(localError)", prefix: "persistence")

            let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return (
                    try ModelContainer(for: schema, configurations: [inMemoryConfiguration]),
                    String(localized: "持久化存储初始化失败，当前仅使用内存存储：\(localError)")
                )
            } catch {
                preconditionFailure("Unable to create even an in-memory SwiftData container: \(error)")
            }
        }
    }
}
