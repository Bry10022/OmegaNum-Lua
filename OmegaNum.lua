--!native

--[[
This is an OmegaNum Lua port created from scratch by Bry10022.
This supports numbers up to 10{1000}9007199254740991 in Bower's operator notation.
This library reaches the level of f_ω in the Fast Growing Hierarcy, hence the name.
The way this library works is that it stores the sign and an array.
The sign is either 1 or -1, that is to say positive and negative respectively.
The array holds the magnitude of the number. An array {n₀,n₁,n₂,n₃,n₄,…} represents the following:
…(10↑⁴)ⁿ-⁴(10↑³)ⁿ-³(10↑↑)ⁿ-²(10↑)ⁿ-¹n₀
Therefore, the array {71945.20468,5,8,0,1,6} represents (10↑⁵)⁶10↑⁴(10↑↑)⁸(10↑)⁵71945.20468, which without using parentheses is:
10↑⁵10↑⁵10↑⁵10↑⁵10↑⁵10↑⁵10↑⁴10↑↑10↑↑10↑↑10↑↑10↑↑10↑↑10↑↑10↑↑10↑10↑10↑10↑10↑71945.20468

Credits:
• Naruyoko - Original JavaScript version
•• https://github.com/Naruyoko/OmegaNum.js
• cloudytheconqueror - FGHJ notation
•• https://cloudytheconqueror.github.io/letter-notation-format/

How to use:
1. Place this ModuleScript in the game's ReplicatedStorage
2. In scripts that want to use it, type local OmegaNum = require(game.ReplicatedStorage.OmegaNum)
3. You can create a new OmegaNum by using the function OmegaNum.toOmega(number/string/table)
3.1 You do not need the quotation marks for values smaller then 1e308, but for larger values, they are required. Otherwise, it will become Infinity.
3.1 You can also do this by setting the value to {-1 or 1, {num1, num2, num3, …}}
4. Use one of the methods below to perform a function on the number as necessary.

Notes:
• You cannot use +, -, *, /, ^, or % on OmegaNums as they are technically arrays.
•• You must use add, sub, mul, div, pow, or mod respectively to perform these operations.
••• Example: to calculate 20 + 3^8, you must format it as OmegaNum.add(20, OmegaNum.pow(3, 8))
•• Metatables are not any faster, so support for them will probably never be added.
• These functions will return tables unless you use a function to convert it to a readable string.
]]

local HttpService = game:GetService("HttpService")

--Configuration
local MaxExecTime = 0.5
local RoundingMode = "Up" --Determines which way x.5 rounds
local MaxInteger = 9007199254740991
local MaxE = math.log10(MaxInteger)
local EMaxInteger = "e" .. MaxInteger
local EEMaxInteger = "ee" .. MaxInteger
local TetratedMaxInteger = "10^^" .. MaxInteger
local PentatedMaxInteger = "10^^^" .. MaxInteger
local MaxValue = 1.7976931348623157e308 -- Lua's maximum value for doubles, only there since Roblox doesn't have it in its math library
local EnablePlainE = false --Determines whether …eenumenum should be …eeenum after a certain point
local PlainEMax = 3 --Determines the point when …eenumenum turns into  …eeenum. This should be smaller than ChainEMax
local ChainEMax = 10 --Determines the point when …eenumenum and  …eeenum into …(10^)^num num. Please do not make this too big.
--[[
	The maximum number of arrows that are accepted in an operation.
	If exceeded, it will warn and then return Infinity.
	This is to prevent non-breaking loops and to help prevent memory leaks.
	1000 means that any operation above {1000} is not allowed.
	Please do not make this number too big.
]]
local MaxArrow = 1000
--[[
	Maximum number of times you can apply 1+log10(x) to numbers < 10 until the result is indistinguishable from 1.
	I calculated this myself and got 45, though this is set it to 48 to be safe.
	Reducing this can speed up formatting, but may lead to inaccurate results.
]]
local MaxLogP1Repeats = 48
--[[
	The maximum number of letters that can be preceeded by 1.
	5 means that "eeeee1" goes to 1F5, "FFFFF1" goes to 1G5, and so on.
	Please do not make this number too big.
]]
local LetterMax = 5
--Error handling
local OmegaNumError = "[OmegaNum error] "
local InvalidArgument = OmegaNumError .. "Invalid argument: "

local OmegaNum = {}
--[[
	Helper function to check if a number is a valid OmegaNum since Roblox Lua doesn't support Regex.
]]
function isOmegaNum(input)
	--/^[-\+]*(Infinity|NaN|(10(\^+|\{[1-9]\d*\})|\(10(\^+|\{[1-9]\d*\})\)\^[1-9]\d* )*((\d+(\.\d*)?|\d*\.\d+)?([Ee][-\+]*))*(0|\d+(\.\d*)?|\d*\.\d+))$/
	--Remove leading signs
	while string.sub(input, 1, 1) == "-" or string.sub(input, 1, 1) == "+" do
		input = string.sub(input, 2)
	end
	--Handle Infinity and NaN case insensitive (also check for "inf")
	if string.lower(input) == "infinity" or string.lower(input) == "inf" or string.lower(input) == "nan" then
		return true
	end
	--Iteratively check hyper-operation prefixes from the front
	while true do
		--Type B: (10^…)^num and (10{num})^num
		local match_b1 = string.match(input, "^%(10%+%)%^%d+ ")
		local match_b2 = string.match(input, "^%(10%^%+%)%^%d+ ")
		local match_b3 = string.match(input, "^%(10{[1-9]%d*}%)%^%d+ ")
		local start_idx, end_idx = string.find(input, "^%(10%^+%)%^[1-9]%d* ")
		if not start_idx then
			start_idx, end_idx = string.find(input, "^%(10{[1-9]%d*}%)%^[1-9]%d* ")
		end
		if start_idx then
			input = string.sub(input, end_idx + 1)
			continue
		end
		--Type A: 10^… and 10{num}
		start_idx, end_idx = string.find(input, "^10%^+")
		if not start_idx then
			start_idx, end_idx = string.find(input, "^10{[1-9]%d*}")
		end
		if start_idx then
			input = string.sub(input, end_idx + 1)
			continue
		end
		--Break if no match
		break
	end
	--Check nested e's
	input = string.gsub(input, "[Ee][%-%+]*", "e")
	--Split and validate each segment
	if string.find(input, "e") then
		for segment in string.gmatch(input, "([^e]+)") do
			if not (string.match(segment, "^%d+%.?%d*$") or string.match(segment, "^%d*%.?%d+$")) then
				return false
			end
		end
		--Ensure it doesn't end with trailing e
		return string.sub(input, -1) ~= "e"
	end
	--Check plain numbers
	if string.match(input, "^%d+%.?%d*$") or string.match(input, "^%d*%.?%d+$") then
		return true
	end
	return false
end

