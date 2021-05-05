import Vapor
import Foundation

final class TranslationAttempt {

    private var dates: [Date: NStackError] = [:]

    init(error: NStackError, date: Date = Date()) {
        append(date: date, error: error)
    }

    func append(date: Date, error: NStackError) {
        dates[date] = error
    }

    func avoidFetchingAgain(
        retryWaitingPeriodInSeconds: Double,
        notFoundWaitingPeriodInSeconds: Double
    ) -> Bool {
        let now = Date()
        let datePreRetryPeriod = now.addingTimeInterval(-retryWaitingPeriodInSeconds)
        let datePreNotFoundPeriod = now.addingTimeInterval(-notFoundWaitingPeriodInSeconds)

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
