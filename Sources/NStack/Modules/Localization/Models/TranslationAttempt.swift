import Vapor
import Foundation

final class TranslationAttempt {

    private var dates: [Date: NStackError] = [:]

    init(error: NStackError) {
        append(error: error)
    }

    func append(error: NStackError) {
        dates[Date()] = error
    }

    func avoidFetchingAgain(
        retryWaitingPeriodInMinutes: Double,
        notFoundWaitingPeriodInMinutes: Double
    ) -> Bool {
        let now = Date()
        let datePreRetryPeriod = now.addingTimeInterval(-retryWaitingPeriodInMinutes * 60)
        let datePreNotFoundPeriod = now.addingTimeInterval(-notFoundWaitingPeriodInMinutes * 60)

        for (date, error) in dates {

            // Any errors within few minutes should give a break in trying again
            if date.compare(datePreRetryPeriod) == .orderedDescending {
                return true
            }

            // Not found errors within few min should give a break in trying again
            if
                date.compare(datePreNotFoundPeriod) == .orderedDescending
                && error.status == .notFound
            {
                return true
            }
        }
        return false
    }
}
