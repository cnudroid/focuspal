//
//  WeeklyEmailScheduler.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import UserNotifications

/// Protocol for weekly email summary service
protocol WeeklySummaryServiceProtocol {
    /// Generate a weekly summary for a specific child
    func generateSummary(for childId: UUID, weekStartDate: Date) async throws -> WeeklySummary

    /// Generate summaries for all children using the current week
    func generateSummariesForAllChildren() async throws -> [WeeklySummary]
}

// Extension to make WeeklySummaryService conform to protocol
extension WeeklySummaryService: WeeklySummaryServiceProtocol {}

/// Handles scheduling and sending of weekly email summaries
class WeeklyEmailScheduler {

    // MARK: - Constants

    private enum Constants {
        static let lastSentDateKey = "FocusPal.WeeklyEmail.LastSentDate"
        static let notificationIdentifier = "FocusPal.WeeklyEmail.Notification"
    }

    // MARK: - Properties

    private let summaryService: WeeklySummaryServiceProtocol
    private let contentBuilder: EmailContentBuilder
    private let emailService: EmailServiceProtocol
    private let parentRepository: ParentRepositoryProtocol
    private let userDefaults: UserDefaults
    private let notificationCenter: UNUserNotificationCenter

    // MARK: - Initialization

    init(
        summaryService: WeeklySummaryServiceProtocol,
        contentBuilder: EmailContentBuilder,
        emailService: EmailServiceProtocol,
        parentRepository: ParentRepositoryProtocol,
        userDefaults: UserDefaults = .standard,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.summaryService = summaryService
        self.contentBuilder = contentBuilder
        self.emailService = emailService
        self.parentRepository = parentRepository
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public Methods

    /// Schedule weekly email notification based on parent preferences
    func scheduleWeeklyEmail() async throws {
        // Get parent (assuming single parent for now)
        guard let parent = try await parentRepository.fetch() else { return }

        let preferences = parent.notificationPreferences

        guard preferences.weeklyEmailEnabled else {
            // Cancel existing notification if email is disabled
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [Constants.notificationIdentifier])
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "FocusPal Weekly Summary Ready"
        content.body = "Your weekly activity summary for your children is ready to view."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_EMAIL"

        // Create date components for trigger
        var dateComponents = DateComponents()
        dateComponents.weekday = preferences.weeklyEmailDay
        dateComponents.hour = preferences.weeklyEmailTime
        dateComponents.minute = 0

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: Constants.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        try await notificationCenter.add(request)
    }

    /// Send weekly email immediately
    func sendWeeklyEmailNow() async throws {
        // Get parent
        guard let parent = try await parentRepository.fetch() else { return }

        // Check if email is enabled
        guard shouldSendEmail(preferences: parent.notificationPreferences) else {
            return
        }

        // Generate summaries
        let summaries = try await summaryService.generateSummariesForAllChildren()

        // Build email content
        let subject: String
        if summaries.count == 1 {
            subject = contentBuilder.buildEmailSubject(
                childName: summaries[0].childName,
                weekEndDate: summaries[0].weekEndDate
            )
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = summaries.first.map { dateFormatter.string(from: $0.weekEndDate) } ?? ""
            subject = "FocusPal Weekly Summary - \(dateString)"
        }

        let body = contentBuilder.buildEmailBody(summaries: summaries)

        // Send email
        try await emailService.sendEmail(to: parent.email, subject: subject, body: body)

        // Update last sent date
        setLastSentDate(Date())
    }

    /// Check if email should be sent and send if due
    func checkAndSendIfDue() async {
        do {
            guard let parent = try await parentRepository.fetch() else { return }

            guard shouldSendEmail(preferences: parent.notificationPreferences) else {
                return
            }

            // Check if we should send based on schedule
            if shouldSendBasedOnSchedule(preferences: parent.notificationPreferences) {
                try await sendWeeklyEmailNow()
            }
        } catch {
            print("Error checking and sending weekly email: \(error)")
        }
    }

    /// Check if email should be sent based on preferences
    func shouldSendEmail(preferences: ParentNotificationPreferences) -> Bool {
        return preferences.weeklyEmailEnabled
    }

    /// Get the last sent date
    func getLastSentDate() -> Date? {
        return userDefaults.object(forKey: Constants.lastSentDateKey) as? Date
    }

    /// Set the last sent date
    func setLastSentDate(_ date: Date) {
        userDefaults.set(date, forKey: Constants.lastSentDateKey)
    }

    // MARK: - Private Methods

    /// Check if email should be sent based on schedule and last sent date
    private func shouldSendBasedOnSchedule(preferences: ParentNotificationPreferences) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Get current weekday and hour
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentHour = calendar.component(.hour, from: now)

        // Check if it's the right day and time
        guard currentWeekday == preferences.weeklyEmailDay,
              currentHour >= preferences.weeklyEmailTime else {
            return false
        }

        // Check if we already sent today
        if let lastSent = getLastSentDate() {
            let lastSentDay = calendar.startOfDay(for: lastSent)
            let today = calendar.startOfDay(for: now)

            if lastSentDay == today {
                return false // Already sent today
            }
        }

        return true
    }
}
