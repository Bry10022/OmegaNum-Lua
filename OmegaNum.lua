-- Making OmegaNum, with support for hyperoperations (Original by FoundForces)

--Config--
local NAN = math.nan -- NAN constant.
local INF = math.huge -- INF constant.
local paraForCorrect = 2 -- Amount of loops in errorcorrect (keep 2).
local maxInt = 2^53-1 -- Max integer thats allowed in an array.
local maxADD = "e" .. maxInt
local maxMUL = 'ee' .. maxInt -- Max Diff for mul
local maxPOW = {1, {1, maxInt}} -- Max Diff for pow
local maxH = math.log10(maxInt) -- Lowest integer thats for first number.
local signif = 2^53 -- Recommended to keep on 2^53 (consant of if x is bigger then signif dont do -1).
local amoes = 5 -- Constant where eee…eex goes to e[y]x.
local PrecisionDisplay = 7 -- Amount of digits of ouput display.
local toScientificVal = 1e9 -- Point where X gets converted to XeN in Display, must be less or equal to maxInt.
local signifDiff = 20 -- Difference where sub, add returns biggest value, recommended to keep on 20.
local ZERO = {1, {0}} -- Zero constant
local ONE = {1, {1}}
local maxAllowed = 1.797693015e308
local maxSuffix = {1, {3000003, 1}} -- max value to return suffix at short
local maxScientific = "e9007199254740991" -- seems to actually be the max before it stops returning suffixes for scientific, change back if issues arise
local maxEs = 10
local ArrowLimit = 1000 -- max number of arrows for hyper (don't make this too large)
local formatArrowLimit = 3
local pi = 3.14159265358979323846
-----------

--[[
Functions:

correct: corrects an omeganum
fromNumber: converts a number to omeganum
toNumber: converts an omeganum to number
toDisplay: displays in arrow notation
toString: converts an omeganum to string (USE THIS FOR STORING VALUES)
fromString: converts a string to omeganum
toOmega
eq
le
me
meeq
leeq
abs
neg
cmp
max
min
log10
isint
recip
pow
mod
root
mul
floor
ceil
div
add
sub
sqrt
log
exp
maxabs
eternitytoOmega
pow10
gamma
fact
rand
exporand
toBigNum
toScientific
toShortScientific
short
toEnt
toShortEnt
toEs
toShortEs
toHyperE
toShortHyperE
lambertw
slog
tetrate
pentate
hexate
hyper
lbencode
lbdecode

]]

trunc = function (n) -- math function
	if math.ceil(n) == n then return n end
	if n < 0 then
		return -(math.floor(n))
	end
	return math.floor(n)
end

function fgamma(n)
	local C = {0.99999999999980993, 676.5203681218851, -1259.1392167224028,771.32342877765313, -176.61502916214059, 12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7}
	if math.floor(n) == n then
		return fact(n-1)
	end
	if (n > 0.5) then
		n -= 1
		local x = C[1]
		for i=1,7 do
			x += C[i+1] / (n + i)
		end
		local t = n + 7.5
		return  x * t^(n+0.5 - 36) * math.exp(-t) * t^36 * 2.50662827463100050241576528
	end
	return 3.141592653589793238 / (math.sin(3.141592653589793238 * n) * fgamma(1 - n))
end

function f_lambertw(z)
	local tol = 1e-10
	local w,wn = nil
	if z > 1.79e308 then return z
	end
	if z == 0 then
		return z
	end
	if z == 1 then
		return 0.56714329040978387299997
	end
	if z < 10 then
		w = 0
	else
		w = math.log(z)-math.log(math.log(z))
	end
	for i=1,100 do
		wn = (z * math.exp(-w) + w * w)/(w + 1)
		if math.abs(wn - w) < tol*math.abs(wn) then
			return wn
		else
			w = wn
		end

	end
	warn("Failed at W")
	return 0/0
end

function Hlambertw(n)
	local tol = 1e-10
	n = OmegaNum.correct(n)
	local wn;
	local w = OmegaNum.log(n)
	for i=1,100 do
		wn = OmegaNum.div(OmegaNum.add(OmegaNum.mul(n,OmegaNum.exp(OmegaNum.neg(w))),OmegaNum.mul(w,w)),OmegaNum.add(w,1))
		if OmegaNum.le(OmegaNum.abs(OmegaNum.sub(wn,w)), OmegaNum.mul(tol,OmegaNum.abs(wn))) then
			return wn
		end
		w = wn
	end
	warn("Failed at hlam")
	return NAN
end

OmegaNum = {}

function OmegaNum.correct(val)
	if val == nil then return ZERO end
	if val ~= val then return NAN end
	if type(val) ~= 'table' then
		return OmegaNum.toOmega(val)
	end
	if type(val[2]) ~= "table" and #val == 2 then
		val = {math.sign(val[1]), {val[2] + math.log10(math.abs(val[1])),1}}
	end
	if type(val[2]) ~= "table" then
		val = {1,val}
	end
	if #val[2] == 0 then
		return ZERO
	end
	if (val[1] == 1 or val[1] == -1) and #val[2] == 1 and val[2][1] == 0 or  #val[2] == 2 and val[2][1] == 0  and val[2][2] == 0 then
		return {val[1],{0}}
	end
	-- {sign, {}}
	local qq = copytab(val)
	local sign = qq[1]
	local array = qq[2]
	array = array or {0}
	sign = sign or 1
	local len = #array

	for i=len,1,-1 do
		if array[i] == 0 then
			table.remove(array)
			len -= 1
		else
			break
		end
	end
	if array[1] > maxInt then
		array[1] = math.log10(array[1])
		if len > 1 then
			array[2] += 1
		else
			table.insert(array, 1)
			len += 1
		end
	end
	-- handle 1,0,0,0,x
	if len > 2 then
		if (array[2] or 0) < 3 then
			for i=1,(array[2] or 0) do
				if array[i] >= math.log10(maxInt) then
					break
				elseif (array[2] or 0) == 0 then
					break
				end
				array[i] = 10^array[i]
				array[2] = (array[2] or 0) - 1
			end
		end
		if array[2] == 0 then
			if array[1] == 1 then
				for i=2,len do
					if array[i] == 0 then
						continue
					elseif array[i] > 1 then
						break
					elseif array[i] == 1 and i == len then
						return {sign, {10}}
					end
				end
			end
			local LastZero = 2
			local OneEncountered = false
			for i=3,#array do
				if array[i] == 0 then
					LastZero = i
				elseif array[i] == 0 and OneEncountered then
					continue
				elseif array[i] == 1 and OneEncountered  then
					break
				elseif array[i] == 1  then
					OneEncountered = true
				else
					break
				end
			end
			if LastZero == len then
				return {sign, {array[1]}}
			else
				local Mode = 1
				if array[1] == 1 then Mode = OneEncountered and 1 or 2 array[1] = 10 end
				array[LastZero] = array[1] - 2
				array[1] = 1e10
				for i=2,LastZero - 1 do
					array[i] = 8
				end
				array[LastZero + 1] -= Mode
				for i=#array,2,-1 do
					if array[i] == 0 then
						array[i] = nil
					else
						break
					end
				end
				-- Loop through LastZero
				--return {sign, array}
			end
		end
	end
	len = #array
	for i=len,1,-1 do
		if array[i] == 0 then
			table.remove(array)
			len -= 1
		else
			break
		end
	end
	if len > 1 then
		if array[1] < math.log10(maxInt) and array[2] > 0  then
			array[2] -= 1
			array[1] = 10^array[1]
			array[2] = (array[2] == 0) and nil or array[2]
		end
		if array[1] < math.log10(maxInt) and array[2] > 0  then
			array[2] -= 1
			array[1] = 10^array[1]
			array[2] = (array[2] == 0) and nil or array[2]
		end
	end
	for i=2,len do
		if array[i]>maxInt then
			array[1] = array[i]
			array[i+1] = (array[i+1] or 0)+1
			array[i]+=1
			for j=2,i do
				array[j] = 0
			end
			if array[1] > maxInt then
				array[1] = math.log10(array[1])
				array[2]+=1
			end
		end
	end
	-- Convert trailing zeros
	-- Remove trailing zeros
	-- loop until
	if qq[1] == 0 then
		return ZERO
	end
	for i=1,#array do
		local cur = array[i]
		if cur == NAN then
			warn('correct() returning NAN')
			return qq
		end
		if cur==INF then
			return qq
		end
		if cur % 1 ~= 0 and i~= 1 then
			array[i] = math.floor(cur)
		end
	end
	if not #array then qq[2] = {0} end
	return qq
end

function OmegaNum.fromNumber(val)
	if type(val) ~= 'number' then
		error('NAN input at fromNumber()')
	end
	if val == 0 then
		return ZERO
	end
	return OmegaNum.correct({math.sign(val), {math.abs(val)}})
end

function OmegaNum.toNumber(val)
	val = OmegaNum.correct(val)
	local array = val[2]
	local sign = val[1]
	if #array >=2 and (array[2]>=2 or (array[2] ==1 and array[1]>math.log10(maxAllowed))) then
		return INF*sign
	end
	return array[2] == 1 and 10^array[1]*sign or array[1]*sign
end

local function formatarrow(val)
	if type(val) == "number" then
		local t = ''
		if val > formatArrowLimit then
			t = "10{"..OmegaNum.toDisplay(val).."}"
		else
			t = '10'
			for i = 1,val do
				t ..= "^"
			end
		end
		return t
	end
end

function OmegaNum.toDisplay(val,short)
	local val1 = OmegaNum.correct(val)
	local array = val1[2]
	local sign = val1[1]
	if short then
		if array[1] == NAN then
			return 'NaN'
		end
		if array[1] > INF then
			return 'Infinity'
		end
		if #array == 2 then
			local es = ''
			local esign = ''
			if sign == 0 then
				return '0'
			end
			if sign < 0 then
				esign = '-'
			end
			local base = 1
			if math.fmod(array[1],1) ~= 0 then
				base = 10^(array[1]-math.floor(array[1]))
				array[1] = math.floor(array[1])
			end
			if array[2] > amoes then
				return  esign .. '10^^' .. OmegaNum.short(array[2]-1) .. ' ' .. base .. 'e' .. OmegaNum.short(array[1])
			end
			for i=1,array[2]-1 do
				es = es .. 'e'
			end
			return esign .. es .. OmegaNum.short(base) .. 'e' .. OmegaNum.short(array[1])
		end
		local function Decimal(val, amo)
			local a = math.floor(val*10^amo)
			a = a/10^amo
			return a
		end
		if #array == 1 then
			if array[1] > toScientificVal then
				local esign = ''
				if sign == 0 then
					return '0'
				end
				if sign < 0 then
					esign = '-'
				end
				local exponent = math.floor(math.log10(array[1]))
				local base = array[1]/10^exponent
				return esign .. OmegaNum.short(Decimal(base, PrecisionDisplay)) .. 'e' .. OmegaNum.short(exponent)
			else
				return OmegaNum.short(array[1]*sign)
			end
		end
		if #array > 2 then
			local str = ''
			for i=#array,1,-1 do
				if i == 1 then
					str = str .. 'e' ..  OmegaNum.short(array[i])
					break
				end
				if array[i] ~= 0 then
					--str = str .. '(10↑[' .. i-1 .. '])' .. array[i]
					str = str .. formatarrow(i) .. OmegaNum.short(array[i]) .. " "
				end
			end
			return str
		end
	else
		if array[1] == NAN then
			return 'NaN'
		end
		if array[1] > INF then
			return 'Infinity'
		end
		if #array == 2 then
			local es = ''
			local esign = ''
			if sign == 0 then
				return '0'
			end
			if sign < 0 then
				esign = '-'
			end
			local base = 1
			if math.fmod(array[1],1) ~= 0 then
				base = 10^(array[1]-math.floor(array[1]))
				array[1] = math.floor(array[1])
			end
			if array[2] > amoes then
				return  esign .. '10^^' .. array[2]-1 .. ' ' .. base .. 'e' .. array[1]
			end
			for i=1,array[2]-1 do
				es = es .. 'e'
			end
			return esign .. es .. base .. 'e' .. array[1]
		end
		local function Decimal(val, amo)
			local a = math.floor(val*10^amo)
			a = a/10^amo
			return a
		end
		if #array == 1 then
			if array[1] > toScientificVal then
				local esign = ''
				if sign == 0 then
					return '0'
				end
				if sign < 0 then
					esign = '-'
				end
				local exponent = math.floor(math.log10(array[1]))
				local base = array[1]/10^exponent
				return esign .. Decimal(base, PrecisionDisplay) .. 'e' .. exponent
			else
				return array[1]*sign
			end
		end
		if #array > 2 then
			local str = ''
			for i=#array,1,-1 do
				if i == 1 then
					str = str .. 'e' ..  array[i]
					break
				end
				if array[i] ~= 0 then
					--str = str .. '(10↑[' .. i-1 .. '])' .. array[i]
					str = str .. formatarrow(i) .. array[i] .. " "
				end
			end
			return str
		end
	end
end

function OmegaNum.toString(val)
	val = OmegaNum.correct(val)
	val[2][1] *= val[1]
	return game.HttpService:JSONEncode(val[2])
end

function OmegaNum.fromString(str)
	if str == "[0]" then
		return ZERO
	end
	if string.find(str, ',') or string.find(str, "%[") then
		local HttpService = game:GetService("HttpService")
		local data = HttpService:JSONDecode(str)
		local sign = math.sign(data[1] or 1)
		data[1] = math.abs(data[1] or 0)
		return OmegaNum.correct({sign, data})
	end
	local isNegative = false
	local signCountStart, signCountEnd = string.find(str, "^[-+]+")
	if signCountStart then
		local signs = string.sub(str, signCountStart, signCountEnd)
		local _, minusCount = string.gsub(signs, "-", "")
		if minusCount % 2 == 1 then
			isNegative = true
		end
		str = string.sub(str, signCountEnd + 1)
	end
	-- Handle infinity and NaN (case-insensitive)
	if str:lower() == "nan" then
		return NAN
	elseif str:lower() == "inf" or str:lower() == "infinity" then
		local sign = isNegative and -1 or 1
		return sign * INF
	end
	-- get all parts between e's
	local parts = string.split(str:lower(), "e")
	local b = {0, 0}
	local indexR = #parts
	while indexR > 1 and parts[indexR] ~= "" do
		local nextVal = tonumber(parts[indexR]) or 0
		if b[2] == 0 and nextVal <= 15 then
			local combinedStr = parts[indexR-1] .. "e" .. tostring(nextVal)
			local parsed = tonumber(combinedStr)
			if parsed then
				b[1] = parsed
				indexR = indexR - 2
			else
				break
			end
		else
			break
		end
	end
	-- Multiply coefficients
	for i = indexR, 1, -1 do
		local currentPart = parts[i]
		if b[1] < 15 and b[2] == 0 then
			b[1] = 10 ^ b[1]
		else
			b[2] = b[2] + 1
		end
		if currentPart ~= "" then
			local num = tonumber(currentPart) or 1
			if b[2] == 0 then
				b[1] = b[1] * num
			elseif b[2] == 1 then
				b[1] = b[1] + math.log10(num)
			else
				if b[2] == 2 and b[1] < 15 + math.log10(math.log10(num)) then
					b[1] = b[1] + math.log10(1 + 10^(math.log10(math.log10(num)) - b[1]))
				end
			end
		end
	end
	-- Adjust for large numbers if needed
	if b[1] < 15 and b[2] > 0 then
		b[1] = 10 ^ b[1]
		b[2] = b[2] - 1
	elseif b[2] == 0 and b[1] > maxInt then
		b[1] = math.log10(b[1])
		b[2] = 1
	elseif b[1] > maxInt then
		b[1] = math.log10(b[1])
		b[2] = b[2] + 1
	end
	-- Apply the sign
	local finalSign = isNegative and -1 or 1
	local first = b[1]
	local second = b[2]

	return OmegaNum.correct({finalSign, {first, second}})
end

function OmegaNum.toOmega(val)
	if type(val) == 'table' then
		-- Assuming its Omega type.
		-- For converting other Bnums please use assigned function.
		if #val < 2 then
			val = {1, val}
		end
		return val
	end
	if type(val) == 'number' then
		-- convert number to omega
		return OmegaNum.fromNumber(val)
	end
	if type(val) == 'string' then
		-- convert str to omega
		return OmegaNum.fromString(val)
	end
end

function OmegaNum.eq(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	return OmegaNum.cmp(val, val2) == 0
end

function OmegaNum.le(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	return OmegaNum.cmp(val, val2) == -1
end

function OmegaNum.me(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	return OmegaNum.cmp(val, val2) == 1
end

function OmegaNum.meeq(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	return OmegaNum.cmp(val, val2) >= 0
end

function OmegaNum.leeq(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	return OmegaNum.cmp(val, val2) <= 0
end

function OmegaNum.abs(val)
	val = OmegaNum.correct(val)
	return {1, val[2]}
end

function OmegaNum.neg(val)
	val = OmegaNum.correct(val)
	return {val[1]*-1, val[2]}
end

function OmegaNum.cmp(val, val2) -- 0 = eq, -1 = le, 1 = me
	val = OmegaNum.correct(val)
	val2 = OmegaNum.correct(val2)
	local V1Nan = val ~= val
	if V1Nan and val2 ~= val2 then return 0
	elseif V1Nan or val2 ~= val2 then return 1
	end
	if val[1] == INF and val2[1] ~= INF then
		return val[1]
	end
	if val[1] ~= INF and val2[1] == INF then
		return -val2[1]
	end
	if #val[2]==1 and val[2][1]==0 and #val2[2]==1 and val2[2][1]==0 then
		return 0
	end
	if val[1] ~= val2[1] then
		return val[1]
	end
	local a = val[1]
	local z
	if #val[2] > #val2[2] then z=1
	elseif #val[2] < #val2[2] then z=-1
	else
		for i=#val[2],1,-1 do
			if val[2][i] > val2[2][i] then
				z = 1
				break
			elseif val[2][i] < val2[2][i] then
				z = -1
				break
			end
		end
		z= z or 0
	end
	return z*a
end

--[[function OmegaNum.sub(val, val2)
	return OmegaNum.add(val, OmegaNum.neg(val2))
end]]

function OmegaNum.max(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	if OmegaNum.me(val, val2) then
		return val
	else
		return val2
	end
end

function OmegaNum.min(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	if OmegaNum.me(val, val2) then
		return val2
	else
		return val
	end
end

function copytab(v)
	local new = {}
	new[1] = v[1]
	new[2] = {}
	for i,v in next, v[2] do
		new[2][i] = v
	end
	return new
end

function OmegaNum.log10(val)
	val = OmegaNum.correct(val)
	if OmegaNum.eq(val , ZERO) then
		return ZERO
	end
	local val1 = copytab(val)
	if OmegaNum.le(val1, 0) then return NAN end
	if OmegaNum.eq(val1, 0) then return -INF end
	if OmegaNum.leeq(val1, maxInt) then return OmegaNum.fromNumber(math.log10(OmegaNum.toNumber(val1))) end
	val1[2][2] -= 1
	return OmegaNum.correct(val1)
end

function OmegaNum.isint(val)
	val = OmegaNum.correct(val)
	if val[1] ==-1 then
		return OmegaNum.isint(OmegaNum.abs(val))
	end
	if OmegaNum.meeq(val, maxInt) then
		return true
	end
	return math.fmod(OmegaNum.toNumber(val),1) == 1
end

function OmegaNum.recip(val)
	val = OmegaNum.correct(val)
	if OmegaNum.me(OmegaNum.abs(val), "2e323") then return ZERO end
	return OmegaNum.div(1, val)
end

function OmegaNum.pow(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	local sign,sign2 = val[1],val2[1]
	local array,array2 = val[2],val2[2]
	if OmegaNum.eq(val2, 0) then
		return {1, {1}}
	end
	if OmegaNum.eq(val2, 1) then
		return val
	end
	if OmegaNum.le(val2, 0) then
		return OmegaNum.recip(OmegaNum.pow(val, OmegaNum.neg(val2)))
	end
	if OmegaNum.le(val, 0) and OmegaNum.isint(val2) then
		if OmegaNum.le(OmegaNum.mod(val2, 2), 1) then
			return OmegaNum.pow(OmegaNum.abs(val), val2)
		end
		return OmegaNum.neg(OmegaNum.pow(OmegaNum.abs(val), val2))
	end
	if OmegaNum.le(val, ZERO) then
		return NAN
	end
	if OmegaNum.eq(val, 1) then
		return {1, {1}}
	end
	if OmegaNum.eq(val, ZERO) then
		return ZERO
	end
	if OmegaNum.meeq(OmegaNum.max(val,val2), maxPOW) then
		return OmegaNum.max(val, val2)
	end
	if OmegaNum.eq(val, 10) then
		if OmegaNum.me(val2, 0) then
			if array2[2] then
				array2[2] = array2[2]+1
			else
				array2[2] = 1
			end
			return OmegaNum.correct(val2)
		else
			return OmegaNum.fromNumber(10^OmegaNum.toNumber(val2))
		end
	end
	if OmegaNum.le(val2, 1) then
		OmegaNum.root(val,OmegaNum.recip(val2))
	end
	local ni = OmegaNum.toNumber(val)^OmegaNum.toNumber(val2)
	if ni<= maxInt then
		return OmegaNum.fromNumber(ni)
	end
	local f = OmegaNum.log10(val)
	local exporrrrrrrrrr =  OmegaNum.mul(f, val2)
	return OmegaNum.pow(10, exporrrrrrrrrr)
end

function OmegaNum.mod(val, val2)
	val = OmegaNum.correct(val)
	val2 = OmegaNum.correct(val2)
	local sign,sign2 = val[1],val2[1]
	if OmegaNum.eq(val,ZERO) then
		return ZERO
	end
	if sign*sign2 == -1 then
		return OmegaNum.neg(OmegaNum.mod(OmegaNum.abs(val), OmegaNum.abs(val2)))
	end
	if sign == -1 then
		return OmegaNum.mod(OmegaNum.abs(val), OmegaNum.abs(val2))
	end
	return OmegaNum.sub(val, OmegaNum.mul(OmegaNum.floor(OmegaNum.div(val, val2)), val2))
end

function OmegaNum.root(val, val2)
	val,val2 = OmegaNum.correct(val),OmegaNum.correct(val2)
	if OmegaNum.eq(val2, 1) then
		return val
	end
	if OmegaNum.le(val2,ZERO) then
		return OmegaNum.recip(OmegaNum.root(val, OmegaNum.neg(val2)))
	end
	if OmegaNum.le(val2, 1) then
		return OmegaNum.pow(val, OmegaNum.recip(val2))
	end
	if OmegaNum.le(val, ZERO)and OmegaNum.isint(val2) and OmegaNum.eq(OmegaNum.mod(val2, 2), 1) then
		return OmegaNum.neg(OmegaNum.root(OmegaNum.neg(val), val2))
	end
	if OmegaNum.le(val, ZERO) then
		return NAN
	end
	if OmegaNum.eq(val, 1) then
		return {1, {1}}
	end
	if OmegaNum.eq(val, ZERO) then
		return ZERO
	end
	if OmegaNum.me(OmegaNum.max(val, val2), maxPOW) then
		if OmegaNum.me(val, val2)  then
			return val
		else
			return ZERO
		end
	end
	return OmegaNum.pow(10, OmegaNum.div(OmegaNum.log10(val), val2))
end

function OmegaNum.mul(val,val1)
	local x = OmegaNum.correct(val)
	local y= OmegaNum.correct(val1)
	if x[1]*y[1]==-1 then
		return OmegaNum.neg( OmegaNum.mul( OmegaNum.abs(x), OmegaNum.abs(y) ) )
	end
	if x[1] == -1 then
		return OmegaNum.mul(OmegaNum.abs(x),OmegaNum.abs(y))
	end
	if OmegaNum.eq(x,ZERO) or OmegaNum.eq(y,ZERO) then
		return ZERO
	end
	if OmegaNum.eq(y,{1,{1}}) then
		return x
	end
	if OmegaNum.me(OmegaNum.max(x,y),maxMUL) then
		return OmegaNum.max(x, y)
	end
	local n = OmegaNum.toNumber(x)*OmegaNum.toNumber(y)
	if math.abs(n) <= maxAllowed then
		return OmegaNum.correct(n)
	end
	return OmegaNum.pow(10,OmegaNum.add(OmegaNum.log10(x),OmegaNum.log10(y)))
end

function OmegaNum.floor(x)
	if OmegaNum.isint(x) then
		return x
	end
	return OmegaNum.correct(math.floor(OmegaNum.toNumber(x)))
end

function OmegaNum.ceil(x)
	if OmegaNum.isint(x) then
		return x
	end
	return OmegaNum.correct(math.ceil(OmegaNum.toNumber(x)))
end

function OmegaNum.div(val,val1)
	local x = OmegaNum.correct(val)
	local y = OmegaNum.correct(val1)
	if x[1]*y[1]==-1 then
		return OmegaNum.neg(OmegaNum.div(OmegaNum.abs(x), OmegaNum.abs(y)))
	end
	if x[1] == -1 then
		return OmegaNum.div(OmegaNum.abs(x),OmegaNum.abs(y))
	end
	if OmegaNum.eq(y, ZERO) then
		return NAN
	end
	if OmegaNum.eq(y,{1,{1}}) then
		return x
	end
	if OmegaNum.eq(x,ZERO) then
		return ZERO
	end
	if OmegaNum.me(OmegaNum.max(x,y),maxMUL) then
		if OmegaNum.me(x,y) then
			return x
		end
		return ZERO
	end
	local FILTER1 = OmegaNum.toNumber(x)/OmegaNum.toNumber(y)
	if math.abs(FILTER1) <= maxAllowed then
		return OmegaNum.correct(FILTER1)
	end
	local qq = OmegaNum.pow(10, OmegaNum.sub(OmegaNum.log10(x),OmegaNum.log10(y)) )
	local qqw = OmegaNum.floor(qq)
	if OmegaNum.le(OmegaNum.sub(qq,qqw), 1e-9) then
		return qqw
	end
	return qq
end

function OmegaNum.add(x,y)
	x = OmegaNum.correct(x)
	y = OmegaNum.correct(y)
	if x[1] == -1 then
		return OmegaNum.neg(OmegaNum.add(OmegaNum.neg(x), OmegaNum.neg(y)))
	end
	if y[1] == -1 then
		return OmegaNum.sub(x, OmegaNum.neg(y))
	end
	if OmegaNum.eq(x, ZERO) then
		return y
	end
	if OmegaNum.eq(y, ZERO) then
		return x
	end
	local p = OmegaNum.min(x,y)
	local q = OmegaNum.max(x,y)
	local a = nil
	if OmegaNum.me(q,maxADD) or OmegaNum.me(OmegaNum.div(q,p), maxInt) then
		a = q
	elseif q[2][2] == nil then
		a = OmegaNum.correct(OmegaNum.toNumber(x)+OmegaNum.toNumber(y))
	elseif q[2][2] == 1 then
		local b = nil
		if p[2][2] then
			b = p[2][1]
		else
			b = math.log10(p[2][1])
		end
		a = OmegaNum.correct({1, {b+math.log10(math.pow(10,q[2][1]-b)+1) , 1}})
	end
	return a
end

function OmegaNum.sub(x,y)
	x = OmegaNum.correct(x)
	y = OmegaNum.correct(y)
	if x[1] == -1 then
		return OmegaNum.neg(OmegaNum.sub(OmegaNum.neg(x),OmegaNum.neg(y)))
	end
	if y[1] == -1 then
		return OmegaNum.add(x, OmegaNum.neg(y))
	end
	if OmegaNum.eq(x,y) then
		return ZERO
	end
	if OmegaNum.eq(y,ZERO) then
		return x
	end
	local p = OmegaNum.min(x,y)
	local q = OmegaNum.max(x,y)
	local FILTER2= OmegaNum.me(y,x)
	local FILTER1;
	if OmegaNum.me(q,maxADD) or OmegaNum.me(OmegaNum.div(q,p), maxADD) then
		FILTER1=q
		if FILTER2 then
			FILTER1 = OmegaNum.neg(FILTER1)
		end
	elseif q[2][2] == nil then
		FILTER1 = OmegaNum.correct(OmegaNum.toNumber(x)-OmegaNum.toNumber(y))
	elseif q[2][2] == 1 then
		local b = nil
		if p[2][2] then
			b = p[2][1]
		else
			b = math.log10(p[2][1])
		end
		local DIFF = q[2][1]-b
		if DIFF > 20 then
			FILTER1 = OmegaNum.max(x,y)
			if FILTER2 then
				return OmegaNum.neg(FILTER1)
			end
			return FILTER1
		end
		FILTER1 = OmegaNum.correct({1, {b+math.log10(math.pow(10,q[2][1]-b)-1) , 1}})
		if FILTER2 then
			FILTER1 = OmegaNum.neg(FILTER1)
		end
	end
	return FILTER1
end

function OmegaNum.sqrt(x)
	return OmegaNum.root(x,2)
end

function OmegaNum.log(x,y)
	y = y or 2.7182818284590452353602874
	return OmegaNum.div(OmegaNum.log10(x),OmegaNum.log10(y))
end

function OmegaNum.exp(x)
	return OmegaNum.pow(2.7182818284590452353602874, x)
end

function OmegaNum.maxabs(x,y)
	return OmegaNum.max(OmegaNum.abs(x),OmegaNum.abs(y))
end

function OmegaNum.eternitytoOmega(num)
	local new = {num[1], {}}
	new[2][1] = num[3]
	new[2][2] = (num[2]>=1) and num[2] or nil
	return new
end

function OmegaNum.pow10(x)
	return OmegaNum.pow(10,x)
end

function OmegaNum.gamma(x)
	x = OmegaNum.correct(x)
	if OmegaNum.me(x,maxPOW) then
		return x
	end
	if OmegaNum.me(x,maxADD) then
		return OmegaNum.exp(x)
	end
	if OmegaNum.me(x,maxInt) then
		return OmegaNum.exp(OmegaNum.mul(x,OmegaNum.sub(OmegaNum.log(x),1)))
	end
	if OmegaNum.leeq(x,171) then
		return OmegaNum.correct(fgamma(OmegaNum.toNumber(x)))
	end
	local q = x[2][1]
	if q>1 then
		local t=q-1
		local l=0.9189385332046727
		l+=(t+.5)*math.log(t)
		l-=t
		local n2 = t^2
		local np=t
		local lm=12*np
		local adj=1/lm
		local l2 = l+adj
		if (l2==l) then
			return OmegaNum.exp(l)
		end
		l=l2
		np*=2
		lm=360*np
		adj=1/lm
		l2=l-adj
		if (l2==l) then
			return OmegaNum.exp(l)
		end
		l=l2
		np*=n2
		lm=1260*np
		local lt=1/lm
		l+=lt
		np*=n2
		lm=1680*np
		lt=1/lm
		l-=lt
		return OmegaNum.exp(l)
	end
	return OmegaNum.recip(x)
end

function fact(x) -- x!
	local amo = 1
	for i=1,x do
		amo *= i
	end
	return amo
end

function OmegaNum.fact(x)
	x = OmegaNum.correct(x)
	if OmegaNum.leeq(x, 170) then
		x = OmegaNum.toNumber(x)
		if x == math.floor(x) then
			return OmegaNum.correct(fact(x))
		end
		return OmegaNum.correct(fgamma(OmegaNum.toNumber(x)+1))
	end
	return OmegaNum.gamma(OmegaNum.add(x,1))
end

function OmegaNum.rand(min, max)
	local seed = math.random()
	local even = OmegaNum.sub(max, min)
	even = OmegaNum.mul(even, seed)
	return OmegaNum.add(even, min)
end

function OmegaNum.exporand(min, max)
	return OmegaNum.exp(OmegaNum.rand(OmegaNum.log(min), OmegaNum.log(max)))
end

function OmegaNum.toBigNum(val)
	val = OmegaNum.correct(val)
	local b = {}
	if #val[2] == 1 then
		return errorcorrection({val[2][1]*val[1],0})
	end
	if val[2][2] == 1 then
		return errorcorrection({1*val[1],val[2][1]})
	end
	if val[2][2] == 2 and math.log10(val[2][1]) <= 308 then
		return {1*val[1], 10^val[2][1]}
	end
	return {1*val[1], INF}
end

function OmegaNum.toScientific(x)
	x = OmegaNum.correct(x)
	if OmegaNum.le(OmegaNum.abs(x), 1000) then
		return OmegaNum.toNumber(x)
	end
	if OmegaNum.me(OmegaNum.abs(x),maxScientific) then
		return OmegaNum.toEs(x)
	end
	local function Decimal(val, amo)
		local a = math.round(val*10^amo)
		a = a/10^amo
		return a
	end
	local array = x[2]
	if array[2] == nil then
		local exp = math.log10(array[1])
		local b = 10^(exp-math.floor(exp))
		if x[1] == -1 then
			return "-" .. Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
		else
			return Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
		end
	end
	if array[2] == 1 then
		local exp = array[1]
		local b = 10^(exp-math.floor(exp))
		if x[1] == -1 then
			return "-" .. Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
		else
			return Decimal(b,PrecisionDisplay) .. 'e' .. math.floor(exp)
		end
	end
end

function OmegaNum.toShortScientific(x)
	x = OmegaNum.correct(x)
	if OmegaNum.le(OmegaNum.abs(x),1000) then
		return OmegaNum.toNumber(x)
	end
	if OmegaNum.me(OmegaNum.abs(x),maxScientific) then
		return OmegaNum.toEs(x)
	end
	local x1 = x[1]
	local x2 = x[2]

	if x1 == -1 then
		return "-" .. string.rep("e", x2[2]) .. short(OmegaNum.toBigNum(x2[1]))
	else
		return string.rep("e", x2[2]) .. short(OmegaNum.toBigNum(x2[1]))
	end
end

function OmegaNum.short(x)
	x = OmegaNum.correct(x)
	if OmegaNum.meeq(OmegaNum.abs(x),maxSuffix) then
		return OmegaNum.toScientific(x)
	end
	return short(OmegaNum.toBigNum(x))
end

function OmegaNum.toEnt(x)
	x = OmegaNum.correct(x)
	if x[2][3] then
		if x[2][3] > 1 or x[2][1] >= 15.954589770191003 or x[2][2] > 1 then
			return OmegaNum.toHyperE(x)
		end
		x[2][2] = 10^x[2][1]
		x[2][3] = nil
	end
	local part = "(E^" .. x[2][2] .. ")"
	if x[1] == -1 then
		part = "-" .. part
	end
	return part .. x[2][1]
end

function OmegaNum.toShortEnt(x)
	x = OmegaNum.correct(x)
	if x[2][3] then
		if x[2][3] > 1 or x[2][1] >= 15.954589770191003 or x[2][2] > 1 then
			return OmegaNum.toShortHyperE(x)
		end
		x[2][2] = 10^x[2][1]
		x[2][3] = nil
	end
	local part = "(E^" .. OmegaNum.short(x[2][2]) .. ")"
	if x[1] == -1 then
		part = "-" .. part
	end
	return part .. OmegaNum.short(x[2][1])
end

function OmegaNum.toEs(x)
	x = OmegaNum.correct(x)
	if #x[2] > 2 then
		return OmegaNum.toEnt(x)
	end
	if x[2][2] == nil then
		return OmegaNum.short(x)
	end
	if x[2][2] > maxEs then
		return OmegaNum.toEnt(x)
	end
	if x[1] == -1 then
		return "-" .. OmegaNum.toEs(OmegaNum.abs(x))
	end
	local function Decimal(val, amo)
		local a = math.floor(val*10^amo)
		a = a/10^amo
		return a
	end
	local estring = string.rep("e", x[2][2])
	return estring .. Decimal(x[2][1],4)
end

function OmegaNum.toShortEs(x)
	x = OmegaNum.correct(x)
	if #x[2] > 2 then
		return OmegaNum.toShortEnt(x)
	end
	if x[2][2] == nil then
		return OmegaNum.short(x)
	end
	if x[2][2] > maxEs then
		return OmegaNum.toShortEnt(x)
	end
	if x[1] == -1 then
		return "-" .. OmegaNum.toShortEs(OmegaNum.abs(x))
	end
	local function Decimal(val, amo)
		local a = math.floor(val*10^amo)
		a = a/10^amo
		return a
	end
	local estring = string.rep("e", x[2][2])
	return estring .. OmegaNum.short(Decimal(x[2][1],4))
end

function OmegaNum.toHyperE(x)
	x = OmegaNum.correct(x)
	if x[1] == -1 then
		return "-" .. OmegaNum.toHyperE(OmegaNum.abs(x))
	end
	if OmegaNum.le(x,maxInt) then
		return OmegaNum.short(x)
	end
	if OmegaNum.le(x,maxADD) then
		return "E" .. x[2][1]
	end
	local function Decimal(val, amo)
		local a = math.floor(val*10^amo)
		a = a/10^amo
		return a
	end
	local str = "E" ..  Decimal(x[2][1],PrecisionDisplay).."#" .. x[2][2]
	for i=3,#x[2] do
		str ..= "#" .. x[2][i]+1
	end
	return str
end

function OmegaNum.toShortHyperE(x)
	x = OmegaNum.correct(x)
	if x[1] == -1 then
		return "-" .. OmegaNum.toShortHyperE(OmegaNum.abs(x))
	end
	if OmegaNum.le(x,maxInt) then
		return OmegaNum.short(x)
	end
	if OmegaNum.le(x,maxADD) then
		return "E" .. OmegaNum.short(x[2][1])
	end
	local function Decimal(val, amo)
		local a = math.floor(val*10^amo)
		a = a/10^amo
		return a
	end
	local str = "E" ..  OmegaNum.short(Decimal(x[2][1],PrecisionDisplay)).."#" .. OmegaNum.short(x[2][2])
	for i=3,#x[2] do
		str ..= "#" .. OmegaNum.short(x[2][i]+1)
	end
	return str
end

function OmegaNum.lambertw(x)
	x = OmegaNum.correct(x)
	if OmegaNum.leeq(x,1e308) then
		return f_lambertw(OmegaNum.toNumber(x))
	end
	if OmegaNum.me(x, maxPOW) then
		return x
	end
	if OmegaNum.me(x, maxMUL) then
		return OmegaNum.log10(x)
	end
	return Hlambertw(x)
end

function OmegaNum.slog(r,base)
	local x = copytab(OmegaNum.correct(r))
	base = OmegaNum.toOmega(base)
	if OmegaNum.le(x, ZERO) then
		return {-1,{1}}
	end
	if OmegaNum.eq(x,ONE)  then
		return ZERO
	end
	if OmegaNum.eq(x,base) then
		return ONE
	end
	if OmegaNum.le(base, math.exp(1/2.7182818284)) then
		return x
	end
	if OmegaNum.me(OmegaNum.max(x,base),{1,{10000000000, 8, maxInt}}) then
		if OmegaNum.me(x,base) then
			return x
		end
		return ZERO
	end
	if OmegaNum.me(OmegaNum.max(x,base), maxPOW) then
		if OmegaNum.me(x,base) then
			x[2][3] -= 1
			return OmegaNum.sub(x,x[2][2])
		end
		return ZERO
	end
	local q =0
	local t = (x[2][2] or 0) - (base[2][2] or 0)
	if t>3 then
		local p = t-3
		q += p
		x[2][2] -= p
	end
	for i=1,99 do
		if OmegaNum.le(x, ZERO) then
			x = OmegaNum.pow(base,x)
			q-=1
		else if OmegaNum.leeq(x,1) then
				return OmegaNum.toOmega(q+OmegaNum.toNumber(x)-1)
			else
				q += 1
				x = OmegaNum.log(x,base)
			end
		end
	end
	if OmegaNum.me(x, 10) then
		return q
	end
end

function OmegaNum.tetrate(x,y)
	x = OmegaNum.correct(x)
	y = OmegaNum.correct(y)
	if OmegaNum.le(y,-2) then
		return NAN
	end
	if OmegaNum.eq(x,ZERO) then
		if OmegaNum.eq(y,0) then
			return NAN
		end
		if OmegaNum.eq(OmegaNum.mod(y,2),0) then
			return ZERO
		end
		return {1,{1}}
	end
	if OmegaNum.eq(x,{1,{1}}) then
		if OmegaNum.eq(y, {-1,{1}}) then
			return NAN
		end
		return {1,{1}}
	end
	if OmegaNum.eq(y, {-1,{1}}) then
		return ZERO
	end
	if OmegaNum.eq(y, 0) then
		return {1,{1}}
	end
	if OmegaNum.eq(y, 1) then
		return x
	end
	if OmegaNum.eq(y,2) then
		return OmegaNum.pow(x,x)
	end
	if OmegaNum.eq(x,2) then
		if OmegaNum.eq(y,3) then
			return OmegaNum.fromNumber(16)
		end
		if OmegaNum.eq(y,4) then
			return OmegaNum.fromNumber(65536)
		end
	end
	local max = OmegaNum.max(x,y)
	if OmegaNum.me(max, {1,{10000000000, 8, maxInt}}) then
		return max
	end
	if OmegaNum.me(x, maxPOW) or OmegaNum.me(y, maxInt) then
		if OmegaNum.le(x, math.exp(1/2.7182818284)) then
			local nel = OmegaNum.neg(OmegaNum.log(x))
			return OmegaNum.div(OmegaNum.lambertw(nel), nel)
		end
		local q = copytab(OmegaNum.add(OmegaNum.slog(x,10),y))
		q[2][3] = (y[2][3] or 0)+1
		return OmegaNum.correct(q)
	end
	local yo = OmegaNum.toNumber(y)
	local fo = math.floor(yo)
	local ro = OmegaNum.pow(x, yo-fo)
	local mo = maxADD
	local lo = NAN
	local count = 0
	for i=1,100 do
		if not(fo~=0 and OmegaNum.le(ro,mo)) then break end
		count +=1
		if fo>0 then
			ro = OmegaNum.pow(x,ro)
			if OmegaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo -= 1
		else
			ro = OmegaNum.log(ro,x)
			if OmegaNum.eq(lo,ro) then
				fo=0
				break
			end
			lo=ro
			fo += 1
		end
	end
	if count == 100 or OmegaNum.le(x,math.exp(1/2.7182818284)) then
		fo = 0
	end
	ro[2][2] = ro[2][2] and ro[2][2]+fo or fo
	return OmegaNum.correct(ro)
end

OmegaNum.tetr = OmegaNum.tetrate

function OmegaNum.pentate(x,y)
	return OmegaNum.hyper(5,x,y)
end

OmegaNum.pent = OmegaNum.pentate

function OmegaNum.hexate(x,y)
	return OmegaNum.hyper(6,x,y)
end

OmegaNum.hext = OmegaNum.hexate

--Allows hyper() to yield so it doesn't cause script timeout for large values of n
local maxHyperExec = 1/60
local nextYieldTime = os.clock() + maxHyperExec

function OmegaNum.hyper(n,x,y)
	x = OmegaNum.correct(x)
	y = OmegaNum.correct(y)
	n = math.floor(n) -- To force it to be an integer since non-integer hyperoperations are all undefined.

	if n >= ArrowLimit + 2 then
		warn("Number is too large to reasonably handle. OmegaNum attempted to " .. n .. "-ate.")
		return INF
	end

	-- Handle special cases
	if n < 0 then
		warn("Hyperoperations are not defined for n < 0.")
		return NAN
	end
	if n == 0 then return OmegaNum.add(x, 1) end -- A hyper-0 function is the successor function, which only adds 1 to the number.
	if n == 1 then return OmegaNum.add(x, y) end
	if n == 2 then return OmegaNum.mul(x, y) end
	if n == 3 then return OmegaNum.pow(x, y) end
	if n == 4 then return OmegaNum.tetr(x, y) end

	if OmegaNum.le(y, -1) then return NAN end
	if OmegaNum.eq(y, ZERO) then return {1, {1}} end
	if OmegaNum.eq(y, 1) then return x end
	if OmegaNum.eq(y, 2) then
		return OmegaNum.hyper(n - 1, x, x)
	end
	
	if math.fmod(n,50) == 0 then --Adjust the second parameter of the fmod as needed
		if os.clock() >= nextYieldTime then
			task.wait()
			nextYieldTime = os.clock() + maxHyperExec
		end
	end

	-- Check for maximum value, which should be 10{n+1}MaxInt
	local max = OmegaNum.max(x, y)
	if OmegaNum.me(max, "[10000000000,"..string.rep("8,",(n-3))..maxInt.."]") then
		return max
	end

	local arrowCount = n-2

	local ro
	if OmegaNum.me(x, "[10000000000,"..string.rep("8,",(n-4))..maxInt.."]") or OmegaNum.me(y, maxInt) then
		if OmegaNum.me(x, "[10000000000,"..string.rep("8,",(n-4))..maxInt.."]") then
			ro = copytab(x)
			ro[2][arrowCount+1] -= 1
			ro = OmegaNum.correct(ro)
		elseif OmegaNum.me(x, "[10000000000,"..string.rep("8,",(n-5))..maxInt.."]") then
			ro = x[2][arrowCount]
		else
			ro = ZERO
		end
		local jo = OmegaNum.add(ro, y)
		-- Fill missing or nil indicies in the array with 0's
		for i = 1, arrowCount + 1 do
			if jo[2][i] == nil then
				jo[2][i] = 0
			end
		end
		jo[2][arrowCount+1] = (jo[2][arrowCount+1] or 0)+1
		return OmegaNum.correct(jo)
	end
	-- The hyper-machine itself
	local yo = OmegaNum.toNumber(y)
	local fo = math.floor(yo)
	ro = OmegaNum.hyper(n-1, x, (yo-fo))
	local count = 0
	local mo = "[10000000000,"..string.rep("8,",(n-5))..maxInt.."]"
	while fo ~= 0 and OmegaNum.le(ro, mo) and count < 100 do
		if fo > 0 then
			ro = OmegaNum.hyper(n-1, x, ro)
			fo = fo - 1
		end
		count = count + 1
	end

	--if count == 100 then fo = 0 end
	-- This bit is necessary. otherwise, it will make it return wrong values
	for i = 1, arrowCount + 1 do
		if ro[2][i] == nil then
			ro[2][i] = 0
		end
	end

	ro[2][arrowCount] = ((ro[2][arrowCount] or 0) + fo) or fo
	return OmegaNum.correct(ro)
end

function OmegaNum.lbencode(onum)
	onum = OmegaNum.correct(onum)
	if OmegaNum.eq(onum,0) then
		return 0
		-- For maximum performance, you do not need to encode 0.
	end
	local sign = onum[1]
	onum = onum[2]
	-- #onum
	local amo = #onum
	-- convert to float rn??
	if amo == 1 then
		-- mode 0: Native Float
		return sign * math.floor(math.log10((onum[1] + 1)) * 6.26775e14)
	elseif amo == 2 and onum[2] < 4 then
		-- mode 1: Native BigNum
		-- mode 2: Native Post-BigNum
		-- mode 3: Native EternityNum
		return sign * (math.floor(math.log10((onum[1] + 1)) * 6.26775e14) + onum[2]*1e16)
	elseif amo == 2 and onum[2] <= 9999 then
		-- mode 4: Native Big EternityNum Numbers
		local cnum = 4e16
		cnum += math.log10((onum[1] + 1)) * 6.26775e8
		cnum += onum[2] * 1e10
		return sign * cnum
	elseif amo == 2 then
		-- mode 5: Native Extreme EternityNum Numbers
		local cnum = 5e16
		cnum += math.log10((onum[2] + (math.log10(onum[1]) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo == 3 and onum[3] == 1 then
		-- mode 6: Beyond EternityNum
		local cnum = 6e16
		cnum += math.log10((onum[2] + (math.log10(onum[1]) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo == 3 and onum[3] == 2 then
		-- mode 7: Post-EternityNum
		local cnum = 7e16
		cnum += math.log10((onum[2] + (math.log10(onum[1]) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo == 3 and onum[3] < 9999 then
		-- mode 8: Pentation Empire
		local cnum = 8e16
		cnum += math.log10((onum[2] + (math.log10(onum[1]) / 16) + 1)) * 6.26775e8
		cnum += onum[3] * 1e10
		return sign * cnum
	elseif amo == 3 then
		-- mode 9: Ultra Pentation
		local cnum = 9e16
		cnum += math.log10((onum[3] + (math.log10(onum[2]+1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo == 4 then
		-- mode 10: Big Number Territory
		local cnum = 1e17
		cnum += math.log10((onum[4] + (math.log10(onum[3]+1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo == 5 then
		-- mode 11: I Do Not Konw
		local cnum = 1.1e17
		cnum += math.log10((onum[5] + (math.log10(onum[4]+1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif amo > 5 and amo < 917 then
		-- good until 916 arrays
		local cnum = amo*1e16 + 6e16
		cnum += math.log10((onum[amo] + (math.log10(onum[amo - 1]+1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	else
		return sign * 9223372036854775808
	end
end

function OmegaNum.lbdecode(int)
	if int == 0 then return {1, {0}} end
	local sign = math.sign(int)
	int = math.abs(int)
	local mode = math.floor(int / 1e16)
	if mode>=3 then
		int -= 1
	end
	if mode == 0 then
		return {sign, {10^(int / 6.26775e14) - 1}}
	elseif mode < 4 then
		return {sign, {10^(math.fmod(int, 1e16) / 6.26775e14) - 1, mode}}
	elseif mode == 4 then
		local remainder = math.fmod(int, 1e10)
		return {sign, {10^(remainder / 6.26775e8) - 1, math.floor((int - 4e16) / 1e10)}}
	elseif mode == 5 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {arg1, math.floor(arrows)}}
	elseif mode == 6 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {arg1, math.floor(arrows), 1}}
	elseif mode == 7 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {arg1, math.floor(arrows), 2}}
	elseif mode == 8 then
		local arg3 = math.floor((int-8e16) / 1e10)
		local remainder = math.fmod(int, 1e10) * 1e6
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {arg1, math.floor(arrows), math.floor(arg3)}}
	elseif mode == 9 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		return {sign, {1, math.floor(arg1), math.floor(arrows)}}
	elseif mode == 10 then
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = 10^(math.fmod(arrows, 1)*16)
		local hixd = {sign, {1, 0, math.floor(arg1), math.floor(arrows)}}
		if hixd[2][4] == 0 then
			table.remove(hixd[2], 4)
		end
		return hixd
	else
		local zeros = mode - 10
		local remainder = math.fmod(int, 1e16)
		local arrows = 10^(remainder / 6.26775e14) - 1
		local arg1 = maxInt^(math.fmod(arrows, 1))
		local xd = {1, 0}
		for i=1,zeros do
			table.insert(xd, 0)
		end
		table.insert(xd, math.floor(arg1))
		table.insert(xd, math.floor(arrows))
		if xd[zeros + 4] == 0 then
			table.remove(xd)
		end
		return {sign, xd}
	end
end

--bignum part ; )
function errorcorrection(bnum)
	local signal = "+"
	if bnum[1] == 0 then
		return {0, 0}
	end
	if bnum[1] < 0 then
		signal = "-"
	end
	if signal == "-" then
		bnum[1] = bnum[1] * -1
	end
	local signal2 = "+"
	if bnum[2] < 0 then
		signal2 = "-"
		bnum[2] = bnum[2] * -1
	end
	if math.fmod(bnum[2], 1) > 0 and signal2 == "-" then
		bnum[1] = bnum[1] * (10^ (1 - math.fmod(bnum[2], 1)))
		bnum[2] = math.floor(bnum[2]) + 1
	elseif math.fmod(bnum[2], 1) > 0 and signal2 == "+"  then
		bnum[1] = bnum[1] * (10^  math.fmod(bnum[2], 1))
		bnum[2] = math.floor(bnum[2])
	end
	if signal2 == "-" then
		bnum[2] = bnum[2] * -1
	end
	local DgAmo = math.log10(bnum[1])
	DgAmo = math.floor(DgAmo)
	bnum[1] = bnum[1] / 10^DgAmo
	bnum[2] = bnum[2] + DgAmo
	bnum[2] = math.floor(bnum[2])
	if signal == "-" then
		bnum[1] = bnum[1] * -1
	end
	return bnum
end

function bnumtostr(bnum)
	return tostring(bnum[1]) .. "e" .. tostring(bnum[2])
end

function bnumtofloat(bnum)
	return tonumber(bnumtostr(bnum))
end

function commas(Value)
	if math.abs(Value) < 1e3 then
		return Value
	end
	local Number
	local Formatted = math.round(Value * 1000) / 1000
	if math.abs(Value) < 10^13 then
		while (Number ~= 0) do
			Formatted, Number = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		end
		return Formatted
	elseif math.abs(Value) < 10^26 then
		local Formatted2 = math.floor(Value / 10^12)
		Formatted = math.fmod(Value, 10^12)
		while Number ~= 0 do
			Formatted2, Number = string.gsub(Formatted2, "^(-?%d+)(%d%d%d)", '%1,%2')
		end
		Number = nil
		while Number ~= 0 do
			Formatted, Number = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		end
		local TpFormatted = math.fmod(Value, 10^12)
		local String = Formatted2 .. ","
		if TpFormatted == 0 then
			String ..= "000,000,000,000"
		elseif TpFormatted < 10 then
			String ..= "000,000,000,00"
		elseif TpFormatted < 100 then
			String ..= "000,000,000,0"
		elseif TpFormatted < 1000 then
			String ..= "000,000,000,"
		elseif TpFormatted < 10000 then
			String ..= "000,000,00"
		elseif TpFormatted < 100000 then
			String ..= "000,000,0"
		elseif TpFormatted < 1000000 then
			String ..= "000,000,"
		elseif TpFormatted < 10000000 then
			String ..= "000,00"
		elseif TpFormatted < 100000000 then
			String ..= "000,0"
		elseif TpFormatted < 1000000000 then
			String ..= "000,"
		elseif TpFormatted < 10000000000 then
			String ..= "00"
		elseif TpFormatted < 100000000000 then
			String ..= "0"
		end
		if TpFormatted > 0 then
			String ..= Formatted
		end
		return String
	else
		return "9,999,999,999,999,999,999,999,999,999+"
	end
end

function short(bnum)
	local SNumber = bnum[2]
	local SNumber1 = bnum[1]
	local leftover = math.fmod(SNumber, 3)
	SNumber = math.floor(SNumber / 3)
	SNumber = SNumber - 1
	if SNumber <= -1 then
		return math.round(bnumtofloat(bnum)*100000)/100000
	end
	local FirstOnes = {"","U","D","T","Qd","Qn","Sx","Sp","Oc","No"}
	local SecondOnes = {"","De","Vt","Tg","qg","Qg","sg","Sg","Og","Ng"}
	local ThirdOnes = {"","Ce","Du","Tr","Qa","Qi","Se","Si","Ot","Nt"}
	local MultOnes = {"","Mil-","Mic-","Nan-","Pic-","Fem-","Att-","Zep-","Yoc-","Ron-","Qet-",
		"Mec-","Due-","Tre-","Ttr-","Pnt-","Hex","Hep-","Oct-","Enn-","Ico-",
		"MeIc-","DeIc-","TrIc-","TeIc-","PeIc-","HeIc-","HpIc-","OcIc-","EnIc-","Trc-",
		"Metc-","Detc-","Trtc-","Tetc-","Petc-","Hetc-","Hptc-","Octc-","Entc-","Ttc-",
		"MeTc-","DeTc-","TrTc-","TeTc-","PeTc-","HeTc-","HpTc-","OcTc-","EnTc-","Pec-",
		"MePc-","DePc-","TrPc-","TePc-","PePc-","HePc-","HpPc-","OcPc-","EnPc-","Het-",
		"Meht-","Deht-","Trht-","Teht-","Peht-","Heht-","Hpht-","Ocht-","Enht-","Hpt-",
		"MeHt-","DeHt-","TrHt-","TeHt-","PeHt-","HeHt-","HpHt-","OcHt-","EnHt-","Oca-",
		"MeOa-","DeOa-","TrOa-","TeOa-","PeOa-","HeOa-","HpOa-","OcOa-","EnOa-","Ent-",
		"MeEt-","DeEt-","TrEt-","TeEt-","PeEt-","HeEt-","HpEt-","OcEt-","EnEt-","Hec-","MeHc-","DeHc-"}
	if bnum[2] == 1/0 then
		if bnum[1] < 0 then
			return "-Infinity"
		else
			return "Infinity"
		end
	end

	if SNumber == 0 then
		return commas(bnumtofloat(bnum))
	elseif SNumber == 1 then
		return math.round(SNumber1 * 10^leftover * 100000)/100000 .. "M"
	elseif SNumber == 2 then
		return math.round(SNumber1 * 10^leftover * 100000)/100000 .. "B"
	end
	local txt = ""

	local function suffixpart(n, is_mult)
		local Hundreds = math.floor(n/100)
		n = math.fmod(n, 100)
		local Tens = math.floor(n/10)
		n = math.fmod(n, 10)
		local Ones = math.floor(n/1)

		if is_mult and Ones == 1 and Tens == 0 and Hundreds == 0 then
			txt = txt .. ""
		else
			txt = txt .. FirstOnes[Ones + 1]
		end

		txt = txt .. SecondOnes[Tens + 1]
		txt = txt .. ThirdOnes[Hundreds + 1]
	end

	if SNumber < 1000 then
		suffixpart(SNumber, false)
		return math.round(SNumber1 * 10^leftover * 100000)/100000 .. txt
	end

	for i = #MultOnes,1,-1 do
		if SNumber >= 10^(i*3) then
			local chunk = math.floor(SNumber / 10^(i*3))
			suffixpart(chunk, true)
			txt = txt .. MultOnes[i+1]
			SNumber = math.fmod(SNumber, 10^(i*3))
		end
	end

	if SNumber > 0 then
		suffixpart(SNumber, false)
	end

	return math.round(SNumber1 * 10^leftover * 100000)/100000 .. string.gsub(txt, "%-$", "")
end

-- Making it easier for SamirDevs to use this for OperatorSim lol.

function OmegaNum.onflt(onum)
	return OmegaNum.toNumber(onum)
end

function OmegaNum.flton(flt)
	return OmegaNum.toOmega(flt)
end

function OmegaNum.onstr(onum)
	return OmegaNum.toString(onum)
end

function OmegaNum.stron(str)
	return OmegaNum.toOmega(str)
end

function OmegaNum.equal(onum1,onum2)
	return OmegaNum.eq(onum1,onum2)
end

function OmegaNum.moOmegaNumqual(onum1,onum2)
	return OmegaNum.meeq(onum1,onum2)
end

function OmegaNum.lessequal(onum1,onum2)
	return OmegaNum.leeq(onum1,onum2)
end

function OmegaNum.more(onum1,onum2)
	return OmegaNum.me(onum1,onum2)
end

function OmegaNum.less(onum1,onum2)
	return OmegaNum.le(onum1,onum2)
end

function OmegaNum.abbreviate(onum)
	onum = OmegaNum.correct(onum)
	if OmegaNum.eq(onum,{1,{0}}) then
		return "0"
	elseif OmegaNum.le(onum, {1, {0.000000001}}) then
		return "1 / " .. OmegaNum.short(OmegaNum.div(1, onum))
	elseif OmegaNum.le(onum,maxSuffix) then
		return OmegaNum.short(onum)
	elseif OmegaNum.le(onum,maxScientific) then
		return OmegaNum.toShortScientific(onum)
	elseif OmegaNum.le(onum,{1,maxEs,1}) then
		return OmegaNum.toShortEs(onum)
	elseif OmegaNum.le(onum,{1,maxInt,1}) then
		return OmegaNum.toShortEnt(onum)
	else
		return OmegaNum.toShortHyperE(onum)
	end
end

return OmegaNum
