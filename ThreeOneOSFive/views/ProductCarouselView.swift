import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

struct ProductCarouselView: View {
    let products: [Product] = []
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    @State private var offset: CGFloat = 0
    
    var body: some View {
        if !products.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("PREVIEW PRODUCTOS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                GeometryReader { geometry in
                    HStack(spacing: 16) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            ProductCardView(product: product)
                                .frame(width: geometry.size.width - 40)
                        }
                    }
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width > threshold && currentIndex > 0 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                    }
                                } else if value.translation.width < -threshold && currentIndex < products.count - 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                }
                            }
                    )
                    .onAppear {
                        startAutoScroll()
                    }
                    .onDisappear {
                        stopAutoScroll()
                    }
                    .onChange(of: currentIndex) { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = -CGFloat(currentIndex) * (geometry.size.width - 24)
                        }
                    }
                }
                .frame(height: 160)
                
                // Page indicators
                HStack(spacing: 6) {
                    ForEach(0..<products.count, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.vertical, 12)
        }
    }
    
    private func startAutoScroll() {
        guard !products.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                guard !products.isEmpty else { return }
                currentIndex = (currentIndex + 1) % products.count
            }
        }
    }
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
}

struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let uiImage = UIImage(named: product.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.red.opacity(0.8), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 140)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.5))
                    }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(product.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Image(systemName: "star.fill")
                        .font(.caption2)
                }
                .foregroundStyle(.yellow)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
