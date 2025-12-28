//
//  RewardEntityMapper.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import CoreData

/// Extension to convert between WeeklyRewardEntity (Core Data) and WeeklyReward (Domain Model)
extension WeeklyRewardEntity {
    /// Creates a domain WeeklyReward model from Core Data entity
    func toDomainModel() -> WeeklyReward? {
        guard let id = id,
              let weekStartDate = weekStartDate,
              let weekEndDate = weekEndDate,
              let child = child,
              let childId = child.id else {
            return nil
        }

        // Convert tier from raw string
        let tier: RewardTier?
        if let tierRaw = tierRaw {
            tier = RewardTier(rawValue: tierRaw)
        } else {
            tier = nil
        }

        return WeeklyReward(
            id: id,
            childId: childId,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            totalPoints: Int(totalPoints),
            tier: tier,
            isRedeemed: isRedeemed,
            redeemedDate: redeemedDate
        )
    }

    /// Updates entity from domain model
    func update(from model: WeeklyReward) {
        self.id = model.id
        self.weekStartDate = model.weekStartDate
        self.weekEndDate = model.weekEndDate
        self.totalPoints = Int32(model.totalPoints)
        self.tierRaw = model.tier?.rawValue
        self.isRedeemed = model.isRedeemed
        self.redeemedDate = model.redeemedDate
    }
}

extension WeeklyReward {
    /// Creates a new Core Data entity from domain model
    /// - Parameters:
    ///   - context: The NSManagedObjectContext to create the entity in
    ///   - child: The parent ChildEntity
    /// - Returns: A new WeeklyRewardEntity
    func toEntity(context: NSManagedObjectContext, child: ChildEntity) -> WeeklyRewardEntity {
        let entity = WeeklyRewardEntity(context: context)
        entity.update(from: self)
        entity.child = child
        return entity
    }
}
