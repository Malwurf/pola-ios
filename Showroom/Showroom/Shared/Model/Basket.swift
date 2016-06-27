import Foundation
import Decodable

enum DeliveryType: Int {
    case UPS = 2
    case RUCH = 7
}

struct Basket: Equatable {
    var productsByBrands: [BasketBrand]
    var deliveryInfo: DeliveryInfo
    let discount: Money?
    let discountErrors: [String]?
    let basePrice: Money
    let price: Money
    
    var isEmpty: Bool {
        return productsByBrands.count == 0
    }
    
    var productsAmount: UInt {
        var count: UInt = 0
        for brand in productsByBrands {
            for product in brand.products {
                count += UInt(product.amount)
            }
        }
        return count
    }
    
    mutating func remove(product: BasketProduct) {
        guard let brandIndex = indexOfBrand(containing: product) else {
            return
        }
        productsByBrands[brandIndex].remove(product)
        if productsByBrands[brandIndex].products.count == 0 {
            productsByBrands.removeAtIndex(brandIndex)
        }
    }
    
    mutating func add(product: BasketProduct, of brand: BasketBrand) {
        if let brandIndex = index(of: brand) {
            productsByBrands[brandIndex].add(product)
        } else {
            var newBrand = brand
            newBrand.removeAllProducts()
            newBrand.add(product)
            productsByBrands.append(newBrand)
        }
    }
    
    mutating func update(product: BasketProduct) {
        guard let brandIndex = indexOfBrand(containing: product) else {
            return
        }
        productsByBrands[brandIndex].update(product)
    }
    
    private func index(of brand: BasketBrand) -> Int? {
        return productsByBrands.indexOf({ $0.isEqualInBasket(to: brand) })
    }
    
    private func indexOfBrand(containing product: BasketProduct) -> Int? {
        return productsByBrands.indexOf({ $0.products.contains({ $0.isEqualInBasket(to: product) }) })
    }
}

struct BasketBrand: Equatable {
    let id: Int
    let name: String
    let shippingPrice: Money
    let waitTime: Int
    var products: [BasketProduct] = []
    
    init(id: Int, name: String, shippingPrice: Money, waitTime: Int, products: [BasketProduct]) {
        self.id = id
        self.name = name
        self.shippingPrice = shippingPrice
        self.waitTime = waitTime
        self.products = products
    }
    
    init(id: Int, name: String, waitTime: Int) {
        self.id = id
        self.name = name
        self.shippingPrice = Money()
        self.waitTime = waitTime
    }
    
    init(from product: ProductDetails) {
        self.id = product.brand.id
        self.name = product.brand.name
        self.shippingPrice = Money()
        self.waitTime = product.waitTime
    }
    
    mutating func remove(product: BasketProduct) {
        guard let productIndex = index(of: product) else {
            return
        }
        products.removeAtIndex(productIndex)
    }
    
    mutating func add(product: BasketProduct) {
        if let productIndex = index(of: product) {
            products[productIndex].amount += 1
        } else {
            products.append(product)
        }
    }
    
    mutating func update(product: BasketProduct) {
        guard let productIndex = index(of: product) else {
            return
        }
        products[productIndex] = product
    }
    
    mutating func removeAllProducts() {
        products.removeAll()
    }
    
    func isEqualInBasket(to brand: BasketBrand) -> Bool {
        return self.id == brand.id
    }
    
    func isEqualExceptProducts(to brand: BasketBrand) -> Bool {
        return self.id == brand.id
            && self.name == brand.name
            && self.shippingPrice == brand.shippingPrice
            && self.waitTime == brand.waitTime
    }
    
    private func index(of product: BasketProduct) -> Int? {
        return products.indexOf { $0.isEqualInBasket(to: product) }
    }
}

struct BasketProduct: Equatable {
    let id: Int
    let name: String
    let imageUrl: String
    let size: BasketProductSize
    let color: BasketProductColor
    let basePrice: Money
    let price: Money
    var amount: Int = 1
    
