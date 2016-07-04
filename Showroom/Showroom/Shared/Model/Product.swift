import Foundation
import Decodable

typealias MeasurementName = String
typealias FabricPercent = Int
typealias TimeInDays = Int

struct Product {
    let id: ObjectId
    let brand: String
    let name: String
    let basePrice: Money
    let price: Money
    let imageUrl: String
    let lowResImageUrl: String?
}

struct ProductListResult {
    let products: [ListProduct]
    let isLastPage: Bool
}

struct ListProduct {
    let id: ObjectId
    let brand: ProductBrand
    let name: String
    let basePrice: Money
    let price: Money
    let imageUrl: String
    let freeDelivery: Bool
    let premium: Bool
    let new: Bool
}

struct ProductDetails {
    let id: ObjectId
    let brand: ProductBrand
    let name: String
    let basePrice: Money
    let price: Money
    let images: [ProductDetailsImage]
    let colors: [ProductDetailsColor]
    let sizes: [ProductDetailsSize]
    let waitTime: TimeInDays
    let description: [String]
    let emarsysCategory: String
    let freeDelivery: Bool
}

struct ProductBrand {
    let id: ObjectId
    let name: String
}

struct ProductDetailsImage {
    let url: String
    let color: ObjectId?
}

enum ProductDetailsColorType: String {
    case RGB = "RGB"
    case Image = "Image"
}

struct ProductDetailsColor {
    let id: ObjectId
    let name: String
    let type: ProductDetailsColorType
    let value: String
    let sizes: [ObjectId]
}

struct ProductDetailsSize {
    let id: ObjectId
    let name: String
    let colors: [ObjectId]
    let measurements: [MeasurementName: String]
}

// MARK: - Decodable, Encodable

extension ProductListResult: Decodable {
    static func decode(json: AnyObject) throws -> ProductListResult {
        return try ProductListResult(
            products: json => "products",
            isLastPage: json => "isLastPage"
        )
    }
}

extension ListProduct: Decodable {
    static func decode(j: AnyObject) throws -> ListProduct {
        return try ListProduct(
            id: j => "id",
            brand: j => "store",
            name: j => "name",
            basePrice: j => "msrp",
            price: j => "price",
            imageUrl: j => "images" => "default" => "url",
            freeDelivery: j => "free_delivery",
            premium: j => "premium",
            new: j => "new"
        )
    }
}

extension ProductDetails: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> ProductDetails {
        return try ProductDetails(
            id: j => "id",
            brand: j => "store",
            name: j => "name",
            basePrice: j => "msrp",
            price: j => "price",
            images: j => "images" => "available",
            colors: j => "colors",
            sizes: j => "sizes",
            waitTime: j => "wait_time",
            description: j => "description",
            emarsysCategory: j => "emarsys_category",
            freeDelivery: j => "free_delivery"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSMutableDictionary = [
            "id": id,
            "store": brand.encode(),
            "name": name,
            "msrp": basePrice.amount,
            "price": price.amount,
            "images": ["available": images.map { $0.encode() } as NSArray] as NSDictionary,
            "colors": colors.map { $0.encode() } as NSArray,
            "sizes": sizes.map { $0.encode() } as NSArray,
            "wait_time": waitTime,
            "description": description as NSArray,
            "emarsys_category": emarsysCategory,
            "free_delivery": freeDelivery
        ]
        return dict
    }
}

extension ProductBrand: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> ProductBrand {
        return try ProductBrand(
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

extension ProductDetailsImage: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> ProductDetailsImage {
        return try ProductDetailsImage(
            url: j => "url",
            color: j =>? "color"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSMutableDictionary = [
            "url": url
        ]
        if color != nil { dict.setObject(color!, forKey: "color") }
        return dict
    }
}

extension ProductDetailsColor: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> ProductDetailsColor {
        return try ProductDetailsColor(
            id: j => "id",
            name: j => "name",
            type: j => "type",
            value: j => "value",
            sizes: j => "sizes"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSDictionary = [
            "id": id,
            "name": name,
            "type": type.rawValue,
            "value": value,
            "sizes": sizes as NSArray
        ]
        return dict
    }
}

extension ProductDetailsColorType: Decodable {
    static func decode(j: AnyObject) throws -> ProductDetailsColorType {
        return ProductDetailsColorType(rawValue: j as! String)!
    }
}

extension ProductDetailsSize: Decodable, Encodable {
    static func decode(j: AnyObject) throws -> ProductDetailsSize {
        return try ProductDetailsSize(
            id: j => "id",
            name: j => "name",
            colors: j => "colors",
            measurements: j => "measurements"
        )
    }
    
    func encode() -> AnyObject {
        let dict: NSDictionary = [
            "id": id,
            "name": name,
            "colors": colors as NSArray,
            "measurements": measurements as NSDictionary
        ]
        return dict
    }
}

// MARK: - Equatable

extension ProductListResult: Equatable {}
extension ListProduct: Equatable {}
extension ProductDetails: Equatable {}
extension ProductBrand: Equatable {}
extension ProductDetailsImage: Equatable {}
extension ProductDetailsColor: Equatable {}
extension ProductDetailsColorType: Equatable {}
extension ProductDetailsSize: Equatable {}

func ==(lhs: ProductListResult, rhs: ProductListResult) -> Bool {
    return lhs.products == rhs.products && lhs.isLastPage == rhs.isLastPage
}

func ==(lhs: ListProduct, rhs: ListProduct) -> Bool {
    return lhs.id == rhs.id && lhs.brand == rhs.brand && lhs.basePrice == rhs.basePrice && lhs.price == rhs.price && lhs.imageUrl == rhs.imageUrl && lhs.freeDelivery == rhs.freeDelivery && lhs.new == rhs.new && lhs.premium == rhs.premium
}

func ==(lhs: ProductDetails, rhs: ProductDetails) -> Bool {
    return lhs.id == rhs.id && lhs.brand == rhs.brand && lhs.name == rhs.name && lhs.basePrice == rhs.basePrice && lhs.price == rhs.price && lhs.images == rhs.images && lhs.colors == rhs.colors && lhs.sizes == rhs.sizes && lhs.waitTime == rhs.waitTime && lhs.description == rhs.description && lhs.freeDelivery == rhs.freeDelivery
}

func ==(lhs: ProductBrand, rhs: ProductBrand) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

func ==(lhs: ProductDetailsImage, rhs: ProductDetailsImage) -> Bool {
    return lhs.color == rhs.color && lhs.url == rhs.url
}

func ==(lhs: ProductDetailsColor, rhs: ProductDetailsColor) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.sizes == rhs.sizes && lhs.type == rhs.type && lhs.value == rhs.value
}

func ==(lhs: ProductDetailsSize, rhs: ProductDetailsSize) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.colors == rhs.colors && lhs.measurements == rhs.measurements
}