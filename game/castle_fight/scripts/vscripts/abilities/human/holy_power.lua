holy_power = class({})
LinkLuaModifier("modifier_holy_power", "abilities/human/holy_power.lua", LUA_MODIFIER_MOTION_NONE)

function holy_power:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local radius = ability:GetSpecialValueFor("radius")

  local allies = FindAlliesInRadius(caster, radius)

  for _,unit in pairs(allies) do
    unit:AddNewModifier(caster, ability, "modifier_holy_power", {})
  end
end

modifier_holy_power = class({})

function modifier_holy_power:IsHidden() return true end

function modifier_holy_power:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.attack_speed = self.ability:GetSpecialValueFor("attack_speed")
end

function modifier_holy_power:DeclareFunctions()
  return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_holy_power:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end