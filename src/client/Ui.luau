-- Small helpers for building the HUD out of code.

local Ui = {}

Ui.WHITE = Color3.new(1, 1, 1)
Ui.GOLD = Color3.fromRGB(255, 215, 90)
Ui.FONT = Enum.Font.FredokaOne

function Ui.rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

function Ui.create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for name, value in props do
		if name ~= "Parent" then
			(instance :: any)[name] = value
		end
	end
	if children then
		for _, c in children do
			c.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function Ui.corner(radius: number): UICorner
	return Ui.create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function Ui.textStroke(): UIStroke
	return Ui.create("UIStroke", { Thickness = 1.5, Color = Ui.rgb(20, 15, 10) })
end

function Ui.label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = Ui.FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Ui.WHITE
	return Ui.create("TextLabel", props, { Ui.textStroke() })
end

function Ui.textButton(props: { [string]: any }): TextButton
	props.Font = Ui.FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Ui.WHITE
	props.AutoButtonColor = true
	return Ui.create("TextButton", props, {
		Ui.corner(12),
		Ui.textStroke(),
		Ui.create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
end

-- A button in the column on the left of the screen.
function Ui.sideButton(parent: Instance, name: string, text: string, color: Color3, order: number): TextButton
	return Ui.textButton({
		Name = name,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = color,
		Text = text,
		LayoutOrder = order,
		Parent = parent,
	})
end

-- A pop-up window with a title, a close button and a scrolling list inside.
function Ui.panel(parent: Instance, name: string, title: string, maxSize: Vector2)
	local frame = Ui.create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.85),
		BackgroundColor3 = Ui.rgb(250, 238, 210),
		Visible = false,
		ZIndex = 5,
		Parent = parent,
	}, {
		Ui.corner(16),
		Ui.create("UISizeConstraint", { MaxSize = maxSize }),
		Ui.create(
			"UIStroke",
			{ Thickness = 3, Color = Ui.rgb(120, 70, 40), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	local titleLabel = Ui.label({
		Name = "Title",
		Size = UDim2.new(1, -70, 0, 40),
		Position = UDim2.fromOffset(14, 8),
		TextColor3 = Ui.GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = frame,
	})
	local close = Ui.create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Ui.rgb(200, 60, 50),
		Font = Ui.FONT,
		TextScaled = true,
		TextColor3 = Ui.WHITE,
		Text = "X",
		Parent = frame,
	}, { Ui.corner(10) })
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local content = Ui.create("ScrollingFrame", {
		Name = "Content",
		Position = UDim2.fromOffset(12, 56),
		Size = UDim2.new(1, -24, 1, -66),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = frame,
	}, {
		Ui.create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	return frame, content, titleLabel
end

return Ui
