/// Модель, хранящая состояние вью модели.
struct ReviewsViewModelState {

    var reviewItems = [any TableCellConfig]()
    var reviewsCountItem = ReviewsCountCellConfig()
    var limit = 20
    var offset = 0
    var shouldLoad = true
    
    var items: [any TableCellConfig] {
        reviewItems + [reviewsCountItem]
    }
}
