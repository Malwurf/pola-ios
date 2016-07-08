import Foundation
import UIKit
import RxSwift

protocol ProductListViewControllerInterface: class, NavigationSender, ExtendedViewController {
    var disposeBag: DisposeBag { get }
    var productListModel: ProductListModel { get }
    var productListView: ProductListViewInterface { get }
    
    func fetchFirstPage()
    func fetchNextPage()
    func pageWasFetched(result productListResult: ProductListResult, page: Int) //it is used to inform viewcontroller that first page has been fetched. You can do some additional stuff here
}

extension ProductListViewControllerInterface {
    func fetchFirstPage() {
        productListView.switcherState = .Loading
        let onNext = { [weak self] (result: FetchResult<ProductListResult>) in
            guard let `self` = self else { return }
            switch result {
            case .Success(let productListResult):
                logInfo("Received first product list page \(productListResult)")
                self.pageWasFetched(result: productListResult, page: self.productListModel.currentPageIndex)
                self.productListView.updateData(productListResult.products, nextPageState: productListResult.isLastPage ? .LastPage : .Fetching)
                self.productListView.switcherState = productListResult.products.isEmpty ? .Empty : .Success
            case .NetworkError(let error):
                logInfo("Failed to receive first product list page \(error)")
                self.productListView.switcherState = .Error
            }
        }
        
        productListModel.fetchFirstPage().subscribeNext(onNext).addDisposableTo(disposeBag)
    }
    
    func fetchNextPage() {
        let onNext = { [weak self] (result: FetchResult<ProductListResult>) in
            guard let `self` = self else { return }
            switch result {
            case .Success(let productListResult):
                logInfo("Received next product list page \(productListResult)")
                self.pageWasFetched(result: productListResult, page: self.productListModel.currentPageIndex)
                self.productListView.appendData(productListResult.products, nextPageState: productListResult.isLastPage ? .LastPage : .Fetching)
            case .NetworkError(let error):
                logInfo("Failed to receive next product list page \(error)")
                self.productListView.updateNextPageState(.Error)
            }
        }
        
        productListModel.fetchNextProductPage().subscribeNext(onNext).addDisposableTo(disposeBag)
    }
    
    //call it in viewDidLoad
    func configureProductList() {
        productListModel.isBigScreen = UIScreen.mainScreen().bounds.width >= ProductListComponent.threeColumnsRequiredWidth
        productListModel.productIndexObservable.subscribeNext { [weak self] (index: Int) in
            self?.productListView.moveToPosition(forProductIndex: index, animated: false)
            }.addDisposableTo(disposeBag)
    }
}

extension ProductListViewDelegate where Self : ProductListViewControllerInterface {
    func productListViewDidReachPageEnd(listView: ProductListViewInterface) {
        fetchNextPage()
    }
    
    func productListViewDidTapRetryPage(listView: ProductListViewInterface) {
        productListView.updateNextPageState(.Fetching)
        fetchNextPage()
    }
    
    func productListView(listView: ProductListViewInterface, didTapProductAtIndex index: Int) {
        let imageWidth = productListView.productImageWidth
        let context = productListModel.createProductDetailsContext(withProductIndex: index, withImageWidth: imageWidth)
        sendNavigationEvent(ShowProductDetailsEvent(context: context))
    }
    
    func productListView(listView: ProductListViewInterface, didDoubleTapProductAtIndex index: Int) {
        //todo
    }
}