import Foundation
import UIKit

protocol CheckoutSummaryViewDelegate: class {
    func checkoutSummaryView(view: CheckoutSummaryView, didTapAddCommentAt index: Int)
    func checkoutSummaryView(view: CheckoutSummaryView, didTapEditCommentAt index: Int)
    func checkoutSummaryView(view: CheckoutSummaryView, didTapDeleteCommentAt index: Int)
    func checkoutSummaryView(view: CheckoutSummaryView, didSelectPaymentAt index: Int)
    func checkoutSummaryViewDidTapBuy(view: CheckoutSummaryView)
}

final class CheckoutSummaryView: ViewSwitcher, UITableViewDelegate {
    private let dataSource: CheckoutSummaryDataSource
    private let contentView = UIView()
    private let tableView = UITableView(frame: CGRectZero, style: .Plain)
    private let buyButton = UIButton()
    
    weak var delegate: CheckoutSummaryViewDelegate?
    
    init(createPayUButton: CGRect -> UIView) {
        dataSource = CheckoutSummaryDataSource(tableView: tableView, createPayUButton: createPayUButton)
        super.init(successView: contentView, initialState: .Success)
        
        dataSource.summaryView = self;
        
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.separatorStyle = .None
        
        buyButton.enabled = false
        buyButton.setTitle(tr(.CheckoutSummaryBuy), forState: .Normal)
        buyButton.applyBlueStyle()
        buyButton.addTarget(self, action: #selector(CheckoutSummaryView.didTapBuy), forControlEvents: .TouchUpInside)
        
        backgroundColor = UIColor(named: .White)
        
        contentView.addSubview(tableView)
        contentView.addSubview(buyButton)
        
        configureCustomConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCustomConstraints() {
        tableView.snp_makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalTo(buyButton.snp_top)
        }
        
        buyButton.snp_makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Dimensions.bigButtonHeight)
        }
    }
    
    func updateData(with basket: Basket?, carrier deliveryCarrier: DeliveryCarrier?, discountCode: String?, comments: [String?]?) {
        guard let basket = basket else { return }
        guard let deliveryCarrier = deliveryCarrier else { return }
    
        dataSource.updateData(with: basket, carrier: deliveryCarrier, discountCode: discountCode, comments: comments)
    }
    
    func updateData(withComments comments: [String?]) {
        dataSource.updateData(withComments: comments)
    }
    
    func update(buyButtonEnabled enabled: Bool) {
        buyButton.enabled = enabled
    }
    
    func didTapBuy() {
        delegate?.checkoutSummaryViewDidTapBuy(self)
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return dataSource.heightForRow(at: indexPath)
    }
    
    // MARK: - Brand comments actions
    
    func checkoutSummaryCommentCellDidTapAddComment(at index: Int) {
        delegate?.checkoutSummaryView(self, didTapAddCommentAt: index)
    }
    
    func checkoutSummaryCommentCellDidTapEditComment(at index: Int) {
        delegate?.checkoutSummaryView(self, didTapEditCommentAt: index)
    }
    
    func checkoutSummaryCommentCellDidTapDeleteComment(at index: Int) {
        delegate?.checkoutSummaryView(self, didTapDeleteCommentAt: index)
    }
    
    func checkoutSummaryDidChangeToPayment(at index: Int) {
        delegate?.checkoutSummaryView(self, didSelectPaymentAt: index)
    }
}