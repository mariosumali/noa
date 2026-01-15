import SwiftUI
import Combine

struct PromptItem: Identifiable, Codable {
    let id: String
    let text: String
    let response: String?
    let created_at: String
    let screenshot_url: String?
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var prompts: [PromptItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var backendURL: String { Config.shared.backendURL }
    
    func fetchHistory() async {
        await MainActor.run { isLoading = true; error = nil }
        
        do {
            let deviceId = APIClient.shared.getDeviceId()
            guard let url = URL(string: "\(backendURL)/api/prompts?device_id=\(deviceId)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Add auth token if available
            if let token = UserDefaults.standard.string(forKey: "noa_user_token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let result = try JSONDecoder().decode([PromptItem].self, from: data)
            
            await MainActor.run {
                self.prompts = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct HistoryView: View {
    @StateObject var historyManager = HistoryManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(historyManager.isLoading)
            }
            .padding(16)
            
            Divider()
            
            // Content
            if historyManager.isLoading && historyManager.prompts.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if let error = historyManager.error {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text("Failed to load history")
                        .font(.system(size: 14, weight: .medium))
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Button("Retry") { refresh() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.top, 8)
                }
                Spacer()
            } else if historyManager.prompts.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No prompts yet")
                        .font(.system(size: 14, weight: .medium))
                    Text("Hold Option and speak to get started")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(historyManager.prompts) { prompt in
                            HistoryItem(prompt: prompt)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            refresh()
        }
    }
    
    private func refresh() {
        Task {
            await historyManager.fetchHistory()
        }
    }
}

struct HistoryItem: View {
    let prompt: PromptItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User prompt
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("You")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(formatDate(prompt.created_at))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        if prompt.screenshot_url != nil {
                            Text("📷")
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text(prompt.text)
                        .font(.system(size: 13))
                }
            }
            
            // AI response
            if let response = prompt.response {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 20, height: 20)
                        
                        Text("n")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("noa")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                        
                        Text(response)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 30)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}
