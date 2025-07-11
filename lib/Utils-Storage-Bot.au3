; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

#include-once

#include <SQLite.au3>
#include <SQLite.dll.au3>
#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'GWA2.au3'
#include 'Utils.au3'
#include 'Utils-Items_Modstructs.au3'
#include 'Utils-Debugger.au3'

Opt('MustDeclareVars', 1)

Global $SQLITE_DB

#Region Tables
; Those tables are built automatically and one is completed by the user
Global $TABLE_DATA_RAW = 'DATA_RAW'
Global $SCHEMA_DATA_RAW = ['batch', 'bag', 'slot', 'model_ID', 'type_ID', 'min_stat', 'max_stat', 'requirement', 'attribute_ID', 'name_string', 'OS', 'modstruct', 'quantity', 'value', 'rarity_ID', 'dye_color', 'ID']
							;address ? interaction ? model_file_id ? name enc ? desc enc ? several modstruct (4, 8 ?) - identifier, arg1, arg2

Global $TABLE_DATA_USER = 'DATA_USER'
Global $SCHEMA_DATA_USER = ['batch', 'bag', 'slot', 'rarity', 'type', 'requirement', 'attribute', 'value', 'name', 'OS', 'prefix', 'suffix', 'inscription', 'type_ID', 'model_ID', 'name_string', 'modstruct', 'dye_color', 'ID']

Global $TABLE_DATA_SALVAGE = 'DATA_SALVAGE'
Global $SCHEMA_DATA_SALVAGE = ['batch', 'model_ID', 'material', 'amount']

; Those 3 lookups are filled directly when database is created
Global $TABLE_LOOKUP_ATTRIBUTE = 'LOOKUP_ATTRIBUTE'
Global $SCHEMA_LOOKUP_ATTRIBUTE = ['attribute_ID', 'attribute']

Global $TABLE_LOOKUP_RARITY = 'LOOKUP_RARITY'
Global $SCHEMA_LOOKUP_RARITY = ['rarity_ID', 'rarity']

Global $TABLE_LOOKUP_TYPE = 'LOOKUP_TYPE'
Global $SCHEMA_LOOKUP_TYPE = ['type_ID', 'type']

; Those lookups are built from the data table filled by the user
Global $TABLE_LOOKUP_MODEL = 'LOOKUP_MODEL'
Global $SCHEMA_LOOKUP_MODEL = ['type_ID', 'model_ID', 'model_name', 'OS']

Global $TABLE_LOOKUP_UPGRADES = 'LOOKUP_UPGRADES'
Global $SCHEMA_LOOKUP_UPGRADES = ['OS', 'upgrade_type', 'weapon', 'effect', 'hexa', 'name', 'propagate']
#EndRegion Tables

;~ Main method from storage bot, does all the things : identify, deal with data, store, salvage
Func ManageInventory($STATUS)
	;SellEverythingToMerchant(DefaultShouldSellItem, True)
	ActiveInventoryManagement()
	Return 2
EndFunc


;~ Function to deal with inventory after farm
Func ActiveInventoryManagement()
	; Operations order :
	; 1-Store unid if desired
	; 2-Sort items
	; 3-Identify items
	; 4-Collect data
	; 5-Salvage
	; 6-Sell materials
	; 7-Sell items
	; 8-Buy ectos with excedent
	; 9-Store items
	If GUICtrlRead($GUI_Checkbox_StoreUnidentifiedGoldItems) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage(GetIsUnidentified)
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If GUICtrlRead($GUI_Checkbox_IdentifyGoldItems) == $GUI_CHECKED And HasUnidentifiedItems() Then
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		IdentifyAllItems()
	EndIf
	If GUICtrlRead($GUI_Checkbox_CollectData) == $GUI_CHECKED Then
		ConnectToDatabase()
		InitializeDatabase()
		CompleteModelLookupTable()
		CompleteUpgradeLookupTable()
		StoreAllItemsData()
		DisconnectFromDatabase()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SalvageItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		SalvageAllItems()
		If $BAG_NUMBER == 5 Then
			If MoveItemsOutOfEquipmentBag() > 0 Then SalvageAllItems()
		EndIf
		;SalvageInscriptions()
		;UpgradeWithSalvageInscriptions()
		;SalvageMaterials()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellMaterials) == $GUI_CHECKED And HasMaterials() Then
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		; If we have more than 60k, we risk running into the situation we can't sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		If HasBasicMaterials() Then SellMaterialsToMerchant()
		If HasRareMaterials() Then SellRareMaterialsToMerchant()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		; If we have more than 60k, we risk running into the situation we can't sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		SellEverythingToMerchant()
	EndIf
	If GUICtrlRead($GUI_CheckBox_StoreGold) == $GUI_CHECKED AND GetGoldCharacter() > 60000 And GetGoldStorage() < 100000 Then
		DepositGold(60000)
		Info('Deposited Gold')
		$TIMESDEPOSITED += 1
	EndIf
	If GUICtrlRead($GUI_Checkbox_BuyEctoplasm) == $GUI_CHECKED And GetGoldCharacter() > 10000 Then BuyRareMaterialFromMerchantUntilPoor($ID_Glob_of_Ectoplasm, 10000, $ID_Obsidian_Shard)
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage()
EndFunc


