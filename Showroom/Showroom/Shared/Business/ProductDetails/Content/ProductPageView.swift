import Foundation
import UIKit
import SnapKit
import RxSwift

protocol ProductDescriptionViewInterface: class {
    var headerHeight: CGFloat { get }
    var calculatedHeaderHeight: CGFloat { get }
    var touchRequiredView: UIView { get } // view for which we want to disable uitapgesturerecognizer
}

protocol ProductPageViewDelegate: ViewSwitcherDelegate {
    func pageView(pageView: ProductPageView, willChangePageViewState newPageViewState: ProductPageViewState, animationDuration: Double?)
    func pageView(pageView: ProductPageView, didChangePageViewState newPageViewState: ProductPageViewState, animationDuration: Double?)
    func pageViewDidTapShareButton(pageView: ProductPageView)
}

enum ProductPageViewState {
    case Default
    case ContentVisible
    case ImageGallery
}

class ProductPageView: ViewSwitcher, UICollectionViewDelegateFlowLayout {
    private let defaultDescriptionTopMargin: CGFloat = 70
    private let descriptionDragVelocityThreshold: CGFloat = 200
    private static let defaultContentAnimationDuration = 0.4
    private let verticalButtonsContentMargin: CGFloat = 8
    
    private let containerView = UIView()
    private let imageCollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private let pageControl = VerticalPageControl()
    private let contentContainerView = UIView()
    private let buttonStackView = UIStackView()
    private let whishlistButton = UIButton()
    private let shareButton = UIButton()
    
    private let modelState: ProductPageModelState
    private let imageDataSource: ProductImageDataSource
    private let disposeBag = DisposeBag()
    
    private var contentTopConstraint: Constraint?
    private var currentTopContentOffset:CGFloat = 0
    private(set) var viewState: ProductPageViewState = .Default {
        didSet {
            imageCollectionView.scrollEnabled = viewState != .ContentVisible
            contentTopConstraint?.updateOffset(currentTopContentOffset)
            pageControl.alpha = viewState == .ImageGallery ? 0 : 1
            imageDataSource.state = viewState == .ImageGallery ? .FullScreen : .Default
        }
    }
    private weak var descriptionViewInterface: ProductDescriptionViewInterface?
    
    var currentImageIndex: Int {
        let pageHeight = imageCollectionView.frame.height
        return Int(imageCollectionView.contentOffset.y / pageHeight)
    }
    var contentInset: UIEdgeInsets?
    var contentGestureRecognizerEnabled = true {
        didSet {
            contentContainerView.gestureRecognizers?.forEach { $0.enabled = contentGestureRecognizerEnabled }
        }
    }
    weak var delegate: ProductPageViewDelegate? {
        didSet { switcherDelegate = delegate }
    }
    
