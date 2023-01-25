/*

ROS Vehicle Airdrop script v1.2 (2022) by Rickoshay

Description
-----------
Simple vehicle airdrop on player map selected pos

Legal Stuff
-----------
If used in a mission or mod or derivative work and shared via the Steam Workshop
then full credit must be given to me in your mision and on the Steam Workshop page.

Usage:
------
Suggest use a Radio trigger to call this airdrop script or an addaction on an object like a laptop:

Radio trigger
[player, "vehicleclass"] execvm "scripts\ROS_AirDrop.sqf";
Example 1: [player, "B_Quadbike_01_F"] execvm "scripts\ROS_AirDrop.sqf";
If no vehicle class is specified in your command line - the default vehicle below will be used.
Example 2: [player] execvm "scripts\ROS_AirDrop.sqf";

Addaction on an object i.e. laptop
this addAction ["<t color='#FF8000'>Airdrop Quad</t>", {[player, "B_Quadbike_01_F"] execvm "scripts\ROS_AirDrop.sqf"},[],1,true,true,"","player distance _target < 3"];
this addAction ["<t color='#FF8000'>Airdrop LSV HMG</t>", {[player, "B_LSV_01_armed_F"] execvm "scripts\ROS_AirDrop.sqf"},[],2,true,true,"","player distance _target < 3"];

Installation: (demo files for example)
--------------------------------------
Copy this script to your mission Scripts folder (or make a folder called scripts)
Copy c17.ogg Sound to your mission Sound folder (or make a folder called sound)
Add the following sound class C17 to CFGSounds in description.ext (or make a text file called description.ext)

/*
class CfgSounds {
    sounds[] = {};

    class c17 {
        name="c17";
        sound[]={"scripts\server\HAWKESTFSscripts\c17.ogg", 2, 1};
        titles[] = {};
    };
};

YOU CAN ADJUST THE FOLLOWING SETTINGS
------------------------------------*/
ROSTotaldrops = 10; // Total number of allowed support drops
_dropheight = 500; // Remember wind and height affects travel distance
_droptime = 15; // Delay time before the drop takes place on the specified position at the above height
_defaultVehicle = "B_LSV_01_AT_F"; // Change this class to suit your mission needs

/* HOW TO GET THE DEFAULT VEHICLE CLASS YOU WANT TO DROP
1) Place the vehicle you need the class for in the Eden editor
2) Right click on the veh and select log class to clipboard
3) Paste that class name including the " " in the default class as per above or into your addaction or radio trigger

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// DO NOT CHANGE ANYTHING BELOW THIS LINE ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

params ["_unit","_vehtype"];

if !(hasInterface) exitWith {};

// Default vehicle (see above)
if (isNil "_vehtype") then {_vehtype = _defaultVehicle};

if (isnil "ROSvehDropNum") then {ROSvehDropNum = 0};

if ((1 + ROSvehDropNum) > ROSTotaldrops) exitWith {hint "Support drop limit exceeded."};

hint "Click on the map to select drop position.";

Relocate_clickpos = [];

openMap true;
Relocate_drop = false;
Relocate_clickpos = [];

onMapSingleClick "Relocate_clickpos = _pos; Relocate_drop = true; onMapSingleClick ''; true;";
waitUntil {Relocate_drop or !(visiblemap)};
if (!visibleMap) exitwith {
    hint "Drop cancelled.";
    Relocate_clickpos = [];
    breakOut "";
};

if (Relocate_drop) then {

    _mkrTxt = format ["%1 drop",name _unit];
    _mkrname = "drop";
    _mkr = createMarkerLocal [_mkrname, Relocate_clickpos];
    _mkrname setMarkerPos Relocate_clickpos;
    _mkr setMarkerTypeLocal "hd_dot";
    _mkr setMarkerColorLocal "colorblue";
    _mkr setMarkerSizeLocal [0.2,0.2];
    _mkr setMarkerTextLocal _mkrtxt;
    _mkr setMarkerAlpha 1;

    ROSvehDropNum = (ROSvehDropNum +1);
    publicVariable "ROSvehDropNum";
    playSound "beep";
    sleep 1;
    openMap false;
    hint format ["Support drop on marked position\nETA %1 secs.", _droptime];

    // stop wind temporarily
    _curwind = wind;
    0 setWindForce 0;
    setWind [0, 0, true];

    sleep _droptime;

    // Simulate flyby of C17
    ["c17"] remoteExec ["playSound"];

    sleep 5;

    // Adjust drop target pos allow for slope and clutter
    _pos = Relocate_clickpos;

    //[center,minDist,maxDist,objDist,waterMode,maxGrads,shoreMode]
    _pos = [_pos, 2, 20, 5, 0, 20, 0] call BIS_fnc_findSafePos;
    _vehpos = [_pos select 0, _pos select 1, _dropheight];
    "drop" setMarkerPos _pos;
    _veh = createVehicle [_vehtype, _vehpos, [], 0, "CAN_COLLIDE"];
    _chute = createVehicle ["B_Parachute_02_F", _vehpos, [], 10, "FLY"];
    _veh attachto [_chute,[0,0,1]];
    hint "Heads up!\nSupport drop on marked position Sir.";
    // Stop damage on decent
    [_veh, false] remoteExec ["allowDamage", _veh];

    // Detach chute and reset wind
    waitUntil{(getposATL _veh select 2) <2 or isNull attachedTo _veh};
    detach _veh;
    _veh setPosATL [(getPosATL _veh select 0),(getPosATL _veh select 1), 0.1];
    setWind [_curwind select 0, _curwind select 1, true];

    waitUntil{isTouchingGround _veh or isNull _veh};
    sleep 1;
    // Allow damage after landing
    [_veh, true] remoteExec ["allowDamage", _veh];
    hint format ["%1 vehicle touch down at marked position",_unit];
    waituntil {_unit distance _veh < 40};
    // Remove marker
    deleteMarkerLocal "drop";
};

hint "";
