A Lua port of [Naruyoko's Javascript OmegaNum](https://github.com/Naruyoko/OmegaNum.js) that supports numbers up to 10{1000}9007199254740991.

This reaches level f<sub>ω</sub>, hence the name.

Internally, it is represented as a sign and array. Sign is either 1 or -1. Array is {n<sub>0</sub>,n<sub>1</sub>,n<sub>2</sub>,n<sub>3</sub>,n<sub>4</sub>…}. They together represents sign\*(…(10↑<sup>4</sup>)<sup>n<sub>4</sub></sup>(10↑<sup>3</sup>)<sup>n<sub>3</sub></sup>(10↑↑)<sup>n<sub>2</sub></sup>(10↑)<sup>n<sub>1</sub></sup>n<sub>0</sub>).

This is intended to be used in Roblox games. Please avoid using arrow with more than 25 arrows where possible as it can get slow due to the complexity of hyperoperations.

# Functions

* fromNumber
  * Converts a primitive number to an OmegaNum.
* toNumber
  * Converts an OmegaNum back to a primitive number.
  * Note: Lua's double only support numbers up to 2<sup>1024</sup>, so anything larger will become infinity.
* fromString
  * Converts a string to an OmegaNum.
* fromHyperE
  * Converts a Hyper E formatted string to an OmegaNum.
* toOmegaNum
  * Converts one-element tables, strings, and primitive numbers to an OmegaNum based on type.
* fix
  * Puts an OmegaNum into a standard format.
* toString
  * Converts an OmegaNum into a string in the format \[a,b,c,…\].
  * This is preferred for DataStores as a literal "9.007199254740982e15" will be treated as "9007199254740982" due to rounding when taking the log of that number.
* dispString
  * Converts an OmegaNum into a displayable string.
* dispStringDecimalPlaces
  * Converts an OmegaNum into a displayable string with a certain number of decimal places.
  * This may show "10.0…0" due to rounding and may have pretty weird results once (10^)^number number happens.
* toHyperE
  * Converts an OmegaNum into a displayable string in Hyper E.
* toSuffix
  * Converts an OmegaNum into a displayable string ending with a suffix.
  * This only supports suffixes up to the multillions (slightly less thsn eee3e45).
* dispFGHJ
  * Converts an OmegaNum into a displayable string in FGHJ notation.
    * ex = 10<sup>x</sup>
    * Fx = eee…eeex (with x e's)
    * Gx = FFF…FFFx (with x F's)
    * Hx = GGG…GGGx (with x G's)
    * Jx = 10↑<sup>x</sup>10
* isNaN
  * Returns true if the value is NaN.
  * NaN stands for Not a Number.
* isInfinite
  * Returns true if the value is infinite
* isFinite
  * Returns true if the value is a finite number.
* isInteger
  * Returns true if the value does not have a decimal portion.
* abs (or absolute)
  * Returns the absolute value of an OmegaNum.
* neg (or negate)
  * Negates an OmegaNum. (positive becomes negative and vice versa)
* compare (or cmp)
  * Compares two OmegaNums.
  * Returns 1 if value1 > value2, 0 if value1 = value2, and -1 if value1 < value2.
* greaterThan (or gt)
  * Returns whether the second OmegaNum is greater than the first.
* greaterThanEqual (or gteq)
  * Returns whether the second OmegaNum is greater than or equal to the first.
* lessThan (or lt)
  * Returns whether the second OmegaNum is less than the first.
* LessThanEqual (or lteq)
  * Returns whether the second OmegaNum is less than or equal to the first.
* equal (or eq)
  * Returns whether two OmegaNums are equal to each other.
* notEqual (or neq)
  * Returns whether two OmegaNums are not equal to each other.
* compareTolerance (or cmpTolerance)
  * Compares two OmegaNums.
  * Returns 1 if value1 > value2, 0 if value1 = value2, and -1 if value1 < value2.
* greaterThanTolerance (or gtTolerance)
  * Returns whether the second OmegaNum is greater than, but not approximately equal to the first.
* greaterThanEqualTolerance (or gteqTolerance)
  * Returns whether the second OmegaNum is greater than or approximately equal to the first.
* lessThanTolerance (or ltTolerance)
  * Returns whether the second OmegaNum is less than, but not approximately equal to the first.
* LessThanEqualTolerance (or lteqTolerance)
  * Returns whether the second OmegaNum is less than or approximately equal to the first.
* equalTolerance (or eqTolerance)
  * Returns whether two OmegaNums are approximately equal to each other.
* notEqualTolerance (or neqTolerance)
  * Returns whether two OmegaNums are not approximately equal to each other.
* minimum (or min)
  * Returns the smaller OmegaNum of the two.
* maximum (or max)
  * Returns the larger OmegaNum of the two.
* floor
  * Returns the largest value smaller than or equal to the given OmegaNum.
* round
  * Returns the value with the smallest difference between it and the given OmegaNum.
  * You can also specify the rounding mode to use when it comes to x.5.
* ceiling (or ceil)
  * Returns the smallest value larger than or equal to the given OmegaNum.
* add (or plus)
  * Adds two OmegaNums together.
* sub (or minus, subtract)
  * Subtracts one OmegaNum from another.
* mul (or times, multiply)
  * Multiplies two OmegaNums together.
* div (or divide, divideBy)
  * Divides one OmegaNum by another.
* rec (or reciprocate, inverse, reciprocal)
  * Returns the reciprocal of an OmegaNum.
  * Not very reliable with very big numbers as they return 0. If you take the reciprocal of that, you will get Infinity.
* mod (or modular, modulo, modulus)
  * Returns the remainder when you divide one OmegaNum by another.
* pow (or power)
  * Takes the exponent of one OmegaNum to another.
* exp (or exponential)
  * Takes the exponent of e to an OmegaNum.
* sqrt (or squareRoot)
  * Takes the square root of an OmegaNum.
* cbrt (or cubeRoot)
  * Takes the cube root of an OmegaNum.
* root
  * Takes a root with an arbitrary degree of an OmegaNum.
* log10 (or generalLog, generalLogarithm)
  * Takes the common logarithm of an OmegaNum.
* logBase (or logarithm)
  * Takes a logarithm with an arbitrary base of an OmegaNum.
* log (or ln,  naturalLog, naturalLogarithm)
  * Takes the natural logarithm of an OmegaNum.
* factorial (or fact)
  * Takes the factorial of an OmegaNum.
  * Uses Stirling's approximation for large numbers and the gamma function for non-integers.
* lambertw
  * Takes the Lambert W function of an OmegaNum.
  * This is also called the omega function or product logarithm.
* tetr (or tetrate, iteratedExp, iteratedExponential)
  * Tetrates one OmegaNum to another.
  * Uses linear approximation for non-integer heights.
* ssqrt
  * Takes the super square root of an OmegaNum.
* iteratedLog (or iteratedLogarithm)
  * Takes the logartihm with an arbitrary base of an OmegaNum, repeatedly.
  * May be inaccurate and slow, and could be given custom code.
* layerAdd
  * Adds a number of layers of exponential tower of a ceratin base of a certain number at the bottom.
* layerAdd10
  * Adds a number of layers of exponential tower of base 10 of a certain number at the bottom.
* linearSroot
  * Takes the super square root with an arbitrary degree of an OmegaNum.
  * Uses linear approximation.
* slog
  * Takes the super logarithm wth an arbitrary base of an OmegaNum.
* pent (or pentate)
  * Pentates one OmegaNum to another.
  * Uses linear approximation for non-integer heights.
* hext (or hexate)
  * Hexates one OmegaNum to another.
  * Uses linear approximation for non-integer heights.
* arrow
  * Takes a hyperoperation with a certain number of arrows of one OmegaNum to another.
  * Uses linear approximation for non-integer heights.
* hyper
  * Takes the n-th hyperoperation of one OmegaNum to another.
  * Uses linear approximation for non-integer heights.
