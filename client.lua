local QBCore = exports['qb-core']:GetCoreObject()

local isWorking = false
local vehicle = nil
local vehicleChoice = nil
local ped = nil
local cooldown = nil
local spawnLocation = nil
local destinationLocation = nil
local vehBlip = nil
local destinationBlip = nil
local spawns = nil
local spawnDriving = false
local player = nil
local isLoggedIn = false
local startEntitySpawned = false
local table = nil
local laptop = nil
local npc = nil
local rank = nil
local copVehicle = nil
local cop = nil
local goFindCar = nil
local goFindParkedCar = nil

local timeout = 0
local level = 1
local tableModel = GetHashKey("prop_table_03b")
local laptopModel = GetHashKey("prop_laptop_01a")
local vehicleHash = GetHashKey("police4")
local pedHash = GetHashKey("s_m_y_cop_01")

RegisterNetEvent('cardelivery:client-receive-rank')
AddEventHandler('cardelivery:client-receive-rank', function(rank_in)
    rank = rank_in
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent("qb-clothes:loadPlayerSkin")
    isLoggedIn = true
    player = PlayerPedId()

    if not startEntitySpawned then
        CreateThread(function()
            TriggerServerEvent('cardelivery:GetMetaData')
            Citizen.Wait(100)
            if not showNpc then
                RequestModel(tableModel)
                while not HasModelLoaded(tableModel) do
                    Citizen.Wait(5)
                end

                RequestModel(laptopModel)
                while not HasModelLoaded(laptopModel) do
                    Citizen.Wait(5)
                end


                table = CreateObject(tableModel, npcCoords.x, npcCoords.y, npcCoords.z - 0.99, false, true, false)
                laptop = CreateObject(laptopModel, npcCoords.x, npcCoords.y, npcCoords.z - 0.2, false, true, false)
            
                FreezeEntityPosition(table, true)
                FreezeEntityPosition(laptop, true)
            else
                RequestModel(pedModel)

                while not HasModelLoaded(pedModel) do
                    Citizen.Wait(5)
                end
                
                npc = CreatePed(4, pedModel, npcCoords.x, npcCoords.y, npcCoords.z - 1, npcHeading, false, true)
                FreezeEntityPosition(npc, true)
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                TaskStartScenarioInPlace(npc, "WORLD_HUMAN_DRUG_DEALER", 0, true)
            end
            startEntitySpawned = true
            UpdateLevel()
        end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

-- Allows the ability to reload this resource live
-- Remove the if for live version
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(100)
        player = PlayerPedId()
        isLoggedIn = true
    end

    if not startEntitySpawned then
        CreateThread(function()
            TriggerServerEvent('cardelivery:GetMetaData')
            Citizen.Wait(100)
            if not showNpc then
                RequestModel(tableModel)
                while not HasModelLoaded(tableModel) do
                    Citizen.Wait(5)
                end

                RequestModel(laptopModel)
                while not HasModelLoaded(laptopModel) do
                    Citizen.Wait(5)
                end


                table = CreateObject(tableModel, npcCoords.x, npcCoords.y, npcCoords.z - 0.99, false, true, false)
                laptop = CreateObject(laptopModel, npcCoords.x, npcCoords.y, npcCoords.z - 0.2, false, true, false)
            
                FreezeEntityPosition(table, true)
                FreezeEntityPosition(laptop, true)
            else
                RequestModel(pedModel)

                while not HasModelLoaded(pedModel) do
                    Citizen.Wait(5)
                end
                
                npc = CreatePed(4, pedModel, npcCoords.x, npcCoords.y, npcCoords.z - 1, npcHeading, false, true)
                FreezeEntityPosition(npc, true)
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                TaskStartScenarioInPlace(npc, "WORLD_HUMAN_DRUG_DEALER", 0, true)
            end
            startEntitySpawned = true
            UpdateLevel()
        end)
    end
end)

RegisterNetEvent("cardelivery:update-cooldown")
AddEventHandler("cardelivery:update-cooldown", function(status)
    cooldown = status
end)

-- Adds a blip
if showblip then
    local blip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
    SetBlipSprite(blip, 524)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(blip)
end

function SpawnCopCar()
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Citizen.Wait(5)
    end

    if spawnDriving then
        copVehicle = CreateVehicle(vehicleHash, drive_spawns[spawnLocation].copx, drive_spawns[spawnLocation].copy, drive_spawns[spawnLocation].copz, drive_spawns[spawnLocation].copHeading, true, true)
    else
        copVehicle = CreateVehicle(vehicleHash, parked_spawns[spawnLocation].copx, parked_spawns[spawnLocation].copy, parked_spawns[spawnLocation].copz, parked_spawns[spawnLocation].copHeading, true, true)
    end

    SetModelAsNoLongerNeeded(vehicleHash)
    cop = CreatePed(4, pedHash, 0, 0, 0, 0, true, true)
    GiveWeaponToPed(cop, "weapon_pistol", 999, false, true)
    SetPedIntoVehicle(cop, copVehicle, -1)
end

function carWithAi()
    CreateThread(function()
        TriggerServerEvent("cardelivery:start_cooldown")
        TriggerServerEvent('cardelivery:GetMetaData')
        vehicleChoice = math.random(1, #vehicles[level])
        local model = GetHashKey(vehicles[level][vehicleChoice].model)

        RequestModel(model)
        local modelLoadingTimeout = 5000
        while not HasModelLoaded(model) do
            Citizen.Wait(10)
            modelLoadingTimeout = modelLoadingTimeout - 10
            if modelLoadingTimeout <= 0 then
                QBCore.Functions.Notify(CarModelLoadingTimeout, "error", 6000)
                isWorking = false
                print("ERROR: MODEL LOADING TIMED OUT")
                return
            end
        end

        -- Decides if the car should spawn parked or driving (Will be made soon)
        if math.random(0, 10) % 2 == 1 and driveAround then
            spawns = drive_spawns
            spawnDriving = true
            print("Car will be driving around!") -- For debugging reasons
        else
            spawns = parked_spawns
            print("Car will be parked!") -- For debugging reasons
        end

        if spawns == nil or #spawns < 1 then
            QBCore.Functions.Notify(NoSpawnLocationInConfigFile, 'error', 5000)
            isWorking = false
            return
        end

        if #spawns >= 1 then
            spawnLocation = math.random(1, #spawns)
        else
            spawnLocation = #spawns
        end

        vehicle = CreateVehicle(model, spawns[spawnLocation].x, spawns[spawnLocation].y, spawns[spawnLocation].z, spawns[spawnLocation].heading, true, true)
        local netid = NetworkGetNetworkIdFromEntity(vehicle)

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetNetworkIdCanMigrate(netid, true)

        if spawnDriving then
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleNeedsToBeHotwired(vehicle, false)
        else
            SetVehicleDoorsLocked(vehicle, 2)
            SetVehicleNeedsToBeHotwired(vehicle, true)
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        SetModelAsNoLongerNeeded(model)

        if spawnDriving then
            ped = CreatePed(4, pedModel, spawns[spawnLocation].x, spawns[spawnLocation].y, spawns[spawnLocation].z, 0, true, true)
            SetPedIntoVehicle(ped, vehicle, -1)
            TaskVehicleDriveWander(driver, veh, 15.0, SetDriveTaskDrivingStyle(ped, 786603))
        end

        vehBlip = AddBlipForEntity(vehicle)

        SetBlipRoute(vehBlip, true)
        SetBlipColour(vehBlip, 5)
        SetBlipRouteColour(vehBlip, 5)

        goFindCar = text_GoFindCar(spawns, level, vehicleChoice, spawnLocation)
        goFindParkedCar = text_GoFindParkedCar(spawns, level, vehicleChoice, spawnLocation)

        if notification and not showAboveHead then
            if spawnDriving then
                QBCore.Functions.Notify(goFindCar, "success", 3500)
            else
                QBCore.Functions.Notify(goFindParkedCar, "success", 3500)
            end
        end

        local zCoord = 0
        player = PlayerPedId()
        while not IsPedInVehicle(player, vehicle, true) and isWorking and IsVehicleDriveable(vehicle, true) and GetVehicleEngineHealth(vehicle) > 50 do
            Citizen.Wait(5)
            if showNpc then
                zCoord = npcCoords.z + 1
            else
                zCoord = npcCoords.z
            end

            if spawnDriving then
                TaskVehicleDriveWander(driver, veh, 15.0, SetDriveTaskDrivingStyle(ped, 786603))
            end
            
            timeout = timeout + 0.5
            if notification and timeout < 200 and showAboveHead then
                if spawnDriving then
                    DrawText3D(npcCoords.x, npcCoords.y, zCoord, goFindCar)
                else
                    DrawText3D(npcCoords.x, npcCoords.y, zCoord, goFindParkedCar)
                end
            end
        end

        SetBlipRoute(vehBlip, false)
        RemoveBlip(vehBlip)
        
        destinationLocation = math.random(1, #destinations)
        destinationBlip = AddBlipForCoord(destinations[destinationLocation].x, destinations[destinationLocation].y, destinations[destinationLocation].z)
        SetBlipRoute(destinationBlip, true)
        SetBlipColour(destinationBlip, 5)
        SetBlipRouteColour(destinationBlip, 5)

        player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)
        local countdown = choiceTimer * 1000

        if IsVehicleDriveable(vehicle, true) and GetVehicleEngineHealth(vehicle) > 50 then
            QBCore.Functions.Notify(KeepTheCar, "primary", 6000)
            if math.random(1, chanceToSpawnCop) == 1 and copSpawn then
                print("Local cops have been tipped off") -- For debugging reasons
                SpawnCopCar()
            else
                print("Cops were not tipped off") -- For debugging reasons
            end
        end

        while (Vdist2(destinations[destinationLocation].x, destinations[destinationLocation].y, destinations[destinationLocation].z, playerCoords.x, playerCoords.y, playerCoords.z) > 15 or GetEntitySpeed(vehicle) > 0) and IsVehicleDriveable(vehicle, true) and GetVehicleEngineHealth(vehicle) > 50 and isWorking do
            Citizen.Wait(8)
            playerCoords = GetEntityCoords(player)
            TaskVehicleDriveToCoord(cop, copVehicle, playerCoords.x, playerCoords.y, playerCoords.z, 30.0, 1.0, vehicleHash, SetDriveTaskDrivingStyle(ped, 786603), 1.0, true)
            TaskCombatPed(cop, player, 0, 16)

            if abilityToKeepVehicle and countdown > choiceTimer then
                if IsControlPressed( 0, 303) then
                    isWorking = false

                    DeletePed(cop)
                    UpdateRank(rankPenalty)
                    
                    QBCore.Functions.DeleteVehicle(copVehicle)
                    QBCore.Functions.Notify(KeepTheCar_JobIsCancelled, "primary", 5000)
                    QBCore.Functions.Notify(SubtractedXP, "error", 5000)
                    Citizen.Wait(300)
                end
                countdown = countdown - 8
            end
        end

        SetBlipRoute(destinationBlip, false)
        RemoveBlip(destinationBlip)

        if isWorking then
            DeletePed(cop)
            QBCore.Functions.DeleteVehicle(copVehicle)

            if GetVehicleEngineHealth(vehicle) > 50 and IsVehicleDriveable(vehicle, true) then
                local extraPoints = GetVehicleEngineHealth(vehicle) + GetVehicleBodyHealth(vehicle)
                TaskLeaveVehicle(PlayerPedId(), vehicle, 256)
                Citizen.Wait(2000)
                -- TriggerServerEvent("cardelivery:addMoney", math.floor(math.random(destinations[destinationLocation].from, destinations[destinationLocation].to) + (extraPoints / 2.0) + level * 1000))
                -- TriggerServerEvent("cardelivery:addMoney", math.floor(math.random(destinations[destinationLocation].from, destinations[destinationLocation].to) / 4.0 ))
				 TriggerServerEvent("cardelivery:addMoney", math.random(30, 50) * 10)
	
                extraPoints = math.floor(extraPoints / 10.0)
                UpdateRank(xpGain + extraPoints)
                -- QBCore.Functions.Notify(text_added  .. " " .. (xpGain + extraPoints) .. " " .. text_xpToCarDeliveryRank, "success", 5000)
                QBCore.Functions.DeleteVehicle(vehicle)
            else
                UpdateRank(rankPenalty)
                QBCore.Functions.Notify(VehicleHasBeenDestroyed_JobIsCancelled, "error", 3000)
                -- QBCore.Functions.Notify(SubtractedXP, "error", 5000)
                Citizen.Wait(2000)
                QBCore.Functions.DeleteVehicle(vehicle)
            end
        end
        isWorking = false
    end)
end

CreateThread(function()
    local notifSent = false

    while true do
        Citizen.Wait(10)

        local pCoords = GetEntityCoords(PlayerPedId())

        if Vdist2(npcCoords, pCoords) < startSize and isLoggedIn then
            timeout = 0
            if IsControlPressed(0, 38) then
                if isWorking then
                    isWorking = false
                    QBCore.Functions.Notify(JobQuit, "error", 3000)
                    QBCore.Functions.DeleteVehicle(vehicle)
                    DeletePed(ped)
                    timeout = 200
                    Citizen.Wait(500)
                else 
                    if not cooldown then
                        isWorking = true
                        QBCore.Functions.Notify(JobStarted, "success", 3000)
                        carWithAi()
                        Citizen.Wait(500)
                    else
                        TriggerServerEvent("cardelivery:request-cooldown-time")
                        Citizen.Wait(500)
                    end
                end

            else
                if not notifSent then
                    if not isWorking then
                        QBCore.Functions.Notify(StartJob, "primary", 3000)
                    else
                        QBCore.Functions.Notify(QuitJob, "primary", 3000)
                    end
                    notifSent = true
                end
            end
        else
            notifSent = false
        end
    end
end)

-- Code taken from QBCore resources, QBCore.Functions.DrawText3D
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function UpdateRank(change)
    change = tonumber(change)

    if rank == nil then
        TriggerServerEvent('cardelivery:GetMetaData')
    end

    if rank + change < 0 then
        change = rank * -1
    end

    while true do
        Citizen.Wait(500)

        if rank ~= nil then
            TriggerServerEvent('QBCore:Server:SetMetaData', 'cardeliveryxp', rank + change)
            rank = rank + change
            UpdateLevel()
            break
        else
            TriggerServerEvent('cardelivery:GetMetaData')
        end
    end
end

function UpdateLevel()
    for i=1, #levelXpGoal, 1 do
        if rank >= levelXpGoal[i] then
            level = i + 1
        end
    end
end
