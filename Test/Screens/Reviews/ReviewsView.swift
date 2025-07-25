import UIKit

final class ReviewsView: UIView {

    let tableView = UITableView()
    let refreshControl = UIRefreshControl()
    let activityIndicator = UIActivityIndicatorView()
    
    var refreshControlAction: (() -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds.inset(by: safeAreaInsets)
    }

}

// MARK: - Private

private extension ReviewsView {

    func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupRefreshControl()
        setupActivityIndicator()
    }

    func setupTableView() {
        addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
        tableView.register(ReviewsCountCell.self, forCellReuseIdentifier: ReviewsCountCellConfig.reuseId)
    }
    
    func setupRefreshControl() {
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = .gray
        refreshControl.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.refreshControlAction?()
                    self?.tableView.reloadData()
                }),
            for: .valueChanged
        )
    }
    
    func setupActivityIndicator() {
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        activityIndicator.startAnimating()
    }

}
