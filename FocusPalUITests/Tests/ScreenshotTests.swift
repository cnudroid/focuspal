//
//  ScreenshotTests.swift
//  FocusPalUITests
//
//  Captures screenshots for App Store and marketing materials
//

import XCTest

class ScreenshotTests: BaseUITest {

    // MARK: - Screenshot Configuration

    override func setUp() {
        super.setUp()
        // Enable animations for prettier screenshots
        app.launchEnvironment.removeValue(forKey: "UITEST_DISABLE_ANIMATIONS")
        // Skip timer restoration for clean screenshots
        app.launchEnvironment["UITEST_SKIP_TIMER_RESTORE"] = "1"
    }

    // MARK: - Helper to dismiss any alerts

    private func dismissAnyAlerts() {
        // Dismiss "Timer Restored" or any other alerts
        let alertButtons = ["OK", "Continue", "Dismiss", "Got it"]
        for buttonName in alertButtons {
            let button = app.alerts.buttons[buttonName]
            if button.exists {
                button.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }

    private func launchAndPrepare() {
        launchWithSampleData()
        sleep(1)
        dismissAnyAlerts()
        sleep(1)
    }

    private func launchSingleChildAndPrepare() {
        launchWithSingleChild()
        sleep(1)
        dismissAnyAlerts()
        sleep(1)
    }

    private func launchMultipleChildrenAndPrepare(count: Int) {
        launchWithMultipleChildren(count: count)
        sleep(1)
        dismissAnyAlerts()
        sleep(1)
    }

    // MARK: - Today Tab Screenshots

    func testScreenshot_TodayTab() {
        launchAndPrepare()

        // Ensure we're on the Today tab
        if app.tabBars.buttons["Today"].exists {
            app.tabBars.buttons["Today"].tap()
        }

        // Wait for content to load
        sleep(2)

        // Scroll to show task cards if they exist
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Scroll up to show mascot and top content
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "01-today-screen")
    }

    func testScreenshot_TodayTabWithTasks() {
        launchAndPrepare()

        // Navigate to Today tab
        if app.tabBars.buttons["Today"].exists {
            app.tabBars.buttons["Today"].tap()
        }

        // Wait for content to load
        sleep(2)

        // Look for task-related content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Scroll to show points summary and task cards
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "02-today-overview")
    }

    // MARK: - Timer Screenshots (via Timer Overlay)

    func testScreenshot_TimerClassic() {
        launchAndPrepare()

        // Tap Start Timer FAB to open timer overlay
        tapStartTimerButton()
        sleep(1)
        dismissAnyAlerts()
        sleep(1)

        takeScreenshot(named: "03-timer-classic")
    }

    func testScreenshot_TimerSpace() {
        launchAndPrepare()

        // Open timer overlay
        tapStartTimerButton()
        sleep(1)
        dismissAnyAlerts()

        // Open theme picker and select Space
        selectTimerTheme("Space Explorer")
        sleep(1)

        takeScreenshot(named: "04-timer-space")
    }

    func testScreenshot_TimerOcean() {
        launchAndPrepare()

        // Open timer overlay
        tapStartTimerButton()
        sleep(1)
        dismissAnyAlerts()

        // Open theme picker and select Ocean
        selectTimerTheme("Ocean Adventure")
        sleep(1)

        takeScreenshot(named: "05-timer-ocean")
    }

    // MARK: - Rewards Screenshots

