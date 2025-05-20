--> Services
local ReplicatedStorage = game.ReplicatedStorage
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--> Player Major
local player = game.Players.LocalPlayer
local character = player.Character

--> Modules
local UPC = require(ReplicatedStorage.UnifiedPlayerController)
local Dialogue = UPC.Dialogue
local CamController = UPC.Camera
local InteractionController = UPC.Interaction
local Interactables = UPC.Interactables

local UPCPlayer, UPCSettings = UPC.CreatePlayer(player)

--> Player Minor
local head = character:WaitForChild("Head")
local hrp = character:WaitForChild("HumanoidRootPart")
local gui = player.PlayerGui

local Camera = UPCSettings.Camera
local Mouse = UPCSettings.Mouse

--> Setup
Camera.CameraType = Enum.CameraType.Scriptable
UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
UIS.MouseIconEnabled = false

--> Events
UIS.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if UPCSettings.CurrentlyViewing then
		if Interactables[UPCSettings.CurrentlyViewing.Name].Check(i) then 
			InteractionController.Interact()
		end
	end
end)

UIS.InputChanged:Connect(function(i, gpe)
	if gpe then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement and not UPCSettings.CameraLock then
		UPCSettings.RotationX = UPCSettings.RotationX - i.Delta.Y * UPCSettings.CamSensitivty
		
		--> CLAMP ROTATION
		UPCSettings.RotationX = math.clamp(UPCSettings.RotationX, -80, 80)
		
		--> UPDATE CAMERA
		if not UPCSettings.CameraLock then
			UPCSettings.CameraOffset = CFrame.Angles(math.rad(UPCSettings.RotationX), 0, 0)
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	
	--> UPDATE CAMERA / CHARACTER ROTATION
	if not UPCSettings.CameraLock then
		local mdelta = UIS:GetMouseDelta()

		Camera.CFrame = head.CFrame * UPCSettings.CameraOffset

		local mousepos = Mouse.Hit.Position
		local unit = (mousepos - hrp.Position).Unit

		local newrot = hrp.CFrame * CFrame.Angles(0, math.rad(-mdelta.X * UPCSettings.CamSensitivty), 0)
		hrp.CFrame = CFrame.new(hrp.Position) * newrot.Rotation
	else
		Camera.CFrame = head.CFrame * UPCSettings.CameraOffset
		
		if UPCSettings.FocusingOn then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, UPCSettings.FocusingOn.CFrame.Position)
		end
		
		if UPCSettings.DialogueOpen then
			
		else
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end
	-->
	
	--> UPDATE TARGET
	local currentTarget = Mouse.Target
	local isint, inttable = InteractionController.CanInteract(currentTarget)
		
	if isint and currentTarget ~= UPCSettings.CurrentlyViewing and UPCSettings.CanInteract then -- INTERACTIVE OBJECT PRESENT
		InteractionController.Hover(isint, inttable)
		
	elseif UPCSettings.CurrentlyViewing ~= nil and not isint then -- NO INTERACTIVE OBJECT
		InteractionController.StopHover(UPCSettings.CurrentlyViewing, UPCSettings.CVTable)
	end
	
	-->
	
	--> UPDATE MOUSE UI
	UPCSettings.MouseGui.Frame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
	-->
	
end)