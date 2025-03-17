local duffle = true

local dbtxterr = "Hey - This weapon can only be taken out of a car or a dufflebag."
local bwtxterr = "Hey - This weapon can only be taken out of a car."

local smgs = {
    "WEAPON_MICROSMG", "WEAPON_MINISMG", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG", "WEAPON_COMBATPDW",
    "WEAPON_GUSENBERG", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2", "WEAPON_PUMPSHOTGUN", "WEAPON_SWEEPERSHOTGUN", "WEAPON_SAWNOFFSHOTGUN",
    "WEAPON_BULLPUPSHOTGUN", "WEAPON_ASSAULTSHOTGUN", "WEAPON_HEAVYSHOTGUN", "WEAPON_DBSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2",
    "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2", "WEAPON_ADVANCEDRIFLE",
    "WEAPON_SPECIALCARBINE", "WEAPON_BULLPUPRIFLE", "WEAPON_COMPACTRIFLE", "WEAPON_SPECIALCARBINE_MK2",
    "WEAPON_BULLPUPRIFLE_MK2", "WEAPON_MG", "WEAPON_MUSKET", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2"
}

local currWeapon = GetHashKey("WEAPON_UNARMED")
local slungWeapon = nil
local weaponObject = nil

RegisterCommand("sling", function()
    local playerPed = GetPlayerPed(-1)
    local weapon = GetSelectedPedWeapon(playerPed)
    
    if isWeaponSMG(weapon) then
        slungWeapon = weapon
        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
        AttachWeaponToBack(playerPed, weapon)
        drawNotification("~p~[DCRP V3]~c~ Weapon slung on back.")
    else
        drawNotification("~r~You can only sling certain weapons.")
    end
end, false)

RegisterCommand("unsling", function()
    local playerPed = GetPlayerPed(-1)
    if slungWeapon then
        RemoveWeaponFromBack(playerPed)
        GiveWeaponToPed(playerPed, slungWeapon, 999, false, true)
        currWeapon = slungWeapon
        slungWeapon = nil
        drawNotification("~p~[DCRP V3]~c~ Weapon unslung.")
    else
        drawNotification("~r~No weapon slung.")
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Wait(250)
        local playerPed = GetPlayerPed(-1)
        if playerPed then
            local weapon = GetSelectedPedWeapon(playerPed, true)
            
            -- Prevent using slung weapon until unslung
            if slungWeapon and weapon == slungWeapon then
                drawNotification("~p~[DCRP V3]~c~ You must unsling your weapon first.")
                SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
            end
            
            if currWeapon ~= weapon then
                if isWeaponSMG(weapon) then
                    if slungWeapon and weapon == slungWeapon then
                        drawNotification("~p~[DCRP V3]~c~ You must unsling your weapon first.")
                        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
                    else
                        local vehicle = VehicleInFront()
                        if GetVehiclePedIsIn(playerPed, false) == 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
                            currWeapon = weapon
                            SetVehicleDoorOpen(vehicle, 5, false, false)
                            Citizen.Wait(2000)
                            SetVehicleDoorShut(vehicle, 5, false)
                        else
                            if not hasDuffleBag(playerPed) then
                                Wait(1)
                                drawNotification("~p~[DCRP V3]~c~ " .. dbtxterr)
                                SetCurrentPedWeapon(playerPed, -1569615261, true)
                            else
                                currWeapon = weapon
                            end
                        end
                    end
                else
                    currWeapon = GetHashKey("WEAPON_UNARMED")
                end
            end
        end
    end
end)

function VehicleInFront()
    local player = PlayerPedId()
    local pos = GetEntityCoords(player)
    local entityWorld = GetOffsetFromEntityInWorldCoords(player, 0.0, 2.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 30, player, 0)
    local _, _, _, _, result = GetRaycastResult(rayHandle)
    return result
end

function isWeaponSMG(model)
    for _, smg in pairs(smgs) do
        if model == GetHashKey(smg) then
            return true
        end
    end
    return false
end

function hasDuffleBag(playerPed)
    return GetPedDrawableVariation(playerPed, 5) == 45 and GetPedTextureVariation(playerPed, 5) == 0
end

function drawNotification(Notification)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(Notification)
    DrawNotification(false, false)
end

function AttachWeaponToBack(playerPed, weapon)
    local boneIndex = GetPedBoneIndex(playerPed, 24816)
    local weaponModel = GetWeapontypeModel(weapon)
    RequestModel(weaponModel)
    while not HasModelLoaded(weaponModel) do
        Wait(10)
    end
    if weaponObject then
        DeleteObject(weaponObject)
    end
    weaponObject = CreateObject(weaponModel, 0, 0, 0, true, true, false)
    AttachEntityToEntity(weaponObject, playerPed, boneIndex, 0.15, -0.20, 0.05, 0, 0.0, 180.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(weaponModel)
    SetEntityAsMissionEntity(weaponObject, true, true)
end

function RemoveWeaponFromBack(playerPed)
    if weaponObject then
        DeleteObject(weaponObject)
        weaponObject = nil
    end
end
