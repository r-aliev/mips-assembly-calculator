# Calculator on Mips Assembly 

## Description

This calculator works in a very simple way. Each operand or operation input should be given in a separate line and result is shown also in a new line.
For example, to calculate 10 + 10:


`````````````````
10
+
10
20
`````````````````

to calculate `(2 + 3)` × 5, enter, line per line : `2, +, 3, * et 5.` During reading of operation, program stops running if input is a empty line or unkown operation/operand.

Calculator runs in 2 modes: integer and float mode. 
Most of the functions are built by using very basic commands, not built-in Mips functions (for example: to multiply used loop with `add` function, not Mips built-in `mult`)

### Available operations

- `+` : addition
- `-` : substraction
- `*` : multiplication
- `/` : division
- `min` : minimum
- `max` : maximum
- `pow` : power
- `abs` : absolute value
- `print_bin`: print a number in a binary form (only for integers)
- `print_hexa`: print a number in a hexadecimal form (only for integers)
- `print_significand`: print a float number significand (only for floats)
- `print_exponent`: print a float number exponent (only for floats)



### Installation

U can use Mars simulator to run a program on a command line:

```
 java -jar Mars4_5.jar nc calculatrice.s

```

To choose between integer and float mode use:

```
 java -jar Mars4_5.jar nc calculatrice.s pa integer
```

```
 java -jar Mars4_5.jar nc calculatrice.s pa float
```

To use  test files from command line:

```
 java -jar Mars4_5.jar nc calculatrice.s pa integer <tests/test_001.txt