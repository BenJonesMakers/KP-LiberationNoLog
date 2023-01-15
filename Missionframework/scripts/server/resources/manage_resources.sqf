waitUntil {!isNil "save_is_loaded"};
waitUntil {!isNil "KP_liberation_production"};
waitUntil {save_is_loaded};

sectors_recalculating = false;
sectors_timer = false;

["Production management started", "PRODUCTION"] call KPLIB_fnc_log;
private _start = 0;
while {GRLIB_endgame == 0} do {

    recalculate_sectors = false;

    if (((count (allPlayers - entities "HeadlessClient_F")) > 0) && ((count KP_liberation_production) > 0)) then {
        waitUntil {sleep 0.5; !sectors_recalculating};
        sectors_recalculating = true;

        private _time_update = false;
        if (sectors_timer) then {_time_update = true; sectors_timer = false;};

        _start = diag_tickTime;
        if (KP_liberation_production_debug > 0) then {[format ["Production interval started: %1 - _time_update: %2", diag_tickTime, _time_update], "PRODUCTION"] call KPLIB_fnc_log;};

        private _tempProduction = [];
        {
            private _storageArray = [];
            private _supplyValue = 0;
            private _ammoValue = 0;
            private _fuelValue = 0;
            private _time = _x select 8;



            private _storage = nearestObjects [(markerPos (_x select 1)), [KP_liberation_small_storage_building], 100];
            diag_log "_storage: ";
            diag_log _storage;
            _storage = _storage select {(_x getVariable ["KP_liberation_storage_type",-1]) == 1};
            diag_log "_storage after: ";
            diag_log _storage;
            if ((count _storage) > 0) then {
                _storage = (_storage select 0);
                diag_log "_storage after again: ";
                diag_log _storage;
                _storageArray = [(getPosATL _storage),(getDir _storage),(vectorUpVisual _storage)];
                diag_log "_storageArray: ";
                diag_log _storageArray;

                if (_time_update) then {

                    if ((_time - 1) < 1) then {
                        _time = KP_liberation_production_interval;
                        //in here
                        if (KP_liberation_noLogistics) then {
                                {
                                    // find the store locations nearby - old

                                        //private _fobStorage = nearestObjects [(_x select 0), [KP_liberation_large_storage_building], 100];
                                        //diag_log "_fobStorage: ";
                                        // diag_log _fobStorage;
                                        // diag_log "_fobStorage after: ";
                                        // diag_log _fobStorage;
                                        // _fobStorage = (_fobStorage select 0);
                                        // diag_log "_fobStorage after again: ";
                                        // diag_log _fobStorage;

                                    // find the store locations new
                                    private _storage_areas = nearestObjects [(_x select 0), [KP_liberation_small_storage_building, KP_liberation_large_storage_building], 150];

                                    diag_log "_storage_areas: ";
                                    diag_log _storage_areas;

                                    if ((count _storage_areas) == 0) then {
                                        diag_log "_storage_areas is empty ";
                                    };

                                    // find storage which isn't full and add it to a list

                                    private _storageWithEnoughFreeSpace = [];
                                    {
                                        if (typeOf _x == KP_liberation_large_storage_building) then {
                                            if ((count KP_liberation_large_storage_positions) - (count (attachedObjects _x)) > 1) then {
                                                _storageWithEnoughFreeSpace pushBack _x;
                                            };
                                        };
                                        if (typeOf _x == KP_liberation_small_storage_building) then {
                                            if ((count KP_liberation_small_storage_positions) - (count (attachedObjects _x)) > 1) then {
                                                _storageWithEnoughFreeSpace pushBack _x;
                                            };
                                        };
                                    } forEach _storage_areas;

                                    if ((count _storageWithEnoughFreeSpace) < 1) then {
                                        diag_log "_storageWithEnoughFreeSpace is empty ";
                                    };

                                    // create crate in the first position of the list

                                    private _fobStorage = (_storageWithEnoughFreeSpace select 0);

                                    diag_log "_fobStorage: ";
                                    diag_log _fobStorage;

                                private _crateType = KP_liberation_supply_crate;
                                switch (_x select 7) do {
                                    case 1: {_crateType = KP_liberation_ammo_crate; stats_ammo_produced = stats_ammo_produced + 100;};
                                    case 2: {_crateType = KP_liberation_fuel_crate; stats_fuel_produced = stats_fuel_produced + 100;};
                                    default {_crateType = KP_liberation_supply_crate; stats_supplies_produced = stats_supplies_produced + 100;};
                                    };

                                    private _crate = [_crateType, 100, getPosATL _fobStorage] call KPLIB_fnc_createCrate;
                                    [_crate, _fobStorage] call KPLIB_fnc_crateToStorage;

                                    diag_log "x: ";
                                    diag_log _x;

                                } forEach KP_liberation_fob_resources;
                        };

                        if (((count (attachedObjects _storage)) < 12) && !((_x select 7) == 3) && !KP_liberation_noLogistics) then {
                            private _crateType = KP_liberation_supply_crate;
                            switch (_x select 7) do {
                                case 1: {_crateType = KP_liberation_ammo_crate; stats_ammo_produced = stats_ammo_produced + 100;};
                                case 2: {_crateType = KP_liberation_fuel_crate; stats_fuel_produced = stats_fuel_produced + 100;};
                                default {_crateType = KP_liberation_supply_crate; stats_supplies_produced = stats_supplies_produced + 100;};
                            };

                            private _crate = [_crateType, 100, getPosATL _storage] call KPLIB_fnc_createCrate;
                            [_crate, _storage] call KPLIB_fnc_crateToStorage;
                        };

                        // here
                    } else {
                        _time = _time - 1;
                    };
                };

                {
                    switch ((typeOf _x)) do {
                        case KP_liberation_supply_crate: {_supplyValue = _supplyValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        case KP_liberation_ammo_crate: {_ammoValue = _ammoValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        case KP_liberation_fuel_crate: {_fuelValue = _fuelValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        default {[format ["Invalid object (%1) at storage area", (typeOf _x)], "ERROR"] call KPLIB_fnc_log;};
                    };
                } forEach (attachedObjects _storage);
            };

            _tempProduction pushBack [
                (markerText (_x select 1)),
                (_x select 1),
                (_x select 2),
                _storageArray,
                (_x select 4),
                (_x select 5),
                (_x select 6),
                (_x select 7),
                _time,
                _supplyValue,
                _ammoValue,
                _fuelValue
            ];
            if (KP_liberation_production_debug > 0) then {[format ["Production Update: %1", _tempProduction select _forEachIndex], "PRODUCTION"] call KPLIB_fnc_log;};
        } forEach KP_liberation_production;

        _tempProduction sort true;

        KP_liberation_production = +_tempProduction;
        sectors_recalculating = false;
    };
    if (KP_liberation_production_debug > 0) then {[format ["Production interval finished - Time needed: %1 seconds", diag_tickTime - _start], "PRODUCTION"] call KPLIB_fnc_log;};
    waitUntil {sleep 1; recalculate_sectors};
};
