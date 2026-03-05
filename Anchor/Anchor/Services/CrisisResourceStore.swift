//
//  CrisisResourceStore.swift
//  Anchor
//
//  Loads localized crisis resources with ThroughLine fallback.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class CrisisResourceStore: ObservableObject {
    @Published var immediate: [CrisisResource] = []
    @Published var additional: [CrisisResource] = []
    @Published var isUsingRemote = false

    func load(for region: CrisisRegion) async {
        do {
            let helplines = try await ThroughLineAPIClient.shared.fetchHelplines(
                countryCode: region.countryCode,
                limit: 12,
                priorityOnly: true
            )
            let mapped = helplines.compactMap { mapHelpline($0) }
            immediate = Array(mapped.prefix(3))
            additional = Array(mapped.dropFirst(3))
            isUsingRemote = true
        } catch {
            immediate = CrisisResources.immediateResources(for: region)
            additional = CrisisResources.additionalResources(for: region)
            isUsingRemote = false
        }
    }

    private func mapHelpline(_ helpline: ThroughLineHelpline) -> CrisisResource? {
        if let phone = helpline.phoneNumber, !phone.isEmpty {
            return CrisisResource(
                name: helpline.name,
                contact: phone,
                description: helpline.description ?? "",
                action: .call(phone)
            )
        }

        if let sms = helpline.smsNumber, !sms.isEmpty {
            return CrisisResource(
                name: helpline.name,
                contact: "Text \(sms)",
                description: helpline.description ?? "",
                action: .sms(number: sms, message: "HOME")
            )
        }

        if let webChat = helpline.webChatUrl, let url = URL(string: webChat) {
            return CrisisResource(
                name: helpline.name,
                contact: "Online chat",
                description: helpline.description ?? "",
                action: .url(url)
            )
        }

        if let website = helpline.website, let url = URL(string: website) {
            return CrisisResource(
                name: helpline.name,
                contact: website,
                description: helpline.description ?? "",
                action: .url(url)
            )
        }

        return nil
    }
}
