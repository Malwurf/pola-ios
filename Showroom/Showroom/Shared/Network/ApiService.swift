import Foundation
import RxSwift

struct ApiService {
    let networkClient: NetworkClient
    
    var basePath: String {
        return Constants.baseUrl
    }
}

extension ApiService {
    func fetchContentPromo(withGender gender: Gender) -> Observable<ContentPromoResult> {
        let url = NSURL(fileURLWithPath: basePath)
            .URLByAppendingPathComponent("home")
            .URLByAppendingParams(["gender": gender.rawValue])
        
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "GET"
        return networkClient
            .request(withRequest: urlRequest)
            .flatMap { data -> Observable<ContentPromoResult> in
                do {
                    let array = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [AnyObject]
                    return Observable.just(try ContentPromoResult.decode(array))
                } catch {
                    return Observable.error(error)
                }
        }
    }
    
    func fetchProductDetails(withProductId productId: Int) -> Observable<ProductDetails> {
        let url = NSURL(fileURLWithPath: basePath)
            .URLByAppendingPathComponent("products")
            .URLByAppendingPathComponent(String(productId))
        
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "GET"
        return networkClient
            .request(withRequest: urlRequest)
            .flatMap { data -> Observable<ProductDetails> in
                do {
                    let result = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    return Observable.just(try ProductDetails.decode(result))
                } catch {
                    return Observable.error(error)
                }
        }
    }
}

extension NSURL {
    func URLByAppendingParams(params: [String: String]) -> NSURL {
        var url = self.absoluteString
        url += url.containsString("?") ? "&" : "?"
        for (key, value) in params {
            url += key + "=" + value + "&"
        }
        url = url.substringToIndex(url.endIndex.predecessor())
        return NSURL(string: url)!
    }
}