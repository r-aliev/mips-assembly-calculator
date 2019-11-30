################################################################################
## calculatrice.s
################################################################################
##
## Examples (assuming 'Mars4_5.jar' is present in the current directory):
## $ echo -en "10\n+\n10\n\n" java -jar Mars4_5.jar nc calculatrice.s
## $ java -jar Mars4_5.jar nc calculatrice.s <test_001.txt 2>/dev/null
## $ java -jar Mars4_5.jar nc calculatrice.s pa "integer"
## $ java -jar Mars4_5.jar nc calculatrice.s pa "float"
##
################################################################################
##
## Copyright (c) 2019 John Doe <user@server.tld>
## This work is free. It comes without any warranty, to the extent permitted by
## applicable law.You can redistribute it and/or modify it under the terms of
## the Do What The Fuck You Want To Public License, Version 2, as published by
## Sam Hocevar. See http://www.wtfpl.net/ or below for more details.
##
################################################################################
##        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##                    Version 2, December 2004
##
## Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
##
## Everyone is permitted to copy and distribute verbatim or modified
## copies of this license document, and changing it is allowed as long
## as the name is MODIFIED.
##
##            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
##
##  0. You just DO WHAT THE FUCK YOU WANT TO.
################################################################################


################################################################################
# Misc.
################################################################################
#
# I/O
# ===
#
# Input is on stdin, the expected output (and only the expected output) is on
# stdout. The output on stderr does not matter.
#
# Float functions conventions
# ===========================
#
# - Use float registers ($f0, $f1, ..., $f12, $f13, ..., $f31)
# - Place function arguments in $f12, $f13, etc.
# - Place function results in $f0, $f1
# - Double values "take" two registers: use even numbered registers
#   ($f0, $f2, $f4, ..., $f30).
#
# Float <-> integer conversion
# ===========================
#
# Two steps:
# (1) convert into an integer (but the result is stored in a float register!)
# (2) move the converted value into the appropriate register
#
#   # Convert $f12 into an integer and store it in $f13:
#   cvt.w.s $f13, $f12
#   # Move the integer into an integer register:
#   mfc1 $a0 $f13
#
# Use mtc1 and cvt.s.w to reverse the process:
#
#   mtc1 $a0 $f0
#   cvt.s.w $f0 $f0
#
# Misc. recommendations
# =====================
#
# 1. Implement basic integer operations (+, -, /, *) and calculator_integer
# 2. Implement basic floating point operations (+, -, /, *) and calculator_float
#    (Set $v0 to 1 instead of 0 at 'ignore_cli_args' to "manually" switch into
#     float mode)
# 3. Complete handle_cli_args
#
################################################################################
# Data
################################################################################

.data
#Input string
userInput: .space 101

#to store a value of function print_hexa
hexa_result: .space 8
#to store a value of function print_significand
significand_result: .space 101
#to store a value of function print_exponent
exponent_result: .space 101
# Floating point values
fp0: .float 0.0
fp1: .float 1.0
fpMoins1: .float -1.0

# Characters
operators: .byte '+' '-' '*' '/'
space: .byte ' '

#-------------------------------------------------------------------------------
# Strings
#-------------------------------------------------------------------------------

# Misc.
string_space: .asciiz " "
string_newline: .asciiz "\n"
string_output_prefix: .asciiz "> "
string_arg: .asciiz "arg: "
string_calculator: .asciiz "calculator: "

# Cli args
string_integer: .asciiz "integer"
string_float: .asciiz "float"
string_double: .asciiz "double"

# Operations
string_min: .asciiz "min"
string_max: .asciiz "max"
string_pow: .asciiz "pow"
string_abs: .asciiz "abs"

#Additional operations
string_print_binary: .asciiz "print_bin"
string_print_hexa: .asciiz "print_hexa"
string_print_significand: .asciiz "print_significand"
string_print_exponent: .asciiz "print_exponent"
################################################################################
# Text
################################################################################

.text
.globl __start

__start:

# argc/argv handling
beq $a0 $0 ignore_cli_args
jal handle_cli_args
j calculator_selection

ignore_cli_args:
  li $v0 0

