// SERVER-SIDE ONLY: Mod injected to clients via remoteExec payload
if (!isServer) exitWith {};

// Define the payload that will be pushed to all clients
fluss_clientPayload = {
	if (!hasInterface) exitWith {};
	if (missionNamespace getVariable ["fluss_payload_initialized", false]) exitWith {};
	missionNamespace setVariable ["fluss_payload_initialized", true];

	// Make calculation function global for UI access
	fluss_fnc_calcMass = {
		params ["_obj"];
		private _mass = 0;
		
		private _weapons = weaponsItemsCargo _obj;
		if (!isNil "_weapons") then {
			{
				_mass = _mass + getNumber (configFile >> "CfgWeapons" >> (_x select 0) >> "WeaponSlotsInfo" >> "mass");
				if ((_x select 1) != "") then { _mass = _mass + getNumber (configFile >> "CfgWeapons" >> (_x select 1) >> "ItemInfo" >> "mass"); };
				if ((_x select 2) != "") then { _mass = _mass + getNumber (configFile >> "CfgWeapons" >> (_x select 2) >> "ItemInfo" >> "mass"); };
				if ((_x select 3) != "") then { _mass = _mass + getNumber (configFile >> "CfgWeapons" >> (_x select 3) >> "ItemInfo" >> "mass"); };
				if (count (_x select 4) > 0) then { _mass = _mass + getNumber (configFile >> "CfgMagazines" >> ((_x select 4) select 0) >> "mass"); };
				if (count _x > 6 && {(_x select 6) != ""}) then { _mass = _mass + getNumber (configFile >> "CfgWeapons" >> (_x select 6) >> "ItemInfo" >> "mass"); };
			} forEach _weapons;
		};

		private _items = itemCargo _obj;
		if (!isNil "_items") then {
			{ _mass = _mass + getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass"); } forEach _items;
		};
		
		private _mags = magazineCargo _obj;
		if (!isNil "_mags") then {
			{ _mass = _mass + getNumber (configFile >> "CfgMagazines" >> _x >> "mass"); } forEach _mags;
		};
		
		_mass
	};

	// Helper to get limits with role overrides
	fluss_fnc_getLimits = {
		params [["_unit", player]];
		private _med = missionNamespace getVariable ["fluss_medWeight", 37];
		private _max = missionNamespace getVariable ["fluss_maxWeight", 40];
		private _role = _unit getVariable ["fluss_role", ""];
		private _overrides = missionNamespace getVariable ["fluss_roleOverrides", "[]"];
		
		if (_role != "" && _overrides != "[]" && _overrides != "") then {
			private _arr = call compile _overrides;
			if (!isNil "_arr" && {_arr isEqualType []}) then {
				{
					if (_x isEqualType []) then {
						_x params [["_r", ""], ["_rMed", _med], ["_rMax", _max]];
					if (_role isEqualTo _r) exitWith {
						_med = _rMed;
						_max = _rMax;
					};
					};
				} forEach _arr;
			};
		};
		[_med, _max]
	};

	// Ground Truth UI logic
	fluss_fnc_weightUI = {
		params ["_display", ["_targetUnit", player]];
		
		if (isNull _targetUnit) then { _targetUnit = player; };
		
		private _idd = ctrlIDD _display;
		private _separateUI = true;

		// Calculate UI preference based on specific settings
		switch (_idd) do {
			case 602: { _separateUI = missionNamespace getVariable ["fluss_separateInventoryUI", true]; };
			case 701: { _separateUI = true; }; // Virtual Arsenal always forced to Separate UI
			default { _separateUI = missionNamespace getVariable ["fluss_separateAceArsenalUI", true]; };
		};

		private _ctrl = controlNull;

		if (_separateUI) then {
			// OLD SYSTEM: Floating box at the top
			_ctrl = _display ctrlCreate ["RscStructuredText", -1];
			_ctrl ctrlSetPosition [safeZoneX + safeZoneW/2 - 0.35, safeZoneY + 0.02, 0.7, 0.08];
			_ctrl ctrlSetBackgroundColor [0, 0, 0, 0.8];
		} else {
			// NEW SYSTEM: Hijack Vanilla Bars / Custom Corner Position
			switch (_idd) do {
				case 602: { // Vanilla Inventory
					private _vanillaBar = _display displayCtrl 111;
					private _pos = ctrlPosition _vanillaBar; 
					
					if (isClass (configFile >> "CfgPatches" >> "bettinv_main")) then {
						// Better Inventory detected: Apply your custom offsets
						_pos set [0, (_pos select 0) - 0.006]; 
						_pos set [2, (_pos select 2) - 0.6];
					} else {
						// Vanilla fallback: Standard hijack width
						_pos set [2, 0.5]; 
					};

					_vanillaBar ctrlShow false;
					_ctrl = _display ctrlCreate ["RscStructuredText", -1];
					_ctrl ctrlSetPosition _pos;
				};
				// 701 (Virtual Arsenal) is handled by the Separate UI block above
				default { 
					// ACE Arsenal: Bottom Left Corner
					_ctrl = _display ctrlCreate ["RscStructuredText", -1];
					
					private _w = 0.455;
					private _h = 0.0616;
					
					// Position
					_ctrl ctrlSetPosition [safeZoneX + 0.073, (safeZoneY + safeZoneH) - _h - 0.015, _w, _h];
					_ctrl ctrlSetBackgroundColor [0, 0, 0, 1.0];
				};
			};
		};
		_ctrl ctrlCommit 0;

		[_display, _ctrl, _separateUI, _targetUnit] spawn {
			params ["_display", "_ctrl", "_separateUI", "_targetUnit"];
			[_targetUnit] call fluss_fnc_recalcWeight; // Recalc once on open for immediate accuracy
			
			while {!isNull _display} do {
				[_targetUnit] call fluss_fnc_recalcWeight; // Recalc while UI is open for real-time Arsenal/Inventory response
				
				private _vanillaMass = _targetUnit getVariable ["fluss_vanillaMass", 0];
				private _kjwMass = _targetUnit getVariable ["fluss_kjwMass", 0];
				private _animateMass = _targetUnit getVariable ["fluss_animateMass", 0];
				private _bocrMass = _targetUnit getVariable ["fluss_bocrMass", 0];
				private _totalWeight = _targetUnit getVariable ["fluss_currentWeight", 0];
				
				private _useFreedom = missionNamespace getVariable ["fluss_useFreedomUnits", false];
				private _unitStr = if (_useFreedom) then {"lbs"} else {"kg"};
				
				private _fnc_formatMass = {
					params ["_mass", "_useFreedom"];
					private _val = _mass / 10;
					if (!_useFreedom) then { _val = _val / 2.20462; };
					_val toFixed 2
				};
				
				private _text = "";
				if (_separateUI) then {
					_text = format [
						"<t align='center' size='1.2' font='RobotoCondensed'>True Weight: %1 %2</t><br/><t align='center' size='0.8' color='#aaaaaa' font='RobotoCondensed'>Vanilla: %3 %2 | KJW: %4 %2 | Animate: %5 %2 | BOCR: %6 %2</t>", 
						_totalWeight toFixed 2,
						_unitStr,
						([_vanillaMass, _useFreedom] call _fnc_formatMass),
						([_kjwMass, _useFreedom] call _fnc_formatMass),
						([_animateMass, _useFreedom] call _fnc_formatMass),
						([_bocrMass, _useFreedom] call _fnc_formatMass)
					];
				} else {
					// Compact "Hijacked" version
					_text = format [
						"<t align='left' size='1.0' font='RobotoCondensed' color='#ffffff'>Weight:%1%2 (V:%3|K:%4|A:%5|B:%6)</t>",
						_totalWeight toFixed 2,
						_unitStr,
						([_vanillaMass, _useFreedom] call _fnc_formatMass),
						([_kjwMass, _useFreedom] call _fnc_formatMass),
						([_animateMass, _useFreedom] call _fnc_formatMass),
						([_bocrMass, _useFreedom] call _fnc_formatMass)
					];
				};
				
				_ctrl ctrlSetStructuredText parseText _text;

				// Get current limits (handling role overrides)
				private _limits = [_targetUnit] call fluss_fnc_getLimits;
				private _medLimit = _limits select 0;
				private _maxLimit = _limits select 1;

				private _bgColor = [0, 0, 0, 1.0]; // Default Black
				if (_totalWeight >= _maxLimit) then {
					_bgColor = [0.8, 0, 0, 1.0]; // Red
				} else {
					if (_totalWeight >= _medLimit) then {
						_bgColor = [0.8, 0.4, 0, 1.0]; // Orange
					};
				};
				_ctrl ctrlSetBackgroundColor _bgColor;

				sleep 0.1;
			};
		};
	};

	// Hook into Vanilla Inventory (Display 602)
	["unit", {
		params ["_newUnit", "_oldUnit"];
		_newUnit addEventHandler ["InventoryOpened", {
			params ["_unit", "_container"];
			[_unit] spawn {
				params ["_unit"];
				private _display = displayNull;
				waitUntil { _display = findDisplay 602; !isNull _display };
				[_display, _unit] spawn fluss_fnc_weightUI;
			};
		}];
	}, true] call CBA_fnc_addPlayerEventHandler;

	// Hook into Virtual Arsenal
	[missionNamespace, "arsenalOpened", {
		params ["_display"];
		[_display, player] spawn fluss_fnc_weightUI;
	}] call BIS_fnc_addScriptedEventHandler;

	[missionNamespace, "arsenalItemSelected", { [player] call fluss_fnc_recalcWeight; }] call BIS_fnc_addScriptedEventHandler;
	[missionNamespace, "arsenalItemDeselected", { [player] call fluss_fnc_recalcWeight; }] call BIS_fnc_addScriptedEventHandler;

	// Hook into ACE Arsenal
	["ace_arsenal_displayOpened", {
		params ["_display"];
		private _target = missionNamespace getVariable ["ace_arsenal_center", player];
		[_display, _target] spawn fluss_fnc_weightUI;
	}] call CBA_fnc_addEventHandler;

	["ace_arsenal_displayClosed", {
		private _target = missionNamespace getVariable ["ace_arsenal_center", player];
		[_target] call fluss_fnc_recalcWeight; 
	}] call CBA_fnc_addEventHandler;

	// Calculation Function
	fluss_fnc_recalcWeight = {
		params [["_unit", player]];
		private _vanillaMass = loadAbs _unit;
		private _kjwMass = 0;
		private _animateMass = 0;
		private _bocrMass = 0;
		
		private _incKJW = missionNamespace getVariable ["fluss_includeKJW", true];
		private _incAnimate = missionNamespace getVariable ["fluss_includeAnimate", true];
		private _incBOCR = missionNamespace getVariable ["fluss_includeBOCR", true];
		private _useFreedom = missionNamespace getVariable ["fluss_useFreedomUnits", false];
		
		if (_incKJW) then {
			{
				private _kjwObjects = _unit getVariable [_x, []];
				{ if (!isNull _x) then { _kjwMass = _kjwMass + ([_x] call fluss_fnc_calcMass); }; } forEach _kjwObjects;
			} forEach ["KJW_TwoPrimaryWeapons_currentWeaponObjects", "KJW_TwoSecondaryWeapons_currentWeaponObjects", "KJW_NoHolsterHolster_currentWeaponObjects"];
		};
		
		if (_incAnimate) then {
			{
				private _animateData = _unit getVariable [_x, []];
				if (count _animateData > 0) then {
					private _holder = _animateData select 0;
					if (!isNull _holder) then { _animateMass = _animateMass + ([_holder] call fluss_fnc_calcMass); };
				};
			} forEach ["tsp_slingweapon", "tsp_sling_1pointweapon", "tsp_sling_3pointweapon", "tsp_sling_lanyardweapon"];
		};

		if (_incBOCR) then {
			private _chestpackData = _unit getVariable ["bocr_main_chestpack", []];
			if (count _chestpackData >= 5) then {
				private _chestpackClass = (_chestpackData select 0) select 0;
				private _currentLoadPct = _chestpackData select 4;
				private _emptyMass = getNumber (configFile >> "CfgVehicles" >> _chestpackClass >> "mass");
				private _maxLoad = getNumber (configFile >> "CfgVehicles" >> _chestpackClass >> "maximumLoad");
				_bocrMass = _emptyMass + (_maxLoad * _currentLoadPct);
			};
		};
		
		private _extraMass = _kjwMass + _animateMass + _bocrMass;
		if (_unit getVariable ["fluss_vanillaMass", 0] != _vanillaMass) then { _unit setVariable ["fluss_vanillaMass", _vanillaMass, true]; };
		if (_unit getVariable ["fluss_kjw_extraMass", 0] != _extraMass) then { _unit setVariable ["fluss_kjw_extraMass", _extraMass, true]; };
		if (_unit getVariable ["fluss_kjwMass", 0] != _kjwMass) then { _unit setVariable ["fluss_kjwMass", _kjwMass, true]; };
		if (_unit getVariable ["fluss_animateMass", 0] != _animateMass) then { _unit setVariable ["fluss_animateMass", _animateMass, true]; };
		if (_unit getVariable ["fluss_bocrMass", 0] != _bocrMass) then { _unit setVariable ["fluss_bocrMass", _bocrMass, true]; };
		
		private _totalMass = _vanillaMass + _extraMass;
		
		// Report extra mass as virtual load to ACE3 safely (delta approach to avoid overwriting other mods)
		// KJW natively reports its mass to ACE3, so we only inject Animate and BOCR to prevent double-penalizing
		private _aceInjectMass = _animateMass + _bocrMass;
		
		private _previousOurMass = _unit getVariable ["fluss_previousExtraMass", 0];
		private _currentVLoad = _unit getVariable ["ace_movement_vLoad", 0];
		_currentVLoad = (_currentVLoad - _previousOurMass) + _aceInjectMass;
		
		_unit setVariable ["ace_movement_vLoad", _currentVLoad];
		_unit setVariable ["fluss_previousExtraMass", _aceInjectMass];
		
		if (!isNil "ace_movement_fnc_handleVirtualMass") then {
			[_unit] call ace_movement_fnc_handleVirtualMass;
		};
		
		private _weight = _totalMass / 10;
		if (!_useFreedom) then { _weight = _weight / 2.20462; };
		
		_unit setVariable ["fluss_currentWeight", _weight];
	};

	// Inventory Action Hooks
	["unit", {
		params ["_newUnit", "_oldUnit"];
		_newUnit addEventHandler ["Put", { [player] call fluss_fnc_recalcWeight; }];
		_newUnit addEventHandler ["Take", { [player] call fluss_fnc_recalcWeight; }];
		_newUnit addEventHandler ["InventoryClosed", { [player] call fluss_fnc_recalcWeight; }];
	}, true] call CBA_fnc_addPlayerEventHandler;

	// Background Calculation Loop
	[] spawn {
		private _originalPlayer = player;
		while {true} do {
			if (player isEqualTo _originalPlayer) then {
				[player] call fluss_fnc_recalcWeight;
			};
			sleep (missionNamespace getVariable ["fluss_calcInterval", 5]);
		};
	};

	// Fast Enforcement Loop
	[] spawn {
		private _originalPlayer = player;
		while {true} do {
			if (player isEqualTo _originalPlayer) then {
				private _weight = player getVariable ["fluss_currentWeight", 0];
				
				// Get current limits (handling role overrides)
				private _limits = [player] call fluss_fnc_getLimits;
				private _medWeight = _limits select 0;
				private _maxWeight = _limits select 1;

				// Uncomment this to test what the client reports as its own weight
				// hintSilent format ["My Weight: %1 \nMax: %2", _weight, _maxWeight];

				if (_weight > _maxWeight) then {		
					player forceWalk true;
					player allowSprint false;
				} else {
					if (_weight > _medWeight) then {
						if (getAnimSpeedCoef player == 1) then {player forceWalk false};
						player allowSprint false;
					}
					else // Auto catching _weight < _medWeight 
					{
						if (getAnimSpeedCoef player == 1) then {player forceWalk false};
						player allowSprint true;
					};
				};
			};
			
			sleep (missionNamespace getVariable ["fluss_enforceInterval", 0.1]);
		};
	};
};

// Inject the payload to all current and joining clients
[[], fluss_clientPayload] remoteExec ["bis_fnc_call", 0, "fluss_weight_jip"];

// SERVER-SIDE: Sync CBA Settings to injected clients
[] spawn {
	private _lastFreedom = fluss_useFreedomUnits;
	private _lastKJW = fluss_includeKJW;
	private _lastAnimate = fluss_includeAnimate;
	private _lastBOCR = fluss_includeBOCR;
	private _lastCalc = fluss_calcInterval;
	private _lastEnf = fluss_enforceInterval;
	private _lastMed = fluss_medWeight;
	private _lastMax = fluss_maxWeight;
	private _lastRole = fluss_roleOverrides;
	private _lastInv = fluss_separateInventoryUI;
	private _lastAce = fluss_separateAceArsenalUI;

	publicVariable "fluss_useFreedomUnits";
	publicVariable "fluss_includeKJW";
	publicVariable "fluss_includeAnimate";
	publicVariable "fluss_includeBOCR";
	publicVariable "fluss_calcInterval";
	publicVariable "fluss_enforceInterval";
	publicVariable "fluss_medWeight";
	publicVariable "fluss_maxWeight";
	publicVariable "fluss_roleOverrides";
	publicVariable "fluss_separateInventoryUI";
	publicVariable "fluss_separateAceArsenalUI";

	while {true} do {
		if (!isNil "fluss_useFreedomUnits" && {fluss_useFreedomUnits isNotEqualTo _lastFreedom}) then { publicVariable "fluss_useFreedomUnits"; _lastFreedom = fluss_useFreedomUnits; };
		if (!isNil "fluss_includeKJW" && {fluss_includeKJW isNotEqualTo _lastKJW}) then { publicVariable "fluss_includeKJW"; _lastKJW = fluss_includeKJW; };
		if (!isNil "fluss_includeAnimate" && {fluss_includeAnimate isNotEqualTo _lastAnimate}) then { publicVariable "fluss_includeAnimate"; _lastAnimate = fluss_includeAnimate; };
		if (!isNil "fluss_includeBOCR" && {fluss_includeBOCR isNotEqualTo _lastBOCR}) then { publicVariable "fluss_includeBOCR"; _lastBOCR = fluss_includeBOCR; };
		if (!isNil "fluss_calcInterval" && {fluss_calcInterval isNotEqualTo _lastCalc}) then { publicVariable "fluss_calcInterval"; _lastCalc = fluss_calcInterval; };
		if (!isNil "fluss_enforceInterval" && {fluss_enforceInterval isNotEqualTo _lastEnf}) then { publicVariable "fluss_enforceInterval"; _lastEnf = fluss_enforceInterval; };
		if (!isNil "fluss_medWeight" && {fluss_medWeight isNotEqualTo _lastMed}) then { publicVariable "fluss_medWeight"; _lastMed = fluss_medWeight; };
		if (!isNil "fluss_maxWeight" && {fluss_maxWeight isNotEqualTo _lastMax}) then { publicVariable "fluss_maxWeight"; _lastMax = fluss_maxWeight; };
		if (!isNil "fluss_roleOverrides" && {fluss_roleOverrides isNotEqualTo _lastRole}) then { publicVariable "fluss_roleOverrides"; _lastRole = fluss_roleOverrides; };
		if (!isNil "fluss_separateInventoryUI" && {fluss_separateInventoryUI isNotEqualTo _lastInv}) then { publicVariable "fluss_separateInventoryUI"; _lastInv = fluss_separateInventoryUI; };
		if (!isNil "fluss_separateAceArsenalUI" && {fluss_separateAceArsenalUI isNotEqualTo _lastAce}) then { publicVariable "fluss_separateAceArsenalUI"; _lastAce = fluss_separateAceArsenalUI; };
		sleep 5;
	};
};

	// SERVER-SIDE Debug loop
	[] spawn {
		private _fnc_convertMass = {
			params ["_mass"];
			private _val = _mass / 10;
			if (!fluss_useFreedomUnits) then { _val = _val / 2.20462; };
			_val
		};

		while {true} do {
			if (missionNamespace getVariable ["fluss_debug", false]) then {
				private _unitStr = if (fluss_useFreedomUnits) then {"lbs"} else {"kg"};
				
				// 1. Global Limits
				[format ["[W] GLOBAL: Med %1%2 | Max %3%2", fluss_medWeight, _unitStr, fluss_maxWeight]] remoteExec ["systemChat", 0];
				
				// 2. Role Overrides
				private _roleStr = trim fluss_roleOverrides;
				if (_roleStr != "" && {_roleStr != "[]"}) then {
					private _arr = call compile _roleStr;
					if (!isNil "_arr" && {_arr isEqualType []}) then {
						{
							if (_x isEqualType []) then {
								_x params [["_r", ""], ["_rMed", fluss_medWeight], ["_rMax", fluss_maxWeight]];
								[format ["[W] ROLE: %1 | Med %2%4 | Max %3%4", _r, _rMed, _rMax, _unitStr]] remoteExec ["systemChat", 0];
							};
						} forEach _arr;
					};
				};

				// 3. Player Breakdown
				{
					private _player = _x;
					private _role = _player getVariable ["fluss_role", "NONE"];
					private _vanillaMass = _player getVariable ["fluss_vanillaMass", loadAbs _player];
					private _kjwMass = _player getVariable ["fluss_kjwMass", 0];
					private _animateMass = _player getVariable ["fluss_animateMass", 0];
					private _bocrMass = _player getVariable ["fluss_bocrMass", 0];
					private _totalMass = _vanillaMass + _kjwMass + _animateMass + _bocrMass;

					private _totalForm = ([_totalMass] call _fnc_convertMass) toFixed 1;
					private _vanillaForm = ([_vanillaMass] call _fnc_convertMass) toFixed 1;
					private _kjwForm = ([_kjwMass] call _fnc_convertMass) toFixed 1;
					private _animateForm = ([_animateMass] call _fnc_convertMass) toFixed 1;
					private _bocrForm = ([_bocrMass] call _fnc_convertMass) toFixed 1;
					
					private _aceVLoad = _player getVariable ["ace_movement_vLoad", 0];
					private _aceTotalLoad = _player getVariable ["ace_movement_totalLoad", loadAbs _player];
					private _aceVLoadForm = ([_aceVLoad] call _fnc_convertMass) toFixed 1;
					private _aceTotalForm = ([_aceTotalLoad] call _fnc_convertMass) toFixed 1;

					[format ["[W] %1 (Role: %8): %2%7 (V:%3|K:%4|A:%5|B:%6) | ACE (vLoad:%9 | Total:%10)", name _player, _totalForm, _vanillaForm, _kjwForm, _animateForm, _bocrForm, _unitStr, _role, _aceVLoadForm, _aceTotalForm]] remoteExec ["systemChat", 0];
				} forEach (allPlayers - (entities "HeadlessClient_F"));
			};
			sleep (missionNamespace getVariable ["fluss_debugInterval", 10]);
		};
	};
