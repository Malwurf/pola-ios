import Foundation

struct Constants {
    #if DEBUG
        static let isDebug = true
    #else
        static let isDebug = false
    #endif
    
    static let baseUrl = "https://api.showroom.pl/ios/v1"
    
    static let emarsysMerchantId = "13CE3A05D54F66DD"
    static let emarsysRecommendationItemsLimit: Int32 = 10
    static let basketProductAmountLimit: Int = 10
    static let productListPageSize: Int = 40
    
    struct Cache {
        static let contentPromoId = "ContentPromoId"
        static let productDetails = "ProductDetails"
        static let productRecommendationsId = "productRecommendationsId"
    }
    
    struct Persistent {
        static let basketStateId = "basketStateId"
    }
}