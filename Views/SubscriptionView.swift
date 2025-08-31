import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var creditManager: CreditManager
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        featuresSection
                        pricingSection
                        subscribeButton
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Subscription Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Daily Light Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Unlimited Sacred Art Generation")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 20)
    }
    
    var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PREMIUM FEATURES")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
            
            FeatureRow(icon: "infinity", title: "Unlimited Generations", subtitle: "Create as many images as you want")
            FeatureRow(icon: "paintbrush.fill", title: "Exclusive Art Styles", subtitle: "Access premium artistic styles")
            FeatureRow(icon: "photo.on.rectangle.angled", title: "Unlimited Storage", subtitle: "Save all your generated images")
            FeatureRow(icon: "crown.fill", title: "Priority Generation", subtitle: "Faster image processing")
            FeatureRow(icon: "arrow.down.circle.fill", title: "HD Downloads", subtitle: "High resolution image exports")
            FeatureRow(icon: "xmark.circle.fill", title: "No Ads", subtitle: "Uninterrupted spiritual experience")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    var pricingSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 4) {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                Text("4.99")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("per month")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Cancel anytime")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 20)
    }
    
    var subscribeButton: some View {
        Button(action: subscribe) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Text("Start Free Trial")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }
    
    var termsSection: some View {
        VStack(spacing: 8) {
            Text("3-day free trial, then $4.99/month")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://dailylight.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://dailylight.app/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
    }
    
    func subscribe() {
        isProcessing = true
        
        Task {
            do {
                // For MVP, just simulate subscription
                // In production, integrate with StoreKit 2
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    creditManager.upgradeToPremium()
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Subscription failed. Please try again."
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}