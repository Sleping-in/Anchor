//
//  FontRegistrar.swift
//  Anchor
//
//  Registers bundled fonts at runtime.
//

import CoreText
import Foundation

enum FontRegistrar {
    static func registerFonts() {
        let fontFiles = [
            "PlayfairDisplay-VariableFont_wght.ttf",
            "PlayfairDisplay-Italic-VariableFont_wght.ttf",
            "SourceSans3-VariableFont_wght.ttf",
            "SourceSans3-Italic-VariableFont_wght.ttf"
        ]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(forResource: fontFile, withExtension: nil) else {
                continue
            }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
