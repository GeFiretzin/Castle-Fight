moon_shine_blessing = class({})

LinkLuaModifier("modifier_moon_shine_blessing", "abilities/night_elves/moon_shine_blessing.lua", LUA_MODIFIER_MOTION_NONE)

function moon_shine_blessing:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local allies = FindOrganicAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local target
  for _,ally in allies do
    if not ally:IsRealHero() then
      if target == nil or ally:GetHealth() < ally:GetMaxHealth() then
        target = ally
      end
    end
  end

  if not target then return end

  local radius = ability:GetSpecialValueFor("radius")
  local duration = ability:GetSpecialValueFor("duration")
  local health_restored = ability:GetSpecialValueFor("health_restored")
  local mana_restored = ability:GetSpecialValueFor("mana_restored")

  caster:EmitSound("Hero_Treant.LivingArmor.Cast")

  local units = FindOrganicAlliesInRadius(target, radius)
  for _,unit in pairs(units) do
    if not IsCustomBuilding(unit) and not unit:IsRealHero() then
      unit:Heal(health_restored, caster)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, health_restored, nil)

      unit:GiveMana(mana_restored)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD , unit, mana_restored, nil)

      unit:EmitSound("DOTA_Item.Mekansm.Target")

      unit:AddNewModifier(caster, ability, "modifier_moon_shine_blessing", {duration = duration})
    end
  end
end

modifier_moon_shine_blessing = class({})

function modifier_moon_shine_blessing:OnCreated()
  local ability = self:GetAbility()

  self.armor = ability:GetSpecialValueFor("armor")
end

function modifier_moon_shine_blessing:GetEffectName()
  "particles/econ/items/treant_protector/ti7_shoulder/treant_ti7_crimson_livingarmor.vpcf"
end

function modifier_moon_shine_blessing:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_moon_shine_blessing:GetModifierPhysicalArmorBonus()
  return self.armor
end