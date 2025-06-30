/// Модель отзыва.
struct Review: Decodable {
    /// Имя пользователя.
    let first_name: String
    /// Фамилия пользователя.
    let last_name: String
    /// Рейтинг отзыва.
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let createdDateText: String
    /// Ссылка на аватар пользователя.
    let avatar_url: String?
    /// Ссылки на фото отзывов.
    let photo_urls: [String]

}
