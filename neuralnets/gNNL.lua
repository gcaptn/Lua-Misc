--[[


STYLE GUIDE

- PascalCase for configurations that user accesses
- this_case or lowercase for variables and private functions 
- semicolon (;) for dictionaries and commas for arrays
- Keep between 1-5 tabs, or at least try to avoid chevrons
- Prefer ternary operators for setting values unless it's more convenient to use if

]]


-- NN Library

local NNL = {}

local debugmode = false
function NNL.dprint(...)
	if debugmode then print(...) end
end
function NNL.tprint(t)
	for i, v in pairs(t) do
		local Type = type(v)
		if Type=="table" then
			print(i); NNL.tprint(v)
		else
			print(i,v)
		end
	end
end


-- NEURAL NETWORK

NNL.nn = {}
local nn = NNL.nn
nn.__index = nn

local activation_functions = {
	sigmoid = function(x, deriv)
		return deriv and 1/(1+math.exp(-x)) * (1-1/(1+math.exp(-x)))
		or 1/(1+math.exp(-x))
	end;
	tanh = function (x, deriv)
		return deriv and math.pow(math.tanh(x),2)
		or math.tanh(x)
	end;
	relu = function (x, deriv)
		return deriv and (x>0 and 1 or x==0 and 0.5)
		or math.max(0, x)
	end;
	leakyrelu = function(x, deriv)
		return deriv and (x>=0 and 1 or 0.1)
		or math.max(0.1*x, x)
	end;
}

local function random01()
	local pv = 1000000000000000
	return math.random(0,pv)/pv
end

function nn.new(newsettings)
	local self = {} 
	setmetatable(self,nn)
	newsettings = newsettings or {}
	self.settings = {
		OutputNodes = newsettings.OutputNodes or 1;
		InputNodes = newsettings.InputNodes or 3;
		HiddenLayers = newsettings.HiddenLayers or 2;
		HiddenNodes = newsettings.HiddenNodes or 2;
		HiddenActivation = newsettings.HiddenActivation or "sigmoid";
		InputActivation = newsettings.InputActivation or "sigmoid";
		LearningRate = newsettings.LearningRate or 0.2;
	}
	self._lastinputs = {}
	--[[
		inputs = {1,2,3,4,5}
			w: the synapse weight, b: the bias, d: the last delta
		nn.layers = {
			{{w={0,1,1,1,1}; b=10}, {w={0,1,1,1,1}}, {w={0,1,1,1,1}}},
			{{w={0,1,1,1,1}; b=10}, {w={0,1,1,1,1}}, {w={0,1,1,1,1}}}
		}
		#weights == #inputs
	]]
	self.layers = {}	  -- Stores the layers to the left of a layer
	for n_syn = 1, self.settings.HiddenLayers do 
		local hiddenlayer = {}
		for n_node = 1, self.settings.HiddenNodes do 
			local node = {w={}; d=0; o=0}
			-- #weights should be #activations
			local weights_needed = n_syn==1 and self.settings.InputNodes or self.settings.HiddenNodes
			for n_w = 1, weights_needed do 
				node.w[n_w] = random01()
			end
			table.insert(hiddenlayer, node)
		end
		table.insert(self.layers, hiddenlayer)
	end
	local outputlayer = {}
	for n_node = 1, self.settings.OutputNodes do 
		local node = {w={}; d=0; o=0}
		local weights_needed = n_syn==1 and self.settings.InputNodes or self.settings.HiddenNodes
		for n_w = 1, weights_needed do 
			node.w[n_w] = random01()
		end
		table.insert(outputlayer, node)
	end
	table.insert(self.layers, outputlayer)

	return self
end

function nn:_activate(weights, inputs)	  
	local activation = 0 
	-- scalar (inputs .  weights)
	for i=1, #inputs do 
		local wa = weights[i] * inputs[i]
		activation = activation + wa
	end
	return activation
end

function nn:Forward(inputs)
	local outputs = {}
	self._lastinputs = inputs
	local last_activations = inputs  -- Use this instead of outputs for readability
	for i, layer in ipairs(self.layers) do 
		local activations = {}
		for i2, node in ipairs(layer) do 
			local activation = self:_activate(node.w, last_activations)
			local a_function = activation_functions[self.settings.HiddenActivation]
			activation = a_function(activation)	 -- sig (wa)
			activations[i2] = activation	
			node.o = activation					  -- Keep the output for backpropagation
		end
		last_activations = activations				  -- forward it to the next layer
	end
	return outputs
end


--	local deriv_function = activation_functions[self.HiddenActivation]
--	local error = (correct - output) 
--	local delta = error * deriv_function(output)

--[[

1. Forward propagate. l1 = activation(dot(layer0, layer0))
2. Calculate the error square. error = (y - l1)^2
3. Find the needed delta. 
	lOutput_deltas = error * activation(lOutput, deriv)
	lHidden_deltas = 
4. Update weights in the layer. layer0 = dot(l0 in columns, l1_deltas)

df = f * (1-f)

]]

function nn:Cost(expected)
	for i = #self.layers, 1, -1 do 
		local layer = self.layers[i]
		local errors = {}
		-- Calculate the deltas for each node
		if i==#self.layers then 
			-- this is an output layer
			local error = 0 -- Total error for this layer's synapse
			for i2, thisnode in ipairs(layer) do 

			end
			table.insert(errors, error)
		else
			-- A hidden layer
			for i2, thisnode in ipairs (layer) do 
				local right_layer = self.layers[i+1] -- Get the layer to the right
				local error = 0
				for i2, rightnode in ipairs (right_layer) do 
					-- Get this node's weight in the right node
					-- And get the error
					error = error + rightnode.w[i2] * rightnode.d
				end
				table.insert(errors, error)
			end
		end
		-- Finally, apply the deltas
		for i2, node in ipairs (layer) do 
			local deriv_function = activation_functions[self.settings.HiddenActivation]
			node.d = errors[i2] * deriv_function(node.o)
		end
	end
end

function nn:Learn()
	-- Use after nn:Cost()
	-- This will apply all the deltas to the weights
	-- If this was called before a forward propagation, jail
	local learning_rate = self.settings.LearningRate

	local inputs = self._lastinputs
	for i, layer in ipairs(self.layers) do
		-- New = Current + dot (inputs . deltas) 
		for i2, node in ipairs(layer) do
			for i3, w in ipairs (node.w)do 
				node.w[i3] = w + inputs[i2]*node.d*learning_rate
			end
		end
		-- Set their last output as the next layer's input
		inputs = {}
		for i2, node in ipairs(layer) do
			inputs[i2] = node.o
		end
	end
end

--[[ Test this

local NNL = require "NNL"
local nn = NNL.nn.new()

local y = 0.5
local x = {1,0,1}

NNL.tprint(nn)

local output = nn:Forward(x)
nn:Cost(y)
nn:Learn()

NNL.tprint(nn)

]]

return NNL
