//
//  HistoryView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.timestamp, order: .reverse) private var sessions: [Session]
    @State private var selectedSession: Session?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: Session?
    
    var body: some View {
        List {
            if sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No sessions yet")
                        .font(.headline)
                    
                    Text("Your conversation history will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowSeparator(.hidden)
            } else {
                ForEach(sessions) { session in
                    SessionDetailRow(session: session)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSession = session
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .alert("Delete Session?", isPresented: $showingDeleteAlert, presenting: sessionToDelete) { session in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSession(session)
            }
        } message: { session in
            Text("This will permanently delete this session. This action cannot be undone.")
        }
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportAllData) {
                            Label("Export All Data", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: deleteAllSessions) {
                            Label("Delete All Sessions", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func deleteSession(_ session: Session) {
        withAnimation {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }
    
    private func deleteAllSessions() {
        // TODO: Show confirmation alert
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
    
    private func exportAllData() {
        // TODO: Implement data export functionality
        print("Export all data")
    }
}

struct SessionDetailRow: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.timestamp, style: .date)
                    .font(.headline)
                
                Spacer()
                
                if session.crisisDetected {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                
                if session.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Text(session.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(session.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !session.summary.isEmpty {
                Text(session.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            if let moodBefore = session.moodBefore, let moodAfter = session.moodAfter {
                HStack(spacing: 4) {
                    Text("Mood:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...moodBefore, id: \.self) { _ in
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...moodAfter, id: \.self) { _ in
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Session Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Details")
                            .font(.headline)
                        
                        InfoRow(label: "Date", value: session.timestamp.formatted(date: .long, time: .shortened))
                        InfoRow(label: "Duration", value: session.formattedDuration)
                        InfoRow(label: "Status", value: session.completed ? "Completed" : "Interrupted")
                        
                        if session.crisisDetected {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Crisis keywords detected")
                                    .foregroundColor(.orange)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Mood
                    if let moodBefore = session.moodBefore, let moodAfter = session.moodAfter {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(.headline)
                            
                            HStack {
                                VStack {
                                    Text("Before")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    MoodIndicator(level: moodBefore)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                VStack {
                                    Text("After")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    MoodIndicator(level: moodAfter)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Summary
                    if !session.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.headline)
                            
                            Text(session.summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Tags
                    if !session.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Topics")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(session.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

struct MoodIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= level ? color(for: level) : Color(.systemGray5))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func color(for level: Int) -> Color {
        switch level {
        case 1...2: return .red
        case 3: return .orange
        case 4: return .yellow
        case 5: return .green
        default: return .gray
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for size in sizes {
            if currentRowWidth + size.width > proposal.width ?? .infinity {
                totalHeight += currentRowHeight + spacing
                currentRowWidth = size.width + spacing
                currentRowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        
        totalHeight += currentRowHeight
        return CGSize(width: proposal.width ?? currentRowWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: Session.self, inMemory: true)
    }
}
