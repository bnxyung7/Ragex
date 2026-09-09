import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

struct ProductCarouselView: View {
    let products: [Product] = [
        Product(
            imageName: "product-holograma-arma",
            title: "Holograma Arma Rojo Negro",
            description: "Personaliza tu arma con este espectacular holograma rojo y negro. Impresiona a tus enemigos con un diseño único."
        )
    ]
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREVIEW PRODUCTOS")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            TabView(selection: $currentIndex) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    ProductCardView(product: product)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 280)
            .onAppear {
                startAutoScroll()
            }
            .onDisappear {
                stopAutoScroll()
            }
        }
        .padding(.vertical)
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
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
        VStack(spacing: 0) {
            // Image with fallback
            if let uiImage = UIImage(named: product.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.red, .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                    .overlay {
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.7))
                            Text(product.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .cornerRadius(12)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}
