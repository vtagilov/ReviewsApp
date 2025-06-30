import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }
    
    /// Метод, вызываемый refreshControl.
    func refreshReviews(completion: @escaping () -> Void) {
        state.isAllItemsLoaded = false
        state.reviewItems = []
        state.shouldLoad = true
        state.offset = 0
        
        getReviews()
        completion()
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                let data = try result.get()
                let reviews = try self.decoder.decode(Reviews.self, from: data)
                
                let newItems = await withTaskGroup(of: (Int, ReviewItem).self) { group in
                    for (index, item) in reviews.items.enumerated() {
                        group.addTask {
                            let reviewItem = await self.makeReviewItem(item)
                            return (index, reviewItem)
                        }
                    }
                    
                    let unordered = await group.reduce(into: [(Int, ReviewItem)]()) { $0.append($1) }
                    return unordered.sorted { $0.0 < $1.0 }.map { $0.1 }
                }
                
                await MainActor.run {
                    self.state.reviewItems += newItems
                    self.state.reviewsCountItem.countText = reviews.count
                        .reviewsCountString
                        .attributed(font: .reviewCount, color: .reviewCount)
                    self.state.offset += self.state.limit
                    self.state.shouldLoad = self.state.offset < reviews.count
                    self.state.isAllItemsLoaded = !self.state.shouldLoad
                    self.onStateChange?(self.state)
                }
                
            } catch {
                await MainActor.run {
                    debugPrint("Failed to process reviews:", error.localizedDescription)
                    self.state.shouldLoad = true
                    self.onStateChange?(self.state)
                }
            }
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.reviewItems[index] = item
        onStateChange?(state)
    }
    
     func loadAvatarImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return nil
        }
        return await downloadImage(from: url)
    }
    
    func fetchImages(photoUrls: [String]) async -> [UIImage] {
        let validUrls = photoUrls.compactMap { URL(string: $0) }
        
        return await withTaskGroup(of: UIImage?.self) { group in
            for url in validUrls {
                group.addTask { return await self.downloadImage(from: url) }
            }
            
            return await group.reduce(into: []) { $0 += [$1].compactMap { $0 } }
        }
    }
    
    func downloadImage(from url: URL) async -> UIImage? {
        let key = url.absoluteString
        if let cachedImage = ImageCache.shared.image(forKey: key) {
            return cachedImage
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                ImageCache.shared.setImage(image, forKey: key)
                return image
            }
        } catch {
            debugPrint("Image download failed for \(url):", error.localizedDescription)
        }
        
        return nil
    }
}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) async -> ReviewItem {
        async let avatarImage = loadAvatarImage(from: review.avatar_url)
        async let photos = fetchImages(photoUrls: review.photo_urls)
        
        let nameText = "\(review.first_name) \(review.last_name)".attributed(font: .username)
        let reviewText = review.text.attributed(font: .text)
        let createdDateText = review.createdDateText.attributed(font: .created, color: .created)
        let onShowMoreTapped: (UUID) -> Void = { [weak self] UUID in
            guard let sSelf = self else { return }
            sSelf.showMoreReview(with: UUID)
        }
        
        let item = ReviewItem(
            nameText: nameText,
            rating: review.rating,
            reviewText: reviewText,
            createdDateText: createdDateText,
            avatarImage: await avatarImage,
            photos: await photos,
            onShowMoreTapped: onShowMoreTapped,
            ratingRenderer: ratingRenderer
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
