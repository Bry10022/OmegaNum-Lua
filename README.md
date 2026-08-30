Original made by FoundForces, with support for hyper() (please don't use hyperoperations that are more than hyper-100, it can get slow).

Intended to be used with Roblox.

Known issues:
- ~~Wonky results with fromString() if you have multiple e's and numbers between the e's ("e4.6e6" being treated as "1e1000000" instead of "1e4600000")~~ Fixed! You can now write "e4.6e6" and have it be treated as "1e4600000". You can do this with any number of e's. For much larger numbers, you still need to do it like "\[num1, num2, num3, …\]".
- ~~Wrong results with hyper() if values go above maxInt and still has instances to perform~~ Fixed! (I hope)