calculator_selection:
  # Calculator
  bne $v0 $0 calculator_select_float
  # $v0 == 0
  calculator_select_integer:
    jal calculator_integer
    j program_exit
  # $v0 != 0
  calculator_select_float:
    jal calculator_float
    j program_exit
  calculator_select_default:
    j program_exit

# Program exit
program_exit:
  li $v0 10
  syscall

################################################################################
# Calculator main
################################################################################

## Integer calculator
##
## Inputs:
## none
##
## Outputs:
## none
calculator_integer:
  subu $sp $sp 32
  sw $ra 0($sp)
  sw $a0 4($sp)
  sw $a1 8($sp)
  sw $a2 12($sp)
  sw $s0 16($sp)
  sw $s1 20($sp)
  sw $s2 24($sp)
  sw $s3 28($sp)

  # Debugging info (integer mode) on stderr
  la $a0 string_calculator
  jal print_string_stderr
  la $a0 string_integer
  jal print_string_stderr
  jal print_newline_stderr

  calculator_integer_start:
    # Very first operand
    jal read_int
    # We save the first arg in $s0
    move $s0 $v0


  # Calculator loop
  #$t0 - address d'elt de operators
  #$t7 - counter
  calculator_integer_loop:
	
	
	#read operation
	li $v0 8
  	la $a0 userInput
  	li $a1 101
 	syscall
 	
 	#length of inputed string
 	la $a0 userInput
 	jal strlen
 	#save n in $s2
 	move $s2 $v0 
 	addi $s2 $s2 -1  # cuz while entering a number count 1 like 2
 	
 	#condition for strings bigger that 1 (min,max,pow etc.)
 	beq $s2 1 enter_1st_loop
 	j big_strings_comparison
 	enter_1st_loop:
 	
 	  #before looping
 	  la $a0 userInput #pass 1st argument to strncmmp
 	  la $t5 operators #for  definind 2nd argument while looping for srncmp
 	  move $a2 $s2 #pass 3rd argument to strncmp
 	  li $t4 0 #counter 
 	
 	  li $v0 0 
 	  loop: #find 2nd argument - operator (arg $a1) - for integer operations
 	    beq $v0 1 fin_loop
 	    la $a1 0($t5)
 	    jal simple_strncmp
 	    addi $t4 $t4 1 #counter++
 	    addi $t5 $t5 1
 	     beq $t4 5 program_exit #stop program if user enters undefined string
 	    j loop
 	  fin_loop:
 	  jal read_int #read 2nd operand from user
 	  move $a1 $v0 #pass 2nd operand as arg for integer operations
 	  move $a0 $s0 #pass 1st operand as arg for integer operations
 	  add:
	    bne $t4 1 substract
	    jal operation_integer_addition
	    j   calculator_integer_loop_end
	  substract: 
	    bne $t4 2 multiply
	    jal operation_integer_substraction
	    j   calculator_integer_loop_end
	  multiply:
	    bne $t4 3 divide
	    jal operation_integer_multiplication
	    j calculator_integer_loop_end
	  divide:
	    #no need - bne $t7 4 (error)
	    jal operation_integer_division
	    j calculator_integer_loop_end
	##############################################################
	###Big Srtings Comparison(max, min , abs etc.)###############
	#############################################################
	big_strings_comparison:
	  #preparing and passing arguments for strincmp
	  #$a0 has been passed
	  #$s2 contains (strlength value - 1)
	  move $a2 $s2
	  #switch 
	  #case('max')
	  la $a1 string_max
	  jal simple_strncmp
	  beq $v0 1 max
	  
	  #case('min')
	  la $a1 string_min
	  jal simple_strncmp
	  beq $v0 1 min
	  
	  #case('pow')
	  la $a1 string_pow
	  jal simple_strncmp
	  beq $v0 1 pow
	  
	  #case('abs')
	  la $a1 string_abs
	  jal simple_strncmp
	  beq $v0 1 absolute
	  

	  #case("print_bin")
	  la $a1 string_print_binary
	  jal simple_strncmp
	  beq $v0 1 print_bin
	  

	  #case("print_hexa")
	  la $a1 string_print_hexa
	  jal simple_strncmp
	  beq $v0 1 print_hex
	  
	  #default - break
	  j program_exit
	  
	  
    max:
      #passing arguments to function
      move $a0 $s0 #pass 1st operand as arg for integer operations
      jal read_int #read 2nd operand from user
      move $a1 $v0 #pass 2nd operand as arg for integer operations
      jal operation_integer_maximum
      j calculator_integer_loop_end
      
    min:
      #passing arguments to function
      move $a0 $s0 #pass 1st operand as arg for integer operations
      jal read_int #read 2nd operand from user
      move $a1 $v0 #pass 2nd operand as arg for integer operations
      jal operation_integer_minimum
      j calculator_integer_loop_end
    
    pow:
      #passing arguments to function
      move $a0 $s0 #pass 1st operand as arg for integer operations
      jal read_int #read 2nd operand from user
      move $a1 $v0 #pass 2nd operand as arg for integer operations
      jal operation_integer_pow
      j calculator_integer_loop_end
	  
	  absolute:
	    #passing arguments to function
	    move $a0 $s0 #pass 1st operand as arg for integer operations
 	    #no need to 2nd operand
	    jal operation_integer_abs
	    j calculator_integer_loop_end	 
	    
    print_bin:
      #passing arguments to function
      move $a0 $s0 #pass 1st operand as arg for integer operations
      #no need to 2nd operand
      jal print_binary
      j calculator_integer_loop_end
        
    print_hex:
      #passing arguments to function
      move $a0 $s0
      #pass 1st operand as arg for integer operations
      #no need to 2nd operand
      jal print_hexa
      j calculator_integer_loop_end
	    
 
    calculator_integer_loop_end:
      # Set the result as new first arg
      move $s0 $v0
      # Print result
      move $a0 $v0
      jal print_int
      jal print_newline

      # TODO: uncomment the looping jump below once you are ready

      # Ready to loop!
      j calculator_integer_loop

  calculator_integer_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $s0 16($sp)
    lw $s1 20($sp)
    lw $s2 24($sp)
    lw $s3 28($sp)
    addu $sp $sp 32
    jr $ra

