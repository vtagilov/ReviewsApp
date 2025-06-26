extension Int {
    /// Склоняет слово "отзыв" в зависимости от числа.
    var reviewsCountString: String {
        let mod10 = self % 10
        let mod100 = self % 100
        
        switch (mod10, mod100) {
        case (1, _) where mod100 != 11:
            return "\(self) отзыв"
        case (2...4, _) where !(12...14 ~= mod100):
            return "\(self) отзыва"
        default:
            return "\(self) отзывов"
        }
    }
}