;~ Function to deal with inventory during farm
Func PassiveInventoryManagement()
	; Operations order :
	; 1-Check if we have at least 1 identification kit and 1 salvage kit
	; 2-If not, buy until we have 4 identification kits and 12 salvaged kits
	; 3-Sort items
	; 4-Identify items
	; 5-Salvage
	Local $superiorIdentificationKits = [$ID_Superior_Identification_Kit]
	Local $identificationKitsCount = GetInventoryKitCount($superiorIdentificationKits)
	Local $salvageKits = [$ID_Salvage_Kit, $ID_Salvage_Kit_2]
	Local $salvageKitsCount = GetInventoryKitCount($salvageKits)

	If GetInventoryKitCount($superiorIdentificationKits) < 1 Or GetInventoryKitCount($salvageKits) < 1 Then
		Info('Buying kits for passive inventory management')
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		; Since we are in EOTN, might as well clear inventory
		ActiveInventoryManagement()
		If 4 - $identificationKitsCount > 0 Then BuySuperiorIdentificationKitInEOTN(4 - $identificationKitsCount)
		If 12 - $salvageKitsCount > 0 Then BuySalvageKitInEOTN(12 - $salvageKitsCount)
		Return True
	EndIf
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	IdentifyAllItems(False)
	SalvageAllItems(False)
	If $BAG_NUMBER == 5 Then
		If MoveItemsOutOfEquipmentBag() > 0 Then SalvageAllItems(False)
	EndIf
	Return False
EndFunc


