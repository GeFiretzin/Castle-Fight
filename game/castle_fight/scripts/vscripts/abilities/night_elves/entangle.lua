druid_entangle = class({})
druid_mass_entangle = class({})

LinkLuaModifier("modifier_druid_entangle", "abilities/night_elves/entangle", LUA_MODIFIER_MOTION_NONE)

function druid_entangle:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_druid_entangle", {duration = duration})
end

function druid_entangle:CastFilterResultTarget(target)
  if target:HasFlyMovementCapability() or IsCustomBuilding(target) then return UF_FAIL_CUSTOM end

  return UF_SUCCESS
end

function druid_mass_entangle:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")
  local num_targets = ability:GetSpecialValueFor("targets")

  local targets = {}
  table.insert(targets, target)

  local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())
  for _,enemy in pairs(enemies) do
    if not enemy == target and not IsCustomBuilding(target) and not target:HasFlyMovementCapability() then
      table.insert(targets, enemy)
    end
  end

  for _,unit in pairs(targets) do
    unit:AddNewModifier(caster, ability, "modifier_druid_entangle", {duration = duration})
  end
end

function druid_mass_entangle:CastFilterResultTarget(target)
  if target:HasFlyMovementCapability() or IsCustomBuilding(target) then return UF_FAIL_CUSTOM end

  return UF_SUCCESS
end

modifier_druid_entangle = class({})

function modifier_druid_entangle:OnCreated()
  self.parent = self:GetParent()
  self.ability = self:GetAbility()
  self.caster = self:GetCaster()

  self.dps = self.ability:GetSpecialValueFor("dps")

  self:StartIntervalThink(1)
end

function modifier_druid_entangle:OnIntervalThink()
  if IsServer() then
    ApplyDamage({
      attacker = self.caster,
      victim = self.parent,
      ability = self.ability,
      damage = self.dps,
      damage_type = DAMAGE_TYPE_MAGICAL
    })    
  end
end

function modifier_druid_entangle:CheckState()
  return { 
    [MODIFIER_STATE_ROOTED] = true,
  }
end