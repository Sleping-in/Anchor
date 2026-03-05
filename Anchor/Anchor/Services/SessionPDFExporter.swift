//
//  SessionPDFExporter.swift
//  Anchor
//
//  Generates a branded therapist-ready PDF from a session summary payload.
//  Magazine-style layout with mixed section types and full data coverage.
//

import UIKit

// MARK: - Brand Image Provider

enum ExportBrandImageProvider {
    private static let cache = NSCache<NSString, UIImage>()

    static func wordmarkImage() -> UIImage? {
        trimmedImage(named: "AnchorWordmark")
    }

    static func markImage() -> UIImage? {
        trimmedImage(named: "AnchorMark")
    }

    private static func trimmedImage(named name: String) -> UIImage? {
        let key = NSString(string: name)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let image = UIImage(named: name) else {
            return nil
        }

        let trimmed = trimTransparentBounds(from: image) ?? image
        cache.setObject(trimmed, forKey: key)
        return trimmed
    }

    private static func trimTransparentBounds(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 1, height > 1 else { return image }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            )
        else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                let alpha = pixelData[index + 3]
                if alpha > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard maxX >= minX, maxY >= minY else {
            return image
        }

        if minX == 0, minY == 0, maxX == width - 1, maxY == height - 1 {
            return image
        }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }
}

// MARK: - PDF Exporter

enum SessionPDFExporter {

    // MARK: - Section Model

    private enum SectionKind {
        case accentBorder(title: String, body: String)
        case highlightPanel(insight: String, quotes: [String])
        case twoColumnMood(
            startLabel: String, startIntensity: Int?, startPhysical: [String],
            endLabel: String, endIntensity: Int?, endPhysical: [String],
            shift: String
        )
        case twoColumnCoping(helped: [String], didntHelp: [String], attempted: [String])
        case bulletList(title: String, items: [String], style: BulletStyle)
        case tagRow(title: String, tags: [String])
        case compactRows(title: String, rows: [(label: String, value: String)])
        case safetyBanner(risk: Bool, notes: String, protective: [String], recommendation: String)
        case emptyState
    }

    private enum BulletStyle {
        case openCircle
        case checkable(completed: Set<String>)
    }

    // MARK: - Layout

    private enum Layout {
        static let pageWidth: CGFloat = 595
        static let pageHeight: CGFloat = 842
        static let margin: CGFloat = 42
        static let contentWidth: CGFloat = pageWidth - (margin * 2)

        static let footerHeight: CGFloat = 22
        static let footerTop: CGFloat = pageHeight - margin - footerHeight
        static let maxContentY: CGFloat = footerTop - 12

        static let headerBottomSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 14
        static let accentBorderWidth: CGFloat = 3
        static let tagHeight: CGFloat = 18
        static let tagHPad: CGFloat = 8
        static let tagSpacing: CGFloat = 6
        static let tagCorner: CGFloat = 9
        static let columnGap: CGFloat = 16
    }

    // MARK: - Colors

    private enum Style {
        static let brandSage = UIColor(red: 141 / 255, green: 163 / 255, blue: 153 / 255, alpha: 1)
        static let brandSageLight = UIColor(
            red: 141 / 255, green: 163 / 255, blue: 153 / 255, alpha: 0.12)
        static let brandSageMedium = UIColor(
            red: 141 / 255, green: 163 / 255, blue: 153 / 255, alpha: 0.25)
        static let quietInk = UIColor(red: 43 / 255, green: 48 / 255, blue: 46 / 255, alpha: 1)
        static let quietInkSecondary = UIColor(
            red: 91 / 255, green: 99 / 255, blue: 95 / 255, alpha: 1)
        static let pageBackground = UIColor.white
        static let ruleColor = UIColor(red: 205 / 255, green: 215 / 255, blue: 210 / 255, alpha: 1)
        static let warmCream = UIColor(red: 252 / 255, green: 252 / 255, blue: 249 / 255, alpha: 1)
        static let warmCreamDarker = UIColor(
            red: 247 / 255, green: 245 / 255, blue: 240 / 255, alpha: 1)
        static let dangerRed = UIColor(red: 239 / 255, green: 68 / 255, blue: 68 / 255, alpha: 1)
        static let dangerRedLight = UIColor(
            red: 239 / 255, green: 68 / 255, blue: 68 / 255, alpha: 0.08)
        static let successGreen = UIColor(red: 34 / 255, green: 139 / 255, blue: 34 / 255, alpha: 1)
        static let mutedGray = UIColor(red: 160 / 255, green: 165 / 255, blue: 162 / 255, alpha: 1)

        static let wordmarkFallbackFont = serifFont(size: 23, weight: .semibold)
        static let reportLabelFont = sansFont(size: 10, weight: .semibold)
        static let headerDateFont = sansFont(size: 10.5, weight: .regular)
        static let headerTitleFont = serifFont(size: 28, weight: .semibold)
        static let headerMetaFont = sansFont(size: 10.5, weight: .regular)
        static let sectionTitleFont = serifFont(size: 14, weight: .semibold)
        static let sectionBodyFont = sansFont(size: 11, weight: .regular)
        static let sectionBodyBoldFont = sansFont(size: 11, weight: .semibold)
        static let quoteFont = serifFont(size: 12.5, weight: .regular)
        static let quoteGlyphFont = serifFont(size: 36, weight: .bold)
        static let intensityFont = sansFont(size: 22, weight: .bold)
        static let tagFont = sansFont(size: 9, weight: .medium)
        static let footerFont = sansFont(size: 8.2, weight: .regular)
        static let columnSubtitleFont = sansFont(size: 10.5, weight: .semibold)
        static let compactLabelFont = sansFont(size: 10, weight: .semibold)
        static let compactValueFont = sansFont(size: 10.5, weight: .regular)

