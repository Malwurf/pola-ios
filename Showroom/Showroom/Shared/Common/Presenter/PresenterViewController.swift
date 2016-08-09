import Foundation
import UIKit

protocol PresenterContentChildProtocol {
    func presenterWillApear()
}

class PresenterViewController: UIViewController {
    var castView: PresenterView { return view as! PresenterView }
    private(set) var contentViewController: UIViewController?
    private(set) var currentModalViewController: UIViewController?
    
    override func loadView() {
        self.view = PresenterView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let contentViewController = self.contentViewController as? PresenterContentChildProtocol {
            contentViewController.presenterWillApear()
        }
    }
    
    final func showContent(viewController: UIViewController, animation: TransitionAnimation?, completion: ((Bool) -> ())?) {
        contentViewController?.willMoveToParentViewController(nil)
        addChildViewController(viewController)
        
        let innerCompletion: (Bool) -> () = { [weak self] _ in
            guard let `self` = self else { return }
            self.contentViewController?.removeFromParentViewController()
            viewController.didMoveToParentViewController(self)
            self.contentViewController = viewController
        }
        castView.showContent(viewController.view, customAnimation: animation?.show, completion: innerCompletion)
    }
    
    final func showModal(viewController: UIViewController, hideContentView: Bool, animation: TransitionAnimation?, completion: ((Bool) -> ())?) {
        guard currentModalViewController == nil else {
            completion?(false)
            return
        }
        
        let innerCompletion: (Bool) -> () = { [weak self] _ in
            viewController.didMoveToParentViewController(self)
            if hideContentView {
                self?.contentViewController?.willMoveToParentViewController(nil)
                self?.castView.contentHidden = true
                self?.contentViewController?.removeFromParentViewController()
            }
            completion?(true)
        }
        
        addChildViewController(viewController)
        self.currentModalViewController = viewController
        castView.showModal(viewController.view, customAnimation: animation?.show, completion: innerCompletion)
    }
    
    final func hideModal(animation animation: TransitionAnimation?, completion: ((Bool) -> ())?) {
        guard let currentModalViewController = currentModalViewController else {
            completion?(false)
            return
        }
        
        if let contentViewController = self.contentViewController where castView.contentHidden {
            addChildViewController(contentViewController)
            castView.contentHidden = false
            contentViewController.didMoveToParentViewController(self)
        }
        
        let innerCompletion: (Bool) -> () = { [weak self] _ in
            currentModalViewController.removeFromParentViewController()
            self?.currentModalViewController = nil
            completion?(true)
        }
        
        currentModalViewController.willMoveToParentViewController(nil)
        castView.hideModal(animation?.hide, completion: innerCompletion)
    }
}