--[[
	Helper function to check if a number is in Hyper E since Roblox Lua doesn't support Regex.
]]
function isHyperE(input)
	--/^[-\+]*(0|[1-9]\d*(\.\d*)?|Infinity|NaN|E[1-9]\d*(\.\d*)?(#[1-9]\d*)*)$/
	--Remove leading signs
	while string.sub(input, 1, 1) == "-" or string.sub(input, 1, 1) == "+" do
		input = string.sub(input, 2)
	end
	--Handle Infinity and NaN case insensitive (also check for "inf")
	if string.lower(input) == "infinity" or string.lower(input) == "inf" or string.lower(input) == "nan" then
		return true
	end
	--Integer and Decimals
	if string.match(input, "^%d+$") ~= nil or string.match(input, "^%d+%.%d*$") ~= nil or string.match(input, "^%d*%.%d+$") ~= nil then
		return true
	end
	if string.match(input,"^E[1-9]") then
		local body = string.sub(input, 2)
		local main, hash = string.match(body, "^([^#]+)(.*)$")
		if not main then return false end
		local valid = string.match(main, "^[1-9]%d*$") or string.match(main, "^[1-9]%d*%.%d*$")
		if not valid then return false end
		if hash ~= "" then
			for segment in string.gmatch(hash, "#[^#]+") do
				if not string.match(segment, "^#[1-9]%d*$") then
					return false
				end
			end
		end
		return true
	end
	return false
end

--[[
	Converts a primitive number to an OmegaNum.
]]
function OmegaNum.fromNumber(number)
	if type(number) ~= "number" then
		error(InvalidArgument .. "Expected number")
	end
	return OmegaNum.fix({math.sign(number), {math.abs(number)}})
end

--[[
	Converts an OmegaNum back into a primitive number.
	Note: Lua's doubles only support numbers up to 2¹⁰²⁴, so anything larger will become infinity.
]]
function OmegaNum.toNumber(value)
	value = OmegaNum.fix(value)
	if value[1] == -1 then return -1 * OmegaNum.toNumber(OmegaNum.abs(value)) end
	if #value[2] >= 2 and (value[2][2] >= 2 or (value[2][2] == 1 and value[2][1] > math.log10(MaxValue))) then
		return value[1] * math.huge
	end
	if value[2][2] == 1 then
		return 10^value[2][1]
	else
		return value[2][1]
	end
end

--[[
	Converts a string to an OmegaNum.
]]
function OmegaNum.fromString(input)
	local data
	local isJSON = false
	if type(input) == "string" then
		if string.sub(input, 1, 1) == "[" then
			local success, result = pcall(function()
				return HttpService:JSONDecode(input)
			end)
			if success then
				isJSON = true
				data = result --Store result of parsed Roblox table
			end
			if isJSON == true then
				local value = {}
				value[1] = math.sign(data[1])
				value[2] = data
				--Flip sign of first element if negative
				value[2][1] = math.abs(data[1])
				return --[[OmegaNum.fix]](value)
			else
				error(OmegaNumError .. "Could not parse JSON")
			end
		else
			--TODO: Support for stuff like "10^^100.5"
			local value = {}
			value[1] = 1
			value[2] = {0}
			if isOmegaNum(input) == false then
				warn(OmegaNumError .. "Malformed input: " .. input)
				value[2] = {math.nan}
				return value
			end
			local negate = false
			--Handle leading plus and minus signs
			if string.sub(input, 1, 1) == "-" or string.sub(input, 1, 1) == "+" then
				local signCount = string.find(input, "[^%+%-]") or (#input + 1)
				signCount = signCount - 1
				local signs = string.sub(input, 1, signCount)
				--Count number of minus signs
				local _, minusCount = string.gsub(signs, "%-", "")
				negate = (minusCount % 2 == 1)
				input = string.sub(input, signCount + 1)
			end
			--Handle NaN and Infinity (case insensitive)
			if input == string.lower("nan") then
				value[2] = {math.nan}
			elseif input == string.lower("infinity") or input == string.lower("inf") then
				value[2] = {math.huge}
			else
				do
					--Sanity check
					local initialCheck = false
					local attemptedArrowsStr
					if string.find(input, "^%(?10") then
						--10{num}, (10{num}^num)
						local _, braceEnd, braceMatch = string.find(input, "^%(?10{(%d+)}")
						if braceMatch then
							if #braceMatch > 10 or tonumber(braceMatch) > MaxArrow then
								initialCheck = true
								attemptedArrowsStr = braceMatch
							end
						else
							--10^…, (10^…)^num
							local _, caretEnd, caretMatch = string.find(input, "^%(?10(%^+)")
							if caretMatch and #caretMatch > MaxArrow then
								initialCheck = true
								attemptedArrowsStr = tostring(#caretMatch)
							end
						end
					end
					if initialCheck then
						warn("Number too large to reasonably handle. Tried to " .. (attemptedArrowsStr + 2) .. "-ate.")
						value[2] = {math.huge}
					end
					if initialCheck == false then
						--The main loop
						local pos = 1
						local inputLen = #input
						while pos <= inputLen do
							local startPos, endPos, match1, match2
							local arrows, c
							--(10{num})^num
							startPos, endPos, match1, match2 = string.find(input, "%(10{(%d+)}%)%^(%d+)%s*", pos)
							if startPos == pos then
								arrows = tonumber(match1)
								c = tonumber(match2)
								pos = endPos + 1
							else
								--(10^…)^num
								startPos, endPos, match1, match2 = string.find(input, "%(10(%^+)%)%^(%d+)%s*", pos)
								if startPos == pos then
									arrows = #match1
									c = tonumber(match2)
									pos = endPos + 1
								else
									--10{num}
									startPos, endPos, match1 = string.find(input, "10{(%d+)}%s*", pos)
									if startPos == pos then
										arrows = tonumber(match1)
										c = 1
										pos = endPos + 1
									else
										--10^…
										startPos, endPos, match1 = string.find(input, "10(%^+)%s*", pos)
										if startPos == pos then
											arrows = #match1
											c = 1
											pos = endPos + 1
										else
											--That was the last one
											break
										end
									end
								end
							end
							if arrows == 1 then
								value[2][2] = (value[2][2] or 0) + c
							elseif arrows == 2 then
								local a = value[2][2] or 0
								local b = value[2][1] or 0
								if b >= 1e10 then a = a + 1 end
								if b >= 10 then a = a + 1 end
								value[2][1] = a
								value[2][2] = 0
								value[2][3] = (value[2][3] or 0) + c
							else
								local a = value[2][arrows] or 0
								local b = value[2][arrows-1] or 0
								if b >= 10 then a = a + 1 end
								for idx = 2, arrows do
									value[2][idx] = 0
								end
								value[2][1] = a
								value[2][arrows+1] = (value[2][arrows-1] or 0) + c
							end
						end
						--Process suffix
						local suffix = string.sub(input, pos)
						local parts = string.split(string.lower(suffix), "e")
						local b = {value[2][1] or 0, 0}
						local c = 1
						-- Process and multiply coefficients
						for idx = #parts, 1, -1 do
							local currentPart = parts[idx]
							if b[1] < MaxE and b[2] == 0 then
								b[1] = 10^(c * b[1])
							elseif c == -1 then
								if b[2] == 0 then
									b[1] = 10^(c * b[1])
								elseif b[2] == 1 and b[1] <= math.log10(MaxValue) then
									b[1] = 10^(c * (10^b[1]))
								else
									b[1] = 0
								end
								b[2] = 0
							else
								b[2] = b[2] + 1
							end
							if b[2] == 0 then
								if currentPart ~= "" then
									b[1] = b[1] * (tonumber(currentPart) or 1)
								end
							else
								local d
								if currentPart ~= "" then
									d = math.log10(tonumber(currentPart) or 1)
								else
									d = 0
								end
								if b[2] == 1 then
									b[1] = b[1] + d
								elseif b[2] == 2 and b[1] < MaxE + math.log10(d) then
									b[1] = b[1] + math.log10(1 + 10 ^ (math.log10(d) - b[1]))
								end
							end
							-- Carrying
							if b[1] < MaxE and b[2] > 0 then
								b[1] = 10 ^ b[1]
								b[2] = b[2] - 1
							elseif b[1] > MaxInteger then
								b[1] = math.log10(b[1])
								b[2] = b[2] + 1
							end
						end
						value[2][1] = b[1]
						value[2][2] = (value[2][2] or 0) + b[2]
					end
				end
			end
			if negate == true then
				value[1] = value[1] * -1
			end
			return OmegaNum.fix(value)
		end
	else
		error(InvalidArgument .. "Expected string")
	end
end

--[[
	Converts a Hyper E formatted string to an OmegaNum.
]]
function OmegaNum.fromHyperE(input)
	if type(input) == "string" then
		local value = {}
		value[1] = 1
		value[2] = {0}
		if isHyperE(input) == false then
			warn(OmegaNumError .. "Malformed input: " .. input)
			value[2] = {math.nan}
			return value
		end
		local negate = false
		--Handle leading plus and minus signs
		if string.sub(input, 1, 1) == "-" or string.sub(input, 1, 1) == "+" then
			local signCount = string.find(input, "[^%+%-]") or (#input + 1)
			signCount = signCount - 1
			local signs = string.sub(input, 1, signCount)
			--Count number of minus signs
			local _, minusCount = string.gsub(signs, "%-", "")
			negate = (minusCount % 2 == 1)
			input = string.sub(input, signCount + 1)
		end
		--Handle NaN and Infinity (case insensitive)
		if input == string.lower("nan") then
			value[2] = {math.nan}
		elseif input == string.lower("infinity") or input == string.lower("inf") then
			value[2] = {math.huge}
		elseif string.sub(input, 1, 1) ~= "E" then
			value[2][1] = tonumber(input)
		elseif not string.find(input,"#") then
			value[2][1] = tonumber(string.sub(input,2))
			value[2][2] = 1
		else
			local hyperion = string.split(string.sub(input, 2), "#")
			for i, index in ipairs(hyperion) do
				local number = tonumber(index)
				if i >= 3 then
					number = number - 1
				end
				value[2][i] = number
			end
		end
		if negate == true then
			value[1] = value[1] * -1
		end
		return OmegaNum.fix(value)
	else
		error(InvalidArgument .. "Expected string")
	end
end

--[[
	Converts one-element tables, strings, and primitive numbers to an OmegaNum based on type.
]]
function OmegaNum.toOmegaNum(value)
	--Check type of value
	if type(value) == "table" then
		--Convert to two-element table {1, {a,b,c,…}} if {a,b,c,…}
		if type(value[2]) ~= "table" then
			--Flip sign if the first element is negative
			if math.sign(value[1]) == -1 then
				value[1] = math.abs(value[1])
				return {-1, value}
			else
				return {1, value}
			end
		end
		return value
	elseif type(value) == "number" then --Convert primitive numbers
		return OmegaNum.fromNumber(value)
	elseif type(value) == "string" and value[1] == "E" then --Convert string in Hyper E
		return OmegaNum.fromHyperE(value)
	elseif type(value) == "string" then --Convert strings
		return OmegaNum.fromString(value)
	else
		error(OmegaNumError .. "Unsupported type: " .. type(value))
	end
end

--[[
	Clones a table so you can make modifications to it without affecting the original.
	In Lua, tables and arrays are passed by reference, which means modifications to it will also change the original.
]]
function copy(value)
	local new = {}
	new[1] = value[1]
	new[2] = {}
	for i, value in value[2] do
		new[2][i] = value
	end
	return new
end

--[[
	Puts an OmegaNum into a standard format.
]]
function OmegaNum.fix(value)
	--Convert to {1, {a,b,c,…}} form if not already in said form
	if type(value) ~= "table" or type(value[2]) ~= "table" then
		value = OmegaNum.toOmegaNum(value)
	end
	if not value[2] or #value[2] == 0 then
		value[2] = {0}
	end
	if value[1] ~= 1 and value[1] ~= -1 then
		if type(value[1]) ~= "number" then
			value[1] = tonumber(value[1]) or 1
		end
		value[1] = (value[1] < 0) and -1 or 1
	end
	--Check for nil values, NaN, infinity, and non-integers beyond first element
	for i = 1, #value[2] do
		local ind = value[2][i]
		if ind == nil then
			value[2][i] = 0
		else
			if ind ~= ind then
				value[2] = {math.nan}
				return value
			end
			if ind == math.huge or ind == -math.huge then
				value[2] = {math.huge}
				return value
			end
			if i ~= 1 and ind % 1 ~= 0 then
				value[2][i] = math.floor(ind)
			end
		end
	end
	local b
	local startTime = os.clock()
	repeat
		b = false
		--Trim trailing zeroes
		while #value[2] > 0 and value[2][#value[2]] == 0 do
			table.remove(value[2])
			b = true
		end
		if (value[2][1] or 0) > MaxInteger then
			value[2][2] = (value[2][2] or 0) + 1
			value[2][1] = math.log10(value[2][1])
			b = true
		end
		while (value[2][1] or 0) < MaxE and (value[2][2] and value[2][2] ~= 0) do
			value[2][1] = 10^value[2][1]
			value[2][2] = value[2][2] - 1
			b = true
		end
		if #value[2] > 2 and (not value[2][2] or value[2][2] == 0) then
			local i = 3
			while not value[2][i] or value[2][i] == 0 do
				i = i + 1
			end
			value[2][i-1] = value[2][1]
			value[2][1] = 1
			value[2][i] = value[2][i] - 1
			b = true
		end
		for i = 2, #value[2] do
			if value[2][i] > MaxInteger then
				value[2][i+1] = (value[2][i+1] or 0) + 1
				value[2][1] = value[2][i] + 1
				for j = 2, i do
					value[2][j] = 0
				end
				b = true
			end
		end
		--Yield if took too long to prevent timeout
		if os.clock() - startTime > MaxExecTime then
			task.wait()
			startTime = os.clock()
		end
	until not b
	if #value[2] == 0 then
		value[2] = {0}
	end
	return value
end

--[[
	Converts an OmegaNum into a string in the format [a,b,c,…].
	This should be used for DataStores since a literal "9.007199254740982e15" will be interpreted as "9007199254740982" due to rounding when taking the log of that number.
]]
function OmegaNum.toString(value)
	value = OmegaNum.fix(value)
	if OmegaNum.isInfinite(value) == false and OmegaNum.isNaN(value) == false then
		value[2][1] = value[2][1] * value[1]
		return HttpService:JSONEncode(value[2])
	else
		local signStr
		if value[1] == -1 then
			signStr = "-"
		else
			signStr = ""
		end
		if OmegaNum.isInfinite(value) then
			return signStr .. "Infinity"
		elseif OmegaNum.isNaN(value) then
			return signStr .. "NaN"
		end
	end
end

--[[
	Converts an OmegaNum into a displayable string.
]]
function OmegaNum.dispString(value)
	value = OmegaNum.fix(value)
	if value[1] == -1 then return "-" .. OmegaNum.dispString(OmegaNum.abs(value)) end
	if OmegaNum.isNaN(value) then return "NaN" end
	if not OmegaNum.isFinite(value) then return "Infinity" end
	local stringy = {}
	if #value[2] >= 3 then
		for i = #value[2], 3, -1 do
			local q = ""
			if i >= 6 then
				q = "{" .. (i - 1) .. "}"
			else
				q = string.rep("^", i - 1)
			end
			if value[2][i] > 1 then
				table.insert(stringy, "(10" .. q .. ")^" .. value[2][i] .. " ")
			elseif value[2][i] == 1 then
				table.insert(stringy, "10" .. q)
			end
		end
	end
	if not value[2][2] or value[2][2] == 0 then
		table.insert(stringy, tostring(OmegaNum.toNumber(value)))
	elseif value[2][2] < PlainEMax or (EnablePlainE == false and value[2][2] < ChainEMax) then
		table.insert(stringy, string.rep("e", value[2][2] - 1) .. (10 ^ (value[2][1] - math.floor(value[2][1]))) .. "e" .. math.floor(value[2][1]))
	elseif EnablePlainE == true and value[2][2] < ChainEMax then
		table.insert(stringy, string.rep("e", value[2][2]) .. value[2][1])
	else
		table.insert(stringy, "(10^)^" .. value[2][2] .. " " .. value[2][1])
	end
	return table.concat(stringy)
end

--[[
	Helper function for dispStringDecimalPlaces().
]]
function decimalPlaces(value, places)
	--TODO: Find a way to keep up to n significant figures and trim any excessive digits.
	return string.format("%." .. (places - 1) .. "f", value)
end

--[[
	Converts an OmegaNum into a displayable string with a certain number of decimal places.
	This may show "10.0…0" due to rounding and may have pretty weird results once (10^)^number number happens.
]]
function OmegaNum.dispStringDecimalPlaces(value, places, applyToOpNums)
	--Default parameters
	if places == nil then
		places = 9
	end
	--Clamp number of decimal places
	places = math.floor(math.clamp(places, 1, 15))
	if applyToOpNums == nil then
		applyToOpNums = false
	end
	value = OmegaNum.fix(value)
	if value[1] == -1 then return "-" .. OmegaNum.dispStringDecimalPlaces(OmegaNum.abs(value), places, applyToOpNums) end
	if OmegaNum.isNaN(value) then return "NaN" end
	if not OmegaNum.isFinite(value) then return "Infinity" end
	local b = 0
	local stringy = {}
	local m = 10^places
	if #value[2] >= 3 then
		for i = #value[2], 3, -1 do
			if b == 0 then
				local x = value[2][i]
				if applyToOpNums == true and x >= m then
					i = i + 1
					b = x
					x = 1
				elseif applyToOpNums == true and value[2][i-1] >= m then
					x = x + 1
					b = value[2][i-1]
				end
				local q = ""
				if i >= 6 then
					q = "{" .. (i - 1) .. "}"
				else
					q = string.rep("^", i - 1)
				end
				if x > 1 then
					table.insert(stringy, "(10" .. q .. ")^" .. x .. " ")
				elseif x == 1 then
					table.insert(stringy, "10" .. q)
				end
			end
		end
	end
	local k = value[2][1]
	local l = (value[2][2] or 0)
	if k > m then
		k = math.log10(k)
		l = l + 1
	end
	if b ~= 0 then
		table.insert(stringy, decimalPlaces(b, places))
	elseif l == 0 then
		table.insert(stringy, decimalPlaces(k, places))
	elseif l < PlainEMax or (EnablePlainE == false and l < ChainEMax) then
		table.insert(stringy, string.rep("e", l - 1) .. decimalPlaces(10^(k - math.floor(k)), places) .. "e" .. math.floor(k))
	elseif EnablePlainE == true and l < ChainEMax then
		table.insert(stringy, string.rep("e", l) .. decimalPlaces(k, places))
	else
		table.insert(stringy, "(10^)^" .. l .. " " .. decimalPlaces(k, places))
	end
	return table.concat(stringy)
end

--[[
	Converts an OmegaNum into a displayable string in Hyper E.
]]
function OmegaNum.toHyperE(value)
	value = OmegaNum.fix(value)
	if value[1] == -1 then return "-" .. OmegaNum.toHyperE(OmegaNum.abs(value)) end
	if OmegaNum.isNaN(value) then return "NaN" end
	if not OmegaNum.isFinite(value) then return "Infinity" end
	if OmegaNum.lessThan(value,MaxInteger) then
		return tostring(value[2][1])
	end
	if OmegaNum.lessThan(value,EMaxInteger) then
		return "E" .. tostring(value[2][1])
	end
	local stringy = {}
	table.insert(stringy, "E" .. tostring(value[2][1]) .. "#" .. tostring(value[2][2]))
	for i = 3, #value[2] do
		table.insert(stringy, "#" .. tostring(value[2][i] + 1))
	end
	return table.concat(stringy)
end

--[[
	Helper function for suffix formatting.
]]
function t1format(x, mult, y)
	--Default parameters
	if mult == nil then
		mult = false
	end
	if y == nil then
		y = 0
	end
	--Define suffix parts
	local t1ones = {"", "U", "D", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No"}
	if mult and y > 0 and x < 10 then 
		t1ones[2] = "" --Shortcut to save space
	end
	local t1tens = {"", "De", "Vt", "Tg", "qg", "Qg", "sg", "Sg", "Og", "Ng"}
	local t1hunds = {"", "Ce", "Du", "Tr", "Qa", "Qi", "Se", "Si", "Ot", "Nt"}
	--Build suffix
	local t1f = t1ones[x+1] 
	if x >= 10 then 
		t1f = t1ones[(x%10)+1] .. t1tens[(math.floor(x/10)%10)+1] .. tostring(t1hunds[math.floor(x/100)+1]) --tostring is needed here so it does not error
	end
	return t1f
end

--[[
	Helper function for suffix formatting.
]]
function t2format(x, mult, y)
	--Default parameters
	if mult == nil then
		mult = false
	end
	if y == nil then
		y = 0
	end
	--Define suffix parts
	local t2ills = {"", "Mil", "Mic", "Nan", "Pic", "Fem", "Att", "Zep", "Yoc", "Ron"}
	local t2ones = {"", "Me", "De", "Tr", "Te", "Pe", "He", "Hp", "Oc", "En"}
	if mult and y > 0 and x < 10 then
		t2ones = {"", "", "Mic", "Nan", "Pic", "Fem", "Att", "Zep", "Yoc", "Ron"}
	end
	local t2teen = {"Mec", "Due", "Tre", "Ttr", "Pnt", "Hex", "Hep", "Oct", "Enn"}
	local t2tens = {"", "c", "Ic", "tc", "Tc", "Pc", "ht", "Ht", "Oa", "Et"}
	if x % 10 == 0 then
		t2tens = {"", "Qet", "Ico", "Trc", "Ttc", "Pec", "Het", "Hpt", "Oca", "Ent"}
	end
	local t2hunds = {"", "Hc", "Dh", "Trh", "Tth", "Ph", "Hxh", "Heh", "Oh", "Eh"}
	if x % 100 == 0 then
		t2hunds = {"", "Hec", "Dhc", "Trhc", "Tthc", "Phc", "Hxhc", "Hehc", "Ohc", "Ehc"}
	end
	--Build suffix
	local t2fir = x % 10
	local t2sec = math.floor(x / 10) % 10
	local t2thi = math.floor(x / 100)
	local t2h = tostring(t2hunds[t2thi+1] or "")
	local t2t = ""
	local t2fo = ""
	local lastt = x % 100
	if lastt > 10 and lastt < 20 then
		t2t = t2teen[t2fir]
	else
		t2t = t2tens[t2sec+1] or ""
		if t2fir > 0 or x < 10 then
			if mult and y > 0 then
				t2fo = t2ones[t2fir+1] or ""
			else
				t2fo = (x < 10) and (t2ills[x+1] or "") or (t2ones[t2fir+1] or "")
			end
		end
	end
	return t2fo .. t2t .. t2h
end

--[[
	Helper function for suffix formatting.
]]
function t3format(x, mult, y, z)
	--Default parameters
	if mult == nil then
		mult = false
	end
	if y == nil then
		y = 0
	end
	if z == nil then
		z = 0
	end
	--Define suffix parts
	local t3ills = {"", "Kil", "Meg", "Gig", "Ter", "Pet", "Ekx", "Zet", "Yot", "Rnn"}
	local t3ones = {"", "En", "Od", "Tr", "Te", "Pt", "Ex", "Ze", "Yo", "Rn"}
	local t3teen = {"Qtt", "Hen", "Dok", "Trd", "Ted", "Ped", "Exd", "Zed", "Yod", "Ned"}
	local t3to = {"k", "k", "c", "c", "c", "k", "k", "c", "k", "c"}
	if mult and y > 0 and x < 10 then
		t3ones = {"", "", "D", "Tr", "T", "P", "Ex", "Z", "Y", "N"}
	end
	local t3tens = {"", "", "I", "Tr", "Te", "Pe", "Ex", "Ze", "Ye", "Ne"}
	local t3hunds = {"", "Ho", "Do", "Tro", "To", "Po", "Exo", "Zo", "Yo", "No"}
	--Build suffix
	local t3f = t3ills[x+1]
	if (mult and y > 0) or z >= 1000 then
		t3f = t3ones[x+1]
	end
	local t3t = t3tens[(math.floor(x/10)%10)+1]
	local t3h = tostring(t3hunds[math.floor(x/100)+1]) --tostring is needed here so it does not error
	if x % 100 == 0 then
		t3h = t3h .. 't'
	end
	if x % 100 < 20 and x % 100 > 9 then
		t3t = t3teen[(x % 10)+1]
	end
	if x % 100 > 19 then
		t3t = t3t .. t3to[(x%10)+1] .. t3ones[(x%10)+1]
	end
	if x >= 10 then
		t3f = t3h .. t3t
	end
	if x >= 100 and x % 100 < 10 then
		t3f = t3h .. t3ones[(x%10)+1]
	end
	return t3f
end

--[[
	Helper function for suffix formatting.
]]
function t4format(x, mult)
	--Default parameters
	if mult == nil then
		mult = false
	end
	--Define suffix parts
	local t4ills = {"", "al", "ej", "ij", "ast", "un", "erm", "ov", "ol", "et", "oc", "ax", "up", "ers", "ult"}
	if mult < 2 then
		t4ills[5] = "Ast" --Uppercase first letter if mult is less than 2 since illion name begins with vowel letter.
	end
	--Build suffix
	local t4m = {"", "K", "M", "G", "", "L", "F", "J", "S", "B", "Gl", "G", "S", "V", "M"}
	local t4f = t4ills[x+1]
	if mult < 2 then 
		t4f = t4m[x+1] .. t4f 
	end
	return t4f
end

--[[
	Converts an OmegaNum into a displayable string ending with a suffix.
	This only supports suffixes up to the multillions (slightly less thsn eee3e45).
]]
function OmegaNum.toSuffix(value, precision, enableThousands)
	--Default parameters
	if precision == nil then
		precision = 9
	end
	if enableThousands == nil then
		enableThousands = false
	end
	value = OmegaNum.fix(value)
	if value[1] == -1 then return "-" .. OmegaNum.toSuffix(OmegaNum.abs(value)) end
	if OmegaNum.isNaN(value) then return "NaN" end
	if not OmegaNum.isFinite(value) then return "Infinity" end
	--Calculate which suffixes to build
	if OmegaNum.greaterThanEqual(value, "eee3e45") then return OmegaNum.dispFGHJ(value) end
	local illion = OmegaNum.sub(OmegaNum.floor(OmegaNum.div(OmegaNum.log10(value), 3)), 1)
	local mantissa = OmegaNum.div(value, OmegaNum.pow(1000, OmegaNum.add(illion, 1)))
	if OmegaNum.lessThan(value, "e1e9") then
		mantissa = OmegaNum.dispStringDecimalPlaces(mantissa, precision)
	else
		mantissa = "" --Not really a lot of precision left at this point
	end
	local t2illion = OmegaNum.floor(OmegaNum.div(OmegaNum.log10(OmegaNum.maximum(illion, 1)), 3))
	local t3illion = OmegaNum.floor(OmegaNum.div(OmegaNum.log10(OmegaNum.maximum(t2illion, 1)), 3))
	local t4illion = OmegaNum.floor(OmegaNum.div(OmegaNum.log10(OmegaNum.maximum(t3illion, 1)), 3))
	local t1 = OmegaNum.toNumber(OmegaNum.floor(OmegaNum.div(illion, OmegaNum.pow(1000, OmegaNum.sub(t2illion, 2)))))
	if OmegaNum.lessThan(illion, 1000) then
		t1 = OmegaNum.toNumber(illion)
	end
	local t2 = OmegaNum.toNumber(OmegaNum.floor(OmegaNum.div(t2illion, OmegaNum.pow(1000, OmegaNum.sub(t3illion, 2)))))
	if OmegaNum.lessThan(t2illion, 1000) then
		t2 = OmegaNum.toNumber(t2illion)
	end
	local t3 = OmegaNum.toNumber(OmegaNum.floor(OmegaNum.div(t3illion, OmegaNum.pow(1000, OmegaNum.sub(t4illion, 2)))))
	if OmegaNum.lessThan(t3illion, 1000) then
		t3 = OmegaNum.toNumber(t3illion)
	end
	local t4 = OmegaNum.toNumber(t4illion)
	--Apply suffixes
	local st = t1format(t1)
	if OmegaNum.greaterThanEqual(illion, 1000) then
		local ternary1 = ""
		if (math.floor(t1 / 1000) % 1000) > 0 then
			ternary1 = "-" .. t1format(math.floor(t1 / 1000) % 1000, true, t2 - 1) .. t2format(t2 - 1)
		end
		st = t1format(math.floor(t1 / 1000000), true, t2) .. t2format(t2) .. ternary1
	end
	if OmegaNum.greaterThanEqual(illion, 1000000) then
		local ternary2 = ""
		if (t1 % 1000) > 0 then
			ternary2 = "-" .. t1format(t1 % 1000, true, t2 - 2) .. t2format(t2 - 2)
		end
		st = st .. ternary2
	end
	if OmegaNum.greaterThanEqual(t2illion, 1000) then
		local ternary3 = ""
		if (math.floor(t2 / 1000) % 1000) > 0 then
			ternary3 = "a'-" .. t2format(math.floor(t2 / 1000) % 1000, true, t3 - 1) .. t3format(t3 - 1)
		end
		st = t2format(math.floor(t2 / 1000000), true, t3) .. t3format(t3) .. ternary3
	end
	if OmegaNum.greaterThanEqual(t2illion, 1000000) then
		local ternary4 = ""
		if (t2 % 1e3) > 0 then
			ternary4 = "a'-" .. t2format(t2 % 1000, true, t3 - 2) .. t3format(t3 - 2)
		end
		st = st .. ternary4
	end
	if OmegaNum.greaterThanEqual(t3illion, 1000) then
		local ternary5 = ""
		if (math.floor(t3 / 1000) % 1000) > 0 then
			ternary5 = "`-" .. t3format(math.floor(t3 / 1000) % 1000, true, t4 - 1, t3) .. t4format(t4 - 1, math.floor(t3 / 1000) % 1000)
		end
		st = t3format(math.floor(t3 / 1e6), true, t4) .. t4format(t4, math.floor(t3 / 1000000)) .. ternary5
	end
	if OmegaNum.greaterThanEqual(t3illion, 1000000) then
		local ternary6 = ""
		if (t3 % 1000) > 0 then
			ternary6 = "`-" .. t3format(t3 % 1000, true, t4 - 2, t3) .. t4format(t4 - 2, t3 % 1000)
		end
		st = st .. ternary6
	end
	if OmegaNum.greaterThanEqual(value, 1000000000000) then
		return mantissa .. st
	elseif OmegaNum.greaterThanEqual(value, 1000000000) then
		return mantissa .. "B"
	elseif OmegaNum.greaterThanEqual(value, 1000000) then
		return mantissa .. "M"
	elseif enableThousands and OmegaNum.greaterThanEqual(value, 1000) then
		return mantissa .. "K"
	else
		return OmegaNum.dispStringDecimalPlaces(value, precision)
	end
end

--[[
	Helper function for FGHJ notation.
	This basically does the opposite of fix().
	Set smallTop to true to force top value to be below 10.
]]
function polarize(array, smallTop)
	--Default parameters
	if smallTop == nil then
		smallTop = false
	end
	if #array == 0 then
		array = {0}
	end
	local bottom = array[1]
	local top = 0
	local height = 0
	if not math.isfinite(array[1]) then
		--Do nothing
	elseif #array <= 1 then
		while smallTop and bottom >= 10 do
			bottom = math.log10(bottom)
			top = top + 1
			height = 1
		end
	else
		top = array[2] or 0
		height = 1
		while (bottom >= 10) or (height < (#array - 1)) or (smallTop and top >= 10) do
			if bottom >= 10 then --Bottom mode: the bottom number climbs to the top
				if height == 1 then
					--Apply once increment
					bottom = math.log10(bottom)
					if bottom >= 10 then
						--Apply again if necessary
						bottom = math.log10(bottom)
						top = top + 1
					end
				elseif height < MaxLogP1Repeats then
					if bottom >= 1e10 then
						bottom = math.log10(math.log10(math.log10(bottom))) + 2
					else
						bottom = math.log10(math.log10(bottom)) + 1
					end
					for i = 2, height - 1 do
						bottom = math.log10(bottom) + 1
					end
				else
					bottom = 1
				end
				top = top + 1
			else --Top mode: height is increased by one
				bottom = math.log10(bottom) + top
				height = height + 1
				top = (array[height+1] or 0) + 1
			end
		end
	end
	return {bottom, top, height}
end

--[[
	Converts an OmegaNum into a displayable string in FGHJ notation.
	What do the letters mean?
	ex = 10ˣ
	Fx = eee…eeex (with x e's)
	Gx = FFF…FFFx (with x F's)
	Hx = GGG…GGGx (with x G's)
	Jx = 10↑ˣ10
]]
function OmegaNum.dispFGHJ(value, precision)
	value = OmegaNum.fix(value)
	--Default parameters
	if precision == nil then
		precision = 9
	end
	if value[1] == -1 then return "-" .. OmegaNum.dispFGHJ(OmegaNum.abs(value)) end
	if OmegaNum.isNaN(value) then return "NaN" end
	if not OmegaNum.isFinite(value) then return "Infinity" end
	local array = value[2]
	if OmegaNum.lessThan(value, 1000000000) then
		return OmegaNum.dispStringDecimalPlaces(value, precision)
	elseif OmegaNum.lessThan(value, "10^^" .. LetterMax) then --1e9 to 1F5
		local rep = (array[2] or 0) - 1
		if array[1] >= 1e9 then
			array[1] = math.log10(array[1])
			rep = rep + 1
		end
		local m = 10 ^ (array[1] - math.floor(array[1]))
		local e = math.floor(array[1])
		return string.rep("e", rep) .. OmegaNum.dispStringDecimalPlaces(m, precision) .. "e" .. e
	elseif OmegaNum.lessThan(value, "10^^1e9") then --1F5 to F1e9
		local pol = polarize(array)
		return OmegaNum.dispStringDecimalPlaces(pol[1], precision) .. "F" .. pol[2]
	elseif OmegaNum.lessThan(value, "10^^^" .. LetterMax) then --F1e9 to 1G5
		if (array[3] or 0) >= 1 then
			local rep = array[3]
			array[3] = 0
			return string.rep("F", rep) .. OmegaNum.dispFGHJ(array, precision)
		end
		local n = array[2] + 1
		if OmegaNum.greaterThan(value, "10^^" .. tostring(n + 1)) then
			n = n + 1
		end
		return "F" .. OmegaNum.dispFGHJ(n, precision)
	elseif OmegaNum.lessThan(value, "10^^^1e9") then --1G5 to G1e9
		local pol = polarize(array)
		return OmegaNum.dispStringDecimalPlaces(pol[1], precision) .. "G" .. pol[2]
	elseif OmegaNum.lessThan(value, "10^^^^" .. LetterMax) then --G1e9 ~ 1H5
		if (array[4] or 0) >= 1 then
			local rep = array[4]
			array[4] = 0
			return string.rep("G", rep) .. OmegaNum.dispFGHJ(array, precision)
		end
		local n = array[3] + 1
		if OmegaNum.greaterThan(value, "10^^^" .. tostring(n + 1)) then
			n = n + 1
		end
		return "G" .. OmegaNum.dispFGHJ(n, precision)
	elseif OmegaNum.lessThan(value, "10^^^^1e9") then --1H5 to H1e9
		local pol = polarize(array)
		return OmegaNum.dispStringDecimalPlaces(pol[1], precision) .. "H" .. pol[2]
	elseif OmegaNum.lessThan(value, "10{5}" .. LetterMax) then --H1e9 ~ 1J5
		if (array[5] or 0) >= 1 then
			local rep = array[5]
			array[5] = 0
			return string.rep("H", rep) .. OmegaNum.dispFGHJ(array, precision)
		end
		local n = array[4] + 1
		if OmegaNum.greaterThan(value, "10^^^^" .. tostring(n + 1)) then
			n = n + 1
		end
		return "H" .. OmegaNum.dispFGHJ(n, precision)
	end --5J4 and beyond
	local pol = polarize(array, true)
	return OmegaNum.dispStringDecimalPlaces(math.log10(pol[1]) +  pol[2], precision) .. "J" .. pol[3]
end

--[[
	Returns true if the value is NaN.
	NaN stands for Not a Number.
]]
function OmegaNum.isNaN(value)
	value = OmegaNum.fix(value)
	return value[2][1] ~= value[2][1]
end

OmegaNum.isNan = OmegaNum.isNaN

--[[
	Returns true if the value is infinite.
]]
function OmegaNum.isInfinite(value)
	value = OmegaNum.fix(value)
	return value[2][1] == math.huge
end

OmegaNum.isInf = OmegaNum.isInfinite

--[[
	Returns true if the value is a finite number.
]]
function OmegaNum.isFinite(value)
	value = OmegaNum.fix(value)
	return math.isfinite(value[2][1])
end

--[[
	Returns true if the value does not have a decimal portion.
]]
function OmegaNum.isInteger(value)
	value = OmegaNum.fix(value)
	if value[1] == -1 then return OmegaNum.isInteger(OmegaNum.abs(value)) end
	if OmegaNum.greaterThan(value, MaxInteger) then return true end
	return OmegaNum.toNumber(value) % 1 == 0
end

OmegaNum.isInt = OmegaNum.isInteger

--[[
	Returns the absolute value of an OmegaNum.
]]
function OmegaNum.abs(value)
	value = OmegaNum.fix(value)
	value[1] = 1
	return value
end

OmegaNum.absoluteValue = OmegaNum.abs

--[[
	Negates an OmegaNum. (positive becomes negative and vice versa)
]]
function OmegaNum.neg(value)
	value = OmegaNum.fix(value)
	value[1] = value[1] * -1
	return value
end

OmegaNum.negate = OmegaNum.neg

--[[
	Compares two OmegaNums. Returns 1 if value1 > value2, 0 if value1 = value2, and -1 if value1 < value2.
]]
function OmegaNum.compare(value1, value2)
	value1 = OmegaNum.fix(value1)
	value2 = OmegaNum.fix(value2)
	--Handle special cases
	if OmegaNum.isNaN(value1[2][1]) or OmegaNum.isNaN(value2[2][1]) then return math.NaN end --NaN is not less than, greater than, or equal to anything
	if OmegaNum.isInfinite(value1[2][1]) and OmegaNum.isFinite(value2[2][1]) then return value1[1] end
	if OmegaNum.isFinite(value1[2][1]) and OmegaNum.isInfinite(value2[2][1]) then return value2[1] * -1 end
	if #value1[2] == 1 and value1[2][1] == 0 and #value2[2] == 1 and value2[2][1] == 0 then return 0 end
	--Compare
	if value1[1] ~= value2[1] then return value1[1] end
	local r
	if #value1[2] > #value2[2] then
		r = 1
	elseif #value1[2] < #value2[2] then
		r = -1
	else
		for i = #value1[2], 1, -1 do
			if value1[2][i] > value2[2][i] then
				r = 1
				break
			elseif value1[2][i] < value2[2][i] then
				r = -1
				break
			end
		end
		if not r then
			r = 0
		end
	end
	return r * value1[1]
end

OmegaNum.cmp = OmegaNum.compare

--[[
	Returns whether the second OmegaNum is greater than the first.
]]
function OmegaNum.greaterThan(value1, value2)
	return OmegaNum.compare(value1, value2) > 0
end

OmegaNum.gt = OmegaNum.greaterThan

--[[
	Returns whether the second OmegaNum is greater than or equal to the first.
]]
function OmegaNum.greaterThanEqual(value1, value2)
	return OmegaNum.compare(value1, value2) >= 0
end

OmegaNum.gteq = OmegaNum.greaterThanEqual

--[[
	Returns whether the second OmegaNum is less than the first.
]]
function OmegaNum.lessThan(value1, value2)
	return OmegaNum.compare(value1, value2) < 0
end

OmegaNum.lt = OmegaNum.lessThan

--[[
	Returns whether the second OmegaNum is less than or equal to the first.
]]
function OmegaNum.lessThanEqual(value1, value2)
	return OmegaNum.compare(value1, value2) <= 0
end

OmegaNum.lteq = OmegaNum.lessThanEqual

--[[
	Returns whether two OmegaNums are equal to each other.
]]
function OmegaNum.equal(value1, value2)
	return OmegaNum.compare(value1, value2) == 0
end

OmegaNum.eq = OmegaNum.equal

--[[
	Returns whether two OmegaNums are equal to each other.
]]
function OmegaNum.notEqual(value1, value2)
	return OmegaNum.compare(value1, value2) ~= 0
end

OmegaNum.neq = OmegaNum.notEqual

--[[
	Compares two OmegaNums. Returns 1 if value1 > value2, 0 if value1 = value2, and -1 if value1 < value2.
]]
function OmegaNum.compareTolerance(value1, value2, tolerance)
	return OmegaNum.equalTolerance(value1, value2, tolerance) and 0 or OmegaNum.compare(value1, value2)
end

OmegaNum.cmpTolerance = OmegaNum.compareTolerance

--[[
	Returns whether the second OmegaNum is greater than, but not approximately equal to the first.
]]
function OmegaNum.greaterThanTolerance(value1, value2, tolerance)
	return not OmegaNum.equalTolerance(value1, value2, tolerance) and OmegaNum.greaterThan(value1, value2)
end

OmegaNum.gtTolerance = OmegaNum.greaterThanTolerance

--[[
	Returns whether the second OmegaNum is greater than or approximately equal to the first.
]]
function OmegaNum.greaterThanEqualTolerance(value1, value2, tolerance)
	return OmegaNum.equalTolerance(value1, value2, tolerance) or OmegaNum.graterThan(value1, value2)
end

OmegaNum.gteqTolerance = OmegaNum.greaterThanEqualTolerance

--[[
	Returns whether the second OmegaNum is less than, but not approximately equal to the first.
]]
function OmegaNum.lessThanTolerance(value1, value2, tolerance)
	return not OmegaNum.equalTolerance(value1, value2, tolerance) and OmegaNum.lessThan(value1, value2)
end

OmegaNum.ltTolerance = OmegaNum.lessThanTolerance

--[[
	Returns whether the second OmegaNum is less than or approximately equal to the first.
]]
function OmegaNum.lessThanEqualTolerance(value1, value2, tolerance)
	return OmegaNum.equalTolerance(value1, value2, tolerance) or OmegaNum.lessThan(value1, value2)
end

OmegaNum.lteqTolerance = OmegaNum.lessThanEqualTolerance

--[[
	Returns whether two OmegaNums are approximately equal to each other.
]]
function OmegaNum.equalTolerance(value1, value2, tolerance)
	value1 = OmegaNum.fix(value1)
	value2 = OmegaNum.fix(value2)
	--Default tolerance
	if tolerance == nil then
		tolerance = 1e-7
	end
	--Handle special cases
	if OmegaNum.isNaN(value1[2][1]) or OmegaNum.isNaN(value2[2][1]) then return 0 end --NaN is not less than, greater than, or equal to anything
	if OmegaNum.isInfinite(value1[2][1]) and OmegaNum.isFinite(value2[2][1]) then return value1[1] end
	if OmegaNum.isFinite(value1[2][1]) and OmegaNum.isInfinite(value2[2][1]) then return value2[1] * -1 end
	if #value1[2] == 1 and value1[2][1] == 0 and #value2[2] == 1 and value2[2][1] == 0 then return 0 end
	--Compare
	if math.abs(#value1[2] - #value2[2]) > 1 then
		return false
	end
	local a, b
	local max_len = math.max(#value1[2], #value2[2])
	for i = max_len, 2, -1 do
		local e = value1[2][i] or 0
		local f = value2[2][i] or 0
		if math.abs(e - f) > 1 then
			return false
		elseif e ~= f then
			local x, y
			if e > f then
				x, y = value1, value2
			else
				x, y = value2, value1
			end
			for j = i - 1, 3, -1 do
				if (x[2][j] or 0) > 0 then
					return false
				end
			end
			if i > 2 and (x[2][2] or 0) > 1 then
				return false
			end
			a = x[2][1]
			if i == 2 then
				b = math.log10(y[2][1])
			elseif i == 3 and (y[2][1] or 0) >= 1e10 then
				b = math.log10((y[2][2] or 0) + 2)
			elseif (y[2][i-2] or 0) >= 10 then
				b = math.log10((y[2][i-1] or 0) + 1)
			else
				b = math.log10(y[2][i-1] or 0)
			end
			break
		elseif i == 2 then
			a = value1[2][1]
			b = value2[2][1]
		end
	end
	if a == nil or b == nil then
		a = value1[2][1]
		b = value2[2][1]
	end
	return math.abs(a - b) <= tolerance * math.max(math.abs(a), math.abs(b))
end

OmegaNum.eqTolerance = OmegaNum.equalTolerance

--[[
	Returns whether two OmegaNums are not approximately equal to each other.
]]
function OmegaNum.notEqualTolerance(value1, value2, tolerance)
	return not OmegaNum.equalTolerance(value1, value2, tolerance)
end

OmegaNum.neqTolerance = OmegaNum.notEqualTolerance

--[[
	Returns the smaller OmegaNum of the two.
]]
function OmegaNum.minimum(value1, value2)
	if OmegaNum.lessThan(value1, value2) then
		return value1
	else
		return value2
	end
end

OmegaNum.min = OmegaNum.minimum

--[[
	Returns the larger OmegaNum of the two.
]]
function OmegaNum.maximum(value1, value2)
	if OmegaNum.greaterThan(value1, value2) then
		return value1
	else
		return value2
	end
end

OmegaNum.max = OmegaNum.maximum

--[[
	Returns the largest value smaller than or equal to the given OmegaNum.
]]
function OmegaNum.floor(value)
	if OmegaNum.isInteger(value) then return OmegaNum.fix(value) end
	return OmegaNum.fix(math.floor(OmegaNum.toNumber(value)))
end

--[[
	Returns the value with the smallest difference between it and the given OmegaNum.
	You can also specify the rounding mode to use.
]]
function OmegaNum.round(value)
	if OmegaNum.isInteger(value) then return OmegaNum.fix(value) end
	if RoundingMode == "Up" then
		return OmegaNum.fix(math.round(OmegaNum.toNumber(value) + 0.5))
	elseif RoundingMode == "Down" then
		return OmegaNum.fix(math.round(OmegaNum.toNumber(value) - 0.5))
	else
		return OmegaNum.fix(math.round(OmegaNum.toNumber(value)))
	end
end

--[[
	Returns the smallest value larger than or equal to the given OmegaNum.
]]
function OmegaNum.ceiling(value)
	if OmegaNum.isInteger(value) then return OmegaNum.fix(value) end
	return OmegaNum.fix(math.ceil(OmegaNum.toNumber(value)))
end

OmegaNum.ceil = OmegaNum.ceiling

--[[
	Adds two OmegaNums together.
]]
function OmegaNum.add(addend1, addend2)
	addend1 = OmegaNum.fix(addend1)
	addend2 = OmegaNum.fix(addend2)
	--Clone first addend into new value
	local adder = copy(addend1)
	--Handle special cases
	if adder[1] == -1 then
		return OmegaNum.neg(OmegaNum.add(OmegaNum.neg(adder), OmegaNum.neg(addend2)))
	end
	if addend2[1] == -1 then
		return OmegaNum.sub(adder, OmegaNum.neg(addend2))
	end
	if OmegaNum.equal(adder, 0) then
		return addend2
	end
	if OmegaNum.equal(addend2, 0) then
		return adder
	end
	if OmegaNum.isNaN(adder) or OmegaNum.isNaN(addend2) or (OmegaNum.isInfinite(adder) and OmegaNum.isInfinite(addend2) and OmegaNum.equal(adder, OmegaNum.neg(addend2))) then
		return {1, {math.nan}}
	end
	if OmegaNum.isInfinite(adder) then
		return adder
	end
	if OmegaNum.isInfinite(addend2) then
		return addend2
	end
	--Add the numbers
	local p = OmegaNum.minimum(adder, addend2)
	local q = OmegaNum.maximum(adder, addend2)
	local t
	if OmegaNum.greaterThan(q, EMaxInteger) or OmegaNum.greaterThan(OmegaNum.div(q, p), MaxInteger) then
		t = q
	elseif not q[2][2] then
		t = OmegaNum.toOmegaNum(OmegaNum.toNumber(adder) + OmegaNum.toNumber(addend2))
	elseif q[2][2] == 1 then
		local a = p[2][2] and p[2][1] or math.log10(p[2][1])
		t = OmegaNum.toOmegaNum({a + math.log10(10^(q[2][1] - a) + 1), 1})
	end
	p = nil
	q = nil
	return t
end

OmegaNum.plus = OmegaNum.add

--[[
	Subtracts one OmegaNum from another.
]]
function OmegaNum.sub(minuend, subtrahend)
	minuend = OmegaNum.fix(minuend)
	subtrahend = OmegaNum.fix(subtrahend)
	--Clone minuend into new value
	local subby = copy(minuend)
	--Handle special cases
	if subby[1] == -1 then
		return OmegaNum.neg(OmegaNum.sub(OmegaNum.neg(subby), OmegaNum.neg(subtrahend)))
	end
	if subtrahend[1] == -1 then
		return OmegaNum.add(subby, OmegaNum.neg(subtrahend))
	end
	if OmegaNum.equal(subby, subtrahend) then
		return {1, {0}}
	end
	if OmegaNum.equal(subtrahend, 0) then
		return subby
	end
	if OmegaNum.isNaN(subby) or OmegaNum.isNaN(subtrahend) or (OmegaNum.isInfinite(subby) and OmegaNum.isInfinite(subtrahend)) then
		return {1, {math.nan}}
	end
	if OmegaNum.isInfinite(subby) then
		return subby
	end
	if OmegaNum.isInfinite(subtrahend) then
		return OmegaNum.neg(subtrahend)
	end
	--Subtract the numbers
	local p = OmegaNum.minimum(subby, subtrahend)
	local q = OmegaNum.maximum(subby, subtrahend)
	local n = OmegaNum.greaterThan(subtrahend, subby)
	local t

	if OmegaNum.greaterThan(q, EMaxInteger) or OmegaNum.greaterThan(OmegaNum.div(q, p), MaxInteger) then
		t = q
		t = n and OmegaNum.neg(t) or t
	elseif not q[2][2] then
		t = OmegaNum.toOmegaNum(OmegaNum.toNumber(subby) - OmegaNum.toNumber(subtrahend))
	elseif q[2][2] == 1 then
		local a = p[2][2] and p[2][1] or math.log10(p[2][1])
		t = OmegaNum.toOmegaNum({a + math.log10(10^(q[2][1] - a) - 1), 1})
		t = n and OmegaNum.neg(t) or t
	end
	p = nil
	q = nil
	return t
end

OmegaNum.minus = OmegaNum.sub
OmegaNum.subtract = OmegaNum.sub

--[[
	Multiplies two OmegaNums together.
]]
function OmegaNum.mul(multiplicand, multiplier)
	multiplicand = OmegaNum.fix(multiplicand)
	multiplier = OmegaNum.fix(multiplier)
	--Clone multiplicand into new value
	local multy = copy(multiplicand)
	--Handle special cases and multipilicative identities
	if multy[1] * multiplier[1] == -1 then
		return OmegaNum.neg(OmegaNum.mul(OmegaNum.abs(multy), OmegaNum.abs(multiplier)))
	end
	if multy[1] == -1 then
		return OmegaNum.mul(OmegaNum.abs(multy), OmegaNum.abs(multiplier))
	end
	if OmegaNum.isNaN(multy) or OmegaNum.isNaN(multiplier) or (OmegaNum.equal(multy, 0) and OmegaNum.isInfinite(multiplier)) or (OmegaNum.isInfinite(multy) and OmegaNum.equal(multiplier, 0)) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(multiplier, 0) then
		return {1, {0}}
	end
	if OmegaNum.equal(multiplier, 1) then
		return multy
	end
	if OmegaNum.isInfinite(multy) then
		return multy
	end
	if OmegaNum.isInfinite(multiplier) then
		return multiplier
	end
	--Multiply the numbers
	if OmegaNum.greaterThan(OmegaNum.maximum(multy, multiplier), EEMaxInteger) then
		return OmegaNum.maximum(multy, multiplier)
	end
	local n = OmegaNum.toNumber(multy) * OmegaNum.toNumber(multiplier)
	if n <= MaxInteger then
		return OmegaNum.toOmegaNum(n)
	end
	return OmegaNum.pow(10, OmegaNum.add(OmegaNum.log10(multy), OmegaNum.log10(multiplier)))
end

OmegaNum.times = OmegaNum.mul
OmegaNum.multiply = OmegaNum.mul

--[[
	Divides one OmegaNum by another.
]]
function OmegaNum.div(dividend, divisor)
	dividend = OmegaNum.fix(dividend)
	divisor = OmegaNum.fix(divisor)
	--Clone dividend into new value
	local divvy = copy(dividend)
	--Handle special cases
	if divvy[1] * divisor[1] == -1 then
		return OmegaNum.neg(OmegaNum.div(OmegaNum.abs(divvy), OmegaNum.abs(divisor)))
	end
	--Handle special cases
	if divvy[1] == -1 then
		return OmegaNum.neg(OmegaNum.div(OmegaNum.abs(divvy), OmegaNum.abs(divisor)))
	end
	if OmegaNum.isNaN(divvy) or OmegaNum.isNaN(divisor) or (OmegaNum.isInfinite(divvy) and OmegaNum.isInfinite(divisor) and OmegaNum.equal(divvy, OmegaNum.neg(divisor))) or (OmegaNum.equal(divvy, 0) and OmegaNum.equal(divisor, 0)) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(divisor, 0) then
		return {1, {math.huge}}
	end
	if OmegaNum.equal(divisor, 1) then
		return divvy
	end
	if OmegaNum.equal(divvy, divisor) then
		return {1, {1}}
	end
	if OmegaNum.isInfinite(divvy) then
		return divvy
	end
	if OmegaNum.isInfinite(divisor) then
		return {1, {0}}
	end
	--Divide the numbers
	if OmegaNum.greaterThan(OmegaNum.maximum(divvy, divisor), EEMaxInteger) then
		if OmegaNum.greaterThan(divvy, divisor) then
			return divvy
		else
			return {1, {0}}
		end
	end
	local n = OmegaNum.toNumber(divvy) / OmegaNum.toNumber(divisor)
	if n <= MaxInteger then
		return OmegaNum.toOmegaNum(n)
	end
	local pw = OmegaNum.pow(10, OmegaNum.sub(OmegaNum.log10(divvy), OmegaNum.log10(divisor)))
	local fp = OmegaNum.floor(pw)
	if OmegaNum.lessThan(OmegaNum.sub(pw, fp), 1e-9) then
		return fp
	end
	return pw
end

OmegaNum.divide = OmegaNum.div
OmegaNum.divideBy = OmegaNum.div

--[[
	Returns the reciprocal of an OmegaNum.
	Not very reliable with very big numbers as they return 0. If you take the reciprocal of that, you will get Infinity.
]]
function OmegaNum.rec(value)
	value = OmegaNum.fix(value)
	--Handle special cases
	if OmegaNum.isNaN(value) or OmegaNum.equal(value, 0) then
		return {1, {math.nan}}
	end
	if OmegaNum.greaterThan(OmegaNum.abs(value), "2e323") then
		return {1, {0}}
	end
	return OmegaNum.div("1", value)
end

OmegaNum.reciprocate = OmegaNum.rec
OmegaNum.inverse = OmegaNum.rec
OmegaNum.reciprocal = OmegaNum.rec

--[[
	Returns the remainder when you divide one OmegaNum by another.
]]
function OmegaNum.mod(dividend, modulus)
	dividend = OmegaNum.fix(dividend)
	modulus = OmegaNum.fix(modulus)
	--Handle special cases
	if OmegaNum.equal(modulus, 0) then
		return {1, {math.nan}}
	end
	if dividend[1] * modulus[1] == -1 then
		return OmegaNum.mod(OmegaNum.abs(dividend), OmegaNum.neg(modulus))
	end
	return OmegaNum.sub(dividend, OmegaNum.mul(OmegaNum.floor(OmegaNum.div(dividend, modulus)), modulus))
end

OmegaNum.modular = OmegaNum.mod
OmegaNum.modulo = OmegaNum.mod
OmegaNum.modulus = OmegaNum.mod

--[[
	Takes the exponent of one OmegaNum to another.
]]
function OmegaNum.pow(base, exponent)
	base = OmegaNum.fix(base)
	exponent = OmegaNum.fix(exponent)
	--Handle special cases
	if OmegaNum.equal(exponent, 0) then
		return {1, {1}}
	end
	if OmegaNum.equal(exponent, 1) then
		return base
	end
	if OmegaNum.lessThan(exponent, 0) then
		return OmegaNum.rec(OmegaNum.pow(base, OmegaNum.neg(exponent)))
	end
	if OmegaNum.lessThan(base, 0) and OmegaNum.isInteger(exponent) then
		if OmegaNum.lessThan(OmegaNum.mod(exponent, 2), 1) then
			return OmegaNum.pow(OmegaNum.abs(base), exponent)
		end
		return OmegaNum.neg(OmegaNum.pow(OmegaNum.abs(base), exponent))
	end
	if OmegaNum.lessThan(base, 0) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(base, 1) then
		return {1, {1}}
	end
	if OmegaNum.equal(base, 0) then
		return {1, {0}}
	end
	--Exponentiate the numbers
	if OmegaNum.greaterThan(OmegaNum.maximum(base, exponent), TetratedMaxInteger) then
		return OmegaNum.maximum(base, exponent)
	end
	if OmegaNum.equal(base, 10) then
		if OmegaNum.greaterThan(exponent, 0) then
			exponent[2][2] = (exponent[2][2] or 0) + 1
			return OmegaNum.fix(exponent)
		else
			return OmegaNum.toOmegaNum(10^OmegaNum.toNumber(exponent))
		end
	end
	if OmegaNum.lessThan(exponent, 1) then
		return OmegaNum.root(base, OmegaNum.rec(exponent))
	end
	local n = OmegaNum.toNumber(base)^OmegaNum.toNumber(exponent)
	if n <= MaxInteger then
		return OmegaNum.toOmegaNum(n)
	end
	return OmegaNum.pow(10, OmegaNum.mul(OmegaNum.log10(base), exponent))
end

OmegaNum.power = OmegaNum.pow

--[[
	Takes the exponent of e to an OmegaNum.
]]
function OmegaNum.exp(exponent)
	return OmegaNum.pow(2.718281828459045, exponent)
end

OmegaNum.exponential = OmegaNum.exp

--[[
	Takes the square root of an OmegaNum.
]]
function OmegaNum.sqrt(radicand)
	return OmegaNum.root(radicand, 2)
end

OmegaNum.squareRoot = OmegaNum.sqrt

--[[
	Takes the cube root of an OmegaNum.
]]
function OmegaNum.cbrt(radicand)
	return OmegaNum.root(radicand, 3)
end

OmegaNum.cubeRoot = OmegaNum.cbrt

--[[
	Takes a root with an arbitrary degree of an OmegaNum.
]]
function OmegaNum.root(radicand, index)
	radicand = OmegaNum.fix(radicand)
	index = OmegaNum.fix(index)
	--Handle special cases
	if OmegaNum.equal(index, 1) then
		return radicand
	end
	if OmegaNum.lessThan(index, 0) then
		return OmegaNum.rec(OmegaNum.root(radicand, OmegaNum.neg(index)))
	end
	if OmegaNum.lessThan(index, 1) then
		return OmegaNum.pow(radicand, OmegaNum.rec(index))
	end
	if OmegaNum.lessThan(radicand, 0) and OmegaNum.isInteger(index) and OmegaNum.equal(OmegaNum.mod(index, 2), 1) then
		return OmegaNum.neg(OmegaNum.root(OmegaNum.neg(radicand), index))
	end
	if OmegaNum.lessThan(radicand, 0) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(radicand, 1) then
		return {1, {1}}
	end
	if OmegaNum.equal(radicand, 0) then
		return {1, {0}}
	end
	--Root the numbers
	if OmegaNum.greaterThan(OmegaNum.maximum(radicand, index), TetratedMaxInteger) then
		if OmegaNum.greaterThan(radicand, index) then
			return radicand
		else
			return {1, {0}}
		end
	end
	return OmegaNum.pow(10, OmegaNum.div(OmegaNum.log10(radicand), index))
end

--[[
	Takes the common logarithm of an OmegaNum.
]]
function OmegaNum.log10(argument)
	argument = OmegaNum.fix(argument)
	local arggy = copy(argument)
	--Handle special cases
	if OmegaNum.lessThan(arggy, 0) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(arggy, 0) then
		return {-1, {math.huge}}
	end
	--Calculate logarithm
	if OmegaNum.lessThanEqual(arggy, MaxInteger) then
		return OmegaNum.toOmegaNum(math.log10(OmegaNum.toNumber(arggy)))
	end
	if not OmegaNum.isFinite(arggy) then
		return arggy
	end
	if OmegaNum.greaterThan(arggy, TetratedMaxInteger) then
		return arggy
	end
	arggy[2][2] = arggy[2][2] - 1
	return OmegaNum.fix(arggy)
end

OmegaNum.generalLog = OmegaNum.log10
OmegaNum.generalLogarithm = OmegaNum.log10

--[[
	Takes a logarithm with an arbitrary base of an OmegaNum.
]]
function OmegaNum.logBase(argument, base)
	if base == nil then
		base = 2.718281828459045
	end
	base = OmegaNum.fix(base)
	return OmegaNum.div(OmegaNum.log10(argument), OmegaNum.log10(base))
end

OmegaNum.logarithm = OmegaNum.logBase

--[[
	Takes the natural logarithm of an OmegaNum.
]]
function OmegaNum.log(argument)
	return OmegaNum.logBase(argument, 2.718281828459045)
end

OmegaNum.ln = OmegaNum.log
OmegaNum.naturalLog = OmegaNum.log
OmegaNum.naturalLogarithm = OmegaNum.log

--[[
	Helper function that gets rid of decimal portions of a number.
	I know I could use math.modf, but that returns two values.
	This one returns just the integer portion.
]]
function truncate(value)
	local integerPart, _ = math.modf(value)
	return integerPart
end

--[[
	Helper function for gamma.
	Note: Does not take OmegaNum.
]]
function gammaDouble(value)
	--Handle Infinity or NaN
	if not OmegaNum.isFinite(value) then
		return value
	end
	if value < -50 then
		if value == truncate(value) then
			return -math.huge
		end
		return 0
	end
	local scale1 = 1
	while value < 10 do
		scale1 = scale1 * value
		value = value + 1
	end
	value = value - 1
	local l = 0.9189385332046727
	l = l + (value + 0.5) * math.log(value)
	l = l - value
	local squValue = value^2
	local np = value
	l = l + 1 / (12 * np)
	np = np * squValue
	l = l - 1 / (360 * np)
	np = np * squValue
	l = l + 1 / (1260 * np)
	np = np * squValue
	l = l - 1 / (1680 * np)
	np = np * squValue
	l = l + 1 / (1188 * np)
	np = np * squValue
	l = l - 691 / (360360 * np)
	np = np * squValue
	l = l + 7 / (1092 * np)
	np = np * squValue
	l = l - 3617 / (122400 * np)
	return math.exp(l) / scale1
end

--[[
	Helper function for non-integer factorials.
]]
function gamma(value)
	value = OmegaNum.fix(value)
	--Clone value into new value
	local gammy = copy(value)
	if OmegaNum.greaterThan(gammy, TetratedMaxInteger) then
		return gammy
	end
	if OmegaNum.greaterThan(gammy, EMaxInteger) then
		return OmegaNum.exp(gammy)
	end
	if OmegaNum.greaterThan(gammy, MaxInteger) then
		return OmegaNum.exp(OmegaNum.mul(gammy, OmegaNum.log(OmegaNum.sub(gammy, 1))))
	end
	local n = gammy[2][1]
	if n > 1 then
		if n < 24 then
			return OmegaNum.toOmegaNum(gammaDouble(gammy[1] * n))
		end
		local t = n - 1
		local l = 0.9189385332046727
		l = l + ((t + 0.5) * math.log(t))
		l = l - t
		local n2 = t^2
		local np = t
		local lm = 12 * np
		local adj = 1 / lm
		local l2 = l + adj
		if l2 == l then 
			return OmegaNum.exp(l) 
		end
		l = l2
		np = np * n2
		lm = 360 * np
		adj = 1 / lm
		l2 = l - adj
		if l2 == l then 
			return OmegaNum.exp(l) 
		end
		l = l2
		np = np * n2
		lm = 1260 * np
		local lt = 1 / lm
		l = l + lt
		np = np * n2
		lm = 1680 * np
		lt = 1 / lm
		l = l - lt
		return OmegaNum.exp(l)
	else
		return OmegaNum.rec(value)
	end
end

--A list of integer factorials from n=0 to n=170
local factorials = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800, 39916800, 479001600, 6227020800, 87178291200, 1307674368000, 20922789888000, 355687428096000, 6402373705728000, 121645100408832000, 2432902008176640000, 51090942171709440000, 1.1240007277776076800e+21, 2.5852016738884978213e+22, 6.2044840173323941000e+23, 1.5511210043330986055e+25, 4.0329146112660565032e+26, 1.0888869450418351940e+28, 3.0488834461171387192e+29, 8.8417619937397018986e+30, 2.6525285981219106822e+32, 8.2228386541779224302e+33, 2.6313083693369351777e+35, 8.6833176188118859387e+36, 2.9523279903960415733e+38, 1.0333147966386145431e+40, 3.7199332678990125486e+41, 1.3763753091226345579e+43, 5.2302261746660111714e+44, 2.0397882081197444123e+46, 8.1591528324789768380e+47, 3.3452526613163807956e+49, 1.4050061177528799549e+51, 6.0415263063373834074e+52, 2.6582715747884488694e+54, 1.1962222086548018857e+56, 5.5026221598120891536e+57, 2.5862324151116817767e+59, 1.2413915592536072528e+61, 6.0828186403426752249e+62, 3.0414093201713375576e+64, 1.5511187532873821895e+66, 8.0658175170943876846e+67, 4.2748832840600254848e+69, 2.3084369733924137924e+71, 1.2696403353658276447e+73, 7.1099858780486348103e+74, 4.0526919504877214100e+76, 2.3505613312828784949e+78, 1.3868311854568983861e+80, 8.3209871127413898951e+81, 5.0758021387722483583e+83, 3.1469973260387939390e+85, 1.9826083154044400850e+87, 1.2688693218588416544e+89, 8.2476505920824715167e+90, 5.4434493907744306945e+92, 3.6471110918188683221e+94, 2.4800355424368305480e+96, 1.7112245242814129738e+98, 1.1978571669969892213e+100, 8.5047858856786230047e+101, 6.1234458376886084639e+103, 4.4701154615126843855e+105, 3.3078854415193862416e+107, 2.4809140811395399745e+109, 1.8854947016660503806e+111, 1.4518309202828587210e+113, 1.1324281178206296794e+115, 8.9461821307829757136e+116, 7.1569457046263805709e+118, 5.7971260207473678414e+120, 4.7536433370128420198e+122, 3.9455239697206587884e+124, 3.3142401345653531943e+126, 2.8171041143805501310e+128, 2.4227095383672734128e+130, 2.1077572983795278544e+132, 1.8548264225739843605e+134, 1.6507955160908460244e+136, 1.4857159644817615149e+138, 1.3520015276784029158e+140, 1.2438414054641308179e+142, 1.1567725070816415659e+144, 1.0873661566567430754e+146, 1.0329978488239059305e+148, 9.9167793487094964784e+149, 9.6192759682482120384e+151, 9.4268904488832479837e+153, 9.3326215443944153252e+155, 9.3326215443944150966e+157, 9.4259477598383598816e+159, 9.6144667150351270793e+161, 9.9029007164861804721e+163, 1.0299016745145628100e+166, 1.0813967582402909767e+168, 1.1462805637347083683e+170, 1.2265202031961380050e+172, 1.3246418194518290179e+174, 1.4438595832024936625e+176, 1.5882455415227430287e+178, 1.7629525510902445874e+180, 1.9745068572210740115e+182, 2.2311927486598137657e+184, 2.5435597334721876552e+186, 2.9250936934930159967e+188, 3.3931086844518980862e+190, 3.9699371608087210616e+192, 4.6845258497542909237e+194, 5.5745857612076058231e+196, 6.6895029134491271205e+198, 8.0942985252734440920e+200, 9.8750442008336010580e+202, 1.2146304367025329301e+205, 1.5061417415111409314e+207, 1.8826771768889261129e+209, 2.3721732428800468512e+211, 3.0126600184576594309e+213, 3.8562048236258040716e+215, 4.9745042224772874590e+217, 6.4668554892204741474e+219, 8.4715806908788206314e+221, 1.1182486511960043298e+224, 1.4872707060906857134e+226, 1.9929427461615187928e+228, 2.6904727073180504073e+230, 3.6590428819525488642e+232, 5.0128887482749919605e+234, 6.9177864726194885808e+236, 9.6157231969410893532e+238, 1.3462012475717525742e+241, 1.8981437590761708898e+243, 2.6953641378881628530e+245, 3.8543707171800730787e+247, 5.5502938327393044385e+249, 8.0479260574719917061e+251, 1.1749972043909107097e+254, 1.7272458904546389230e+256, 2.5563239178728653927e+258, 3.8089226376305697893e+260, 5.7133839564458546840e+262, 8.6272097742332399855e+264, 1.3113358856834524492e+267, 2.0063439050956822953e+269, 3.0897696138473507759e+271, 4.7891429014633940780e+273, 7.4710629262828942235e+275, 1.1729568794264144743e+278, 1.8532718694937349890e+280, 2.9467022724950384028e+282, 4.7147236359920616095e+284, 7.5907050539472189932e+286, 1.2296942187394494177e+289, 2.0044015765453026266e+291, 3.2872185855342959088e+293, 5.4239106661315886750e+295, 9.0036917057784375454e+297, 1.5036165148649991456e+300, 2.5260757449731984219e+302, 4.2690680090047051083e+304, 7.2574156153079990350e+306}

--[[
	Takes the factorial of an OmegaNum.
	Uses Stirling's approximation for large numbers and the gamma function for non-integers.
]]
function OmegaNum.factorial(value)
	value = OmegaNum.fix(value)
	--Clone value into new value
	local facty = copy(value)
	if OmegaNum.lessThan(facty, 0) or not OmegaNum.isInteger(facty) then 
		return gamma(OmegaNum.add(facty, 1))
	end
	if OmegaNum.lessThan(facty, 170) then 
		return OmegaNum.toOmegaNum(factorials[OmegaNum.toNumber(facty)+1]) 
	end
	local errorFixer = 1
	local e = OmegaNum.toNumber(facty)
	if e < 500 then e = e + 163879 / 209018880 * (e^5) end
	if e < 1000 then e = e + -571 / 2488320 * (e^4) end
	if e < 50000 then e = e + -139 / 51840 * (e^3) end
	if e < 1e7 then e = e + 1 / 288 * (e^2) end
	if e < 1e20 then e = e + 1 / 12 * e end
	return OmegaNum.times(OmegaNum.mul(OmegaNum.pow(OmegaNum.div(facty, 2.718281828459045), facty), OmegaNum.sqrt(OmegaNum.mul(OmegaNum.mul(facty, 3.141592653589793), 2))), errorFixer)
end

OmegaNum.fact = OmegaNum.factorial

local Omega = 0.5671432904097838

--[[
	Helper function for lambertw.
	Note: Does not take OmegaNum.
]]
function dLambertwDouble(value, tolerance, principal)
	--Default parameters
	if tolerance == nil then
		tolerance = 1e-10
	end
	if principal == nil then
		principal = true
	end
	local w
	--Make sure value is finite
	if math.isnan(value) or value == math.huge or value == -math.huge then
		return value
	end
	--Check branches
	if principal then
		if value == 0 then return value end
		if value == 1 then return Omega end
		if value < 10 then
			w = 0
		else
			w = math.log(value) - math.log(math.log(value))
		end
	else
		if value == 0 then return -math.huge end
		if value <= -0.1 then
			w = -2
		else
			w = math.log(-value) - math.log(-math.log(-value))
		end
	end
	--Calculate
	for i = 1, 100 do
		local wn = (value * math.exp(-w) + w^2) / (w + 1)
		if math.abs(wn - w) < tolerance * math.abs(wn) then
			return wn
		end
		w = wn
	end
	--Failure state
	warn("Iteration failed to converge: " .. tostring(value))
	return math.nan
end

--[[
	Helper function for lambertw.
	Note: Evaluation can be inaccurate when very close to branch point (-1/e).
	In certain corner cases, this may fail to converge or end up on the wrong branch.
]]
function dLambertw(value, tolerance, principal)
	--Default parameters
	if tolerance == nil then
		tolerance = 1e-10
	end
	if principal == nil then
		principal = true
	end
	local w
	--Make sure value is finite
	if not OmegaNum.isFinite(value) then
		return value
	end
	--Check branches
	if principal then
		if OmegaNum.equal(value, 0) then return value end
		if OmegaNum.equal(value, 1) then return {1, {Omega}} end
		w = OmegaNum.log(value)
	else
		if OmegaNum.equal(value, 0) then return {1, {-math.huge}} end
		w = OmegaNum.log(OmegaNum.neg(value))
	end
	--Calculate
	for i = 1, 100 do
		local ew = OmegaNum.exp(OmegaNum.neg(value))
		local wewz = OmegaNum.sub(w, OmegaNum.mul(value, ew))
		local numerator = OmegaNum.mul(OmegaNum.add(w, 2), wewz)
		local denominator = OmegaNum.add(OmegaNum.mul(2, w), 2)
		local dd = OmegaNum.sub(OmegaNum.add(w, 1), OmegaNum.div(numerator, denominator))
		if OmegaNum.equal(dd, 0) then return w end
		local wn = OmegaNum.sub(w, OmegaNum.div(wewz, dd))
		local diff_abs = OmegaNum.abs(OmegaNum.sub(wn, w))
		local limit_abs = OmegaNum.mul(OmegaNum.abs(wn), tolerance)
		if OmegaNum.lessThan(diff_abs, limit_abs) then
			return wn
		end
		w = wn
	end
	--Failure state
	warn("Iteration failed to converge: " .. tostring(value))
	return {1, {math.nan}}
end

--[[
	Takes the Lambert W function of an OmegaNum.
	This is also called the omega function or product logarithm.
]]
function OmegaNum.lambertw(value, principal)
	--Default parameters
	if principal == nil then principal = true end
	value = OmegaNum.fix(value)
	--Clone value into new value
	local lamby = OmegaNum.copy(value)
	--Checks
	if OmegaNum.isNaN(lamby) then
		return lamby
	end
	if OmegaNum.lessThan(lamby, -0.3678794411710499) then
		return {1, {math.nan}}
	end
	--Calculate
	if principal then
		if OmegaNum.greaterThan(lamby, TetratedMaxInteger) then
			return lamby
		end
		if OmegaNum.greaterThan(lamby, TetratedMaxInteger) then
			lamby[2][1] = lamby[2][1] - 1
			return lamby
		end
		if OmegaNum.greaterThan(lamby, MaxInteger) then
			return dLambertw(lamby)
		else
			return OmegaNum.toOmega(dLambertwDouble(lamby[1] * lamby[2][1]))
		end
	else
		if OmegaNum.greaterThan(lamby, 0) then
			return {1, {math.nan}}
		end
		if OmegaNum.greaterThan(OmegaNum.abs(lamby), EEMaxInteger) then
			return OmegaNum.neg(OmegaNum.lambetw(OmegaNum.rec(OmegaNum.neg(lamby))))
		end
		if OmegaNum.greaterThan(OmegaNum.abs(lamby), MaxInteger) then
			return dLambertw(lamby, 1e-10, false)
		else
			return OmegaNum.toOmega(dLambertwDouble(lamby[1] * lamby[2][1], 1e-10, false))
		end
	end
end

--[[
	Tetrates one OmegaNum to another.
	Uses linear approximation for non-integer heights.
]]
function OmegaNum.tetr(base, height, payload)
	--Default parameters
	if payload == nil then
		payload = 1
	end
	base = OmegaNum.fix(base)
	height = OmegaNum.fix(height)
	payload = OmegaNum.fix(payload)
	--Clone base into new value
	local tetra = copy(base)
	if OmegaNum.notEqual(payload, 1) then
		height = OmegaNum.add(height, OmegaNum.slog(payload))
	end
	local negln
	if OmegaNum.isNaN(tetra) or OmegaNum.isNaN(height) or OmegaNum.isNaN(payload) then
		return {1, {math.nan}}
	end
	if OmegaNum.isInfinite(height) and OmegaNum.greaterThan(height, 0) then
		if OmegaNum.greaterThanEqual(tetra, 1.444667861009766) then
			return {1, {math.huge}}
		end
		--Infinite height power tower formula
		negln = OmegaNum.neg(OmegaNum.log(tetra))
		return OmegaNum.div(OmegaNum.lambertw(negln), negln)
	end
	--Handle special cases
	if OmegaNum.lessThanEqual(height, -2) then
		return {1, {math.nan}}
	end
	if OmegaNum.equal(tetra, 0) then
		if OmegaNum.equal(height, 0) then
			return {1, {math.nan}}
		end
		if OmegaNum.equal(OmegaNum.mod(height, 2), 0) then
			return {1, {0}}
		end
		return {1, {1}}
	end
	if OmegaNum.equal(tetra, 1) then
		if OmegaNum.equal(height, -1) then
			return {1, {math.nan}}
		end
		return {1, {1}}
	end
	if OmegaNum.equal(height, -1) then
		return {1, {0}}
	end
	if OmegaNum.equal(height, 0) then
		return {1, {1}}
	end
	if OmegaNum.equal(height, 1) then
		return tetra
	end
	if OmegaNum.equal(height, 2) then
		return OmegaNum.pow(tetra, tetra)
	end
	if OmegaNum.equal(tetra, 2) then
		if OmegaNum.equal(height, 3) then
			return {1, {16}}
		end
		if OmegaNum.equal(height, 4) then
			return {1, {65536}}
		end
	end
	--Check against 10^^^MaxInt
	local max = OmegaNum.maximum(tetra, height)
	if OmegaNum.greaterThan(max, PentatedMaxInteger) then
		return max
	end
	--Tetrate the numbers
	if OmegaNum.greaterThan(tetra, TetratedMaxInteger) or OmegaNum.greaterThan(height, MaxInteger) then
		if OmegaNum.lessThan(base, 1.444667861009766) then
			negln = OmegaNum.neg(OmegaNum.log(negln))
			return OmegaNum.div(OmegaNum.lambertw(negln), negln)
		end
		local jo = OmegaNum.add(OmegaNum.slog(tetra, 10), height)
		jo[2][3] = (height[2][3] or 0) + 1
		return OmegaNum.fix(jo)
	end
	local yo = OmegaNum.toNumber(height)
	local fo = math.floor(yo)
	local ro = OmegaNum.pow(tetra, yo - fo)
	local mo = EMaxInteger
	local lo = math.nan
	local count = 0
	for i = 1, 100 do
		if not (fo ~= 0 and OmegaNum.lessThan(ro, mo)) then break end
		count = count + 1
		if fo > 0 then
			ro = OmegaNum.pow(tetra, ro)
			if OmegaNum.equal(lo, ro) then
				fo = 0
				break
			end
			lo = copy(ro)
			fo = fo - 1
		else
			ro = OmegaNum.logBase(ro, tetra)
			if OmegaNum.equal(lo, ro) then
				fo = 0
				break
			end
			lo = ro
			fo = fo + 1
		end
	end
	--Stop if too many iterations occur
	if count == 100 or OmegaNum.lessThan(base, 1.444667861009766) then
		fo = 0
	end
	--Add remaining iterations
	ro[2][2] = ro[2][2] and (ro[2][2] + fo) or fo
	return OmegaNum.fix(ro)
end

OmegaNum.tetrate = OmegaNum.tetr
OmegaNum.iteratedExp = OmegaNum.tetr
OmegaNum.iteratedExponential = OmegaNum.tetr

--[[
	Takes the super square root of an OmegaNum.
]]
function OmegaNum.ssqrt(radicand)
	radicand = OmegaNum.fix(radicand)
	local rooty = copy(radicand)
	--Handle special cases
	if OmegaNum.lessThan(rooty, 0.6922006275553464) then
		return {1, {math.nan}}
	end
	if not OmegaNum.isFinite(rooty) then
		return rooty
	end
	if OmegaNum.greaterThan(rooty, TetratedMaxInteger) then
		return rooty
	end
	if OmegaNum.greaterThan(rooty, EEMaxInteger) then
		rooty[2][2] = rooty[2][2] - 1
		return rooty
	end
	local l = OmegaNum.log(rooty)
	return OmegaNum.div(l, OmegaNum.lambertw(l))
end

--[[
	Takes the logartihm with an arbitrary base of an OmegaNum, repeatedly.
	May be inaccurate and slow, and could be given custom code.
]]
function OmegaNum.iteratedLog(argument, base, payload)
	--Default parameters
	if base == nil then
		base = 10
	end
	if payload == nil then
		payload = 1
	end
	argument = OmegaNum.fix(argument)
	base = OmegaNum.fix(base)
	payload = OmegaNum.fix(payload)
	--Handle special cases
	if OmegaNum.equal(payload, 0) then
		return argument
	end
	if OmegaNum.equal(payload, 1) then
		return OmegaNum.log(argument, base)
	end
	return OmegaNum.tetr(base, OmegaNum.sub(OmegaNum.slog(argument, base), payload))
end

OmegaNum.iteratedLogarithm = OmegaNum.iteratedLog

--[[
	Adds a number of layers of exponential tower of a ceratin base of a certain number at the bottom.
]]
function OmegaNum.layerAdd(value, height, base)
	--Default parameters
	if height == nil then
		height = 1
	end
	if base == nil then
		base = 10
	end
	value = OmegaNum.fix(value)
	height = OmegaNum.fix(height)
	base = OmegaNum.fix(base)
	return OmegaNum.tetr(base, OmegaNum.add(OmegaNum.slog(value, base), height))
end

--[[
	Adds a number of layers of exponential tower of base 10 of a certain number at the bottom.
]]
function OmegaNum.layerAdd10(value, height)
	return OmegaNum.layerAdd(value, height, 10)
end

--[[
	Takes the super square root with an arbitrary degree of an OmegaNum.
	Uses linear approximation.
]]
function OmegaNum.linearSroot(radicand, index)
	radicand = OmegaNum.fix(radicand)
	index = OmegaNum.fix(index)
	--Handle special cases
	if OmegaNum.isNaN(index) then
		return {1, {math.nan}}
	end
	local indexNum = OmegaNum.toNumber(index)
	if indexNum == 1 then
		return radicand
	end
	if OmegaNum.equal(radicand, math.huge) then
		return {1, {math.huge}}
	end
	if not OmegaNum.isFinite(radicand) then
		return {1, {math.nan}}
	end
	if indexNum > 0 and indexNum < 1 then
		return OmegaNum.root(radicand, indexNum)
	end
	if indexNum > -2 and indexNum < -1 then
		return OmegaNum.pow(OmegaNum.add(index, 2), OmegaNum.rec(radicand))
	end
	if indexNum <= 0 then
		return {1, {math.nan}}
	end
	if OmegaNum.greaterThan(index, MaxInteger) then
		local radicandNum = OmegaNum.toNumber(radicand)
		if radicandNum < 2.718281828459045 and radicandNum > 0.3678794411710499 then
			return OmegaNum.pow(radicand, OmegaNum.rec(radicand))
		end
		if OmegaNum.greaterThan(radicand, TetratedMaxInteger) then
			return OmegaNum.tetr(10, OmegaNum.sub(OmegaNum.slog(radicand, 10), index))
		end
		return {1, {math.nan}}
	end
	if OmegaNum.equal(radicand, 1) then
		return {1, {1}}
	end
	if OmegaNum.lessThan(radicand, 0) then
		return {1, {math.nan}}
	end
	--Calcaulate
	if OmegaNum.greaterThan(radicand, 1) then
		local upperBound
		if indexNum <= 1 then
			upperBound = OmegaNum.root(radicand, index)
		elseif OmegaNum.greaterThanEqual(radicand, OmegaNum.tetr(10, index)) then
			upperBound = OmegaNum.iteratedLog(radicand, 10, indexNum - 1)
		else
			upperBound = {1, {10}} --The table format is necessary to prevent error
		end
		local lower = 0
		local layer = upperBound[2][3] or 0
		local upper = OmegaNum.iteratedLog(upperBound, 10, layer)
		local guess = OmegaNum.div(upper, 2)
		while true do
			if OmegaNum.greaterThan(OmegaNum.tetr(OmegaNum.tetr(10, layer, guess), index), radicand) then
				upper = guess
			else
				lower = guess
			end
			local newguess = OmegaNum.div(OmegaNum.add(lower, upper), 2)
			if OmegaNum.equal(newguess, guess) then break end
			guess = newguess
		end
		return OmegaNum.tetr(10, layer, guess)
	else
		local BIG = "10^^10"
		local stage = 1
		local minimum = BIG
		local maximum = BIG
		local lower = BIG
		local upper = 1e-16
		local prevspan = 0
		local difference = BIG
		local upperBound = OmegaNum.rec(OmegaNum.pow(10, upper))
		local distance = 0
		local prevPoint = upperBound
		local nextPoint = upperBound
		local evenindex = math.ceil(indexNum) % 2 == 0
		local range = 0
		local lastValid = BIG
		local infLoopDetector = false
		local previousUpper = 0
		local decreasingFound = false
		while stage < 4 do
			if stage == 2 then
				if evenindex then break end
				lower = BIG
				upper = minimum
				stage = 3
				difference = BIG
				lastValid = BIG
			end
			infLoopDetector = false
			while OmegaNum.notEqual(upper, lower) do
				previousUpper = upper
				local up10r = OmegaNum.rec(OmegaNum.pow(10, upper))
				local up10rtd = OmegaNum.tetr(up10r, index)
				if OmegaNum.equal(up10rtd, 1) and OmegaNum.lessThan(up10r, 0.4) then
					upperBound = up10r
					prevPoint = up10r
					nextPoint = up10r
					distance = 0
					range = -1
					if stage == 3 then lastValid = upper end
				elseif OmegaNum.equal(up10rtd, up10r) and not evenindex and OmegaNum.lessThan(up10r, 0.4) then
					upperBound = up10r
					prevPoint = up10r
					nextPoint = up10r
					distance = 0
					range = 0
				elseif OmegaNum.equal(up10rtd, OmegaNum.tetr(OmegaNum.mul(up10r, 2), index)) then
					upperBound = up10r
					prevPoint = 0
					nextPoint = OmegaNum.mul(upperBound, 2)
					distance = upperBound
					if evenindex then range = -1
					else range = 0 end
				else
					prevspan = OmegaNum.mul(upper, 1.2e-16)
					upperBound = up10r
					prevPoint = OmegaNum.rec(OmegaNum.pow(10, OmegaNum.add(upper, prevspan)))
					distance = OmegaNum.sub(upperBound, prevPoint)
					nextPoint = OmegaNum.add(upperBound, distance)
					local ubtd
					local pptd
					local nptd
					pptd = OmegaNum.tetr(previousUpper, index)
					ubtd = OmegaNum.tetr(upperBound, index)
					nptd = OmegaNum.tetr(nextPoint, index)
					while OmegaNum.equal(pptd, ubtd) or OmegaNum.equal(nptd, ubtd) do
						prevspan = OmegaNum.mul(upper, 2)
						prevPoint = OmegaNum.rec(OmegaNum.pow(10, OmegaNum.add(upper, prevspan)))
						distance = OmegaNum.sub(upperBound, prevPoint)
						nextPoint = OmegaNum.add(upperBound, distance)
						pptd = OmegaNum.tetr(previousUpper, index)
						ubtd = OmegaNum.tetr(upperBound, index)
						nptd = OmegaNum.tetr(nextPoint, index)
					end
					if (stage == 1 and OmegaNum.greaterThan(nptd, ubtd)) or (stage == 2 and OmegaNum.lessThan(nptd, ubtd)) then
						lastValid = upper
					end
					if OmegaNum.lessThan(nptd, ubtd) then 
						range = -1
					elseif evenindex then
						range = 1
					elseif stage == 3 and OmegaNum.greaterThanTolerance(upper, minimum, 1e-8) then
						range = 0
					else
						pptd = OmegaNum.tetr(previousUpper, index)
						ubtd = OmegaNum.tetr(upperBound, index)
						nptd = OmegaNum.tetr(nextPoint, index)
						while OmegaNum.greaterThanEqual(prevPoint, upperBound) or OmegaNum.lessThanEqual(nextPoint, upperBound) or OmegaNum.equalTolerance(pptd, ubtd, 1e-8) or OmegaNum.equalTolerance(nptd, ubtd, 1e-8) do
							prevspan = OmegaNum.mul(upper, 2)
							prevPoint = OmegaNum.rec(OmegaNum.pow(10, OmegaNum.add(upper, prevspan)))
							distance = OmegaNum.sub(upperBound, prevPoint)
							nextPoint = OmegaNum.add(upperBound, distance)
							pptd = OmegaNum.tetr(previousUpper, index)
							ubtd = OmegaNum.tetr(upperBound, index)
							nptd = OmegaNum.tetr(nextPoint, index)
						end
						if OmegaNum.lessThan(OmegaNum.sub(nptd, ubtd), OmegaNum.sub(ubtd, pptd)) then
							range = 0
						else
							range = 1
						end
					end
				end
				if range == -1 then
					decreasingFound = true
				end
				if (stage == 1 and range == 1) or (stage == 3 and range ~= 0) then
					if OmegaNum.equal(lower, BIG) then upper = OmegaNum.mul(upper, 2)
					else
						upper = OmegaNum.div(OmegaNum.add(upper, lower), 2)
						if infLoopDetector and ((range == 1 and stage == 1) or (range == -1 and stage == 3)) then break end
					end
				else
					if OmegaNum.equal(lower, BIG) then
						lower = upper
						upper = OmegaNum.div(upper, 2)
					else
						lower = OmegaNum.sub(lower, difference)
						upper = OmegaNum.sub(upper, difference)
						if infLoopDetector and ((range == 1 and stage == 1) or (range == -1 and stage == 3)) then break end
					end
				end
				local newDifference = OmegaNum.abs(OmegaNum.div(OmegaNum.sub(lower, upper), 2))
				if OmegaNum.greaterThan(newDifference, OmegaNum.mul(difference, 1.5)) then
					infLoopDetector = true
				end
				difference = newDifference
				if OmegaNum.graterThan(upper, 1e18) or OmegaNum.equal(upper, previousUpper) then break end
			end
			if OmegaNum.greaterThan(upper, 1e18) then break end
			if not decreasingFound then break end
			if OmegaNum.equal(lastValid, BIG) then break end
			if stage == 1 then minimum = lastValid
			elseif stage == 3 then maximum = lastValid end
			stage = stage + 1
		end
		lower = minimum
		upper = 1e-18
		local previous = upper
		local guess = 0
		local loopGoing = true
		while loopGoing do
			if OmegaNum.equal(lower, BIG) then guess = OmegaNum.mul(upper, 2)
			else guess = OmegaNum.div(OmegaNum.add(lower, upper), 2) end
			if OmegaNum.greaterThan(OmegaNum.tetr(OmegaNum.rec(OmegaNum.pow(10, guess)), index), radicand) then
				upper = guess
			else lower = guess end
			if OmegaNum.equal(guess, previous) then
				loopGoing = false
			else
				previous = guess
			end
			if OmegaNum.greaterThan(upper, 1e18) then
				return {1, {math.nan}}
			end
		end
		if OmegaNum.notEqualTolerance(guess, minimum, 1e-15) then
			return OmegaNum.rec(OmegaNum.pow(10, guess))
		else
			if OmegaNum.equal(maximum, BIG) then
				return {1, {math.nan}}
			end
			lower = BIG
			upper = maximum
			previous = upper
			guess = 0
			loopGoing = true
			while loopGoing do
				if OmegaNum.equal(lower, BIG) then
					guess = OmegaNum.mul(upper, 2)
				else
					guess = OmegaNum.div(OmegaNum.add(lower, upper), 2)
				end
				if OmegaNum.greaterThan(OmegaNum.tetr(OmegaNum.rec(OmegaNum.pow(10, guess)), index), radicand) then
					upper = guess
				else
					lower = guess
				end
				if OmegaNum.equal(guess, previous) then
					loopGoing = false
				else
					previous = guess
				end
				if OmegaNum.greaterThan(upper, 1e18) then
					return {1, {math.nan}}
				end
			end
			return OmegaNum.rec(OmegaNum.pow(10, guess))
		end
	end
end

--[[
	Takes the super logarithm wth an arbitrary base of an OmegaNum.
]]
function OmegaNum.slog(argument, base)
	--Default parameters
	if base == nil then
		base = {1, {10}}
	end
	argument = OmegaNum.fix(argument)
	base = OmegaNum.fix(base)
	local slogy = copy(argument)
	--Handle special cases
	if OmegaNum.isNaN(argument) or OmegaNum.isNaN(base) or (OmegaNum.isInfinite(slogy) and OmegaNum.isInfinite(base)) then
		return {1, {math.nan}}
	end
	if OmegaNum.isInfinite(argument) then
		return argument
	end
	if OmegaNum.isInfinite(base) then
		return {1, {0}}
	end
	if OmegaNum.lessThan(argument, 0) then
		return {-1, {1}}
	end
	if OmegaNum.equal(argument, 1) then
		return {1, {0}}
	end
	if OmegaNum.equal(argument, base) then
		return {1, {1}}
	end
	--Calculate
	if OmegaNum.lessThan(base, 1.444667861009766) then
		local a = OmegaNum.tetr(base, math.huge)
		if OmegaNum.equal(argument, a) then return {1, {math.huge}} end
		if OmegaNum.greaterThan(argument, a) then return {1, {math.nan}} end
	end
	if OmegaNum.greaterThan(OmegaNum.maximum(argument, base), PentatedMaxInteger) then
		if OmegaNum.greaterThan(argument, base) then
			return argument
		end
		return {1, {0}}
	end
	if OmegaNum.greaterThan(OmegaNum.maximum(argument, base), TetratedMaxInteger) then
		if OmegaNum.greaterThan(argument, base) then
			argument[2][3] = (argument[2][3] or 0) - 1
			argument = OmegaNum.fix(argument)
			return OmegaNum.sub(argument, argument[2][2])
		end
		return {1, {0}}
	end
	local ro = 0
	local t = (argument[2][2] or 0) - (base[2][2] or 0)
	if t > 3 then
		local l = t - 3
		ro = ro + l
		argument[2][2] = (argument[2][2] or 0) - l
	end
	for i = 1, 100 do
		if OmegaNum.lessThan(argument, 0) then
			argument = OmegaNum.pow(base, argument)
			ro = ro - 1
		elseif OmegaNum.lessThanEqual(argument, 1) then
			return OmegaNum.fix(ro + OmegaNum.toNumber(argument) - 1)
		else
			ro = ro + 1
			argument = OmegaNum.logBase(argument, base)
		end
	end
	if OmegaNum.greaterThan(argument, 10) then return OmegaNum.fix(ro) end
end

--[[
	Pentates one OmegaNum to another.
	Uses linear approximation for non-integer heights.
]]
function OmegaNum.pent(base, height)
	return OmegaNum.arrow(base, 3, height)
end

OmegaNum.pentate = OmegaNum.pent

--[[
	Hexates one OmegaNum to another.
	Uses linear approximation for non-integer heights.
]]
function OmegaNum.hext(base, height)
	return OmegaNum.arrow(base, 4, height)
end

OmegaNum.hext = OmegaNum.hext

--Allow yielding in arrow() to prevent timeouts

local nextYieldTime = os.clock() + MaxExecTime

--[[
	Takes a hyperoperation with a certain number of arrows of one OmegaNum to another.
	Uses linear approximation for non-integer heights.
]]
function OmegaNum.arrow(base, arrows, height)
	base = OmegaNum.fix(base)
	arrows = OmegaNum.fix(arrows)
	height = OmegaNum.fix(height)
	--Clone base into new value
	local hypey = copy(base)
	--Handle special cases
	if not OmegaNum.isInteger(arrows) and OmegaNum.lessThan(arrows, -2) then
		warn(InvalidArgument .. "Non-integer number of arrows specified and negative hyperoperations are undefined.")
		return {1, {math.nan}}
	end
	if not OmegaNum.isInteger(arrows) then
		warn(InvalidArgument .. "Non-integer number of arrows specified.")
		return {1, {math.nan}}
	end
	if OmegaNum.lessThan(arrows, -2) then
		warn(InvalidArgument .. "Negative hyperoperations are undefined.")
		return {1, {math.nan}}
	end
	if OmegaNum.greaterThan(arrows, MaxArrow) then
		warn("Number too large to reasonably handle. Tried to " .. OmegaNum.add(arrows, 2) .. "-ate.")
		return {1, {math.huge}}
	end
	if OmegaNum.equal(arrows, -2) then return OmegaNum.add(hypey, 1) end
	if OmegaNum.equal(arrows, -1) then return OmegaNum.add(hypey, height) end
	if OmegaNum.equal(arrows, 0) then return OmegaNum.mul(hypey, height) end
	if OmegaNum.equal(arrows, 1) then return OmegaNum.pow(hypey, height) end
	if OmegaNum.equal(arrows, 2) then return OmegaNum.tetr(hypey, height) end
	if OmegaNum.lessThan(height, 0) then return {1, {math.nan}} end
	if OmegaNum.equal(height, 0) then return {1, {1}} end
	if OmegaNum.equal(height, 1) then return hypey end
	if OmegaNum.equal(height, 2) then
		if OmegaNum.equal(hypey, 2) then
			return {1, {4}} --2{arrows}2 is always equal to 4
		end
		return OmegaNum.arrow(hypey, OmegaNum.sub(arrows, 1), hypey)
	end
	--Yield if took too long to prevent timeout
	if os.clock() >= nextYieldTime then
		task.wait()
		nextYieldTime = os.clock() + MaxExecTime
	end
	--Calculate hyperoperation
	local arrowNum = OmegaNum.toNumber(arrows)
	local max = OmegaNum.maximum(hypey, height)
	if OmegaNum.greaterThan(max, "10{" .. arrowNum + 1 .. "}" .. MaxInteger) then
		return max
	end
	local ro
	if OmegaNum.greaterThan(hypey, "10{" .. arrowNum .. "}" .. MaxInteger) or OmegaNum.greaterThan(height, MaxInteger) then
		if OmegaNum.greaterThan(hypey, "10{" .. arrowNum .. "}" .. MaxInteger) then
			ro = copy(hypey)
			ro[2][arrowNum+1] = ro[2][arrowNum+1] - 1
			ro = OmegaNum.fix(ro)
		elseif OmegaNum.greaterThan(hypey, "10{" .. arrowNum - 1 .. "}" .. MaxInteger) then
			ro = hypey[2][arrowNum]
		else
			ro = {1, {0}} --The table format is necessary to prevent error
		end
		local jo = OmegaNum.add(ro, height)
		jo[2][arrowNum+1] = (jo[2][arrowNum+1] or 0) + 1
		return OmegaNum.fix(jo)
	end
	local yo = OmegaNum.toNumber(height)
	local fo = math.floor(yo)
	local arrowm1 = OmegaNum.sub(arrows, 1)
	ro = OmegaNum.arrow(hypey, arrowm1, (yo - fo))
	local count = 0
	local mo = "10{" .. arrowNum - 1 .. "}" .. MaxInteger
	for i = 1, 100 do
		if not (fo ~= 0 and OmegaNum.lessThan(ro, mo)) then break end
		if fo > 0 then
			ro = OmegaNum.arrow(hypey, arrowm1, ro)
			fo = fo - 1
		end
		count = count + 1
	end
	--Stop if too many iterations occur
	if count == 100 then
		fo = 0
	end
	--Fill missing indicies with zeroes. This bit is necessary. Otherwise, it will return wrong values
	for i = 1, arrowNum - 1 do
		if ro[2][i] == nil then
			ro[2][i] = 0
		end
	end
	--Add remaining iterations
	ro[2][arrowNum] = ro[2][arrowNum] and (ro[2][arrowNum] + fo) or fo
	return OmegaNum.fix(ro)
end

--[[
	Takes the n-th hyperoperation of one OmegaNum to another.
	Uses linear approximation for non-integer heights.
]]
function OmegaNum.hyper(hyperoperation, base, height)
	return OmegaNum.arrow(base, OmegaNum.add(hyperoperation, 2), height)
end

--TODO: Hyper-roots, leaderboard support

return OmegaNum