calculator_float:
  subu $sp $sp 24
  sw $ra 0($sp)
  sw $a0 4($sp)
  swc1 $f0 8($sp)
  swc1 $f12 12($sp)
  swc1 $f13 16($sp)
  swc1 $f3 20($sp)

  # Debugging info (float mode) on stderr
  la $a0 string_calculator
  jal print_string_stderr
  la $a0 string_float
  jal print_string_stderr
  jal print_newline_stderr

  calculator_float_start:
    # Very first operand
    jal read_float
    # We save the first arg in $f3 (arbitrarily chosen register)
    mov.s $f3 $f0

  # Calculator loop
  calculator_float_loop:

    # TODO:
    # Read operation
    li $v0 8
      la $a0 userInput
      li $a1 101
    syscall
    
    #length of inputed string
    la $a0 userInput
    jal strlen
    addi $v0 $v0 -1
    move $s2 $v0 #save strlen value
    
    beq $s2 1 enter_1st_loop_float
    j big_strings_comparison_float
    enter_1st_loop_float:
      #before looping
      la $a0 userInput #pass 1st argument to strncmp
      la $t5 operators #to define 2nd argument while looping
      move $a2 $s2 #pass 3rd argument to strncmp
      li $t4 0 #counter
      
      li $v0 0 #set return value to false for being able to loop
      loop_float: 
        beq $v0 1 fin_loop_float
        la $a1 0($t5)
        jal simple_strncmp
        addi $t4 $t4 1 #increment counter
        addi $t5 $t5 1 #delete first char of operator each time
        beq $t4 5 program_exit #stop program if user enters undefined string with 1 char
        j loop_float
      fin_loop_float:
      jal read_float #read 2nd operand from user 
      mov.s $f13 $f0 #pass it to float operations as 2nd arg
      mov.s $f12 $f3 #pass saved 1st operand to float operation as 1st arg
      add_float:
        bne $t4 1 substract_float
        jal operation_float_addition
        j calculator_float_loop_end
      substract_float:
        bne $t4 2 multiply_float
        jal operation_float_substraction
        j calculator_float_loop_end
      multiply_float:
        bne $t4 3 divide_float
        jal operation_float_multiplication
        j calculator_float_loop_end
      divide_float:
        #bne $t4 4 error - non need
        jal operation_float_division
        j calculator_float_loop_end
        
   big_strings_comparison_float:   
        #preparing and passing arguments for strncmp
        # $a0 has been passed
        # $s2 contains n
        move $a2 $s2
        #switch
        #case('max')
        la $a1 string_max
        jal simple_strncmp
        beq $v0 1 max_float
        
        #case('min')
        la $a1 string_min
        jal simple_strncmp
        beq $v0 1 min_float
        
     
         #case('pow')
	  la $a1 string_pow
	  jal simple_strncmp
	  beq $v0 1 pow_float
	  
	  #case('abs')
	  la $a1 string_abs
	  jal simple_strncmp
	  beq $v0 1 absolute_float
	  
	  #case('print_significand')
	  la $a1 string_print_significand
	  jal simple_strncmp
	  beq $v0 1 print_sign
	  
	  #case('print_exponent')
	  la $a1 string_print_exponent
	  jal simple_strncmp
	  beq $v0 1 print_exp
	  
	  #default - break
	  j program_exit
	  
	  max_float:
	    #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    jal read_float #read 2nd operand from user
 	    mov.s $f13 $f0 #pass 2nd operand as arg for float operations
	    jal operation_float_maximum
	    j calculator_float_loop_end
	      
	  min_float:
	   #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    jal read_float #read 2nd operand from user
 	    mov.s  $f13 $f0 #pass 2nd operand as arg for float operations
	    jal operation_float_minimum
	    j calculator_float_loop_end
	   
	  pow_float:
	   #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    jal read_float #read 2nd operand from user
            mov.s $f13 $f0 #pass 2nd operand as arg for float operations
	    jal operation_float_pow
	    j calculator_float_loop_end
	  
	  absolute_float:
	    #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    #no need to 2nd operand
	    jal operation_float_abs
	    j calculator_float_loop_end	  
	    
	  print_sign:
	    #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    #no need to 2nd operand
	    jal print_significand
	    j calculator_float_loop_end	 
	  
    print_exp:
	    #passing arguments to function
	    mov.s $f12 $f3 #pass 1st operand as arg for float operations
 	    #no need to 2nd operand
	    jal print_exponent
	    j calculator_float_loop_end	 
	  
	  
    

    calculator_float_loop_end:
      # Set the result as 'new first arg'
      mov.s $f3 $f0
      # Print result
      mov.s $f12 $f0
      jal print_float
      jal print_newline

      # TODO: uncomment the looping jump below once you are ready

      # Ready to loop!
       j calculator_float_loop

  calculator_float_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lwc1 $f0 8($sp)
    lwc1 $f12 12($sp)
    lwc1 $f13 16($sp)
    lwc1 $f3 20($sp)
    addu $sp $sp 24
    jr $ra