    init (id: Int, name: String, imageUrl: String, size: BasketProductSize, color: BasketProductColor, basePrice: Money, price: Money, amount: Int) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.size = size
        self.color = color
        self.basePrice = basePrice
        self.price = price
        self.amount = amount
    }
    
    init (id: Int, name: String, imageUrl: String, size: BasketProductSize, color: BasketProductColor, basePrice: Money, price: Money) {
        self.init(id: id, name: name, imageUrl: imageUrl, size: size, color: color, basePrice: basePrice, price: price, amount: 1)
    }
    
    func isEqualInBasket(to product: BasketProduct) -> Bool {
        return self.id == product.id && self.color.id == product.color.id && self.size.id == product.size.id
    }
}

struct BasketProductColor: Equatable {
    let id: Int
    let name: String
    
    init(id: Int, name: String){
        self.id = id
        self.name = name
    }
    
    init(from color: ProductDetailsColor) {
        self.id = color.id
        self.name = color.name
    }
}

struct BasketProductSize: Equatable {
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    init(from size: ProductDetailsSize) {
        self.id = size.id
        self.name = size.name
    }
}

struct DeliveryInfo: Equatable {
    let defaultCountry: DeliveryCountry
    let availableCountries: [DeliveryCountry]
    let carriers: [DeliveryCarrier]
}

struct DeliveryCountry: Equatable {
    let id: String
    let name: String
}

struct DeliveryCarrier: Equatable {
    let id: DeliveryType
    let name: String
    let deliveryCost: Money?
    let available: Bool
    let isDefault: Bool
}

// MARK: - Operators handling
func == (lhs: Basket, rhs: Basket) -> Bool {
    return lhs.productsByBrands == rhs.productsByBrands
        && lhs.deliveryInfo == rhs.deliveryInfo
        && lhs.discount == rhs.discount
        && lhs.basePrice == rhs.basePrice
        && lhs.price == rhs.price
        && lhs.discountErrors == rhs.discountErrors
}

func == (lhs: DeliveryInfo, rhs: DeliveryInfo) -> Bool {
    return lhs.defaultCountry == rhs.defaultCountry && lhs.availableCountries == rhs.availableCountries && lhs.carriers == rhs.carriers
}

func == (lhs: DeliveryCountry, rhs: DeliveryCountry) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

func == (lhs: DeliveryCarrier, rhs: DeliveryCarrier) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.deliveryCost == rhs.deliveryCost && lhs.available == rhs.available && lhs.isDefault == rhs.isDefault
}

func == (lhs: BasketBrand, rhs: BasketBrand) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.shippingPrice == rhs.shippingPrice
        && lhs.waitTime == rhs.waitTime
        && lhs.products == rhs.products
}

func == (lhs: BasketProduct, rhs: BasketProduct) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.imageUrl == rhs.imageUrl
        && lhs.size == rhs.size
        && lhs.color == rhs.color
        && lhs.basePrice == rhs.basePrice
        && lhs.amount == rhs.amount
}

func == (lhs: BasketProductColor, rhs: BasketProductColor) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

func == (lhs: BasketProductSize, rhs: BasketProductSize) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

// MARK: - Decodable, Encodable
extension Basket: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> Basket {
        let discount: Money = try j => "coupon" => "discount"
        let errors: [String] = try j => "coupon" => "errors"
        return try Basket(
            productsByBrands: j => "bags",
            deliveryInfo: j => "delivery",
            discount: discount == Money(amt: 0.0) ? nil : discount,
            discountErrors: errors.count == 0 ? nil : errors,
            basePrice: j => "total" => "msrp",
            price: j => "total" => "price"
        )
    }
    
    func encode() -> AnyObject {
        let brandsArray: NSMutableArray = []
        for brand in productsByBrands {
            brandsArray.addObject(brand.encode())
        }
        
        let totalDict: NSMutableDictionary = [
            "msrp": basePrice.amount,
            "price": price.amount
        ]
        
        let dict: NSMutableDictionary = [
            "bags": brandsArray,
            "delivery": deliveryInfo.encode(),
            "total": totalDict,
            "coupon": [
                "discount": discount?.amount ?? 0,
                "errors": (discountErrors ?? []) as NSArray
            ] as NSDictionary
        ]
        return dict
    }
}