#Region Reading items data
;~ Read data from item at bagIndex and slot and print it in the console
Func ReadOneItemData($bagIndex, $slot)
	Info('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $output = GetOneItemData($bagIndex, $slot)
	If $output == '' Then Return
	Info($output)
EndFunc


;~ Read data from all items in inventory and print it in the console
Func ReadAllItemsData()
	Info('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $item, $output
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'slots')
			$output = GetOneItemData($bagIndex, $slot)
			If $output == '' Then ContinueLoop
			Info($output)
			RndSleep(50)
		Next
	Next
EndFunc


;~ Get data from an item into a string
Func GetOneItemData($bagIndex, $slot)
	Local $item = GetItemBySlot($bagIndex, $slot)
	Local $output = ''
	If DllStructGetData($item, 'ID') <> 0 Then
		$output &= $bagIndex & ';'
		$output &= $slot & ';'
		$output &= DllStructGetData($item, 'rarity') & ';'
		$output &= DllStructGetData($item, 'ModelID') & ';'
		$output &= DllStructGetData($item, 'ID') & ';'
		$output &= DllStructGetData($item, 'Type') & ';'
		$output &= GetOrDefault(GetItemAttribute($item) & ';', '')
		$output &= GetOrDefault(GetItemReq($item) & ';', '')
		$output &= GetOrDefault(GetItemMaxDmg($item) & ';', '')
		$output &= DllStructGetData($item, 'NameString') & ';'
		$output &= GetModStruct($item) & ';'
		$output &= DllStructGetData($item, 'quantity') & ';'
		$output &= GetOrDefault(DllStructGetData($item, 'Value') & ';', 0)
	EndIf
	Return $output
EndFunc
#EndRegion Reading items data


#Region Database
;~ Connect to the database storing information about items
Func ConnectToDatabase()
	_SQLite_Startup()
	If @error Then Exit MsgBox(16, 'SQLite Error', 'Failed to start SQLite')
	FileChangeDir(@ScriptDir)
	$SQLITE_DB = _SQLite_Open('data\items_database.db3')
	If @error Then Exit MsgBox(16, 'SQLite Error', 'Failed to open database: ' & _SQLite_ErrMsg())
	;_SQLite_SetSafeMode(False)
	Info('Opened database at ' & @ScriptDir & '\data\items_database.db3')
EndFunc


;~ Disconnect from the database
Func DisconnectFromDatabase()
	_SQLite_Close()
	_SQLite_Shutdown()
EndFunc


;~ Create tables and views and fill the ones that need it
Func InitializeDatabase()
	CreateTable($TABLE_LOOKUP_ATTRIBUTE, $SCHEMA_LOOKUP_ATTRIBUTE)
	CreateTable($TABLE_LOOKUP_RARITY, $SCHEMA_LOOKUP_RARITY)
	CreateTable($TABLE_LOOKUP_TYPE, $SCHEMA_LOOKUP_TYPE)

	CreateTable($TABLE_LOOKUP_MODEL, $SCHEMA_LOOKUP_MODEL)
	CreateTable($TABLE_LOOKUP_UPGRADES, $SCHEMA_LOOKUP_UPGRADES)

	CreateTable($TABLE_DATA_RAW, $SCHEMA_DATA_RAW)
	CreateTable($TABLE_DATA_USER, $SCHEMA_DATA_USER)

	Local $columnsTypeIsNumber[] = [True, False]
	If TableIsEmpty($TABLE_LOOKUP_TYPE) Then FillTable($TABLE_LOOKUP_TYPE, $columnsTypeIsNumber, $Item_Types_Double_Array)
	If TableIsEmpty($TABLE_LOOKUP_ATTRIBUTE) Then FillTable($TABLE_LOOKUP_ATTRIBUTE, $columnsTypeIsNumber, $Attributes_Double_Array)
	If TableIsEmpty($TABLE_LOOKUP_RARITY) Then FillTable($TABLE_LOOKUP_RARITY, $columnsTypeIsNumber, $Rarities_Double_Array)
EndFunc


;~ Create a table
Func CreateTable($tableName, $tableColumns, $ifNotExists = True)
	Local $query = 'CREATE TABLE '
	If $ifNotExists Then $query &= 'IF NOT EXISTS '
	$query &= $tableName & ' ('
	For $column in $tableColumns
		$query &= $column & ', '
	Next
	$query = StringLeft($query, StringLen($query) - 2)
	$query &= ');'
	SQLExecute($query)
EndFunc


;~ Drop a table
Func DropTable($tableName)
	Local $query = 'DROP TABLE IF EXISTS ' & $tableName & ';'
	SQLExecute($query)
EndFunc


;~ Fill a table with the given values (bidimensional array)
Func FillTable($table, Const ByRef $isNumber, Const ByRef $values)
	Local $query = 'INSERT INTO ' & $table & ' VALUES '
	For $i = 0 To UBound($values) - 1
		$query &= '('
		For $j = 0 To Ubound($values,2) - 1
			If $isNumber[$j] Then
				$query &= $values[$i][$j] & ', '
			Else
				$query &= "'" & $values[$i][$j] & "', "
			EndIf
		Next
		$query = StringLeft($query, StringLen($query) - 2)
		$query &= '), '
	Next

	$query = StringLeft($query, StringLen($query) - 2)
	$query &= ';'
	SQLExecute($query)
EndFunc


#Region Database Utils
;~ Returns true if a table exists
Func TableExists($table)
	Local $query, $queryResult, $row
	SQLQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='" & $table & "';", $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$lastBatchID = $row[0]
	WEnd
	Return $lastBatchID
EndFunc


;~ Returns true if a table is empty
Func TableIsEmpty($table)
	Local $query, $queryResult, $row, $rowCount
	SQLQuery('SELECT COUNT(*) FROM ' & $table & ';', $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$rowCount = $row[0]
	WEnd
	Return $rowCount == 0
EndFunc


;~ Query database
Func SQLQuery($query, ByRef $queryResult)
	Debug($query)
	Local $result = _SQLite_Query($SQLITE_DB, $query, $queryResult)
	If $result <> 0 Then Error('Query failed ! Failure on : ' & @CRLF & $query)
EndFunc


;~ Execute a request on the database
Func SQLExecute($query)
	Debug($query)
	Local $result = _SQLite_Exec($SQLITE_DB, $query)
	If $result <> 0 Then Error('Query failed ! Failure on : ' & @CRLF & $query & @CRLF & @error)
EndFunc
#EndRegion Database Utils


;~ Store in database all data that can be found in items in inventory
Func StoreAllItemsData()
	Local $InsertQuery, $item
	Local $batchID = GetPreviousBatchID() + 1

	Info('Scanning and storing all items data')
	SQLExecute('BEGIN;')
	$InsertQuery = 'INSERT INTO ' & $TABLE_DATA_RAW & ' VALUES' & @CRLF
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			GetItemReq($item)
			$InsertQuery &= '	('
			$InsertQuery &= $batchID & ', '
			$InsertQuery &= $bagIndex & ', '
			$InsertQuery &= $i & ', '
			$InsertQuery &= DllStructGetData($item, 'modelID') & ', '
			$InsertQuery &= DllStructGetData($item, 'type') & ', '
			$InsertQuery &= 'NULL, '
			$InsertQuery &= (IsWeapon($item) ? GetItemMaxDmg($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemReq($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemAttribute($item) : 'NULL') & ", '"
			$InsertQuery &= DllStructGetData($item, 'nameString') & "', '"
			$InsertQuery &= (IsInscribable($item) ? 0 : 1) & "', '"
			$InsertQuery &= GetModStruct($item) & "', "
			$InsertQuery &= DllStructGetData($item, 'quantity') & ', '
			$InsertQuery &= GetOrDefault(DllStructGetData($item, 'value'), 0) & ', '
			$InsertQuery &= GetRarity($item) & ', '
			$InsertQuery &= DllStructGetData($item, 'DyeColor') & ', '
			$InsertQuery &= DllStructGetData($item, 'ID')
			$InsertQuery &= '),' & @CRLF
			Sleep(20)
		Next
	Next

	$InsertQuery = StringLeft($InsertQuery, StringLen($InsertQuery) - 3) & @CRLF & ';'
	SQLExecute($InsertQuery)
	SQLExecute('COMMIT;')

	AddToFilledData($batchID)
	CompleteItemsMods($batchID)
EndFunc


;~ Insert data into the RAW data table
Func AddToFilledData($batchID)
	Local $InsertQuery = 'WITH raw AS (' & @CRLF _
		& '	SELECT batch, bag, slot, value, requirement, rarity_ID, type_ID, attribute_ID, model_ID, type_ID, model_ID, name_string, OS, modstruct, dye_color, ID FROM ' & $TABLE_DATA_RAW & ' WHERE batch = ' & $batchID & @CRLF _
		& ')' & @CRLF _
		& 'INSERT INTO ' & $TABLE_DATA_USER & @CRLF _
		& 'SELECT raw.batch, raw.bag, raw.slot, rarities.rarity, types.type, requirement, attributes.attribute, raw.value, names.model_name, raw.OS, NULL, NULL, NULL, raw.type_ID, raw.model_ID, raw.name_string, raw.modstruct, raw.dye_color, raw.ID' & @CRLF _
		& 'FROM raw' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_RARITY & ' rarities ON raw.rarity_ID = rarities.rarity_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_TYPE & ' types ON raw.type_ID = types.type_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_ATTRIBUTE & ' attributes ON raw.attribute_ID = attributes.attribute_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_MODEL & ' names ON raw.type_ID = names.type_ID AND raw.model_ID = names.model_ID;'
	SQLExecute($InsertQuery)
EndFunc


;~ Auto fill the items mods based on the known modstructs
Func CompleteItemsMods($batchID)
	Info('Completing items mods')
	Local $upgradeTypes[3] = ['prefix', 'suffix', 'inscription']
	Local $query
	For $upgradeType In $upgradeTypes
		$query = 'UPDATE ' & $TABLE_DATA_USER & @CRLF _
			& 'SET ' & $upgradeType & ' = (' & @CRLF _
			& '	SELECT upgrades.effect' & @CRLF _
			& '	FROM ' & $TABLE_LOOKUP_UPGRADES & ' upgrades' & @CRLF _
			& '	WHERE upgrades.propagate = 1' & @CRLF _
			& '		AND upgrades.weapon = type_ID' & @CRLF _
			& '		AND upgrades.hexa IS NOT NULL' & @CRLF _
			& "		AND upgrades.upgrade_type = '" & $upgradeType & "'" & @CRLF _
			& "		AND modstruct LIKE ('%' || upgrades.hexa || '%')" & @CRLF _
			& ')' & @CRLF _
			& 'WHERE ' & $upgradeType & ' IS NULL' & @CRLF _
			& '	AND batch = ' & $batchID & @CRLF _
			& '	AND EXISTS (' & @CRLF _
			& '		SELECT upgrades.effect' & @CRLF _
			& '		FROM ' & $TABLE_LOOKUP_UPGRADES & ' upgrades' & @CRLF _
			& '		WHERE upgrades.propagate = 1' & @CRLF _
			& '			AND upgrades.weapon = type_ID' & @CRLF _
			& '			AND upgrades.hexa IS NOT NULL' & @CRLF _
			& "			AND upgrades.upgrade_type = '" & $upgradeType & "'" & @CRLF _
			& "			AND modstruct LIKE ('%' || upgrades.hexa || '%')" & @CRLF _
			& ');'
		SQLExecute($query)
	Next
EndFunc


;~ Get the previous batchID or -1 if no batch has been added into database
Func GetPreviousBatchID()
	Local $queryResult, $row, $lastBatchID, $query
	$query = 'SELECT COALESCE(MAX(batch), -1) FROM ' & $TABLE_DATA_RAW & ';'
	SQLQuery($query, $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$lastBatchID = $row[0]
	WEnd
	Return $lastBatchID
EndFunc


;~ Complete model name lookup table
Func CompleteModelLookupTable()
	Local $query
	Info('Completing model lookup ')
	$query = 'INSERT INTO ' & $TABLE_LOOKUP_MODEL & @CRLF _
		& 'SELECT DISTINCT type_id, model_id, name, OS' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE name IS NOT NULL' & @CRLF _
		& '	AND (type_ID, model_ID) NOT IN (SELECT type_ID, model_ID FROM ' & $TABLE_LOOKUP_MODEL & ');'
	SQLExecute($query)
EndFunc


;~ Complete mods data by cross-comparing all modstructs from items that have the same mods and deduce the mod hexa from it
Func CompleteUpgradeLookupTable()
	Info('Completing upgrade lookup')
	Local $modTypes[3] = ['prefix', 'suffix', 'inscription']
	For $upgradeType In $modTypes
		InsertNewUpgrades($upgradeType)
		UpdateNewUpgrades($upgradeType)
		ValidateNewUpgrades($upgradeType)
	Next
EndFunc


;~ Insert upgrades not already present in database
Func InsertNewUpgrades($upgradeType)
	Local $query = 'INSERT INTO ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
		& "SELECT DISTINCT OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ', NULL, NULL, 0' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE ' & $upgradeType & ' IS NOT NULL' & @CRLF _
		& "AND (OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ') NOT IN (SELECT OS, upgrade_type, weapon, effect FROM ' & $TABLE_LOOKUP_UPGRADES & ');'
	SQLExecute($query)
EndFunc


;~ Update upgrades with their hexa struct if we manage to find enough similarities
Func UpdateNewUpgrades($upgradeType)
	Local $queryResult, $row
	Local $mapItemStruct[]
	Local $query = 'WITH valid_groups AS (' & @CRLF _
		& '	SELECT OS, type_ID AS weapon, ' & $upgradeType & ' FROM ' & $TABLE_DATA_USER & ' WHERE ' & $upgradeType & ' IS NOT NULL GROUP BY OS, weapon, ' & $upgradeType & ' HAVING COUNT(*) > 3' & @CRLF _
		& ')' & @CRLF _
		& 'SELECT valid_groups.OS, weapon, valid_groups.' & $upgradeType & ', data.modstruct' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & ' data' & @CRLF _
		& 'INNER JOIN valid_groups' & @CRLF _
		& '	ON valid_groups.OS = data.OS AND valid_groups.weapon = data.type_ID AND valid_groups.' & $upgradeType & ' = data.' & $upgradeType & @CRLF _
		& 'ORDER BY valid_groups.' & $upgradeType & ';'
	SQLQuery($query, $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$mapItemStruct = AppendArrayMap($mapItemStruct, $row[0] & '|' & $row[1] & '|' & $row[2], $row[3])
	WEnd

	Local $OSWeaponUpgradeTypes = MapKeys($mapItemStruct)
	For $OSWeaponUpgradeType In $OSWeaponUpgradeTypes
		Local $modStruct = LongestCommonSubstring($mapItemStruct[$OSWeaponUpgradeType])
		Local $bananaSplit = StringSplit($OSWeaponUpgradeType, '|')

		$query = 'UPDATE ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
			& "	SET hexa = '" & $modStruct & "' WHERE OS = " & $bananaSplit[1] & " AND upgrade_type = '" & $upgradeType & "' AND weapon = " & $bananaSplit[2] & " AND effect = '" & $bananaSplit[3] & "';"
		SQLExecute($query)
	Next
EndFunc


;~ Validate that the upgrades hexa structs we found are correct
Func ValidateNewUpgrades($upgradeType)
	Local $query
	$query = 'UPDATE ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
		& 'SET propagate = 2' & @CRLF _
		& 'WHERE hexa IS NOT NULL' & @CRLF _
		& 'AND EXISTS (' & @CRLF _
		& "	SELECT data.OS, type_ID, '" & $upgradeType & "', " & $upgradeType & @CRLF _
		& '	FROM ' & $TABLE_DATA_USER & ' data' & @CRLF _
		& '	WHERE data.OS = ' & $TABLE_LOOKUP_UPGRADES & '.OS' & @CRLF _
		& "		AND upgrade_type = '" & $upgradeType & "'" & @CRLF _
		& "		AND data.rarity = 'Gold'" & @CRLF _
		& '		AND data.type_ID = weapon' & @CRLF _
		& "		AND data.modstruct LIKE ('%' || hexa || '%')" & @CRLF _
		& '		AND data.' & $upgradeType & ' <> effect' & @CRLF _
		& ');'
	SQLExecute($query)
EndFunc
#EndRegion Database


#Region Inventory
;~ Move all items out of the equipment bag so they can be salvaged
Func MoveItemsOutOfEquipmentBag()
	Local $equipmentBag = GetBag(5)
	Local $inventoryEmptySlots = FindAllEmptySlots(1, 4)
	Local $countEmptySlots = UBound($inventoryEmptySlots) / 2
	Local $cursor = 0
	If $countEmptySlots <= $cursor Then
		Warn('No space in inventory to move the items out of the equipment bag')
		Return 0
	EndIf

	For $slot = 1 To DllStructGetData($equipmentBag, 'slots')
		If $countEmptySlots <= $cursor Then
			Warn('No space in inventory to move the items out of the equipment bag')
			Return 0
		EndIf
		Local $item = GetItemBySlot(5, $slot)
		If DllStructGetData($item, 'ModelID') <> 0 Then
			If IsArmor($item) Then ContinueLoop
			If Not DefaultShouldSalvageItem($item) Then ContinueLoop
			MoveItem($item, $inventoryEmptySlots[2 * $cursor], $inventoryEmptySlots[2 * $cursor + 1])
			$cursor += 1
			RndSleep(50)
		EndIf
	Next
	Return $cursor
EndFunc


;~ Sell general items to trader
Func SellEverythingToMerchant($shouldSellItem = DefaultShouldSellItem, $dryRun = False)
	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to merchant')
	Local $merchant = GetNearestNPCToCoords(-2700, 1075)
	UseCitySpeedBoost()
	GoToNPC($merchant)
	RndSleep(500)

	Local $item, $itemID
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 Then
				If $shouldSellItem($item) Then
					If Not $dryRun Then
						SellItem($item, DllStructGetData($item, 'Quantity'))
						RndSleep(GetPing() + 200)
					EndIf
				Else
					If $dryRun Then Info('Will not sell item at ' & $bagIndex & ':' & $i)
				EndIf
			EndIf
		Next
	Next
EndFunc


;~ Returns true if there are materials in inventory
Func HasMaterials()
	Return HasInInventory(IsMaterial)
EndFunc


;~ Returns true if there are basic materials in inventory
Func HasBasicMaterials()
	Return HasInInventory(IsBasicMaterial)
EndFunc


;~ Returns true if there are rare materials in inventory
Func HasRareMaterials()
	Return HasInInventory(IsRareMaterial)
EndFunc


;~ Returns true if there are items in inventory satisfying condition
Func HasInInventory($condition)
	Local $item, $itemID
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $condition($item) Then Return True
		Next
	Next
	Return False
EndFunc


;~ Sell materials to materials merchant in EOTN
Func SellMaterialsToMerchant($shouldSellItem = DefaultShouldSellMaterial)
	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to materials merchant')
	Local $materialMerchant = GetNearestNPCToCoords(-1850, 875)
	UseCitySpeedBoost()
	GoToNPC($materialMerchant)
	RndSleep(500)

	Local $item, $itemID
	For $bagIndex = 1 To _Min(4, $BAG_NUMBER)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellItem($item) Then
				$itemID = DllStructGetData($item, 'ID')
				Local $totalAmount = DllStructGetData($item, 'Quantity')
				Debug('Selling ' & $totalAmount & ' material ' & $bagIndex & '-' & $i)
				While $totalAmount > 9
					TraderRequestSell($itemID)
					Sleep(GetPing() + 200)
					TraderSell()
					Sleep(GetPing() + 200)
					$totalAmount -= 10
					; Safety net incase some sell orders didn't go through
					If ($totalAmount < 10) Then
						$item = GetItemBySlot($bagIndex, $i)
						$totalAmount = DllStructGetData($item, 'Quantity')
					EndIf
				WEnd
			EndIf
		Next
	Next
EndFunc


;~ Sell rare materials to rare materials merchant in EOTN
Func SellRareMaterialsToMerchant($shouldSellItem = DefaultShouldSellRareMaterial)
	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to rare materials merchant')
	Local $rareMaterialMerchant = GetNearestNPCToCoords(-2100, 1125)
	UseCitySpeedBoost()
	GoToNPC($rareMaterialMerchant)
	RndSleep(250)

	Local $item, $itemID
	For $bagIndex = 1 To _Min(4, $BAG_NUMBER)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellItem($item) Then
				$itemID = DllStructGetData($item, 'ID')
				Local $totalAmount = DllStructGetData($item, 'Quantity')
				Debug('Selling ' & $totalAmount & ' material ' & $bagIndex & '-' & $i)
				While $totalAmount > 0
					TraderRequestSell($itemID)
					Sleep(GetPing() + 200)
					TraderSell()
					Sleep(GetPing() + 200)
					$totalAmount -= 1
					; Safety net incase some sell orders didn't go through
					If ($totalAmount < 1) Then
						$item = GetItemBySlot($bagIndex, $i)
						$totalAmount = DllStructGetData($item, 'Quantity')
					EndIf
				WEnd
			EndIf
		Next
	Next
EndFunc


;~ Buy rare material from rare materials merchant in EOTN
Func BuyRareMaterialFromMerchant($materialModelID, $amount)
	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to rare materials merchant')
	Local $rareMaterialMerchant = GetNearestNPCToCoords(-2100, 1125)
	UseCitySpeedBoost()
	GoToNPC($rareMaterialMerchant)
	RndSleep(250)

	For $i = 1 To $amount
		TraderRequest($materialModelID)
		Sleep(GetPing() + 200)
		Local $traderPrice = GetTraderCostValue()
		Debug('Buying for ' & $traderPrice)
		TraderBuy()
		Sleep(GetPing() + 200)
	Next
	; TODO: add safety net to check amount of items bought and buy some more if needed
EndFunc


;~ Buy rare material from rare materials merchant in EOTN until you have little or no money left
;~ Possible issue if you provide a very low poorThreshold and the price of an item hike up enough to reduce your money to less than 0
;~ So please only use with $poorThreshold > 5k
Func BuyRareMaterialFromMerchantUntilPoor($materialModelID, $poorThreshold = 20000, $backupMaterialModelID = Null)
	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	If CountSlots(1, 4) == 0 Then
		Warn('No room in inventory to buy rare materials, tick some checkboxes to clear inventory')
		Return
	EndIf
	Info('Moving to rare materials merchant')
	Local $rareMaterialMerchant = GetNearestNPCToCoords(-2100, 1125)
	UseCitySpeedBoost()
	GoToNPC($rareMaterialMerchant)
	RndSleep(250)

	Local $IDMaterialToBuy = $materialModelID
	TraderRequest($IDMaterialToBuy)
	Sleep(GetPing() + 200)
	Local $traderPrice = GetTraderCostValue()
	If $traderPrice <= 0 Then
		Error('Couldnt get trader price for the original material')
		If ($backupMaterialModelID <> Null) Then
			TraderRequest($backupMaterialModelID)
			Sleep(GetPing() + 200)
			Local $traderPrice = GetTraderCostValue()
			If $traderPrice <= 0 Then Return
			$IDMaterialToBuy = $backupMaterialModelID
			Notice('Falling back to backup material')
		Else
			Return
		EndIf
	EndIf
	Local $amount = Floor((GetGoldCharacter() - $poorThreshold) / $traderPrice)
	Info('Buying ' & $amount & ' items for ' & $traderPrice)
	While $amount > 0
		TraderBuy()
		Sleep(GetPing() + 200)
		TraderRequest($IDMaterialToBuy)
		Sleep(GetPing() + 200)
		$traderPrice = GetTraderCostValue()
		$amount -= 1
	WEnd
EndFunc


;~ Store all item in the Xunlai Storage
Func StoreEverythingInXunlaiStorage($shouldStoreItem = DefaultShouldStoreItem)
	Info('Storing money')
	BalanceCharacterGold(10000)
	Info('Storing items')
	Local $item, $itemID
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 And $shouldStoreItem($item) Then
				Debug('Moving ' & $bagIndex & ':' & $i)
				StoreItemInXunlaiStorage($item)
				RndSleep(50)
			EndIf
		Next
	Next
EndFunc


;~ Store an item in the Xunlai Storage
Func StoreItemInXunlaiStorage($item)
	Local $existingStacks
	Local $itemID, $storageSlot, $amount
	$itemID = DllStructGetData($item, 'ModelID')
	$amount = DllStructGetData($item, 'Quantity')

	If IsMaterial($item) Then
		Local $materialStorageLocation = $Map_Material_Location[$itemID]
		Local $materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $countMaterial = DllStructGetData($materialInStorage, 'Equipped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		MoveItem($item, 6, $materialStorageLocation)
		RndSleep(GetPing() + 20)
		$materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $newCountMaterial = DllStructGetData($materialInStorage, 'Equipped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		If $newCountMaterial - $countMaterial == $amount Then Return
		$amount = DllStructGetData($item, 'Quantity')
	EndIf
	If (IsStackable($item) Or IsMaterial($item)) And $amount < 250 Then
		$existingStacks = FindAllInXunlaiStorage($item)
		For $bagIndex = 0 To Ubound($existingStacks) - 1 Step 2
			Local $existingStack = GetItemBySlot($existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
			Local $existingAmount = DllStructGetData($existingStack, 'Quantity')
			If $existingAmount < 250 Then
				Debug('To ' & $existingStacks[$bagIndex] & ':' & $existingStacks[$bagIndex + 1])
				MoveItem($item, $existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
				RndSleep(GetPing() + 20)
				$amount = $amount + $existingAmount - 250
				If $amount <= 0 Then Return
			EndIf
		Next
	EndIf
	$storageSlot = FindChestFirstEmptySlot()
	If $storageSlot[0] == 0 Then
		Warn('Storage is full')
		Return
	EndIf
	Debug('To ' & $storageSlot[0] & ':' & $storageSlot[1])
	MoveItem($item, $storageSlot[0], $storageSlot[1])
	RndSleep(GetPing() + 20)
EndFunc


;~ Return True if the item should be stored in Xunlai Storage
Func DefaultShouldStoreItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	If IsConsumable($itemID) Then
		Return True
	ElseIf IsBasicMaterial($item) Then
		Return True
	ElseIf ($itemID == $ID_Identification_Kit Or $itemID == $ID_Superior_Identification_Kit) Then
		Return False
	ElseIf ($itemID == $ID_Salvage_Kit Or $itemID == $ID_Salvage_Kit_2 Or $itemID == $ID_Expert_Salvage_Kit Or $itemID == $ID_Superior_Salvage_Kit) Then
		Return False
	ElseIf IsRareMaterial($item) Then
		Return True
	ElseIf IsTome($itemID) Then
		Return True
	ElseIf IsGoldScroll($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Dyes) Then
		Return True
	ElseIf ($itemID == $ID_Ministerial_Commendation) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick) Then
		Return False
	ElseIf IsWeapon($item) Then
		Return ShouldKeepWeapon($item)
	ElseIf isArmorSalvageItem($item) Then
		Return ContainsValuableUpgrades($item)
	EndIf
	Return False
EndFunc


;~ Return True if the item should be sold to the merchant
Func DefaultShouldSellItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_Green Then Return False
	If IsKey($itemID) Then Return True
	If IsBlueScroll($itemID) Then Return True
	If IsGoldScroll($itemID) And $itemID <> $ID_UW_Scroll And $itemID <> $ID_FoW_Scroll Then Return True
	If isArmorSalvageItem($item) Then Return GetIsIdentified($item) And Not ContainsValuableUpgrades($item)
	If IsWeapon($item) Then
		Return Not ShouldKeepWeapon($item)
	EndIf
	Return False
EndFunc


;~ Return True if the item should be salvaged
Func DefaultShouldSalvageItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_Green Then Return False
	If IsTrophy($itemID) Then
		If $Map_Feather_Trophies[$itemID] <> Null Then Return True
		If $Map_Dust_Trophies[$itemID] <> Null Then Return True
		If $Map_Bones_Trophies[$itemID] <> Null Then Return True
		If $Map_Fiber_Trophies[$itemID] <> Null Then Return True
		Return False
	EndIf
	If IsArmorSalvageItem($item) Then Return GetIsIdentified($item) And Not ContainsValuableUpgrades($item)
	If IsWeapon($item) Then
		If Not DllStructGetData($item, 'IsMaterialSalvageable') Then Return False
		Return Not ShouldKeepWeapon($item)
	EndIf
	Return False
EndFunc


;~ Return True if the item should not be sold or salvaged
Func ShouldKeepWeapon($item)
	Local Static $lowReqValuableWeaponTypes = [$ID_Type_Shield, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
	Local Static $lowReqValuableWeaponTypesMap = MapFromArray($lowReqValuableWeaponTypes)
	Local Static $valuableOSWeaponTypes = [$ID_Type_Shield, $ID_Type_Offhand, $ID_Type_Wand, $ID_Type_Staff]
	Local Static $valuableOSWeaponTypesMap = MapFromArray($valuableOSWeaponTypes)

	Local $rarity = GetRarity($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $type = DllStructGetData($item, 'Type')
	; Keeping equipped items
	If DllStructGetData($item, 'Equipped') Then Return True
	; Keeping customized items
	If DllStructGetData($item, 'Customized') <> 0 Then Return True
	; Throwing white items
	If $rarity == $RARITY_White Then Return False
	; Keeping green items
	If $rarity == $RARITY_Green Then Return True
	; Keeping unidentified items
	If Not GetIsIdentified($item) Then Return True
	; Keeping super-rare items, good in all cases, items (BDS, voltaic, etc)
	If $Map_UltraRareWeapons[$itemID] <> null Then Return True
	; Keeping items that contain good upgrades
	If ContainsValuableUpgrades($item) Then Return True
	; Throwing items without good damage/energy/armor
	If Not IsMaxDamageForReq($item) Then Return False
	; Inscribable are kept only if : 1) rare skin and q9 2) low req of a good type
	If IsInscribable($item) Then
		If IsLowReqMaxDamage($item) And $lowReqValuableWeaponTypesMap[DllStructGetData($item, 'type')] <> Null Then Return True
		If GetItemReq($item) == 9 And $Map_RareWeapons[$itemID] <> Null Then Return True
		Return False
	; OS ... it's more complicated
	Else
		If GetItemReq($item) >= 9 Then
			; OS high req are kept only if : 1) perfect mods and good type or good skin 2) rare skin and almost perfect mods
			If HasPerfectMods($item) And ($Map_RareWeapons[$itemID] <> Null Or $valuableOSWeaponTypesMap[DllStructGetData($item, 'type')] <> Null) Then Return True
			If $Map_RareWeapons[$itemID] == Null Then Return False
			If HasAlmostPerfectMods($item) Then Return True
			Return False
		Else
			; Low req are kept if they have perfect mods, almost perfect mods, or a rare skin with somewhat okay mods
			If HasPerfectMods($item) Then Return True
			If HasAlmostPerfectMods($item) Then Return True
			If $Map_RareWeapons[$itemID] <> Null And HasOkayMods($item) Then Return True
			Return False
		EndIf
	EndIf
	Return False
EndFunc


;~ Return true if the item should be sold to the material merchant
Func DefaultShouldSellMaterial($item)
	If Not IsBasicMaterial($item) Then Return False

	; Lazy instantiation
	Local Static $materialsKeptArray = [$ID_Pile_of_Glittering_Dust, $ID_Feather]
	;Local Static $materialsKeptArray = []
	Local Static $mapMaterialsKept = MapFromArray($materialsKeptArray)

	Local $modelID = DllStructGetData($item, 'ModelID')
	Return $mapMaterialsKept[$modelId] == null
EndFunc


;~ Return true if the item should be sold to the material merchant
Func DefaultShouldSellRareMaterial($item)
	If Not IsRareMaterial($item) Then Return False

	; Lazy instantiation
	Local Static $materialsKeptArray = [$ID_Glob_of_Ectoplasm, $ID_Obsidian_Shard]
	Local Static $mapMaterialsKept = MapFromArray($materialsKeptArray)

	Local $modelID = DllStructGetData($item, 'ModelID')
	Return $mapMaterialsKept[$modelId] == null
EndFunc


;~ Returns true if an item has a 'Salvageable' inscription
Func HasSalvageInscription($item)
	Local $salvageableInscription[] = ['1F0208243E0432251', '0008260711A8A7000000C', '0008261323A8A7000000C', '00082600011826900098260F1CA8A7000000C']
	Local $modstruct = GetModStruct($item)
	For $salvageableModStruct in $salvageableInscription
		If StringInStr($modstruct, $salvageableModStruct) Then Return True
	Next
	Return False
EndFunc
#EndRegion Inventory