//
//  CardShareService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import UIKit

/// Service for generating shareable images from SwiftUI views
@MainActor
class CardShareService {

    // MARK: - Card Sizes

    enum CardSize {
        case square       // 540x540 - Social media (scaled down for memory)
        case story        // 540x960 - Stories (scaled down for memory)
        case twitter      // 600x338 - Twitter card (scaled down for memory)

        var size: CGSize {
            switch self {
            case .square: return CGSize(width: 540, height: 540)
            case .story: return CGSize(width: 540, height: 960)
            case .twitter: return CGSize(width: 600, height: 338)
            }
        }

        var scale: CGFloat {
            // Use 2x scale for crisp images (540*2 = 1080 final resolution)
            2.0
        }
    }

    // MARK: - Image Generation

    /// Generate a UIImage from a SwiftUI view
    @MainActor
    static func generateImage<V: View>(from view: V, size: CardSize) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.size.width, height: size.size.height))
        renderer.scale = size.scale

        return renderer.uiImage
    }

    /// Generate achievement badge card image
    @MainActor
    static func generateAchievementCard(
        achievement: AchievementDisplayItem,
        childName: String
    ) -> UIImage? {
        let card = ShareableAchievementCard(
            achievement: achievement,
            childName: childName
        )
        return generateImage(from: card, size: .square)
    }

    /// Generate achievement story card image (vertical)
    @MainActor
    static func generateAchievementStoryCard(
        achievement: AchievementDisplayItem,
        childName: String
    ) -> UIImage? {
        let card = ShareableAchievementCard(
            achievement: achievement,
            childName: childName,
            isStoryFormat: true
        )
        return generateImage(from: card, size: .story)
    }

    /// Generate weekly summary card image
    @MainActor
    static func generateWeeklyCard(
        childName: String,
        totalMinutes: Int,
        streak: Int,
        tier: RewardTier?,
        points: Int
    ) -> UIImage? {
        let card = ShareableWeeklyCard(
            childName: childName,
            totalMinutes: totalMinutes,
            streak: streak,
            tier: tier,
            points: points
        )
        return generateImage(from: card, size: .square)
    }

    // MARK: - Sharing

    /// Share images using UIActivityViewController
    static func share(images: [UIImage], from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: images,
            applicationActivities: nil
        )

        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        viewController.present(activityVC, animated: true)
    }

    /// Share a single image
    static func share(image: UIImage, from viewController: UIViewController) {
        share(images: [image], from: viewController)
    }
}
