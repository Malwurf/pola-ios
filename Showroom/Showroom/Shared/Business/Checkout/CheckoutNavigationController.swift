import UIKit

protocol CheckoutNavigationControllerDelegate: class {
    func checkoutWantsGoToMainScreen(checkout: CheckoutNavigationController)
    func checkoutWantsDismiss(checkout: CheckoutNavigationController)
}

class CheckoutNavigationController: UINavigationController, NavigationHandler {
    private let resolver: DiResolver
    private let model: CheckoutModel
    
    weak var checkoutDelegate: CheckoutNavigationControllerDelegate?
    
    init(with resolver: DiResolver, and checkout: Checkout) {
        self.resolver = resolver
        self.model = resolver.resolve(CheckoutModel.self, argument: checkout)
        super.init(nibName: nil, bundle: nil)
        
        navigationBar.applyWhiteStyle()
        
        let checkoutDeliveryViewController = resolver.resolve(CheckoutDeliveryViewController.self, argument: model)
        checkoutDeliveryViewController.navigationItem.title = tr(.CheckoutDeliveryNavigationHeader)
        checkoutDeliveryViewController.applyBlackCloseButton(target: self, action: #selector(CheckoutNavigationController.didTapCloseButton))
        checkoutDeliveryViewController.resetBackTitle()
        
        viewControllers = [checkoutDeliveryViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showSummaryView() {
        let summaryViewController = resolver.resolve(CheckoutSummaryViewController.self, argument: model)
        summaryViewController.navigationItem.title = tr(.CheckoutSummaryNavigationHeader)
        summaryViewController.resetBackTitle()
        pushViewController(summaryViewController, animated: true)
    }
    
    func showEditAddressView() {
        let editAddressViewController = resolver.resolve(EditAddressViewController.self, argument: model)
        editAddressViewController.delegate = self
        editAddressViewController.navigationItem.title = tr(.CheckoutDeliveryEditAddressNavigationHeader)
        editAddressViewController.resetBackTitle()
        pushViewController(editAddressViewController, animated: true)
    }
    
    func showEditKioskView(editKioskEntry editKioskEntry: EditKioskEntry?) {
        let editKioskViewController = resolver.resolve(EditKioskViewController.self, arguments: (model, editKioskEntry))
        editKioskViewController.delegate = self
        editKioskViewController.navigationItem.title = tr(.CheckoutDeliveryEditKioskNavigationHeader)
        editKioskViewController.resetBackTitle()
        pushViewController(editKioskViewController, animated: true)
    }
    
    func showPaymentSuccessView(orderId orderId: ObjectId, let orderUrl: String) {
        let successViewController = resolver.resolve(PaymentSuccessViewController.self, arguments: (orderId, orderUrl))
        pushViewController(successViewController, animated: true)
        setNavigationBarHidden(true, animated: true)
    }
    
    func showPaymentFailureView(orderId orderId: ObjectId, let orderUrl: String) {
        let failureViewController = resolver.resolve(PaymentFailureViewController.self, arguments: (orderId, orderUrl))
        pushViewController(failureViewController, animated: true)
        setNavigationBarHidden(true, animated: true)
    }
    
    func didTapCloseButton(sender: UIBarButtonItem) {
        logAnalyticsEvent(AnalyticsEventId.CheckoutCancelClicked)
        checkoutDelegate?.checkoutWantsDismiss(self)
    }
    
    func handleNavigationEvent(event: NavigationEvent) -> EventHandled {
        switch event {
        case let paymentSuccessEvent as ShowPaymentSuccessEvent:
            showPaymentSuccessView(orderId: paymentSuccessEvent.orderId, orderUrl: paymentSuccessEvent.orderUrl)
            return true
        case let paymentFailureEvent as ShowPaymentFailureEvent:
            showPaymentFailureView(orderId: paymentFailureEvent.orderId, orderUrl: paymentFailureEvent.orderUrl)
            return true
        case let showEditKioskEvent as ShowEditKioskEvent:
            showEditKioskView(editKioskEntry: showEditKioskEvent.editKioskEntry)
            return true
        case let simpleEvent as SimpleNavigationEvent:
            switch simpleEvent.type {
            case .ShowCheckoutSummary:
                showSummaryView()
                return true
            case .ShowDashboard:
                checkoutDelegate?.checkoutWantsGoToMainScreen(self)
                return true
            case .Close:
                checkoutDelegate?.checkoutWantsDismiss(self)
                return true
            case .ShowEditAddress:
                showEditAddressView()
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}

extension CheckoutNavigationController: EditKioskViewControllerDelegate {
    func editKioskViewControllerDidChooseKiosk(viewController: EditKioskViewController) {
        popViewControllerAnimated(true)
    }
}

// MARK: - EditAddressViewControllerDelegate

extension CheckoutNavigationController: EditAddressViewControllerDelegate {
    func editAddressViewControllerWantsDismiss(viewController: EditAddressViewController) {
        if let deliveryViewController = viewControllers.first as? CheckoutDeliveryViewController {
            deliveryViewController.markLastAddressOptionAsSelected()
        }
        popViewControllerAnimated(true)
    }
}