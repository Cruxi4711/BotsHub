#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#Region (=== GUI generated by GuiBuilderPlus 1.2.0 ===)
Global $GWBotHub
Global $TabsParent, $MainTab, $ConsoleEdit, $RunInfosGroup, $RunsLabel, $FailuresLabel, $TimeLabel, $GoldLabel
Global $GoldItemsLabel, $ExperienceLabel, $ItemsLootedGroup, $GlacialStonesLabel, $ChunkOfDrakeFleshLabel
Global $SkaleFinsLabel, $WintersdayGiftsLabel, $DiessaChalicesLabel, $RinRelicsLabel, $MargoniteGemstoneLabel
Global $StygianGemstoneLabel, $TitanGemstoneLabel, $TormentGemstoneLabel, $TitlesGroup, $AsuraTitleLabel
Global $DeldrimorTitleLabel, $NornTitleLabel, $VanguardTitleLabel, $KurzickTitleLabel, $LuxonTitleLabel
Global $LightbringerTitleLabel, $SunspearTitleLabel, $RunOptionsTab, $GlobalOptionsGroup, $LoopRunsCheckbox
Global $HMCheckbox, $StoreUnidentifiedGoldItemsCheckbox, $IdentifyGoldItemsCheckbox, $SalvageItemsCheckbox
Global $SellItemsCheckbox, $ConsumableOptionsGroup, $ConsumeCupcakeCheckbox, $ConsumeCandyAppleCheckbox
Global $ConsumePumpkingPieSliceCheckbox, $ConsumeGoldenEggCheckbox, $ConsumeCandyCornCheckbox, $LootOptionsTab
Global $BaseLootOptionsGroup, $LootEverythingCheckbox, $LootNothingCheckbox, $LootRareMaterialsCheckbox
Global $LootBasicMaterialsCheckbox, $LootSalvageItemsCheckbox, $LootTomesCheckbox, $LootKeysCheckbox
Global $LootDyesCheckbox, $LootScrollsCheckbox, $RarityLootOptionsGroup, $LootWhiteItemsCheckbox, $LootBlueItemsCheckbox
Global $LootPurpleItemsCheckbox, $LootGoldItemsCheckbox, $FarmSpecificLootOptionsGroup, $GlacialStonesCheckbox
Global $MapPiecesCheckbox, $LootTrophiesCheckbox, $ConsumablesLootOptionGroup, $GoldenEggsCheckbox, $SparklersCheckbox
Global $ToTBagsCheckbox, $HoneycombCheckbox, $LunarTokensCheckbox, $CandyCaneShardsCheckbox, $FarmInfosTab
Global $CharacterBuild, $HeroBuildLabel, $LootComponentsTab, $GUITODO, $CharacterChoiceCombo, $FarmChoiceCombo
Global $StartButton, $FarmProgress