    init(contentView: UIView, descriptionViewInterface: ProductDescriptionViewInterface, modelState: ProductPageModelState) {
        self.descriptionViewInterface = descriptionViewInterface
        self.modelState = modelState
        imageDataSource = ProductImageDataSource(collectionView: imageCollectionView)
        
        super.init(successView: containerView, initialState: modelState.product == nil ? .Loading : .Success)
        
        switcherDataSource = self
        
        modelState.productDetailsObservable.subscribeNext(updateProductDetails).addDisposableTo(disposeBag)
        configure(forProduct: modelState.product)
        
        let imageCollectionTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProductPageView.didTapOnImageCollectionView))
        imageCollectionTapGestureRecognizer.delegate = self
        
        let contentContainerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProductPageView.didTapOnDescriptionView))
        contentContainerTapGestureRecognizer.delegate = self
        
        imageCollectionView.backgroundColor = UIColor.clearColor()
        imageCollectionView.dataSource = imageDataSource
        imageCollectionView.delegate = self
        imageCollectionView.pagingEnabled = true
        imageCollectionView.showsVerticalScrollIndicator = false
        imageCollectionView.addGestureRecognizer(imageCollectionTapGestureRecognizer)
        let flowLayout = imageCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .Vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        pageControl.currentPage = 0
        
        contentContainerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(ProductPageView.didPanOnDescriptionView)))
        contentContainerView.addGestureRecognizer(contentContainerTapGestureRecognizer)
        
        buttonStackView.axis = .Horizontal
        buttonStackView.spacing = 10
        
        whishlistButton.setImage(UIImage(asset: .Ic_do_ulubionych), forState: .Normal)
        whishlistButton.setImage(UIImage(asset: .Ic_w_ulubionych), forState: .Selected)
        whishlistButton.applyCircleStyle()
        
        shareButton.setImage(UIImage(asset: .Ic_share), forState: .Normal)
        shareButton.addTarget(self, action: #selector(ProductPageView.didTapShareButton(_:)), forControlEvents: .TouchUpInside)
        shareButton.applyCircleStyle()
        
        buttonStackView.addArrangedSubview(whishlistButton)
        buttonStackView.addArrangedSubview(shareButton)
        
        contentContainerView.addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight)))
        contentContainerView.addSubview(contentView)
        
        containerView.addSubview(imageCollectionView)
        containerView.addSubview(pageControl)
        containerView.addSubview(contentContainerView)
        containerView.addSubview(buttonStackView)
        
        configureCustomConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(forProduct product: Product?) {
        guard let p = product else { return }
        imageDataSource.lowResImageUrl = p.lowResImageUrl
        imageDataSource.imageUrls = [p.imageUrl]
    }
    
    private func updateProductDetails(productDetails: ProductDetails?) {
        guard let p = productDetails else { return }
        
        imageDataSource.imageUrls = p.images.map { $0.url }
        pageControl.numberOfPages = imageDataSource.imageUrls.count
        pageControl.invalidateIntrinsicContentSize()
        
        let forceUpdate = calculateTopContentOffset(forViewState: viewState) != currentTopContentOffset
        changeViewState(viewState, animationDuration: 0.3, forceUpdate: forceUpdate)
    }
    
    func changeViewState(viewState: ProductPageViewState, animationDuration: Double? = defaultContentAnimationDuration, forceUpdate: Bool = false, completion: (() -> Void)? = nil) {
        if self.viewState == viewState && !forceUpdate { return }
        
        delegate?.pageView(self, willChangePageViewState: viewState, animationDuration: animationDuration)
        
        currentTopContentOffset = calculateTopContentOffset(forViewState: viewState)
        
        layoutIfNeeded()
        setNeedsLayout()
        UIView.animateWithDuration(animationDuration ?? 0, delay: 0, options: [.CurveEaseInOut], animations: {
            self.viewState = viewState
            self.layoutIfNeeded()
        }) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.pageView(strongSelf, didChangePageViewState: strongSelf.viewState, animationDuration: animationDuration)
            completion?()
        }
    }
    
    private func configureCustomConstraints() {
        imageCollectionView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentContainerView.snp_makeConstraints { make in
            contentTopConstraint = make.top.equalTo(contentContainerView.superview!.snp_bottom).constraint
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalToSuperview().offset(-defaultDescriptionTopMargin)
        }
        
        contentContainerView.subviews.forEach { view in
            view.snp_makeConstraints { make in make.edges.equalToSuperview() }
        }
        
        pageControl.snp_makeConstraints { make in
            make.centerY.equalToSuperview().offset(-50)
            make.leading.equalTo(10)
        }
        
        buttonStackView.snp_makeConstraints { make in
            make.trailing.equalToSuperview().inset(Dimensions.defaultMargin)
            make.bottom.equalTo(contentContainerView.snp_top).offset(-verticalButtonsContentMargin)
        }
        
        shareButton.snp_makeConstraints { make in
            make.width.equalTo(Dimensions.circleButtonDiameter)
            make.height.equalTo(shareButton.snp_width)
        }
        
        whishlistButton.snp_makeConstraints { make in
            make.width.equalTo(Dimensions.circleButtonDiameter)
            make.height.equalTo(whishlistButton.snp_width)
        }
    }
    
    private func calculateTopContentOffset(forViewState viewState: ProductPageViewState) -> CGFloat {
        switch viewState {
        case .Default:
            return -((descriptionViewInterface?.calculatedHeaderHeight ?? 0) + (contentInset?.bottom ?? 0))
        case .ContentVisible:
            return defaultDescriptionTopMargin - bounds.height
        case .ImageGallery:
            return verticalButtonsContentMargin + Dimensions.circleButtonDiameter
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.bounds.size
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl.currentPage = currentImageIndex
    }
}

