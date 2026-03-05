//
//  CrisisResources.swift
//  Anchor
//
//  Localized crisis resources by region.
//

import Combine
import Foundation

struct CrisisResource: Identifiable {
    let id = UUID()
    let name: String
    let contact: String
    let description: String
    let action: CrisisAction
}

enum CrisisAction {
    case call(String)
    case sms(number: String, message: String)
    case url(URL)
}

enum CrisisRegion: String {
    case US
    case CA
    case GB
    case AU
    case NZ
    case IE
    case IN
    case ZA
    case SG
    case other

    static func current() -> CrisisRegion {
        let regionCode = Locale.current.region?.identifier ?? "US"
        switch regionCode {
        case "US": return .US
        case "CA": return .CA
        case "GB", "UK": return .GB
        case "AU": return .AU
        case "NZ": return .NZ
        case "IE": return .IE
        case "IN": return .IN
        case "ZA": return .ZA
        case "SG": return .SG
        default: return .other
        }
    }

    var emergencyNumber: String {
        switch self {
        case .US, .CA: return "911"
        case .GB: return "999"
        case .AU: return "000"
        case .NZ: return "111"
        case .IE: return "112"
        case .IN: return "112"
        case .ZA: return "112"
        case .SG: return "999"
        case .other: return "112"
        }
    }

    var countryCode: String {
        switch self {
        case .US: return "US"
        case .CA: return "CA"
        case .GB: return "GB"
        case .AU: return "AU"
        case .NZ: return "NZ"
        case .IE: return "IE"
        case .IN: return "IN"
        case .ZA: return "ZA"
        case .SG: return "SG"
        case .other:
            return Locale.current.region?.identifier ?? "US"
        }
    }
}

enum CrisisResources {
    static func immediateResources(for region: CrisisRegion) -> [CrisisResource] {
        switch region {
        case .US:
            return [
                CrisisResource(
                    name: "Suicide & Crisis Lifeline",
                    contact: "988",
                    description: "24/7 free and confidential support",
                    action: .call("988")
                ),
                CrisisResource(
                    name: "Crisis Text Line",
                    contact: "Text HOME to 741741",
                    description: "24/7 text-based crisis support",
                    action: .sms(number: "741741", message: "HOME")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .CA:
            return [
                CrisisResource(
                    name: "Talk Suicide Canada",
                    contact: "1-833-456-4566",
                    description: "24/7 crisis support",
                    action: .call("1-833-456-4566")
                ),
                CrisisResource(
                    name: "Crisis Services Canada",
                    contact: "Text 45645",
                    description: "Text support in Canada",
                    action: .sms(number: "45645", message: "HOME")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .GB:
            return [
                CrisisResource(
                    name: "Samaritans",
                    contact: "116 123",
                    description: "24/7 listening support",
                    action: .call("116123")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .AU:
            return [
                CrisisResource(
                    name: "Lifeline",
                    contact: "13 11 14",
                    description: "24/7 crisis support",
                    action: .call("131114")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .NZ:
            return [
                CrisisResource(
                    name: "Lifeline",
                    contact: "0800 543 354",
                    description: "24/7 crisis support",
                    action: .call("0800543354")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .IE:
            return [
                CrisisResource(
                    name: "Samaritans Ireland",
                    contact: "116 123",
                    description: "24/7 listening support",
                    action: .call("116123")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .IN:
            return [
                CrisisResource(
                    name: "Kiran",
                    contact: "1800-599-0019",
                    description: "National mental health helpline",
                    action: .call("18005990019")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .ZA:
            return [
                CrisisResource(
                    name: "Suicide Crisis Line",
                    contact: "0800 567 567",
                    description: "24/7 crisis support",
                    action: .call("0800567567")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .SG:
            return [
                CrisisResource(
                    name: "Samaritans of Singapore",
                    contact: "1767",
                    description: "24/7 crisis support",
                    action: .call("1767")
                ),
                CrisisResource(
                    name: "Emergency Services",
                    contact: region.emergencyNumber,
                    description: "For immediate life-threatening emergencies",
                    action: .call(region.emergencyNumber)
                )
            ]
        case .other:
            return [
                CrisisResource(
                    name: "Local Emergency Number",
                    contact: region.emergencyNumber,
                    description: "For immediate danger",
                    action: .call(region.emergencyNumber)
                ),
                CrisisResource(
                    name: "Find a Helpline",
                    contact: "findahelpline.com",
                    description: "Crisis support worldwide",
                    action: .url(URL(string: "https://findahelpline.com")!)
                )
            ]
        }
    }

    static func additionalResources(for region: CrisisRegion) -> [CrisisResource] {
        switch region {
        case .US:
            return [
                CrisisResource(
                    name: "SAMHSA National Helpline",
                    contact: "1-800-662-4357",
                    description: "Treatment referral and information service",
                    action: .call("18006624357")
                ),
                CrisisResource(
                    name: "Veterans Crisis Line",
                    contact: "1-800-273-8255 (Press 1)",
                    description: "Support for veterans and their families",
                    action: .call("18002738255")
                ),
                CrisisResource(
                    name: "LGBTQ+ Support - Trevor Project",
                    contact: "1-866-488-7386",
                    description: "Crisis support for LGBTQ+ young people",
                    action: .call("18664887386")
                ),
                CrisisResource(
                    name: "Disaster Distress Helpline",
                    contact: "1-800-985-5990",
                    description: "For those affected by disasters",
                    action: .call("18009855990")
                )
            ]
        case .CA:
            return [
                CrisisResource(
                    name: "Wellness Together Canada",
                    contact: "wellnesstogether.ca",
                    description: "Mental health and substance use support",
                    action: .url(URL(string: "https://www.wellnesstogether.ca")!)
                )
            ]
        case .GB, .IE:
            return [
                CrisisResource(
                    name: "Mind",
                    contact: "mind.org.uk",
                    description: "Mental health support and information",
                    action: .url(URL(string: "https://www.mind.org.uk")!)
                )
            ]
        case .AU:
            return [
                CrisisResource(
                    name: "Beyond Blue",
                    contact: "1300 22 4636",
                    description: "Mental health support",
                    action: .call("1300224636")
                )
            ]
        case .NZ:
            return [
                CrisisResource(
                    name: "1737",
                    contact: "Text or call 1737",
                    description: "24/7 support from a trained counselor",
                    action: .call("1737")
                )
            ]
        case .IN:
            return [
                CrisisResource(
                    name: "AASRA",
                    contact: "91-22-2754-6669",
                    description: "24/7 helpline",
                    action: .call("912227546669")
                )
            ]
        case .ZA:
            return [
                CrisisResource(
                    name: "SADAG",
                    contact: "0800 567 567",
                    description: "South African Depression and Anxiety Group",
                    action: .call("0800567567")
                )
            ]
        case .SG:
            return [
                CrisisResource(
                    name: "IMH Mental Health Helpline",
                    contact: "6389 2222",
                    description: "Institute of Mental Health",
                    action: .call("63892222")
                )
            ]
        case .other:
            return [
                CrisisResource(
                    name: "Find a Helpline",
                    contact: "findahelpline.com",
                    description: "Crisis support worldwide",
                    action: .url(URL(string: "https://findahelpline.com")!)
                )
            ]
        }
    }
}