################################################################################
# CLI
################################################################################

## Handle CLI arguments (currently just prints them...)
##
## Inputs:
## $a0: argc
## $a1: argv
##
## Outputs:
## $v0: 0 if we choose integer mode, 1 if we choose float mode
handle_cli_args:
  subu $sp $sp 20
  sw $ra 0($sp)
  sw $a0 4($sp)
  sw $a1 8($sp)
  sw $s0 12($sp)
  sw $s1 16($sp)

  # Copy argc and argv in $s0 and $s1
  move $s0 $a0
  move $s1 $a1
  # Set default return value
  li $v0 0

  handle_cli_args_loop:
    beq $s0 $0 handle_cli_args_exit

    # Debugging info on stderr
    handle_cli_args_loop_debug:
      # Print the prefix "arg: "
      la $a0 string_arg
      jal print_string_stderr
      # Print current arg on stderr
      lw $a0 ($s1)
      jal print_string_stderr
      jal print_space_stderr
      jal print_newline_stderr

    # Process the current argument

    handle_cli_args_loop_current_arg_handling:
      # Compare the argument with authorized values
      # Set $v0 and exit if an authorized value is detected
     
      lw $a0 0($s1)
      jal strlen
      move $t4 $v0
      
      
      #la $a0 string_integer
      #jal strlen
      #move $t5 $v0  
      #length of string "integer" is 7
      li $t5 7
      
      #la $a0 string_float
      #jal strlen
      #move $t6 $v0
      #length of string "float" is 6
      li $t6 5
      
      #if length of input value != length of string "integer"
      bne $t4 $t5 verify_float
      
        lw $a0 0($s1)
        la $a1 string_integer
        move $a2 $t4
        jal simple_strncmp
        beq $v0 0 verify_float
        li $v0 0
        j handle_cli_args_exit
      #else
        verify_float: 
          li $v0 0 #set value to int like default statement
          bne $t4 $t6 entered_value_is_undefined
          
            lw $a0 0($s1)
            la $a1 string_float
            move $a2 $t4 ##########################
            jal simple_strncmp
            beq $v0 0 entered_value_is_undefined
            # $v0 = 1 - so we do not need to change it
          j handle_cli_args_exit
     
    #entered_value_is_undefined:
    entered_value_is_undefined:

        
	
    handle_cli_args_loop_end:
      # Move on to the next argument (akin to argc--, argv++)
      add $s0 $s0 -1
      add $s1 $s1 4
      j handle_cli_args_loop
  
  handle_cli_args_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $s0 12($sp)
    lw $s1 16($sp)
    addu $sp $sp 20
    jr $ra

