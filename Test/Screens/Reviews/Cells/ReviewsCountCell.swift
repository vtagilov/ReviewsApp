import UIKit

/// Конфигурация ячейки
struct ReviewsCountCellConfig {
    static let reuseId = String(describing: ReviewsCountCellConfig.self)
    
    var countText: NSAttributedString
    
    fileprivate let layout = Layout()
    
    init(countText: NSAttributedString? = nil) {
        self.countText = countText ?? "0 отзывов".attributed(font: .reviewCount, color: .reviewCount)
    }
}

// MARK: - TableCellConfig

extension ReviewsCountCellConfig: TableCellConfig {
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewsCountCell else { return }
        cell.countLabel.attributedText = countText
        cell.config = self
    }
    
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
}

// MARK: - Cell

final class ReviewsCountCell: UITableViewCell {
    
    fileprivate var config: Config?
    
    fileprivate let countLabel = UILabel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        countLabel.frame = layout.countLabelFrame
    }
}

// MARK: - Private

private extension ReviewsCountCell {
    func setupCell() {
        contentView.addSubview(countLabel)
        countLabel.textAlignment = .center
    }
}

// MARK: - Layout

private final class ReviewsCountCellLayout {
    private(set) var countLabelFrame = CGRect.zero
    
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        let height = config.countText.boundingRect(width: width).height
        
        countLabelFrame = CGRect(
            x: insets.left,
            y: insets.top,
            width: width,
            height: height
        )
        return countLabelFrame.maxY + insets.bottom
    }
}

// MARK: - Typealias

fileprivate typealias Config = ReviewsCountCellConfig
fileprivate typealias Layout = ReviewsCountCellLayout
