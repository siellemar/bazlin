--> Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--> Variables
local assets = game.ReplicatedStorage.Assets


--> Module setup & variables
local module = {}
local player = nil
local settings = nil

--> Module functions and settings
function module.CreatePlayer(plr:Player)
	module.Player = {
		PlayerObject = plr;
		Character = plr.Character;
		PlayerSettings = {
			
			--> Camera settings
			CameraLock = false;
			Camera = workspace.CurrentCamera;
			RotationX = 0;
			CamSensitivty = 0.1;
			CameraOffset = CFrame.new();
			FocusingOn = nil;
			
			--> Interaction settings
			CurrentlyViewing = nil;
			CVTable = nil;
			CurrentlyHolding = nil;
			CanInteract = true;
			
			--> Character Settings
			DefaultWalkSpeed = 10;
			
			--> Mouse Settings
			Mouse = plr:GetMouse();
			MouseGui = plr.PlayerGui.InteractionMouse;
			
			--> Dialogue settings
			DialogueOpen = false;
			CurrentNode = nil;
			
		}
	}
	
	module.Dialogue.Player = module.Player
	
	player = module.Player
	settings = module.Player.PlayerSettings
	
	return player, settings
end

-- [[============================]] --
-- [[          FUNCTIONS         ]] --
-- [[============================]] --


function Highlight(instance: Instance, hl: Highlight)
	hl = hl or assets.DefaultHighlight:Clone()
	
	hl.Parent = instance
	hl.Adornee = instance
	hl.Name = "InteractionHighlight"
end

function Unhighlight(instance: Instance)
	for _, v in instance:GetDescendants() do
		if v:IsA("Highlight") then
			v:Destroy()
		end
	end
end

function IsInRange(x:number , min:number , max:number , noninclusive:boolean)
	if noninclusive then
		if x > min and x < max then return true
		else return false end
	else
		if x >= min and x <= max then return true
		else return false end
	end
end


-- [[============================]] --
-- [[           MODULES          ]] --
-- [[============================]] --



-- [[        INTERACTABLES       ]] --
module.Interactables = {
	
	["TestInteractable"] = { -- Name should be the same as the interactable Instance
		DisplayName = "Test Interactable"; -- Will display on Player's UI when hovering
		MinimumDistance = 0; -- Minimum distance to interact
		MaximumDistance = 20; -- Maximum distance to interact
		InteractionInputDisplay = "M1";

		Enabled = true;

		Conditions = {
			Holding = { -- Player must be holding this

			};

			Has = { -- Player must have these in their inventory

			};
		};

		Hover = function(instance)
			Highlight(instance)
		end,
		StopHover = function(instance)
			Unhighlight(instance)
		end,
		Interact = function(instance)
			
			module.Dialogue.OpenDialogue()
			module.Dialogue.LoadNode("TestNode1")
			
		end,
		Check = function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then return true else return false end
		end,
	};
	
}



-- [[        DIALOGUE DATA       ]] --
module.DialogueNodes = {
	["TestNode1"] = {
		Speaker = workspace.TestInteractable;
		Text = "HELLO, I AM JUST TALKING BECAUSE I AM TESTING THIS. PLEASE CONTINUE WITH YOUR CONVERSATION... AND I WILL KILL YOU";
		Callback = function()
		end,
		Responses = {
			{
				Text = "Hi"; 
				Next = "TestNode2"; 
				Callback = function()

				end,
			},
			{
				Text = "are you literally kidding me dude what the hell";
				Next = "TestNode4";
				Callback = function()
					
				end,
			},
		}
	};
	
	["TestNode2"] = {
		Speaker = workspace.TestInteractable;
		Text = "How are you";
		Callback = function()
		end,
		Responses = {
			{
				Text = "Good"; 
				Next = "TestNode3"; 
				Callback = function()
					
				end,
			}
		}
	};
	
	["TestNode3"] = {
		Speaker = workspace.TestInteractable;
		Text = "I couldn't keep skibidi rizzing for YEARS!";
		Callback = function()
		end,
		Responses = {
			{
				Text = "Ok"; 
				Next = "end"; 
				Callback = function()

				end,
			}
		}
	};
	
	["TestNode4"] = {
		Speaker = workspace.TestInteractable;
		Text = "So sorry!";
		Callback = function()
		end,
		Responses = {
			{
				Text = "Whateva"; 
				Next = "end"; 
				Callback = function()

				end,
			}
		}
	};
}



