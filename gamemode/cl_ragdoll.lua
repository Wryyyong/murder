local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

if not PlayerMeta.GetRagdollEntityOld then
	PlayerMeta.GetRagdollEntityOld = PlayerMeta.GetRagdollEntity
end

function PlayerMeta:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then return ent end

	return self:GetRagdollEntityOld()
end

if not EntityMeta.GetRagdollOwnerOld then
	EntityMeta.GetRagdollOwnerOld = EntityMeta.GetRagdollOwner
end

function EntityMeta:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then return ent end

	return self:GetRagdollOwnerOld()
end