        private static func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let candidates = [
                "Playfair Display",
                "PlayfairDisplay-Regular",
                "PlayfairDisplayRoman-Regular",
                "TimesNewRomanPSMT",
            ]

            for name in candidates {
                if let font = UIFont(name: name, size: size) {
                    return weighted(font, weight: weight)
                }
            }

            if let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
                .withDesign(.serif)
            {
                return UIFont(descriptor: descriptor, size: size)
            }

            return UIFont.systemFont(ofSize: size, weight: weight)
        }

        private static func sansFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let candidates = [
                "Source Sans 3",
                "SourceSans3-Regular",
                "SourceSans3Roman-Regular",
                "HelveticaNeue",
            ]

            for name in candidates {
                if let font = UIFont(name: name, size: size) {
                    return weighted(font, weight: weight)
                }
            }

            return UIFont.systemFont(ofSize: size, weight: weight)
        }

        private static func weighted(_ font: UIFont, weight: UIFont.Weight) -> UIFont {
            let descriptor = font.fontDescriptor.addingAttributes([
                UIFontDescriptor.AttributeName.traits: [
                    UIFontDescriptor.TraitKey.weight: weight
                ]
            ])
            return UIFont(descriptor: descriptor, size: font.pointSize)
        }
    }

    // MARK: - Public

    static func generatePDF(from payload: SessionSummaryPayload) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let contentRect = CGRect(
            x: Layout.margin, y: Layout.margin,
            width: Layout.contentWidth,
            height: Layout.pageHeight - (Layout.margin * 2)
        )
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let sections = buildSections(from: payload)

        let data = renderer.pdfData { context in
            var pageNumber = 0
            var y: CGFloat = 0

            func beginPage(continued: Bool) {
                if pageNumber > 0 {
                    drawFooter(pageNumber: pageNumber, pageRect: pageRect)
                }
                context.beginPage()
                pageNumber += 1
                Style.pageBackground.setFill()
                UIRectFill(pageRect)
                y = drawHeader(
                    payload: payload, at: Layout.margin,
                    contentRect: contentRect, continued: continued
                )
            }

            beginPage(continued: false)

            for section in sections {
                y = drawSectionKind(
                    section, startY: y, contentRect: contentRect
                ) {
                    beginPage(continued: true)
                    return y
                }
            }

            drawFooter(pageNumber: pageNumber, pageRect: pageRect)
        }

        let fileURL = makeExportURL(for: payload)
        let parentDirectory = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(
                at: parentDirectory, withIntermediateDirectories: true
            )
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("[SessionPDFExporter] Failed to write PDF: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Build Sections

    private static func buildSections(from p: SessionSummaryPayload) -> [SectionKind] {
        var sections: [SectionKind] = []

        // 1. Narrative summary
        if !p.narrativeSummary.isEmpty {
            sections.append(
                .accentBorder(
                    title: String(localized: "What we discussed"),
                    body: p.narrativeSummary
                ))
        }

        // 2. Mood journey
        if !p.moodStartDescription.isEmpty || !p.moodEndDescription.isEmpty {
            sections.append(
                .twoColumnMood(
                    startLabel: p.moodStartDescription,
                    startIntensity: p.moodStartIntensity,
                    startPhysical: p.moodStartPhysicalSymptoms,
                    endLabel: p.moodEndDescription,
                    endIntensity: p.moodEndIntensity,
                    endPhysical: p.moodEndPhysicalSymptoms,
                    shift: p.moodShiftDescription
                ))
        } else if !p.observedMood.isEmpty {
            sections.append(
                .accentBorder(
                    title: String(localized: "Observed mood"),
                    body: p.observedMood
                ))
        }

        // 3. Key insight
        if !p.keyInsight.isEmpty {
            sections.append(.highlightPanel(insight: p.keyInsight, quotes: p.userQuotes))
        }

        // 4. Coping strategies
        let hasDetailedCoping =
            !p.copingStrategiesWorked.isEmpty || !p.copingStrategiesDidntWork.isEmpty
        if hasDetailedCoping {
            sections.append(
                .twoColumnCoping(
                    helped: p.copingStrategiesWorked,
                    didntHelp: p.copingStrategiesDidntWork,
                    attempted: p.copingStrategiesAttempted
                ))
        } else {
            let strategies =
                p.copingStrategiesExplored.isEmpty
                ? p.copingStrategies : p.copingStrategiesExplored
            if !strategies.isEmpty {
                sections.append(
                    .bulletList(
                        title: String(localized: "Coping strategies"),
                        items: strategies, style: .openCircle
                    ))
            }
        }

        // 5. Action items for user
        if !p.actionItemsForUser.isEmpty {
            sections.append(
                .bulletList(
                    title: String(localized: "Action items for you"),
                    items: p.actionItemsForUser, style: .openCircle
                ))
        }

        // 6. Home practice
        if !p.homeworkItems.isEmpty || !p.homework.isEmpty {
            let completed = Set(p.completedHomeworkItems)
            if !p.homeworkItems.isEmpty {
                sections.append(
                    .bulletList(
                        title: String(localized: "Home practice"),
                        items: p.homeworkItems,
                        style: .checkable(completed: completed)
                    ))
            } else {
                sections.append(
                    .accentBorder(
                        title: String(localized: "Home practice"),
                        body: p.homework
                    ))
            }
        }

        // 7. For your therapist
        if !p.actionItemsForTherapist.isEmpty {
            sections.append(
                .bulletList(
                    title: String(localized: "For your therapist"),
                    items: p.actionItemsForTherapist, style: .openCircle
                ))
        }

        // 8. Recurring patterns
        if !p.recurringPatternAlert.isEmpty || !p.patternRecognized.isEmpty
            || !p.recurringTopicsSnapshot.isEmpty || !p.recurringTopicsTrend.isEmpty
        {
            var rows: [(String, String)] = []
            if !p.recurringPatternAlert.isEmpty {
                rows.append((String(localized: "Alert"), p.recurringPatternAlert))
            }
            if !p.patternRecognized.isEmpty {
                rows.append((String(localized: "You noticed"), p.patternRecognized))
            }
            if !p.recurringTopicsSnapshot.isEmpty {
                rows.append(
                    (
                        String(localized: "Recurring topics"),
                        p.recurringTopicsSnapshot.joined(separator: ", ")
                    ))
            }
            if !p.recurringTopicsTrend.isEmpty {
                rows.append((String(localized: "Trend"), p.recurringTopicsTrend))
            }
            sections.append(
                .compactRows(title: String(localized: "Recurring patterns"), rows: rows))
        }

        // 9. Progress tracking
        if !p.previousHomeworkAssigned.isEmpty || !p.previousHomeworkCompletion.isEmpty
            || !p.previousHomeworkReflection.isEmpty || !p.therapyGoalProgress.isEmpty
        {
            var rows: [(String, String)] = []
            if !p.previousHomeworkAssigned.isEmpty {
                rows.append((String(localized: "Previous homework"), p.previousHomeworkAssigned))
            }
            if !p.previousHomeworkCompletion.isEmpty {
                rows.append((String(localized: "Completion"), p.previousHomeworkCompletion))
            }
            if !p.previousHomeworkReflection.isEmpty {
                rows.append((String(localized: "Reflection"), p.previousHomeworkReflection))
            }
            if !p.therapyGoalProgress.isEmpty {
                rows.append(
                    (
                        String(localized: "Therapy goals"),
                        p.therapyGoalProgress.joined(separator: "; ")
                    ))
            }
            sections.append(.compactRows(title: String(localized: "Progress tracking"), rows: rows))
        }

        // 10. Suggested follow-up
        if !p.suggestedFollowUp.isEmpty {
            sections.append(
                .accentBorder(
                    title: String(localized: "Suggested follow-up"),
                    body: p.suggestedFollowUp
                ))
        }

        // 11. Context for continuity
        if !p.continuityPeopleMentioned.isEmpty || !p.continuityUpcomingEvents.isEmpty
            || !p.continuityEnvironmentalFactors.isEmpty
        {
            var rows: [(String, String)] = []
            if !p.continuityPeopleMentioned.isEmpty {
                rows.append(
                    (
                        String(localized: "People"),
                        p.continuityPeopleMentioned.joined(separator: "; ")
                    ))
            }
            if !p.continuityUpcomingEvents.isEmpty {
                rows.append(
                    (
                        String(localized: "Upcoming"),
                        p.continuityUpcomingEvents.joined(separator: "; ")
                    ))
            }
            if !p.continuityEnvironmentalFactors.isEmpty {
                rows.append(
                    (
                        String(localized: "Environment"),
                        p.continuityEnvironmentalFactors.joined(separator: "; ")
                    ))
            }
            sections.append(
                .compactRows(title: String(localized: "Context for continuity"), rows: rows))
        }

        // 12. Clinical observations
        if !p.dominantEmotions.isEmpty || !p.primaryCopingStyle.isEmpty
            || p.sessionEffectivenessSelfRating != nil
        {
            var rows: [(String, String)] = []
            if !p.dominantEmotions.isEmpty {
                rows.append(
                    (
                        String(localized: "Dominant emotions"),
                        p.dominantEmotions.joined(separator: ", ")
                    ))
            }
            if !p.primaryCopingStyle.isEmpty {
                rows.append((String(localized: "Primary coping style"), p.primaryCopingStyle))
            }
            if let eff = p.sessionEffectivenessSelfRating {
                rows.append((String(localized: "Session effectiveness"), "\(eff)/10"))
            }
            sections.append(
                .compactRows(title: String(localized: "Clinical observations"), rows: rows))
        }

        // 13. Safety assessment
        if p.crisisRiskDetectedByModel != nil || !p.crisisNotes.isEmpty
            || !p.protectiveFactors.isEmpty || !p.safetyRecommendation.isEmpty
        {
            sections.append(
                .safetyBanner(
                    risk: p.crisisRiskDetectedByModel ?? false,
                    notes: p.crisisNotes,
                    protective: p.protectiveFactors,
                    recommendation: p.safetyRecommendation
                ))
        }

        // 14. Focus and themes (if not already shown as tags in header)
        if !p.primaryFocus.isEmpty, p.narrativeSummary.isEmpty {
            var body = String.localizedStringWithFormat(
                String(localized: "Primary focus: %@"), p.primaryFocus)
            if !p.relatedThemes.isEmpty {
                body +=
                    "\n"
                    + String.localizedStringWithFormat(
                        String(localized: "Related themes: %@"),
                        p.relatedThemes.joined(separator: ", ")
                    )
            }
            sections.append(.accentBorder(title: String(localized: "Focus and themes"), body: body))
        }

        if sections.isEmpty {
            sections.append(.emptyState)
        }

        return sections
    }

    // MARK: - Draw Dispatcher

    private static func drawSectionKind(
        _ kind: SectionKind,
        startY: CGFloat,
        contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        switch kind {
        case .accentBorder(let title, let body):
            return drawAccentBorder(
                title: title, body: body, startY: startY, contentRect: contentRect,
                beginNewPage: beginNewPage)
        case .highlightPanel(let insight, let quotes):
            return drawHighlightPanel(
                insight: insight, quotes: quotes, startY: startY, contentRect: contentRect,
                beginNewPage: beginNewPage)
        case .twoColumnMood(let sL, let sI, let sP, let eL, let eI, let eP, let shift):
            return drawMoodJourney(
                startLabel: sL, startIntensity: sI, startPhysical: sP, endLabel: eL,
                endIntensity: eI, endPhysical: eP, shift: shift, startY: startY,
                contentRect: contentRect, beginNewPage: beginNewPage)
        case .twoColumnCoping(let helped, let didntHelp, let attempted):
            return drawCopingColumns(
                helped: helped, didntHelp: didntHelp, attempted: attempted, startY: startY,
                contentRect: contentRect, beginNewPage: beginNewPage)
        case .bulletList(let title, let items, let style):
            return drawBulletList(
                title: title, items: items, style: style, startY: startY, contentRect: contentRect,
                beginNewPage: beginNewPage)
        case .tagRow(let title, let tags):
            return drawTagRow(
                title: title, tags: tags, startY: startY, contentRect: contentRect,
                beginNewPage: beginNewPage)
        case .compactRows(let title, let rows):
            return drawCompactRows(
                title: title, rows: rows, startY: startY, contentRect: contentRect,
                beginNewPage: beginNewPage)
        case .safetyBanner(let risk, let notes, let protective, let recommendation):
            return drawSafetyBanner(
                risk: risk, notes: notes, protective: protective, recommendation: recommendation,
                startY: startY, contentRect: contentRect, beginNewPage: beginNewPage)
        case .emptyState:
            return drawAccentBorder(
                title: String(localized: "Session Notes"),
                body: String(localized: "No notes available for this session."), startY: startY,
                contentRect: contentRect, beginNewPage: beginNewPage)
        }
    }

    // MARK: - Header

    @discardableResult
    private static func drawHeader(
        payload: SessionSummaryPayload,
        at startY: CGFloat,
        contentRect: CGRect,
        continued: Bool
    ) -> CGFloat {
        var y = startY

        // Top accent line
        Style.brandSage.setFill()
        UIRectFill(CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: 2))
        y += 10

        // Wordmark left
        let wordmarkX = contentRect.minX
        let wordmarkY = y + 2
        if let wordmark = ExportBrandImageProvider.wordmarkImage(), wordmark.size.height > 0 {
            let targetH: CGFloat = 28
            let ratio = wordmark.size.width / max(wordmark.size.height, 1)
            let targetW = min(200, targetH * ratio)
            wordmark.draw(in: CGRect(x: wordmarkX, y: wordmarkY, width: targetW, height: targetH))
        } else {
            let fallbackAttrs: [NSAttributedString.Key: Any] = [
                .font: Style.wordmarkFallbackFont,
                .foregroundColor: Style.brandSage,
            ]
            NSAttributedString(string: "Anchor", attributes: fallbackAttrs)
                .draw(at: CGPoint(x: wordmarkX, y: wordmarkY))
        }

        // Report badge right
        let reportType = NSAttributedString(
            string: String(localized: "Session Report"),
            attributes: [.font: Style.reportLabelFont, .foregroundColor: Style.quietInkSecondary]
        )
        let reportDate = NSAttributedString(
            string: payload.date.formatted(date: .abbreviated, time: .shortened),
            attributes: [.font: Style.headerDateFont, .foregroundColor: Style.quietInkSecondary]
        )
        let rtSize = ceilSize(for: reportType, maxWidth: 230)
        let rdSize = ceilSize(for: reportDate, maxWidth: 230)
        reportType.draw(at: CGPoint(x: contentRect.maxX - rtSize.width, y: y))
        reportDate.draw(at: CGPoint(x: contentRect.maxX - rdSize.width, y: y + rtSize.height + 2))

        // Continuation pages: slim header only (wordmark + date + rule)
        if continued {
            let separatorY = y + max(rtSize.height + rdSize.height + 4, 30) + 4
            Style.ruleColor.setFill()
            UIRectFill(
                CGRect(x: contentRect.minX, y: separatorY, width: contentRect.width, height: 1))
            return separatorY + Layout.headerBottomSpacing
        }

        // Title
        let titleAttr = NSAttributedString(
            string: String(localized: "Session Notes"),
            attributes: [.font: Style.headerTitleFont, .foregroundColor: Style.quietInk]
        )
        let titleY = y + 42
        titleAttr.draw(at: CGPoint(x: contentRect.minX, y: titleY))

        // Meta line
        let durationText = formattedDuration(payload.duration)
        var metaParts = [
            String.localizedStringWithFormat(String(localized: "Duration: %@"), durationText)
        ]
        if let ordinal = payload.sessionOrdinal {
            metaParts.append(
                String.localizedStringWithFormat(String(localized: "Session: %lld"), Int64(ordinal))
            )
        }
        if let before = payload.moodBefore, let after = payload.moodAfter {
            metaParts.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood: %lld/5 → %lld/5"), Int64(before), Int64(after)))
        }

        let metaText = NSAttributedString(
            string: metaParts.joined(separator: "  •  "),
            attributes: [.font: Style.headerMetaFont, .foregroundColor: Style.quietInkSecondary]
        )
        let metaY = titleY + 34
        metaText.draw(
            in: CGRect(x: contentRect.minX, y: metaY, width: contentRect.width, height: 16))

        var bottomY = metaY + 18

        // Topic tags
        let allTopics = payload.topics.isEmpty ? payload.relatedThemes : payload.topics
        if !allTopics.isEmpty {
            bottomY = drawInlineTags(
                Array(allTopics.prefix(7)), at: bottomY, contentRect: contentRect)
            bottomY += 4
        }

        // Focus line (compact)
        if !payload.primaryFocus.isEmpty {
            let focusText = NSAttributedString(
                string: String.localizedStringWithFormat(
                    String(localized: "Focus: %@"), payload.primaryFocus),
                attributes: [
                    .font: Style.headerMetaFont, .foregroundColor: Style.quietInkSecondary,
                ]
            )
            focusText.draw(
                in: CGRect(x: contentRect.minX, y: bottomY, width: contentRect.width, height: 16))
            bottomY += 16
        }

        // Separator
        let separatorY = bottomY + 2
        Style.ruleColor.setFill()
        UIRectFill(CGRect(x: contentRect.minX, y: separatorY, width: contentRect.width, height: 1))

        return separatorY + Layout.headerBottomSpacing
    }

    // MARK: - Accent Border Block

    private static func drawAccentBorder(
        title: String, body: String,
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let innerWidth = contentRect.width - Layout.accentBorderWidth - 12
        let titleH = measuredHeight(for: title, width: innerWidth, attributes: titleAttrs)
        let bodyH = measuredHeight(for: body, width: innerWidth, attributes: bodyAttrs)
        let totalH = 8 + titleH + 6 + bodyH + 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        // Accent line
        let accentRect = CGRect(
            x: contentRect.minX, y: y, width: Layout.accentBorderWidth, height: totalH)
        let accentPath = UIBezierPath(roundedRect: accentRect, cornerRadius: 1.5)
        Style.brandSage.setFill()
        accentPath.fill()

        let textX = contentRect.minX + Layout.accentBorderWidth + 10

        NSAttributedString(string: title, attributes: titleAttrs)
            .draw(in: CGRect(x: textX, y: y + 8, width: innerWidth, height: titleH))

        NSAttributedString(string: body, attributes: bodyAttrs)
            .draw(in: CGRect(x: textX, y: y + 8 + titleH + 6, width: innerWidth, height: bodyH + 2))

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Highlight Panel (Key Insight)

    private static func drawHighlightPanel(
        insight: String, quotes: [String],
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.quoteFont, .foregroundColor: Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let pad: CGFloat = 14
        let innerW = contentRect.width - (pad * 2) - 30
        let titleH = measuredHeight(
            for: String(localized: "Key insight"), width: innerW, attributes: titleAttrs)
        let insightH = measuredHeight(for: insight, width: innerW, attributes: quoteAttrs)
        var totalH: CGFloat = pad + titleH + 8 + insightH + pad

        var quotesText = ""
        for q in quotes where !q.isEmpty {
            quotesText += "\"\(q)\"\n"
        }
        let quotesH: CGFloat
        if !quotesText.isEmpty {
            quotesH = measuredHeight(
                for: quotesText.trimmingCharacters(in: .whitespacesAndNewlines), width: innerW,
                attributes: bodyAttrs)
            totalH += 6 + quotesH
        } else {
            quotesH = 0
        }

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        // Background
        let bgRect = CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: totalH)
        let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 8)
        Style.brandSageLight.setFill()
        bgPath.fill()

        let textX = contentRect.minX + pad + 24

        // Decorative quote glyph
        let glyphAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.quoteGlyphFont, .foregroundColor: Style.brandSageMedium,
        ]
        NSAttributedString(string: "\u{201C}", attributes: glyphAttrs)
            .draw(at: CGPoint(x: contentRect.minX + pad, y: y + pad - 4))

        // Title
        NSAttributedString(string: String(localized: "Key insight"), attributes: titleAttrs)
            .draw(in: CGRect(x: textX, y: y + pad, width: innerW, height: titleH))

        // Insight
        NSAttributedString(string: insight, attributes: quoteAttrs)
            .draw(
                in: CGRect(x: textX, y: y + pad + titleH + 8, width: innerW, height: insightH + 2))

        // User quotes
        if !quotesText.isEmpty {
            NSAttributedString(
                string: quotesText.trimmingCharacters(in: .whitespacesAndNewlines),
                attributes: bodyAttrs
            )
            .draw(
                in: CGRect(
                    x: textX, y: y + pad + titleH + 8 + insightH + 6, width: innerW,
                    height: quotesH + 2))
        }

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Mood Journey (Two Column)

    private static func drawMoodJourney(
        startLabel: String, startIntensity: Int?, startPhysical: [String],
        endLabel: String, endIntensity: Int?, endPhysical: [String],
        shift: String,
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.columnSubtitleFont, .foregroundColor: Style.quietInkSecondary,
        ]
        let intensityAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.intensityFont, .foregroundColor: Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let colW = (contentRect.width - Layout.columnGap) / 2
        let titleH = measuredHeight(
            for: String(localized: "Mood journey"), width: contentRect.width, attributes: titleAttrs
        )

        // Estimate column heights
        var leftH: CGFloat = 20  // subtitle
        if startIntensity != nil { leftH += 28 }
        if !startLabel.isEmpty { leftH += 16 }
        if !startPhysical.isEmpty { leftH += Layout.tagHeight + 4 }

        var rightH: CGFloat = 20
        if endIntensity != nil { rightH += 28 }
        if !endLabel.isEmpty { rightH += 16 }
        if !endPhysical.isEmpty { rightH += Layout.tagHeight + 4 }

        let colH = max(leftH, rightH)
        var totalH: CGFloat = 8 + titleH + 8 + colH
        let shiftH: CGFloat
        if !shift.isEmpty {
            shiftH = measuredHeight(
                for: shift, width: contentRect.width - 12, attributes: bodyAttrs)
            totalH += 8 + 16 + shiftH
        } else {
            shiftH = 0
        }
        totalH += 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        // Section title
        NSAttributedString(string: String(localized: "Mood journey"), attributes: titleAttrs)
            .draw(
                in: CGRect(x: contentRect.minX, y: y + 8, width: contentRect.width, height: titleH))

        let columnsY = y + 8 + titleH + 8

        // Left column (Start)
        var ly = columnsY
        NSAttributedString(string: String(localized: "Start"), attributes: subAttrs)
            .draw(at: CGPoint(x: contentRect.minX, y: ly))
        ly += 20
        if let intensity = startIntensity {
            NSAttributedString(string: "\(intensity)/10", attributes: intensityAttrs)
                .draw(at: CGPoint(x: contentRect.minX, y: ly))
            ly += 28
        }
        if !startLabel.isEmpty {
            NSAttributedString(string: startLabel, attributes: bodyAttrs)
                .draw(at: CGPoint(x: contentRect.minX, y: ly))
            ly += 16
        }
        if !startPhysical.isEmpty {
            drawInlineTags(
                startPhysical, at: ly,
                contentRect: CGRect(x: contentRect.minX, y: 0, width: colW, height: 0))
        }

        // Right column (End)
        let rightX = contentRect.minX + colW + Layout.columnGap
        var ry = columnsY
        NSAttributedString(string: String(localized: "End"), attributes: subAttrs)
            .draw(at: CGPoint(x: rightX, y: ry))
        ry += 20
        if let intensity = endIntensity {
            NSAttributedString(string: "\(intensity)/10", attributes: intensityAttrs)
                .draw(at: CGPoint(x: rightX, y: ry))
            ry += 28
        }
        if !endLabel.isEmpty {
            NSAttributedString(string: endLabel, attributes: bodyAttrs)
                .draw(at: CGPoint(x: rightX, y: ry))
            ry += 16
        }
        if !endPhysical.isEmpty {
            drawInlineTags(
                endPhysical, at: ry, contentRect: CGRect(x: rightX, y: 0, width: colW, height: 0))
        }

        var bottomY = columnsY + colH

        // What shifted
        if !shift.isEmpty {
            let shiftLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: Style.sectionBodyBoldFont, .foregroundColor: Style.quietInk,
            ]
            NSAttributedString(
                string: String(localized: "What shifted"), attributes: shiftLabelAttrs
            )
            .draw(at: CGPoint(x: contentRect.minX, y: bottomY + 8))
            NSAttributedString(string: shift, attributes: bodyAttrs)
                .draw(
                    in: CGRect(
                        x: contentRect.minX, y: bottomY + 8 + 16, width: contentRect.width,
                        height: shiftH + 2))
            bottomY += 8 + 16 + shiftH
        }

        // Separator line
        bottomY += 8
        Style.ruleColor.setFill()
        UIRectFill(CGRect(x: contentRect.minX, y: bottomY, width: contentRect.width, height: 0.5))

        return bottomY + Layout.sectionSpacing
    }

    // MARK: - Coping Columns

    private static func drawCopingColumns(
        helped: [String], didntHelp: [String], attempted: [String],
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.columnSubtitleFont, .foregroundColor: Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let colW = (contentRect.width - Layout.columnGap) / 2
        let titleH = measuredHeight(
            for: String(localized: "Coping strategies"), width: contentRect.width,
            attributes: titleAttrs)
        let lineH = measuredLineHeight(attributes: bodyAttrs)

        let leftLines = max(helped.count, 1)
        let rightLines = max(didntHelp.count, 1)
        let maxLines = max(leftLines, rightLines)
        let colH: CGFloat = 20 + CGFloat(maxLines) * lineH

        var totalH: CGFloat = 8 + titleH + 8 + colH
        if !attempted.isEmpty {
            totalH += 8 + 16 + CGFloat(attempted.count) * lineH
        }
        totalH += 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        NSAttributedString(string: String(localized: "Coping strategies"), attributes: titleAttrs)
            .draw(
                in: CGRect(x: contentRect.minX, y: y + 8, width: contentRect.width, height: titleH))

        let columnsY = y + 8 + titleH + 8

        // Left: What Helped
        var ly = columnsY
        NSAttributedString(string: "✓ " + String(localized: "What helped"), attributes: subAttrs)
            .draw(at: CGPoint(x: contentRect.minX, y: ly))
        ly += 20
        for item in helped {
            NSAttributedString(string: "• \(item)", attributes: bodyAttrs)
                .draw(at: CGPoint(x: contentRect.minX + 4, y: ly))
            ly += lineH
        }

        // Right: What Didn't Help
        let rightX = contentRect.minX + colW + Layout.columnGap
        var ry = columnsY
        NSAttributedString(
            string: "✗ " + String(localized: "What didn't help"), attributes: subAttrs
        )
        .draw(at: CGPoint(x: rightX, y: ry))
        ry += 20
        for item in didntHelp {
            NSAttributedString(string: "• \(item)", attributes: bodyAttrs)
                .draw(at: CGPoint(x: rightX + 4, y: ry))
            ry += lineH
        }

        var bottomY = columnsY + colH

        // Attempted
        if !attempted.isEmpty {
            let attemptAttrs: [NSAttributedString.Key: Any] = [
                .font: Style.sectionBodyBoldFont, .foregroundColor: Style.quietInk,
            ]
            NSAttributedString(
                string: String(localized: "Also attempted:"), attributes: attemptAttrs
            )
            .draw(at: CGPoint(x: contentRect.minX, y: bottomY + 8))
            var ay = bottomY + 8 + 16
            for item in attempted {
                NSAttributedString(string: "◦ \(item)", attributes: bodyAttrs)
                    .draw(at: CGPoint(x: contentRect.minX + 4, y: ay))
                ay += lineH
            }
            bottomY = ay
        }

        bottomY += 8
        Style.ruleColor.setFill()
        UIRectFill(CGRect(x: contentRect.minX, y: bottomY, width: contentRect.width, height: 0.5))

        return bottomY + Layout.sectionSpacing
    }

    // MARK: - Bullet List

    private static func drawBulletList(
        title: String, items: [String], style: BulletStyle,
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let titleH = measuredHeight(for: title, width: contentRect.width, attributes: titleAttrs)
        let lineH = measuredLineHeight(attributes: bodyAttrs)
        let totalH = 8 + titleH + 6 + CGFloat(items.count) * (lineH + 2) + 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        // Accent line
        let accentRect = CGRect(
            x: contentRect.minX, y: y, width: Layout.accentBorderWidth, height: totalH)
        Style.brandSage.setFill()
        UIBezierPath(roundedRect: accentRect, cornerRadius: 1.5).fill()

        let textX = contentRect.minX + Layout.accentBorderWidth + 10
        let innerW = contentRect.width - Layout.accentBorderWidth - 12

        NSAttributedString(string: title, attributes: titleAttrs)
            .draw(in: CGRect(x: textX, y: y + 8, width: innerW, height: titleH))

        var iy = y + 8 + titleH + 6
        for item in items {
            let bullet: String
            switch style {
            case .openCircle:
                bullet = "◦"
            case .checkable(let completed):
                bullet = completed.contains(item) ? "✓" : "◦"
            }

            let bulletColor: UIColor
            switch style {
            case .openCircle:
                bulletColor = Style.quietInkSecondary
            case .checkable(let completed):
                bulletColor =
                    completed.contains(item) ? Style.successGreen : Style.quietInkSecondary
            }

            let bulletStr = NSAttributedString(
                string: bullet,
                attributes: [.font: Style.sectionBodyFont, .foregroundColor: bulletColor])
            bulletStr.draw(at: CGPoint(x: textX, y: iy))

            NSAttributedString(string: item, attributes: bodyAttrs)
                .draw(in: CGRect(x: textX + 14, y: iy, width: innerW - 14, height: lineH + 2))
            iy += lineH + 2
        }

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Compact Rows

    private static func drawCompactRows(
        title: String, rows: [(label: String, value: String)],
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.compactLabelFont, .foregroundColor: Style.quietInk,
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.compactValueFont, .foregroundColor: Style.quietInkSecondary,
        ]

        let titleH = measuredHeight(for: title, width: contentRect.width, attributes: titleAttrs)
        let lineH = measuredLineHeight(attributes: valueAttrs)
        let totalH = 8 + titleH + 6 + CGFloat(rows.count) * (lineH + 3) + 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        // Light background
        let bgRect = CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: totalH)
        Style.warmCream.setFill()
        UIBezierPath(roundedRect: bgRect, cornerRadius: 6).fill()

        let pad: CGFloat = 10
        NSAttributedString(string: title, attributes: titleAttrs)
            .draw(
                in: CGRect(
                    x: contentRect.minX + pad, y: y + 8, width: contentRect.width - pad * 2,
                    height: titleH))

        var ry = y + 8 + titleH + 6
        let labelW: CGFloat = 130
        for row in rows {
            NSAttributedString(string: row.label, attributes: labelAttrs)
                .draw(in: CGRect(x: contentRect.minX + pad, y: ry, width: labelW, height: lineH))
            NSAttributedString(string: row.value, attributes: valueAttrs)
                .draw(
                    in: CGRect(
                        x: contentRect.minX + pad + labelW + 4, y: ry,
                        width: contentRect.width - pad * 2 - labelW - 4, height: lineH + 2))
            ry += lineH + 3
        }

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Safety Banner

    private static func drawSafetyBanner(
        risk: Bool, notes: String, protective: [String], recommendation: String,
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont,
            .foregroundColor: risk ? Style.dangerRed : Style.quietInk,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionBodyFont, .foregroundColor: Style.quietInkSecondary,
        ]

        var lines: [String] = []
        lines.append(
            risk ? String(localized: "Risk detected: yes") : String(localized: "Risk detected: no"))
        if !notes.isEmpty {
            lines.append(String.localizedStringWithFormat(String(localized: "Notes: %@"), notes))
        }
        if !protective.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Protective factors: %@"), protective.joined(separator: ", "))
            )
        }
        if !recommendation.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recommendation: %@"), recommendation))
        }

        let body = lines.joined(separator: "\n")
        let pad: CGFloat = 12
        let innerW = contentRect.width - pad * 2
        let titleH = measuredHeight(
            for: String(localized: "Safety assessment"), width: innerW, attributes: titleAttrs)
        let bodyH = measuredHeight(for: body, width: innerW, attributes: bodyAttrs)
        let totalH = pad + titleH + 6 + bodyH + pad

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        let bgRect = CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: totalH)
        let bgColor = risk ? Style.dangerRedLight : Style.warmCream
        bgColor.setFill()
        UIBezierPath(roundedRect: bgRect, cornerRadius: 8).fill()

        if risk {
            Style.dangerRed.setStroke()
            let borderPath = UIBezierPath(
                roundedRect: bgRect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 8)
            borderPath.lineWidth = 1
            borderPath.stroke()
        }

        NSAttributedString(string: String(localized: "Safety assessment"), attributes: titleAttrs)
            .draw(in: CGRect(x: contentRect.minX + pad, y: y + pad, width: innerW, height: titleH))

        NSAttributedString(string: body, attributes: bodyAttrs)
            .draw(
                in: CGRect(
                    x: contentRect.minX + pad, y: y + pad + titleH + 6, width: innerW,
                    height: bodyH + 2))

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Tag Row

    @discardableResult
    private static func drawTagRow(
        title: String, tags: [String],
        startY: CGFloat, contentRect: CGRect,
        beginNewPage: () -> CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.sectionTitleFont, .foregroundColor: Style.quietInk,
        ]
        let titleH = measuredHeight(for: title, width: contentRect.width, attributes: titleAttrs)
        let totalH = 8 + titleH + 6 + Layout.tagHeight + 8

        var y = startY
        if y + totalH > Layout.maxContentY { y = beginNewPage() }

        NSAttributedString(string: title, attributes: titleAttrs)
            .draw(
                in: CGRect(x: contentRect.minX, y: y + 8, width: contentRect.width, height: titleH))

        drawInlineTags(tags, at: y + 8 + titleH + 6, contentRect: contentRect)

        return y + totalH + Layout.sectionSpacing
    }

    // MARK: - Inline Tags Helper

    @discardableResult
    private static func drawInlineTags(_ tags: [String], at y: CGFloat, contentRect: CGRect)
        -> CGFloat
    {
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: Style.tagFont, .foregroundColor: Style.brandSage,
        ]
        var x = contentRect.minX

        for tag in tags {
            let tagStr = NSAttributedString(string: tag, attributes: tagAttrs)
            let tagSize = ceilSize(for: tagStr, maxWidth: 200)
            let pillW = tagSize.width + Layout.tagHPad * 2
            let pillH = Layout.tagHeight

            if x + pillW > contentRect.maxX {
                break
            }

            let pillRect = CGRect(x: x, y: y, width: pillW, height: pillH)
            Style.brandSageLight.setFill()
            UIBezierPath(roundedRect: pillRect, cornerRadius: Layout.tagCorner).fill()

            tagStr.draw(at: CGPoint(x: x + Layout.tagHPad, y: y + (pillH - tagSize.height) / 2))
            x += pillW + Layout.tagSpacing
        }

        return y + Layout.tagHeight
    }

    // MARK: - Footer

    private static func drawFooter(pageNumber: Int, pageRect: CGRect) {
        let footerY = Layout.footerTop + 4
        let leftColumnWidth: CGFloat = 146
        let rightColumnWidth: CGFloat = 68
        let centerColumnWidth = max(
            120,
            pageRect.width - (Layout.margin * 2) - leftColumnWidth - rightColumnWidth - 12
        )

        var leftStartX = Layout.margin
        if let mark = ExportBrandImageProvider.markImage(), mark.size.height > 0 {
            let iconHeight: CGFloat = 9
            let iconRatio = mark.size.width / max(mark.size.height, 1)
            let iconWidth = iconHeight * iconRatio
            mark.draw(
                in: CGRect(x: leftStartX, y: footerY + 1, width: iconWidth, height: iconHeight))
            leftStartX += iconWidth + 5
        }

        let leftText = NSAttributedString(
            string: String(localized: "Generated by Anchor"),
            attributes: [.font: Style.footerFont, .foregroundColor: Style.quietInkSecondary]
        )
        leftText.draw(
            in: CGRect(
                x: leftStartX, y: footerY, width: leftColumnWidth, height: Layout.footerHeight))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail

        let centerText = NSAttributedString(
            string: String(
                localized: "Supportive notes — not a clinical record. No transcripts included."),
            attributes: [
                .font: Style.footerFont, .foregroundColor: Style.quietInkSecondary,
                .paragraphStyle: paragraph,
            ]
        )
        centerText.draw(
            in: CGRect(
                x: Layout.margin + leftColumnWidth, y: footerY, width: centerColumnWidth,
                height: Layout.footerHeight))

        let rightParagraph = NSMutableParagraphStyle()
        rightParagraph.alignment = .right

        let pageLabel = String.localizedStringWithFormat(
            String(localized: "Page %lld"), Int64(pageNumber))
        let pageText = NSAttributedString(
            string: pageLabel,
            attributes: [
                .font: Style.footerFont, .foregroundColor: Style.quietInkSecondary,
                .paragraphStyle: rightParagraph,
            ]
        )
        pageText.draw(
            in: CGRect(
                x: pageRect.width - Layout.margin - rightColumnWidth, y: footerY,
                width: rightColumnWidth, height: Layout.footerHeight))
    }

    // MARK: - Utilities

    private static func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return String.localizedStringWithFormat(
                String(localized: "%lldm %llds"), Int64(minutes), Int64(remainingSeconds))
        }
        return String.localizedStringWithFormat(String(localized: "%llds"), Int64(remainingSeconds))
    }

    private static func measuredLineHeight(attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let sample = NSAttributedString(string: "Ag", attributes: attributes)
        let rect = sample.boundingRect(
            with: CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        )
        return ceil(rect.height) + 1
    }

    private static func measuredHeight(
        for text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        let attrStr = NSAttributedString(string: text, attributes: attributes)
        let rect = attrStr.boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        )
        return ceil(rect.height)
    }

    private static func ceilSize(for string: NSAttributedString, maxWidth: CGFloat) -> CGSize {
        let rect = string.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        )
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }

    private static func makeExportURL(for payload: SessionSummaryPayload) -> URL {
        let cachesRoot =
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let exportDirectory = cachesRoot.appendingPathComponent("SessionExports", isDirectory: true)
        let stamp = payload.date.formatted(.iso8601.year().month().day())
        let nonce = String(payload.sessionID.uuidString.prefix(8))
        let fileName = "Anchor_Session_\(stamp)_\(nonce).pdf"
        return exportDirectory.appendingPathComponent(fileName)
    }
}
