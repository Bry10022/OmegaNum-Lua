A Lua port of [Naruyoko's Javascript OmegaNum](https://github.com/Naruyoko/OmegaNum.js) that supports numbers up to 10{1000}9007199254740991.

This reaches level f<sub>ω</sub>, hence the name.

Internally, it is represented as an sign and array. Sign is either 1 or -1. Array is {n<sub>0</sub>,n<sub>1</sub>,n<sub>2</sub>,n<sub>3</sub>,n<sub>4</sub>…}. They together represents sign\*(…(10↑<sup>4</sup>)<sup>n<sub>4</sub></sup>(10↑<sup>3</sup>)<sup>n<sub>3</sub></sup>(10↑↑)<sup>n<sub>2</sub></sup>(10↑)<sup>n<sub>1</sub></sup>n<sub>0</sub>).

I'll write an explanation of what each function does as I don't have the time right now.