################################################################################
# I/O
################################################################################

#-------------------------------------------------------------------------------
# stdout
#-------------------------------------------------------------------------------

## Print a string on stdout
##
## Inputs:
## $a0: string
##
## Outputs:
## none
print_string:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  li $v0 4
  syscall

  print_string_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a newline on stdout
##
## Inputs:
## none
##
## Outputs:
## none
print_newline:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_newline
  jal print_string

  print_newline_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a space on stdout
##
## Inputs:
## none
##
## Outputs:
## none
print_space:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_space
  jal print_string

  print_space_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print an integer on stdout
##
## Inputs:
## $a0: integer
##
## Outputs:
## none
print_int:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  li $v0 1
  syscall

  print_int_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a float (single precision) on stdout
##
## Inputs:
## $f12: float
##
## Outputs:
## none
print_float:
  subu $sp $sp 8
  sw $ra 0($sp)
  swc1 $f12 4($sp)

  li $v0 2
  syscall

  print_float_exit:
    lw $ra 0($sp)
    lwc1 $f12 4($sp)
    addu $sp $sp 8
    jr $ra

#-------------------------------------------------------------------------------
# stderr
#-------------------------------------------------------------------------------

## Print a string on stderr
##
## Inputs:
## $a0: string
##
## Outputs:
## none
print_string_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  jal strlen
  move $a2 $v0
  move $a1 $a0
  li $a0 2
  # syscall 15 (write to file)
  # a0: file descriptor
  # a1: address of buffer
  # a2: number of characters to write
  li $v0 15
  syscall

  print_string_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a newline on stderr
##
## Inputs:
## none
##
## Outputs:
## none
print_newline_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_newline
  jal print_string_stderr

  print_newline_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a space on stderr
##
## Inputs:
## none
##
## Outputs:
## none
print_space_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_space
  jal print_string_stderr

  print_space_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

print_result_prefix:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_output_prefix
  jal print_string_stderr

  print_result_prefix_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

#-------------------------------------------------------------------------------
# misc.
#-------------------------------------------------------------------------------

## Read an integer
##
## Inputs:
## none
##
## Outputs:
## $v0: read integer
read_int:
  li $v0 5
  syscall
  jr $ra

## Read a float
##
## Inputs:
## none
##
## Outputs:
## $f0: read float
read_float:
  li $v0 6
  syscall
  jr $ra

################################################################################
# Strings
################################################################################

## Ignore spaces in a string
##
## Inputs:
## $a0: null terminated string
##
## Outputs:
## $v0: first non-space character
ignore_spaces:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $t0 space
  lb $t0 0($t0)

  move $v0 $a0
  ignore_spaces_loop:
    lb $t1 0($v0)
    beq $t0 $0 ignore_spaces_exit
    bne $t0 $t1 ignore_spaces_exit
    addu $v0 $v0 1
    j ignore_spaces_loop

  ignore_spaces_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## strlen
