import Foundation
import UIKit

class BrandDescriptionViewController: UIViewController, ExtendedViewController {
    private let brand: Brand
    
    private var castView: BrandDescriptionView { return view as! BrandDescriptionView }
    
    init(with brand: Brand) {
        self.brand = brand
        super.init(nibName: nil, bundle: nil)
        
        title = tr(.BrandAboutTitle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = BrandDescriptionView(with: brand)
    }
}