//
//  ZoomableScrollVew.swift
//  QChat
//
//  Created by Trangptt on 17/12/25.
//
import SwiftUI
import UIKit


struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        // Khởi tạo UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator // Gán delegate để xử lý zoom
        scrollView.maximumZoomScale = 5.0 // Độ phóng to tối đa
        scrollView.minimumZoomScale = 1.0 // Độ thu nhỏ tối thiểu (gốc)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true // Hiệu ứng đàn hồi khi zoom quá đà
        scrollView.backgroundColor = .clear

        // Nhúng nội dung SwiftUI vào trong UIScrollView thông qua UIHostingController
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        scrollView.addSubview(hostedView)

        // Thiết lập constraints để nội dung nằm giữa và khớp với scrollview
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            // Giúp nội dung căn giữa khi chưa zoom
            hostedView.centerSubView.constraint(equalTo: scrollView.centerSubView)
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Cập nhật nội dung nếu cần thiết
        context.coordinator.hostingController.rootView = self.content
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }

    //cCoordinator để xử lý Delegate của UIScrollView
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        // Hàm quan trọng: Nói cho UIScrollView biết view nào sẽ được phóng to
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}

// Extension giúp căn giữa view trong scrollview
extension UIView {
    var centerSubView: NSLayoutYAxisAnchor {
        self.centerYAnchor
    }
}
