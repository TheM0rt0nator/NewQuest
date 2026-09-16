local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestAnimations = require(ReplicatedStorage.Modules.QuestAnimations)

local DoctorPatient = {}
local patient
local track
local originalPivot

function DoctorPatient.Stop()
	QuestAnimations.Stop(track)
	track = nil

	if patient and patient.Parent then
		patient:PivotTo(originalPivot)
	end

	patient = nil
	originalPivot = nil
end

function DoctorPatient.Start(stage)
	if patient == stage.Patient and track then
		return
	end

	DoctorPatient.Stop()
	patient = stage.Patient
	originalPivot = patient:GetPivot()

	-- MQ's bed clip supplies the recline; its root must remain upright.
	local position = originalPivot.Position
	patient:PivotTo(CFrame.lookAt(position, position - Vector3.xAxis))
	track = QuestAnimations.Play(patient.Humanoid, "HospitalBed", true)
end

return DoctorPatient
