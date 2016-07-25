import Foundation
import RxSwift

final class SearchProductListModel: ProductListModel {
    private let emarsysService: EmarsysService
    private(set) var entrySearchInfo: EntrySearchInfo
    var query: String
    
    init(with searchEntryData: EntrySearchInfo, and apiService: ApiService, and emarsysService: EmarsysService) {
        self.entrySearchInfo = searchEntryData
        self.query = searchEntryData.query
        self.emarsysService = emarsysService
        super.init(with: apiService)
    }
    
    func update(with data: EntrySearchInfo) {
        self.entrySearchInfo = data
        self.query = data.query
    }
    
    override func createObservable(page: Int) -> Observable<ProductListResult> {
        if page == 1 {
            emarsysService.sendSearchEvent(withQuery: query)
        }
        return super.createObservable(page)
    }
}