extension ProductPageView {
    func didPanOnDescriptionView(panGestureRecognizer: UIPanGestureRecognizer) {
        let bottomOffset = (descriptionViewInterface?.headerHeight ?? 0) + (contentInset?.bottom ?? 0)
        let movableY = bounds.height - defaultDescriptionTopMargin - bottomOffset
        var moveY = panGestureRecognizer.translationInView(contentContainerView).y
        
        let contentVisible = viewState == .ContentVisible
        
        switch panGestureRecognizer.state {
        case .Changed:
            if contentVisible && moveY < 0 { moveY = 0 }
            else if contentVisible && moveY > movableY { moveY = movableY }
            else if !contentVisible && moveY > 0 { moveY = 0 }
            else if !contentVisible && moveY < -movableY { moveY = -movableY }
            
            let newOffset = contentVisible ? (defaultDescriptionTopMargin - bounds.height) + moveY: -bottomOffset + moveY
            self.contentTopConstraint?.updateOffset(newOffset)
        case .Ended:
            let movedMoreThanHalf = contentVisible && moveY > movableY * 0.5 || !contentVisible && moveY < -movableY * 0.5
            
            let yVelocity = panGestureRecognizer.velocityInView(contentContainerView).y
            let movedFasterForward = contentVisible && yVelocity > descriptionDragVelocityThreshold || !contentVisible && yVelocity < -descriptionDragVelocityThreshold
            let movedFasterBackward = contentVisible && yVelocity < -descriptionDragVelocityThreshold || !contentVisible && yVelocity > descriptionDragVelocityThreshold
            
            var newViewState = viewState
            if movedFasterForward || (movedMoreThanHalf && !movedFasterBackward) {
                newViewState = contentVisible ? .Default : .ContentVisible
            }
            
            changeViewState(newViewState, animationDuration: 0.2, forceUpdate: true)
        default: break
        }
    }
    
    func didTapOnDescriptionView(tapGestureRecognizer: UITapGestureRecognizer) {
        let contentVisible = viewState == .ContentVisible
        let newViewState: ProductPageViewState = contentVisible ? .Default : .ContentVisible
        changeViewState(newViewState)
    }
    
    func didTapOnImageCollectionView(tapGestureRecognizer: UITapGestureRecognizer) {
        switch viewState {
        case .Default:
            changeViewState(.ImageGallery)
        case .ContentVisible:
            changeViewState(.Default)
        case .ImageGallery:
            changeViewState(.Default)
        }
    }
    
    func didTapShareButton(sender: UIButton) {
        delegate?.pageViewDidTapShareButton(self)
    }
}

extension ProductPageView: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer.view == contentContainerView {
            if let touchHandlingDelegate = touch.view as? TouchHandlingDelegate {
                return !touchHandlingDelegate.shouldConsumeTouch(touch)
            }
            if let touchRequiredView = descriptionViewInterface?.touchRequiredView, let touchView = touch.view {
                return !touchView.isDescendantOfView(touchRequiredView)
            }
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tapGestureRecognizer = otherGestureRecognizer as? UITapGestureRecognizer where gestureRecognizer.view == imageCollectionView {
            return tapGestureRecognizer.numberOfTapsRequired == 2 && viewState == .ImageGallery
        }
        return false
    }
}

extension ProductPageView: ViewSwitcherDataSource {
    func viewSwitcherWantsErrorInfo(view: ViewSwitcher) -> (ErrorText, ErrorImage?) {
        return (tr(.CommonError), nil)
    }
}