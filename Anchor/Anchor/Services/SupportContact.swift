//
//  SupportContact.swift
//  Anchor
//
//  Centralized support contact details.
//

import Foundation

enum SupportContact {
    static let email = "support@anchor-app.com"

    static var mailtoURL: URL {
        URL(string: "mailto:\(email)")!
    }
}
