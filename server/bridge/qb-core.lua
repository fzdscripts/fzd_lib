if Config.Framework ~= "qb-core" then return end

fzd.bridge = {}

local QBCore = exports['qb-core']:GetCoreObject()

local Players = {}

function fzd.bridge.getJob(src)
  return Players[src] and Players[src].job
end

function fzd.bridge.hasJob(src, job, grade)
  local Player = Players[src]

  if not Player then
    return false
  end

  return Player.job.name == job and Player.job.grade >= grade
end

function fzd.bridge.getPlayer(src)
  return Players[src]
end

function fzd.bridge.getPlayerFromIdentifier(identifier)
  for _, Player in pairs(Players) do
    if Player.identifier == identifier then
      return Player
    end
  end

  return false
end

function fzd.bridge.getPlayerIdentifier(src)
  return Players[src] and Players[src].identifier or false
end

function fzd.bridge.getFullName(src)
  return Players[src] and Players[src].name or false
end

function fzd.bridge.getMoney(src, type)
  local Player = QBCore.Functions.GetPlayer(src)

  if not Player then
    return
  end

  return Player.PlayerData.money[type]
end

function fzd.bridge.addMoney(src, amount, type, reason)
  local Player = QBCore.Functions.GetPlayer(src)

  if not Player then
    return
  end

  Player.Functions.AddMoney(type, amount, reason or 'unknown')
end

function fzd.bridge.removeMoney(src, amount, type, reason)
  local Player = QBCore.Functions.GetPlayer(src)

  if not Player then
    return
  end

  if Player.PlayerData.money[type] < amount then
    return
  end

  Player.Functions.RemoveMoney(type, amount, reason or 'unknown')
end

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
  local Player = Players[source]

  if not Player then
    return
  end

  TriggerEvent("fzd_lib:server:updateJob", source, Player.job, job.name, job.grade)

  Player.job.name = job.name
  Player.job.grade = job.grade
end)

local function updatePlayerData(PlayerData)
  Players[PlayerData.source] = {
    job = {
      name = PlayerData.job.name,
      grade = PlayerData.job.grade
    },

    identifier = PlayerData.citizenid,
    name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
    source = PlayerData.source
  }
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
  local PlayerData = Player.PlayerData

  updatePlayerData(PlayerData)
  TriggerEvent("fzd_lib:server:playerLoaded", PlayerData.source, Players[PlayerData.source])
end)

CreateThread(function()
  Wait(250)

  for _, sourceId in ipairs(GetPlayers()) do
    local Player = QBCore.Functions.GetPlayer(tonumber(sourceId))

    if not Player then
      return
    end

    updatePlayerData(Player.PlayerData)
    Wait(50)
  end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
  if Players[source] then
    TriggerEvent("fzd_lib:server:playerUnloaded", source)
    Players[source] = nil
  end
end)

AddEventHandler('playerDropped', function()
  if Players[source] then
    TriggerEvent('fzd_lib:server:playerUnloaded', source, Players[source])
    Players[source] = nil
  end
end)