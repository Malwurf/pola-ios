import UIKit

class ScanCodeView: UIView {
    
    let logoImageView = UIImageView(image: R.image.logoIcon())
    let menuButton = UIButton(type: .custom)
    let flashButton = UIButton(type: .custom)
    let keyboardButton = UIButton(type: .custom)
    
    var buttonsVisible = true {
        didSet {
            let alpha = CGFloat(buttonsVisible ? 1.0 : 0.0)
            UIView.animate(withDuration: 0.3) {
                self.menuButton.alpha = alpha
                self.flashButton.alpha = alpha
                self.keyboardButton.alpha = alpha
            }
        }
    }
    
    private let dimView = UIImageView(image: R.image.gradientImage())

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(dimView)
        
        logoImageView.sizeToFit()
        addSubview(logoImageView)
                        
        flashButton.accessibilityLabel = R.string.localizable.accessibilityFlash()
        flashButton.setImage(R.image.flashIcon(), for: .normal)
        flashButton.setImage(R.image.flashSelectedIcon(), for: .selected)
        flashButton.sizeToFit()
        addSubview(flashButton)

        menuButton.accessibilityLabel = R.string.localizable.accessibilityInfo()
        menuButton.setImage(R.image.burgerIcon(), for: .normal)
        menuButton.sizeToFit()
        addSubview(menuButton)
        
        keyboardButton.accessibilityLabel = R.string.localizable.accessibilityWriteCode()
        keyboardButton.setImage(R.image.keyboardIcon(), for: .normal)
        keyboardButton.setImage(R.image.keyboardSelectedIcon(), for: .selected)
        keyboardButton.sizeToFit()
        addSubview(keyboardButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scanCodeMargin = CGFloat(15.0)

        dimView.frame = bounds
    
        let topY = topSafeAreaInset + scanCodeMargin
        keyboardButton.frameOrigin = CGPoint(x: scanCodeMargin, y: topY)
        
        flashButton.frameOrigin = CGPoint(
            x: scanCodeMargin,
            y: scanCodeMargin + keyboardButton.frame.maxY
        )
        
        menuButton.frameOrigin = CGPoint(
            x: bounds.width - scanCodeMargin - menuButton.bounds.width,
            y: topY
        )

        logoImageView.frameOrigin = CGPoint(
            x: (bounds.width / 2) - (logoImageView.bounds.width / 2),
            y: menuButton.frame.minY
                + (menuButton.bounds.height / 2)
                - (logoImageView.bounds.height / 2)
        )

    }

}