extension BasketBrand: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> BasketBrand {
        let productsArray: [AnyObject] = try j => "items" as! [AnyObject]
        return try BasketBrand(
            id: j => "store" => "id",
            name: j => "store" => "name",
            shippingPrice: j => "delivery_cost",
            waitTime: j => "wait_time",
            products: productsArray.map(BasketProduct.decode))
    }
    
    func encode() -> AnyObject {
        let brandDict: NSDictionary = [
            "id": id,
            "name": name
        ]
        
        let productsArray: NSMutableArray = []
        for product in products {
            productsArray.addObject(product.encode())
        }
        let dict: NSDictionary = [
            "store": brandDict,
            "delivery_cost": shippingPrice.amount,
            "wait_time": waitTime,
            "items": productsArray
        ]
        return dict
    }
}

extension BasketProduct: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> BasketProduct {
        return try BasketProduct(
            id: j => "product" => "id",
            name: j => "product" => "name",
            imageUrl: j => "product" => "images" => "default" => "url",
            size: j => "size",
            color: j => "color",
            basePrice: j => "product" => "msrp",
            price: j => "product" => "price",
            amount: j => "amount"
        )
    }
    
    func encode() -> AnyObject {
        let productDict: NSDictionary = [
            "id": id,
            "name": name,
            "price": price.amount,
            "msrp": basePrice.amount,
            "images": ["default": ["url" : imageUrl] as NSDictionary] as NSDictionary
        ]
        
        let dict: NSMutableDictionary = [
            "product": productDict,
            "amount": amount,
            "size": size.encode(),
            "color": color.encode()
        ]
        return dict
    }
}

extension BasketProductSize: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> BasketProductSize {
        return try BasketProductSize(
            id: j => "id",
            name: j => "name"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSDictionary = [
            "id": id,
            "name": name
        ]
        return dict
    }
}

extension BasketProductColor: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> BasketProductColor {
        return try BasketProductColor(
            id: j => "id",
            name: j => "name"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSDictionary = [
            "id": id,
            "name": name
        ]
        return dict
    }
}

extension DeliveryInfo: Decodable, Encodable {
    static func decode(json: AnyObject) throws -> DeliveryInfo {
        return try DeliveryInfo(
            defaultCountry: json => "countries" => "default",
            availableCountries: json => "countries" => "available",
            carriers: json => "carriers"
        )
    }
    
    func encode() -> AnyObject {
        let countries: NSMutableArray = []
        for country in availableCountries {
            countries.addObject(country.encode())
        }
        
        let carriers: NSMutableArray = []
        for carrier in self.carriers {
            carriers.addObject(carrier.encode())
        }
        
        return [
            "countries": [
                "default": defaultCountry.encode(),
                "available": countries
            ] as NSDictionary,
            "carriers": carriers
        ] as NSDictionary
    }
}

extension DeliveryCountry: Decodable, Encodable {
    static func decode(json: AnyObject) throws -> DeliveryCountry {
        return try DeliveryCountry(
            id: json => "id",
            name: json => "name"
        )
    }
    
    func encode() -> AnyObject {
        return [
            "id": id,
            "name": name
        ] as NSDictionary
    }
}

extension DeliveryCarrier: Decodable, Encodable {
    static func decode(json: AnyObject) throws -> DeliveryCarrier {
        return try DeliveryCarrier(
            id: DeliveryType(rawValue: json => "id")!,
            name: json => "name",
            deliveryCost: json =>? "delivery_cost",
            available: json => "available",
            isDefault: json => "default"
        )
    }
    
    func encode() -> AnyObject {
        let dict = [
            "id": id.rawValue,
            "name": name,
            "available": available,
            "default": isDefault
            ] as NSMutableDictionary
        if deliveryCost != nil { dict.setObject(deliveryCost!.amount, forKey: "delivery_cost") }
        return dict
    }
}