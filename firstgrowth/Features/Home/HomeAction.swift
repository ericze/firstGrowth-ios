import Foundation

enum HomeAction {
    case onAppear
    case selectModule(HomeModule)
    case tapMilkEntry
    case tapDiaperEntry
    case tapSleepEntry
    case tapFoodEntry
    case tapOngoingSleep
    case dismissSheet
    case saveMilkPreset(Int)
    case adjustMilkCustom(Int)
    case saveCustomMilk
    case saveDiaper(DiaperSubtype)
    case finishSleep
    case saveFood
    case undoLastRecord
    case dismissUndo
    case loadMoreIfNeeded(UUID)
}
