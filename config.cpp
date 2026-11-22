class CfgPatches
{
	class FLUSS_WeightLimit
	{
		requiredAddons[]=
		{
			"A3_Data_F_AoW_Loadorder",
			"CBA_main"
		};
		requiredVersion=0.1;
		units[]={};
		weapons[]={};
	};
};

class CfgFunctions
{
	class FLUSS
	{
		class FLUSS_WeightLimit_Functions
		{
			tag = "FLUSS";
			file="\ModerateWeightLimit\functions";
			class weightLimit {postInit = 1;};
		};
	};
};

class Extended_PreInit_EventHandlers {
    class weightLimit_initCBA {
        init = "call compile preprocessFileLineNumbers 'ModerateWeightLimit\functions\fn_cbaSettings.sqf'";
    };
};