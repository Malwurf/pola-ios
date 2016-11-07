import Foundation

final class PromoSummaryViewController: UIViewController, PromoPageInterface, PromoSummaryViewDelegate {
    weak var pageDelegate: PromoPageDelegate?
    var shouldShowProgressViewInPauseState: Bool { return false }
    
    private var castView: PromoSummaryView { return view as! PromoSummaryView }
    private let promoSlideshow: PromoSlideshow
    
    var pageState: PromoPageState {
        didSet {
            guard pageState.focused != oldValue.focused else { return }
            logInfo("set focused: \(pageState.focused)")
            
            if pageState.focused {
                castView.startActions()
            } else {
                castView.stopActions()
            }
        }
    }
    
    init(with resolver: DiResolver, promoSlideshow: PromoSlideshow, pageState: PromoPageState) {
        self.promoSlideshow = promoSlideshow
        self.pageState = pageState
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PromoSummaryView(promoSlideshow: promoSlideshow)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        castView.delegate = self
    }
    
    // MARK:- PromoSummaryViewDelegate
    
    func promoSummaryDidTapRepeat(promoSummary: PromoSummaryView) {
        logInfo("Did tap repeat")
        let videoId = promoSlideshow.playlist[0].id
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryWatchAgain(videoId))
        let entry = PromoSlideshowEntry(id: videoId, link: nil)
        sendNavigationEvent(ShowPromoSlideshowEvent(entry: entry, transitionImageTag: nil))
    }
    
    func promoSummary(promoSummary: PromoSummaryView, didTapLink link: PromoSlideshowLink) {
        logInfo("Did tap link \(link)")
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryLinkClick(link.link))
        sendNavigationEvent(ShowItemForLinkEvent(link: link.link, title: link.text, productDetailsFromType: .Video, transitionImageTag: nil))
    }
    
    func promoSummary(promoSummary: PromoSummaryView, didTapPlayForVideo video: PromoSlideshowPlaylistItem) {
        logInfo("Did tap play video \(video)")
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryPlay(video.id))
        let entry = PromoSlideshowEntry(id: video.id, link: nil)
        sendNavigationEvent(ShowPromoSlideshowEvent(entry: entry, transitionImageTag: nil))
    }
    
    func promoSummaryDidTapNext(promoSummary: PromoSummaryView, withCurrentVideo video: PromoSlideshowPlaylistItem) {
        logInfo("Did tap next")
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryNextButton(video.id))
    }
    
    func promoSummaryDidTapPrevious(promoSummary: PromoSummaryView, withCurrentVideo video: PromoSlideshowPlaylistItem) {
        logInfo("Did tap previous")
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryPrevButton(video.id))
    }
    
    func promoSummaryDidAutoPlay(promoSummary: PromoSummaryView, forVideo video: PromoSlideshowPlaylistItem) {
        logInfo("Did auto play with video \(video)")
        logAnalyticsEvent(AnalyticsEventId.VideoSummaryAutoPlay(video.id))
        let entry = PromoSlideshowEntry(id: video.id, link: nil)
        sendNavigationEvent(ShowPromoSlideshowEvent(entry: entry, transitionImageTag: nil))
    }

    // MARK:- PromoPageInterface
    
    func didTapDismiss() {}
    
    func resetProgressState() {}
}
