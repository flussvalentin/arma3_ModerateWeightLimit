
//Adds max weight option to CBA settings.
[
	"fluss_maxWeight", 
	"SLIDER", 
	["Maximum Weight Limit", "Players exceeding this weight cannot Jog or Sprint (forced to walk)."], 
	"Weight Limit", 
	[0, 500, 40, 1], 
	true 
] call CBA_fnc_addSetting;

//Adds med weight option to CBA settings.
[
	"fluss_medWeight", 
	"SLIDER", 
	["Medium Weight Limit", "Players exceeding this weight cannot Sprint."], 
	"Weight Limit", 
	[0, 500, 37, 1], 
	true 
] call CBA_fnc_addSetting;

//Toggle for Freedom Units
[
	"fluss_useFreedomUnits", 
	"CHECKBOX", 
	["Use Freedom Units (lbs)", "If enabled, all weights and settings will be interpreted as Pounds (lbs). If disabled, Kilograms (kg) are used."], 
	"Weight Limit", 
	false, 
	true 
] call CBA_fnc_addSetting;

//Toggle for KJW Mod Compatibility
[
	"fluss_includeKJW", 
	"CHECKBOX", 
	["Include KJW Mod Stowed Weapons", "Enable to include the weight of weapons stowed via KJW's Two Primary/Secondary Weapons mods."], 
	"Weight Limit", 
	true, 
	true 
] call CBA_fnc_addSetting;

//Toggle for Animate Mod Compatibility
[
	"fluss_includeAnimate", 
	"CHECKBOX", 
	["Include Animate Mod Slung Weapons", "Enable to include the weight of weapons carried in Animate - Rewrite slings and lanyards."], 
	"Weight Limit", 
	true, 
	true 
] call CBA_fnc_addSetting;

//Toggle for BackpackOnChest Mod Compatibility
[
	"fluss_includeBOCR", 
	"CHECKBOX", 
	["Include BackpackOnChest (BOCR)", "Enable to include the weight of the chestpack and its contents from the BackpackOnChest - Redux mod."], 
	"Weight Limit", 
	true, 
	true 
] call CBA_fnc_addSetting;

//Slider for Calculation Loop Sleep
[
	"fluss_calcInterval",
	"SLIDER",
	["Weight Calc Interval", "Seconds to wait between full weight calculations."],
	"Weight Limit",
	[0.1, 600, 5, 1], // [min, max, default, trailing decimals]
	true
] call CBA_fnc_addSetting;

//Slider for Enforcement Loop Sleep
[
	"fluss_enforceInterval",
	"SLIDER",
	["Penalty Enforce Interval", "Seconds to wait between applying movement penalties."],
	"Weight Limit",
	[0.1, 60, 0.50, 2], // [min, max, default, trailing decimals]
	true
] call CBA_fnc_addSetting;

//Toggle for Inventory UI Type
[
	"fluss_separateInventoryUI", 
	"CHECKBOX", 
	["Separate Inventory UI", "If enabled, the weight in the Vanilla Inventory appears in a floating box at the top. If disabled, it hijacks the vanilla Load bar."], 
	"Weight Limit", 
	false, 
	true 
] call CBA_fnc_addSetting;

//Toggle for ACE Arsenal UI Type
[
	"fluss_separateAceArsenalUI", 
	"CHECKBOX", 
	["Separate ACE Arsenal UI", "If enabled, the weight appears at the top. If disabled, it appears in the lower-left corner (Note: Custom position is optimized for Interface Size 'Small')."], 
	"Weight Limit", 
	true, 
	true 
] call CBA_fnc_addSetting;

//Toggle for Debug Logging
[
	"fluss_debug", 
	"CHECKBOX", 
	["Enable Debug Logging", "If enabled, the server will print a detailed weight breakdown for every player in the system chat on an interval."], 
	"Weight Limit", 
	false, 
	true 
] call CBA_fnc_addSetting;

//Slider for Debug Loop Interval
[
	"fluss_debugInterval",
	"SLIDER",
	["Debug Print Interval", "Seconds to wait between debug chat messages. Higher values reduce chat spam."],
	"Weight Limit",
	[1, 600, 10, 0], // [min, max, default, trailing decimals]
	true
] call CBA_fnc_addSetting;

//Role Overrides (Array as String)
[
	"fluss_roleOverrides", 
	"EDITBOX", 
	["Role Overrides", "Define custom limits for specific roles. Format: [['roleName', medLimit, maxLimit], ...]. To assign a role, use: player setVariable ['fluss_role', 'roleName', true];"], 
	"Weight Limit", 
	"[['medic', 37, 40], ['mg', 37, 40]]", 
	true 
] call CBA_fnc_addSetting;
