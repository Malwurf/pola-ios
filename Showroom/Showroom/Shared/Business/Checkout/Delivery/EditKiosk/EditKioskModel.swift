import UIKit
import CoreLocation
import RxSwift

class EditKioskModel {
    private let api: ApiService
    private let geocoder = CLGeocoder()
    private let disposeBag = DisposeBag()
    let checkoutModel: CheckoutModel
    
    private let isoCountryCode = "PL"
    
    private(set) var kiosks: [Kiosk]?
    
    init(with api: ApiService, and checkoutModel: CheckoutModel) {
        self.api = api
        self.checkoutModel = checkoutModel
    }
    
    func fetchKiosks(withLatitude latitude: Double, longitude: Double, limit: Int = 10) -> Observable<KioskResult> {
        return api.fetchKiosks(withLatitude: latitude, longitude: longitude, limit: limit)
            .doOnNext { [weak self] in self?.kiosks = $0.kiosks }
            .observeOn(MainScheduler.instance)
    }
    
    func fetchKiosks(withAddressString addressString: String) -> Observable<KioskResult> {
        
        return geocoder.rx_geocodeAddressString(addressString)
            .flatMap { [weak self](placemarks: [CLPlacemark]) -> Observable<KioskResult> in
                guard let `self` = self else { return Observable.empty() }

                for placemark in placemarks {
                    guard placemark.ISOcountryCode == self.isoCountryCode else { continue }
                    let coordinates = placemark.location!.coordinate
                    return self.fetchKiosks(withLatitude: coordinates.latitude, longitude: coordinates.longitude)
                }
                return Observable.just(KioskResult(kiosks: []))
            }
    }
}