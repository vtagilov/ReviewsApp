/// Модель, хранящая состояние вью модели.
struct ReviewsViewModelState {

    var reviewItems = [any TableCellConfig]()
    var reviewsCountItem = ReviewsCountCellConfig()
    var limit = 21
    var offset = 0
    var shouldLoad = true
    var isAllItemsLoaded = false
    
    var items: [any TableCellConfig] {
        isAllItemsLoaded ? reviewItems + [reviewsCountItem] : reviewItems
    }
}
