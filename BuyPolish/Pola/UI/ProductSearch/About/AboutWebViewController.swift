import UIKit

final class AboutWebViewController: UIViewController {
    private let url: String
    private var webView: UIWebView! {
        view as? UIWebView
    }

    init(url: String, title: String) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIWebView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = URL(string: url) else {
            return
        }
        webView.loadRequest(URLRequest(url: url))
        webView.delegate = self
    }
}

extension AboutWebViewController: UIWebViewDelegate {
    func webView(_: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if navigationType == .other {
            return true
        } else {
            if let url = request.url {
                UIApplication.shared.openURL(url)
            }
            return false
        }
    }
}