;------------------------------------------------------
; Title...........:	_guiCreate
; Description.....:	Create the main GUI
;------------------------------------------------------
Func _guiCreate()
	$GWBotHub = GUICreate("GW Bot Hub", 600, 450, 851, 263)

	$CharacterChoiceCombo = GUICtrlCreateCombo("No character selected", 10, 420, 136, 20)
	$FarmChoiceCombo = GUICtrlCreateCombo("Choose a farm", 155, 420, 136, 20)
	GUICtrlSetData($FarmChoiceCombo, "Tests|Vaettir", "Choose a farm")
	$StartButton = GUICtrlCreateButton("Start", 300, 420, 136, 21)
	GUICtrlSetOnEvent($StartButton, "GuiButtonHandler")
	GUISetOnEvent($GUI_EVENT_CLOSE, "GuiButtonHandler")
	$FarmProgress = GUICtrlCreateProgress(445, 420, 141, 21)

	$TabsParent = GUICtrlCreateTab(11, 9, 581, 401)

	$MainTab = GUICtrlCreateTabItem("Main")
	$ConsoleEdit = GUICtrlCreateEdit("", 21, 224, 271, 176)

	$RunInfosGroup = GUICtrlCreateGroup("Infos", 21, 39, 271, 176)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$RunsLabel = GUICtrlCreateLabel("Runs: 0", 31, 64, 246, 16)
	$FailuresLabel = GUICtrlCreateLabel("Failures: 0", 31, 84, 246, 16)
	$TimeLabel = GUICtrlCreateLabel("Time: 0", 31, 104, 246, 16)
	$GoldLabel = GUICtrlCreateLabel("Gold: 0", 31, 124, 246, 16)
	$GoldItemsLabel = GUICtrlCreateLabel("Gold Items: 0", 31, 144, 246, 16)
	$ExperienceLabel = GUICtrlCreateLabel("Experience: 0", 31, 164, 246, 16)

	$ItemsLootedGroup = GUICtrlCreateGroup("Items", 306, 39, 271, 241)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GlacialStonesLabel = GUICtrlCreateLabel("Glacial Stones: 0", 316, 64, 246, 16)
	$ChunkOfDrakeFleshLabel = GUICtrlCreateLabel("Chunk Of Drake Flesh: 0", 316, 84, 246, 16)
	$SkaleFinsLabel = GUICtrlCreateLabel("Skale Fins: 0", 316, 104, 246, 16)
	$WintersdayGiftsLabel = GUICtrlCreateLabel("Wintersday Gifts:", 316, 124, 246, 16)
	$DiessaChalicesLabel = GUICtrlCreateLabel("Diessa Chalices: 0", 316, 144, 246, 16)
	$RinRelicsLabel = GUICtrlCreateLabel("Rin Relics: 0", 316, 164, 246, 16)
	$MargoniteGemstoneLabel = GUICtrlCreateLabel("Margonite Gemstone: 0", 316, 184, 246, 16)
	$StygianGemstoneLabel = GUICtrlCreateLabel("Stygian Gemstone: 0", 315, 205, 246, 16)
	$TitanGemstoneLabel = GUICtrlCreateLabel("Titan Gemstone: 0", 314, 229, 246, 16)
	$TormentGemstoneLabel = GUICtrlCreateLabel("Torment Gemstone: 0", 315, 250, 246, 16)

	$TitlesGroup = GUICtrlCreateGroup("Titles", 306, 289, 271, 111)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$AsuraTitleLabel = GUICtrlCreateLabel("Asura: 0", 316, 314, 121, 16)
	$DeldrimorTitleLabel = GUICtrlCreateLabel("Deldrimor: 0", 316, 334, 121, 16)
	$NornTitleLabel = GUICtrlCreateLabel("Norn: 0", 316, 354, 121, 16)
	$VanguardTitleLabel = GUICtrlCreateLabel("Vanguard: 0", 316, 374, 121, 16)
	$KurzickTitleLabel = GUICtrlCreateLabel("Kurzick: 0", 446, 314, 116, 16)
	$LuxonTitleLabel = GUICtrlCreateLabel("Luxon: 0", 446, 334, 116, 16)
	$LightbringerTitleLabel = GUICtrlCreateLabel("Lightbringer: 0", 446, 354, 116, 16)
	$SunspearTitleLabel = GUICtrlCreateLabel("Sunspear: 0", 446, 374, 116, 16)

	$RunOptionsTab = GUICtrlCreateTabItem("Run options")

	$GlobalOptionsGroup = GUICtrlCreateGroup("Options", 21, 39, 271, 361)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$LoopRunsCheckbox = GUICtrlCreateCheckbox("Loop Runs", 31, 64, 156, 20)
	$HMCheckbox = GUICtrlCreateCheckbox("HM", 31, 94, 156, 20)
	$StoreUnidentifiedGoldItemsCheckbox = GUICtrlCreateCheckbox("Store Unidentified Gold Items", 31, 124, 156, 20)
	$IdentifyGoldItemsCheckbox = GUICtrlCreateCheckbox("Identify Gold Items", 31, 154, 156, 20)
	$SalvageItemsCheckbox = GUICtrlCreateCheckbox("Salvage items", 31, 184, 156, 20)
	$SellItemsCheckbox = GUICtrlCreateCheckbox("Sell Items", 31, 214, 156, 20)

	$ConsumableOptionsGroup = GUICtrlCreateGroup("Consumables to consume", 306, 39, 271, 361)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$ConsumeCupcakeCheckbox = GUICtrlCreateCheckbox("Cupcake", 316, 64, 156, 20)
	$ConsumeCandyAppleCheckbox = GUICtrlCreateCheckbox("Candy Apple", 316, 94, 156, 20)
	$ConsumePumpkingPieSliceCheckbox = GUICtrlCreateCheckbox("Pumpking Pie Slice", 316, 124, 156, 20)
	$ConsumeGoldenEggCheckbox = GUICtrlCreateCheckbox("Golden Egg", 316, 154, 156, 20)
	$ConsumeCandyCornCheckbox = GUICtrlCreateCheckbox("Candy Corn", 316, 184, 156, 20)

	$LootOptionsTab = GUICtrlCreateTabItem("Loot options")

	$BaseLootOptionsGroup = GUICtrlCreateGroup("Base Loot", 21, 39, 271, 176)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$LootEverythingCheckbox = GUICtrlCreateCheckbox("Loot everything", 31, 64, 96, 20)
	$LootNothingCheckbox = GUICtrlCreateCheckbox("Loot nothing", 31, 94, 96, 20)
	$LootRareMaterialsCheckbox = GUICtrlCreateCheckbox("Rare materials", 31, 124, 96, 20)
	$LootBasicMaterialsCheckbox = GUICtrlCreateCheckbox("Basic materials", 30, 155, 96, 20)
	$LootSalvageItemsCheckbox = GUICtrlCreateCheckbox("Salvage items", 151, 64, 111, 20)
	$LootTomesCheckbox = GUICtrlCreateCheckbox("Tomes", 151, 94, 111, 20)
	$LootKeysCheckbox = GUICtrlCreateCheckbox("Keys", 151, 154, 96, 20)
	$LootDyesCheckbox = GUICtrlCreateCheckbox("Dyes (other than black and white)", 31, 184, 231, 20)
	$LootScrollsCheckbox = GUICtrlCreateCheckbox("Scrolls", 151, 124, 111, 20)

	$RarityLootOptionsGroup = GUICtrlCreateGroup("Rarity Loot", 166, 224, 126, 176)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$LootWhiteItemsCheckbox = GUICtrlCreateCheckbox("White items", 176, 249, 106, 20)
	$LootBlueItemsCheckbox = GUICtrlCreateCheckbox("Blue items", 176, 279, 106, 20)
	$LootPurpleItemsCheckbox = GUICtrlCreateCheckbox("Purple items", 176, 309, 106, 20)
	$LootGoldItemsCheckbox = GUICtrlCreateCheckbox("Gold items", 176, 339, 106, 20)

	$FarmSpecificLootOptionsGroup = GUICtrlCreateGroup("Farm Specific", 23, 224, 136, 176)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GlacialStonesCheckbox = GUICtrlCreateCheckbox("Glacial Stones", 31, 249, 81, 20)
	$MapPiecesCheckbox = GUICtrlCreateCheckbox("Map pieces", 31, 279, 81, 20)
	$LootTrophiesCheckbox = GUICtrlCreateCheckbox("Trophies", 30, 310, 81, 20)

	$ConsumablesLootOptionGroup = GUICtrlCreateGroup("Consumables loot", 306, 39, 271, 361)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$SweetsCheckbox = GUICtrlCreateCheckbox("Sweets", 316, 64, 121, 20)
	$AlcoholCheckbox = GUICtrlCreateCheckbox("Alcohols", 446, 64, 121, 20)
	$FestiveItemsCheckbox = GUICtrlCreateCheckbox("Festive Items", 316, 94, 121, 20)
	$ToTBagsCheckbox = GUICtrlCreateCheckbox("ToT Bags", 316, 124, 121, 20)
	$LunarTokensCheckbox = GUICtrlCreateCheckbox("Lunar Tokens", 446, 124, 121, 20)
	$CandyCaneShardsCheckbox = GUICtrlCreateCheckbox("Candy Cane Shards", 446, 94, 121, 20)

	$FarmInfosTab = GUICtrlCreateTabItem("Farm infos")
	$CharacterBuild = GUICtrlCreateLabel("Character build:", 31, 54, 531, 26)
	$HeroBuildLabel = GUICtrlCreateLabel("Hero build:", 31, 94, 531, 26)
	$LootComponentsTab = GUICtrlCreateTabItem("Loot components")
	$GUITODO = GUICtrlCreateLabel("GUI TODO : (farm specific to Secret Lair of the Snowmen)Peppermint Candy Cane, Rainbow Candy Cane, Spiked Eggnog, Wintergreen Candy Cane, Yuletide Tonic (specific to Irontoe's lair) Dwarven Ale, Aged Dwarven Ale", 31, 94, 531, 26)
	GUICtrlCreateTabItem("")
EndFunc   ;==>_guiCreate
#EndRegion (=== GUI generated by GuiBuilderPlus 1.2.0 ===)

_main()

;------------------------------------------------------
; Title...........:	_main
; Description.....:	run the main program loop
;------------------------------------------------------
Func _main()
	_guiCreate()
	GUISetState(@SW_SHOWNORMAL)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop

			Case Else
				;
		EndSwitch
	WEnd
EndFunc   ;==>_main