-- [[     DIALOGUE CONTROLLER    ]] --
module.Dialogue = {
	OpenDialogue = function()
		local gui = assets.Dialogue
		gui.Parent = player.PlayerObject.PlayerGui
		
		settings.CanInteract = false
		settings.CameraLock = true
		settings.DialogueOpen = true
		module.Character.SetSpeed(0)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		
		return gui
	end,
	
	LoadNode = function(NodeName)
		local gui = player.PlayerObject.PlayerGui:FindFirstChild("Dialogue")
		if not gui then gui = module.Dialogue.OpenDialogue() end
		gui = gui.Frame
		
		local node = module.DialogueNodes[NodeName]
		
		module.Camera.FocusOn(
			node.Speaker,
			TweenInfo.new(.5)
		)
		
		for i, button in gui:GetChildren() do
			if button:IsA("TextButton") then
				button.Text = ""
				button.Interactable = false
			end 
		end
		
		local connections = {}
		local buttonconn;
		
		gui.Spoken.Text = ""
		local writer = module.Typewriter.new(node.Text, gui.Spoken, .03)
		
		for i, response in node.Responses do
			local guibutton = gui["Response"..i]
			
			guibutton.Text = response.Text
			guibutton.Interactable = true
			
			table.insert(connections, 
				guibutton.Activated:Once(function()
					response.Callback()
					writer:Destroy()
					buttonconn:Disconnect()
					for i, conn in connections do conn:Disconnect() end
					if response.Next == "end" then
						module.Dialogue.CloseDialogue()
					else
						module.Dialogue.LoadNode(response.Next)
					end
				end)
			)
		end
		
		buttonconn = UserInputService.InputBegan:Connect(function(i, gpe)
			if gpe then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				writer:Destroy()
				buttonconn:Disconnect()
			end
		end)
		
		task.spawn(function()
			writer:Start()
		end)
	end,
	
	CloseDialogue = function()
		local gui = player.PlayerObject.PlayerGui.Dialogue
		gui.Parent = assets

		settings.CanInteract = true
		settings.CameraLock = false
		settings.DialogueOpen = false
		module.Character.SetSpeed(settings.DefaultWalkSpeed)
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		return gui
	end,
}



-- [[         TYPE WRITER        ]] --
module.Typewriter = {}
module.Typewriter.__index = module.Typewriter

function module.Typewriter.new(text, output, speed)
	local self = setmetatable({}, module.Typewriter)


	self.text = text
	self.output = output
	self.speed = speed or 0.05
	self.isRunning = false
	self.triggers = {
		["."] = function()
			task.wait(self.speed*10)
		end,
		["!"] = function()
			task.wait(self.speed*25)
		end,
		["?"] = function()
			task.wait(self.speed*25)
		end,
		[","] = function()
			task.wait(self.speed*4)
		end,
	}


	return self
end

function module.Typewriter:Start()
	self.isRunning = true 
	local currentText = ""

	for i = 1, #self.text do
		if not self.isRunning then break end

		local char = self.text:sub(i, i)
		currentText = currentText .. char


		if typeof(self.output) == "Instance" and self.output:IsA("TextLabel") then
			self.output.Text = currentText
		elseif typeof(self.output) == "string" then
			self.output = currentText
		end

		for trigger, action in pairs(self.triggers) do
			local triggerLength = #trigger
			if self.text:sub(i - triggerLength + 1, i) == trigger then
				action()
			end
		end

		task.wait(self.speed)
	end

	self.isRunning = false
end

function module.Typewriter:Destroy()
	if typeof(self.output) == "Instance" and self.output:IsA("TextLabel") then
		self.output.Text = self.text
	elseif typeof(self.output) == "string" then
		self.output =  self.text
	end
	
	self.isRunning = false
	self = nil
end

function module.Typewriter:AddTrigger(trigger, callback)
	self.triggers[trigger] = callback
end



-- [[        CAMERA MODULE       ]] --
module.Camera = {
	FocusOn = function(instance: Instance, tweeninfo: TweenInfo)
		local tween = TweenService:Create(
			workspace.CurrentCamera,
			tweeninfo,
			{CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, instance.Position)}
		)

		tween:Play()

		tween.Completed:Once(function()
			tween:Destroy()
			settings.FocusingOn = instance
		end)
		return tween
	end;


	SetLock = function(set)
		settings.CameraLock = set
	end;


	SetSubject = function(subject:Instance)
		settings.Camera.Subject = subject
	end,
}



-- [[         INTERACTION        ]] --
module.Interaction = {
	CanInteract = function(inst: Instance)
		if not inst then return false end
		if not settings.CanInteract then return false end
		
		local inttable = module.Interactables[inst.Name]
		if not inttable then return false end
		
		if not inttable.Enabled then return false end
		
		local distance = (player.Character.HumanoidRootPart.Position - inst.Position).Magnitude
		if not IsInRange(distance, inttable.MinimumDistance, inttable.MaximumDistance) then return false end 
		
		return inst, inttable
	end;
	
	
	Hover = function(inst:Instance, interactable)
		settings.CurrentlyViewing = inst
		settings.CVTable = interactable
		settings.MouseGui.Frame.MouseIcon.BackgroundColor3=Color3.fromRGB(255,255,255)
		settings.MouseGui.Frame.InteractName.Text = interactable.DisplayName
		settings.MouseGui.Frame.Key.Text = interactable.InteractionInputDisplay
		
		interactable.Hover(inst)
	end,
	
	
	StopHover = function(inst:Instance, interactable)
		settings.CurrentlyViewing = nil
		settings.CVTable = nil
		settings.MouseGui.Frame.MouseIcon.BackgroundColor3=Color3.fromRGB(29,29,29)
		settings.MouseGui.Frame.InteractName.Text = ""
		settings.MouseGui.Frame.Key.Text = ""
		
		interactable.StopHover(inst)
	end,
	
	Interact = function()
		local inst, inttable = module.Interaction.CanInteract(settings.CurrentlyViewing)
		
		if not inst and not inttable then
			return
		end
		
		inttable.Interact(inst)
	end,
}



-- [[          CHARACTER         ]] --
module.Character = {
	SetSpeed = function(setto)
		player.Character.Humanoid.WalkSpeed = setto
	end,
}

--

return module