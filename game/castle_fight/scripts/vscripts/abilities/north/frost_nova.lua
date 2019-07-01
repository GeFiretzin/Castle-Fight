ice_queen_frost_nova = class({})

LinkLuaModifier("modifier_ice_queen_frost_nova", "abilities/north/frost_nova.lua", LUA_MODIFIER_MOTION_NONE)

function ice_queen_frost_nova:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local aoe_damage = ability:GetSpecialValueFor("aoe_damage")
  local duration = ability:GetSpecialValueFor("duration")
  local radius = ability:GetSpecialValueFor("radius")

  local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:IsRealHero() then
      ApplyDamage({
        victim = target,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })

      target:AddNewModifier(caster, ability, "modifier_ice_queen_frost_nova", {duration = duration})
    end
  end

  -- The target takes double damage
  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = ability
  })
end

modifier_ice_queen_frost_nova = class({})

function modifier_ice_queen_frost_nova:IsDebuff()
  return true
end

function modifier_ice_queen_frost_nova:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
  return decFuns
end

function modifier_ice_queen_frost_nova:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.move_slow = self.ability:GetSpecialValueFor("slow")
  self.attack_slow = self.ability:GetSpecialValueFor("slow")
end


function modifier_ice_queen_frost_nova:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end

function modifier_ice_queen_frost_nova:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow
end

function modifier_ice_queen_frost_nova:GetEffectName()
  return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_ice_queen_frost_nova:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end