##
## Inputs:
## $a0: input null terminated string
##
## Outputs:
## $v0: string length
strlen:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  move $v0 $0

  strlen_loop:
    lb $t1 0($a0)
    beq $t1 $0 strlen_exit
    add $v0 $v0 1
    add $a0 $a0 1
    j strlen_loop

  strlen_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Simplified strncmp
##
## Simplified strncmp outputs a boolean value as opposed to the common behaviour
## (Usually it outpus 0 for perfect match or either a negative or positive
## value if the (sub)strings do not exactly match)
##
## Inputs:
## $a0: string 1
## $a1: string 2
## $a2: n
##
## Outputs:
## $v0: boolean
simple_strncmp:
  subu $sp $sp 16
  sw $ra 0($sp)
  sw $a0 4($sp)
  sw $a1 8($sp)
  sw $a2 12($sp)

  # Initialize result to true
  li $v0 1

  simple_strncmp_loop:
  # Have we compared n characters?
    ble $a2 $0 simple_strncmp_exit
    #Load the characters for comparison
    lb $t0 0($a0)
    lb $t1 0($a1)
    # Characters differ
    bne $t0 $t1 simple_strncmp_false
    # Identical characters
    #beq $a2 1  simple_strncmp_exit_of_string #?
    addi $a0 $a0 1
    addi $a1 $a1 1
    #decrement n
    addi $a2 $a2 -1
    j simple_strncmp_loop


  simple_strncmp_exit_of_string:
    # (Sub)Strings match
    li $v0 1
    j simple_strncmp_exit

  simple_strncmp_false:
    # (Sub)Strings do not match
    li $v0 0
    j simple_strncmp_exit

  simple_strncmp_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    addu $sp $sp 16
    jr $ra

################################################################################
# Integer Operations
################################################################################

## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1 + $a2
operation_integer_addition:
  add $v0 $a0 $a1
  jr $ra

## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1 - $a2
operation_integer_substraction:
op_int_sub_loop:
  beq $a1 0  exit_from_substraction
  addi $a1 $a1 -1
  addi $a0 $a0 -1
  j op_int_sub_loop
 exit_from_substraction:
  move $v0 $a0  	
  jr $ra

## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1 * $a2
operation_integer_multiplication:
  li $v0 0
  blez $a1 op_int_mult_loop_negative
  op_int_mult_loop:
    beq $a1 0  exit_from_multiplication
    add $v0 $v0 $a0
    addi $a1 $a1 -1
    j op_int_mult_loop
  op_int_mult_loop_negative:
    beq $a1 0  exit_from_multiplication
    sub $v0 $v0 $a0
    addi $a1 $a1 1
    j op_int_mult_loop_negative
   
  exit_from_multiplication: 
   jr $ra

## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1/$a2

operation_integer_division:
  #negative numbers case
  #As for negative numbers it would be too long  and easy , i have used div function for that purpose
  blez $a0 negative_number_case
  blez $a1 negative_number_case
  #case of positive integers
  #case a1 = 1
  move $v0 $a0
  beq $a1 1 exit_from_int_div_loop1
  #case of the other positive integers
  li $v0 0 #in role of counter
  move $t4 $a1 #save value of $a1
  
  op_int_div_loop1:

    ble $a0 1 exit_from_int_div_loop1
    move $a1 $t4
    
    op_int_div_loop2:
      beq $a1 $0  exit_from_int_div_loop2
      addi $a0 $a0 -1
      addi $a1 $a1 -1
      j  op_int_div_loop2   
   exit_from_int_div_loop2:
   addi $v0 $v0 1 # increment counter
   j op_int_div_loop1
    
  negative_number_case:
  div $v0 $a0 $a1
  
  exit_from_int_div_loop1:
    jr $ra


## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: minimum of $a1 $a2
operation_integer_minimum:
  move $v0 $a0 #suppose that 1st is min
  ble $a0 $a1 exit_minimum
  move $v0 $a1
  exit_minimum:
  jr $ra

##################################################################
#VERSION THAT WORK ONLY FOR UNSIGNED INT
#operation_integer_minimum:
#  move $t8 $a0
#  move $t9 $a1
# loop_min: 
#  beq $a1 0  exit_min
#  addi $a1 $a1 -1
#  addi $a0 $a0 -1
# j loop_min
#  exit_min:
#  move $v0 $t9
#  bgez $a0 second_stay_min #if they are equal that is not a problem
#    move $v0 $t8
#  second_stay_min:
#  jr $ra
#######################################################################




## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: maximum of $a1  $a2
operation_integer_maximum:
  move $v0 $a0 #suppose that 1st is max
  bge $a0 $a1 exit_maximum
  move $v0 $a1
  exit_maximum:
  jr $ra
 
######################################################################
#VERSION THAT WORK ONLY FOR UNSIGNED INT
#operation_integer_maximum:
  #move $t8 $a0
  #move $t9 $a1
 #loop_max: 
  #beq $a1 0  exit_max
  #addi $a1 $a1 -1
  #addi $a0 $a0 -1
  #j loop_max
  #exit_max:
  #move $v0 $t9
  #blez $a0 second_stay_max #if they are equal that is not a problem
  #  move $v0 $t8
  #second_stay_max:
###############################################################

## Input
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1^$a2
#NOTE THAT POW IS UNSIGNED INT HERE
operation_integer_pow:
   # $t4 - i
   # $t5 - j
   # $t6 - sum
   beqz $a1 pow_zero
   li $t4 1
   li $t5 0
   move $v0 $a0 
   
   
   op_int_pow_loop1:
    beq $t4 $a1 exit_loop1
      li $t5 0
      move $t6 $v0
      li $v0 0
      op_int_pow_loop2:
        beq $t5 $a0 exit_loop2
          add $v0 $v0 $t6
          addi $t5 $t5 1  
          j op_int_pow_loop2     
        exit_loop2:
        addi $t4 $t4 1
    j op_int_pow_loop1
    pow_zero:
    li $v0 1
    exit_loop1:
     jr $ra
   
## Inputs:
## $a0: operand 1
##
## Outputs:
## $v0: absolute value of $a0
operation_integer_abs:
  move $v0 $a0
  bgez $a0 exit
  li $t4 0 #counter
  op_int_abs_loop:
    beq $a0 $0 exit_int_abs_loop
      addi $a0 $a0 1 #double of the same number
      addi $t4 $t4 1
      j op_int_abs_loop
  exit_int_abs_loop:
      move $v0 $t4
  exit:
    jr $ra

## Inputs:
## $a0: operand 1
##
## Outputs:
## print binary form of $a0 
## $v0:  decimal value of $a0 to continue process
print_binary:
  subu $sp $sp 8
  sw $ra 0($sp)
  
  move $t4 $a0
  li $t5 31  #const shift amount
  li $t6 0   #counter and variable shift amount

  print_binary_loop:
  	beq $t6 32 print_binary_exit
  	sllv $a0 $t4 $t6
  	srlv $a0 $a0 $t5
  	jal print_int
  	addi $t6 $t6 1
  	j print_binary_loop
       
      
  print_binary_exit:
    jal print_newline
    #print the same value in integer form , for being able to continue calculation process
    move $v0 $t4
    #restore registers
    lw $ra 0($sp)
    addu $sp $sp 8
  jr $ra

## Inputs:
## $a0: operand 1
##
## Outputs:
## print hexadecimal form of $a0  
## $v0: decimal value of $a0 to continue process
print_hexa:
  subu $sp $sp 8
  sw $ra 0($sp)  
  move $t4 $a0
  li $t5 8 #counter
  la $t6 hexa_result #where we will store the answer
  hexa_loop:
    beqz $t5 hexa_loop_exit
    rol $t4 $t4 4 
    and $t7 $t4 0xf #mask with 1111
    ble $t7 9 hexa_sum
    addi $t7 $t7 55 #if greater than 9 , add 55 to start from 65 in ASCII table
  j hexa_loop_end
  hexa_sum:
    addi $t7 $t7 48 #add 48 to result to start from 48 in ASCII table
    hexa_loop_end:
     sb $t7 0($t6)
     addi $t6 $t6 1 #increment adress
     addi $t5 $t5 -1 #decrement loop counet
  j hexa_loop
 hexa_loop_exit:
  la $a0 hexa_result 
  li $v0 4 
  syscall
  jal print_newline
  move $v0 $t4
  lw $ra 0($sp)
  addu $sp $sp 8
jr $ra
  