    func testScreenshot_RewardsTab() {
        launchAndPrepare()

        if app.tabBars.buttons["Rewards"].exists {
            app.tabBars.buttons["Rewards"].tap()
        }

        // Wait for rewards content to load
        sleep(2)

        // Scroll to show tier progression
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "06-rewards-tiers")
    }

    func testScreenshot_BadgesView() {
        launchAndPrepare()

        if app.tabBars.buttons["Rewards"].exists {
            app.tabBars.buttons["Rewards"].tap()
        }

        sleep(2)

        // Tap on Badges segment if it exists
        let badgesButton = app.buttons["Badges"]
        if badgesButton.exists {
            badgesButton.tap()
            sleep(2)
        }

        // Scroll to show badges grid
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "07-badges")
    }

    // MARK: - Profile Screenshots

    func testScreenshot_ProfileSelection() {
        launchMultipleChildrenAndPrepare(count: 3)
        takeScreenshot(named: "08-profile-select")
    }

    // MARK: - Me Tab Screenshots

    func testScreenshot_MeTab() {
        launchAndPrepare()

        if app.tabBars.buttons["Me"].exists {
            app.tabBars.buttons["Me"].tap()
        }

        // Wait for Me tab content to load
        sleep(2)

        // Scroll to show profile customization options
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "09-me-tab")
    }

    // MARK: - Parent Dashboard Screenshots

    func testScreenshot_ParentDashboard() {
        launchAndPrepare()

        // Navigate to Me tab
        if app.tabBars.buttons["Me"].exists {
            app.tabBars.buttons["Me"].tap()
            sleep(2)
        }

        // Look for settings/parent button
        let settingsButton = app.buttons["gearshape.fill"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)

            // Enter PIN if required
            enterPIN("1234", using: app)
            sleep(2)
        }

        // Wait for parent dashboard content
        sleep(1)

        // Scroll to show dashboard stats
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(named: "10-parent-dashboard")
    }

    // MARK: - Daily Gift Screenshot

    func testScreenshot_DailyGift() {
        // Launch fresh to see daily gift
        app.launchEnvironment["UITEST_SHOW_DAILY_GIFT"] = "1"
        launchAndPrepare()
        takeScreenshot(named: "11-daily-gift")
    }

    // MARK: - Helper Methods

    private func tapStartTimerButton() {
        // Try multiple ways to find the Start Timer button
        let startTimerButton = app.buttons["Start Timer"]
        if startTimerButton.exists {
            startTimerButton.tap()
            return
        }

        // Try finding by accessibility identifier
        let fabButton = app.buttons.matching(identifier: "startTimerFAB").firstMatch
        if fabButton.exists {
            fabButton.tap()
            return
        }

        // Try finding any button with timer-related text
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.label.contains("Timer") || button.label.contains("Start") {
                button.tap()
                return
            }
        }
    }

    private func selectTimerTheme(_ themeName: String) {
        // Find theme picker button (paintbrush icon)
        let themeButtons = ["paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill"]
        for buttonName in themeButtons {
            let button = app.buttons[buttonName]
            if button.exists {
                button.tap()
                Thread.sleep(forTimeInterval: 0.5)
                break
            }
        }

        // Select theme
        let themeButton = app.buttons[themeName]
        if themeButton.exists {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Run All Screenshots

    func testCaptureAllScreenshots() {
        // This test runs through all screens and captures screenshots
        print("Starting screenshot capture...")

        // Capture Today - with task cards and mascot
        launchWithSampleData()
        sleep(2)
        dismissAnyAlerts()

        // Navigate to Today tab
        if app.tabBars.buttons["Today"].exists {
            app.tabBars.buttons["Today"].tap()
        }
        sleep(2)

        // Scroll to show mascot and tasks
        let todayScrollView = app.scrollViews.firstMatch
        if todayScrollView.exists {
            todayScrollView.swipeDown()
            sleep(1)
        }
        takeScreenshot(named: "today-screen")

        // Capture Timer - Classic theme
        tapStartTimerButton()
        sleep(2)
        dismissAnyAlerts()
        takeScreenshot(named: "timer-classic")

        // Switch to Space theme
        selectTimerTheme("Space Explorer")
        sleep(1)
        takeScreenshot(named: "timer-space")

        // Switch to Ocean theme
        selectTimerTheme("Ocean Adventure")
        sleep(1)
        takeScreenshot(named: "timer-ocean")

        // Dismiss timer overlay (tap X or swipe down)
        dismissTimerOverlay()
        sleep(1)

        // Capture Rewards
        if app.tabBars.buttons["Rewards"].exists {
            app.tabBars.buttons["Rewards"].tap()
            sleep(2)

            // Scroll to show tier progression
            let rewardsScrollView = app.scrollViews.firstMatch
            if rewardsScrollView.exists {
                rewardsScrollView.swipeDown()
                sleep(1)
            }
            takeScreenshot(named: "rewards-tiers")

            let badgesButton = app.buttons["Badges"]
            if badgesButton.exists {
                badgesButton.tap()
                sleep(2)
                takeScreenshot(named: "badges")
            }
        }

        // Capture Me tab
        if app.tabBars.buttons["Me"].exists {
            app.tabBars.buttons["Me"].tap()
            sleep(2)

            // Scroll to show profile content
            let meScrollView = app.scrollViews.firstMatch
            if meScrollView.exists {
                meScrollView.swipeDown()
                sleep(1)
            }
            takeScreenshot(named: "me-tab")
        }

        print("Screenshot capture complete!")
    }

    private func dismissTimerOverlay() {
        // Try X button first
        let closeButtons = ["xmark", "xmark.circle", "xmark.circle.fill", "Close", "Done"]
        for buttonName in closeButtons {
            let button = app.buttons[buttonName]
            if button.exists {
                button.tap()
                return
            }
        }

        // Swipe down to dismiss
        app.swipeDown()
    }
}