################################################################################
# Floating Point Operations
################################################################################

## Float addition
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 + $f13
operation_float_addition:
  add.s $f0 $f12 $f13
  jr $ra

## Float substraction
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 - $f13
operation_float_substraction:
    sub.s $f0 $f12 $f13
    jr $ra

## Float multiplication
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 * $f13
operation_float_multiplication:
  mul.s $f0 $f12 $f13 #to rewrite
  jr $ra

## Float division
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 / $f13
operation_float_division:
  div.s $f0 $f12 $f13 #to rewrite
  jr $ra

## Float minimum
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: min($f12, $f13)
operation_float_minimum:
  mov.s $f0 $f12 #suppose 1st is min
  c.le.s $f12 $f13 
  bc1t exit_minimum_float
  mov.s $f0 $f13
  exit_minimum_float: 
  jr $ra

## Float maximum
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: max($f12, $f13)
operation_float_maximum:
  mov.s $f0 $f12
  c.le.s $f12 $f13 
  bc1f  exit_maximum_float
  mov.s $f0 $f13
  exit_maximum_float:
  jr $ra

#POW IS UNSIGNED INT HERE
operation_float_pow:
  l.s $f0 fp1
  # convert 2nd operand to int
  cvt.w.s $f14 $f13
  mfc1 $t4 $f14
  
  op_pow_float_loop:
    beq $t4 $zero exit_pow_float_loop
      mul.s $f0 $f0 $f12
      addi $t4 $t4 -1
      j op_pow_float_loop
  exit_pow_float_loop:
  jr $ra

operation_float_abs:
  #suppose that $f0 > 0
  mov.s $f0 $f12
  #else
  l.s $f14 fp0
  l.s $f15 fpMoins1
  c.le.s  $f12 $f14
  bc1f exit_abs_float
  mul.s $f0 $f12 $f15
  exit_abs_float:
  jr $ra

## Float print significand
##
## Inputs
## $f12: argument
##
## Outputs
## print significand of $f12 in binary
## $f0:  $f12 decimal value to continue process
print_significand:
  subu $sp $sp 8
  sw $ra 0($sp)
  mov.s $f14 $f12 #save value of $f12 in $f14 
  mfc1 $t4 $f14 #store argument value into integer register 
  li $t5 22  #const shift amoun
  li $t6 0   #counter and variable shift amount
  la $a0 significand_result
  print_significand_loop:
    beq $t6 23 print_significand_exit
    sllv  $t7 $t4 $t6
    srlv $t7 $t7 $t5
    and $t8 $t7 0x1
    addi $t8 $t8 48
    sb $t8 0($a0)
    addi $t6 $t6 1 #increment counter
    addi $a0 $a0 1 #increment adress
    j print_significand_loop      
  print_significand_exit:
    la $a0 significand_result
    li $v0 4 
    syscall
    jal print_newline
    mov.s $f0 $f14 #print the same value in integer form , for being able to continue calculation process
    lw $ra 0($sp) #restore registers
    addu $sp $sp 8
  jr $ra

## Float print exponent
##
## Inputs
## $f12: argument
##
## Outputs
## print exponent of $f12 in binary
## $f0:  $f12 decimal value to continue process
print_exponent:
  subu $sp $sp 8
  sw $ra 0($sp)
  mov.s $f14 $f12 #save value of $f12 in $f14 
  mfc1 $t4 $f14 #store argument value into integer register 
  li $t5 30 #const shift amount
  li $t6  0  #counter and also variable shift amount
  la $a0 exponent_result
  print_exponent_loop:
    beq $t6 8 print_exponent_exit
    sllv  $t7 $t4 $t6
    srlv $t7 $t7 $t5
    and $t8 $t7 0x1
    addi $t8 $t8 48
    sb $t8 0($a0)
    addi $t6 $t6 1 #increment counter
    addi $a0 $a0 1 #increment adress
    j print_exponent_loop      
  print_exponent_exit:
    la $a0 exponent_result
    li $v0 4 
    syscall
    jal print_newline
    mov.s $f0 $f12 #print the same value in integer form , for being able to continue calculation process
    lw $ra 0($sp) #restore registers
    addu $sp $sp 8
jr $ra

# vim:ft=mips
