################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Kevin Le, 1007952805
# Student 2: Chin Chin Jim, 1007935424
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to configure and connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# An array of colours 
MY_COLOURS:
	.word	0xff0000    # red
	.word	0x00ff00    # green
	.word	0x0000ff    # blue
	.word 	0xC0C0C0    # silver
	.word 	0xE6E6FA    # purple
	.word   0xFFA500    # orange
	.word   0x000000    # black
	.word   0xB20000    #red2
	.word   0x660000    #red3
	.word   0x00B200    #green2
	.word   0x006600    #green3
	.word   0x0000B2    #blue2
	.word   0x000066    #blue3
	
##############################################################################
# Mutable Data
##############################################################################
GAME_STATUS:
	.word 0 # pause (1 = paused, 0 = ongoing)
	.word 3 #lives

GAME_BALL:
	.word 35 # x coord
	.word 55 # y coord
	.word 0 # x direction
	.word 0 # y direction
	.word 1 # size
	.word 0 # launch_ball
	
GAME_PADDLE_ONE:
	.word 29 # x
	.word 56 # y
	
GAME_PADDLE_TWO:
	.word 29 # x
	.word 61 # y


##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:	



# checking if all bricks are broken (iterate through whole screen and find colour
reset_screen:
	
	lw $t5, ADDR_DSPL	# loading current address
	li $t1, 4096		# checks top half of the screen(sinces bricks can only be found on top half)
	la $t2, MY_COLOURS + 24    # get address of red
        lw $t0, 0($t2)     # assigning $t4 with address of colour blue
  
	reset_screen_loop:
 	
    	beq $t1, $0, reset_screen_epi  # if i == 0, loop ends and quit game (no colour bricks found)
    	
    	sw $t0, 0($t5)		# current pixel address colour check
    	addi $t5, $t5, 4	# moving to the next pixel address
    	addi $t1, $t1, -1        # $t1 -= 1
    	b reset_screen_loop  # jump back to start of loop

reset_screen_epi:
    
# 1. DRAW BRICKS FIRST before entering game loop (so that it doesn't get repainted into the screen as each brick gets eliminated.
    
    
    # 1. a) RED BRICKS 2 ROWS 
    
    li $a0, 5			# loading in beginning x coordinate for location address
    li $a1, 15			# loading in beginnning y coordinate for location address
    jal get_location_address	# getting starting location address for printing

    addi $a0, $v0, 0            # Put location address return value in $a0
    la $a1, MY_COLOURS          # $a1 = colour_address = red
    li $a2, 55			# $a2 = 55 = width of bricks line
    jal draw_bricks_line        # Draw top red brick line
    
    li $a0, 7			# loading in x coordinate (shifted right to alternate the bricks)
    li $a1, 17			# loading in y coordinate (shifted down to create new row)
    jal get_location_address	# $v0 now has location address of corodinates
    
    addi $a0, $v0, 0		# putting location address from $V0 to $a0 
    li $a2, 50			# $a2 = 50 = width of bricks line
    la $a1, MY_COLOURS		# $a1 = hex code of red (argument for next line)
    jal draw_bricks_line	# drawing bottom red bricks line
    
    
    # 1. b) GREEN BRICKS 2 ROWS 
    li $a0, 5			# $a0 = 5 = x coord 
    li $a1, 19			# $a1 = 19 = y coord
    jal get_location_address	# $v0 = location address of coords
 
    addi $a0, $v0, 0            # Put $v0 in $a0
    la $a1, MY_COLOURS + 4      # $a1 = colour_address = green
    li $a2, 55			# $a2 = width = 55
    jal draw_bricks_line       	# Draw top green brick line
    
    li $a0, 7			# $a0 = 7 = x coord
    li $a1, 21			# $a1 = 21 = y coord
    jal get_location_address	# $v0 = location address of coords

    addi $a0, $v0, 0            # Put locationa address in $a0
    la $a1, MY_COLOURS + 4      # colour_address = green
    li $a2, 50			# set width of green brick line to 50
    jal draw_bricks_line        # Draw green lines
    
    
    # 1. c) BLUE BRICKS 2 ROWS 
    li $a0, 5			# set x coord = 5
    li $a1, 23			# set y coord = 23
    jal get_location_address	# $v0 = location address of coords

    addi $a0, $v0, 0            # Put location address in $a0
    la $a1, MY_COLOURS + 8      # colour_address = blue
    li $a2, 55			# set brick line width
    
    jal draw_bricks_line        # Draw top blue brick line
    li $a0, 7			# set x coord = 7
    li $a1, 25			# set y coord = 25
    jal get_location_address	# $v0 = location address of coords

    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, MY_COLOURS + 8      # colour_address = &MY_COLOURS[0]
    li $a2, 50			# set width of brick line = 50
    jal draw_bricks_line        # Draw bottom blue brick line
   
   
       

# start game after printing bricks
jal game_loop


# EXIT GAME
exit:
	li 		$v0, 10
	syscall


game_loop:

# checking if the game ball goes below the screen (quit game if so) 
check_bounds:
	la $t0, GAME_BALL 	# $t0 = x coord of ball
    	lw $t1, 4($t0)		# $t1 - y coord of ball
    	li $t2, 64		# $t2 = 64
    	
    	slt $t3, $t2, $t1	# if 64 < y coord of ball, set $t3 = 1 
    				# (if ball below bottom screen line, set $t3 = 1)
    	
    	bne $t3, $0, lives_check	# branch to respond_to_Q (quit game) if $t3 == 1 (ball below bottom)
	jal collision_check
	
# checks if any lives are remaining (if so, then decrement remaining lives and reset game, if not then quit)
lives_check:
	la $t0, GAME_STATUS	   # get address of GAME_STATUS which holds information of number of remaining lives
	lw $t1, 4($t0) 		   # $t1:  y coord of game ball
	li $t2, 1		# $t2: bounds used to compare current remaining lives in $t1
	
	beq $t1, $t2, respond_to_Q # if it remaining lives is equal to 1 then quit game through respond_to_Q
	
	add $t1, $t1, -1		# otherwise subtract 1 from remaining lives and reset the game
	
	sw $t1, 4($t0)		# store the subtracted 1 remaining lives back to GAME_STATUS
	
	
	# resetting location and direction of the ball
	la $t0, GAME_BALL 	#get address of GAME_BALL to reset position of ball to reset game
	li $t2, 55		# loading intermediate of original y value
	li $t3, 0		# loading intermediate of original x direction value
	li $t4, 0		# loading intermediate of original y direction value
	li $t5, 0		# loading intermediate of ball_launch
	
	la $t6, GAME_PADDLE_ONE
	lw $t1, 0($t6)	# loading intermediate value of ball_launch
	addi $t1, $t1, 6
	sw $t1, 0($t0)		# storing original x value into GAME_BALL x value
	sw $t2, 4($t0)		# storing original y value into GAME_BALL y value
	sw $t3, 8($t0)		# storing original x value into GAME_BALL x value
	sw $t4, 12($t0)		# storing original y value into GAME_BALL y value
	sw $t5, 20($t0)		# storing original ball_launch value into GAME_BALL
	
	
	jal main		# jump back to main to reset the game 
    	
	# 1a. Check if key has been pressed
	
	
# 2a. Check for collisions
collision_check:
 
 
  	
# check if it is hitting right wall
right_wall:
	la $t2, MY_COLOURS + 24      # $t2 = colour_address = black
	lw $t4, 0($t2)               # $t4 = hex code of black 
	
	# checks value of pixel to the right of the ball (if it is grey, the ball has hit the right wall)
	la $t0, GAME_BALL	     # $t0 = address of x coord of game ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of game ball
	add $a0, $a0, -1		     # adding 1 to the x coord of game ball, into $a0
    	lw $a1, 4($t0)		     # $a1 = value of y coord of game ball
    	jal get_location_address     # getting location address of new ball coords 
    	addi $t9, $v0, 0             # $t9 = location address of ball coords
    	lw $t8, 8($t9)		     # $t8 = value of colour in the new ball coords
    	beq $t8, $t4, left_wall	     # branch to check left_wall if the right side of the ball if black (has not hit right wall)
    	jal bounce_side_wall 	     # if ball did hit right wall, bounce
    	
    	
    	# la $t0, GAME_BALL 	     # $t0 = address of x coord of game ball
    	# lw $a0, 0($t0)		     # $a0 = value of x coord of game ball
    	# li $t1, 28		     # $t1 = 28, for comparison 
    	# lw $a1, 4 ($t0)		     # $a1 = value of y coord of game ball
    	# li $t2, 7		     # $t2 = 7 for corner case comparison
    	# bne $a0, $t1,left_wall	     # if the ball is not in the most right column, check if its hitting left wall
    	# beq $a1, $t2, corner_case # if the ball is in the farthest right column, check if its in the top right corner
    	# jal bounce_side_wall	     # if ball is hitting right wall and not in the corner, side wall bounce 

    	
# check if it is hitting left wall
left_wall:
    	la $t2, MY_COLOURS + 24      # $t2 = colour_address = black
    	lw $t4, 0($t2)		     # $t4 = hex code of black
    	
    	# checks value of pixel to the left of the ball (if it is grey, the ball has hit the left wall)
	la $t0, GAME_BALL            # $t0 = address of x coord of game ball
	lw $a0, 0($t0)		     # $a0 = value of x coord of game ball
	add $a0, $a0, -1	     # subtracting 1 from x coord of game ball, put into $a0
    	lw $a1, 4($t0)		     # $a1 = value of y coord of game ball
    	jal get_location_address     # getting location address of new ball coords
    	addi $t9, $v0, 0             # Putting location address intp $t9
    	lw $t8, 0($t9)		     # $t9 = value of colour in new ball coords
    	beq $t8, $t4, roof_wall      # branch to check roof_wall if the left side (and by order, the right side as well),
    				     # of the ball is black (has not hit left wall)
    	jal bounce_side_wall	     # if ball did hit left wall, bounce
    	# la $t0, GAME_BALL 	     # $t0 = address of x coord of game ball
    	# lw $a0, 0($t0)		     # $a0 = value of x coord of game ball
    	# li $t1, 3		     # $t1 = 3, for comparison 
    	# lw $a1, 4 ($t0)		     # $a1 = value of y coord of game ball
    	# li $t2, 7		     # $t2 = 7 for corner case comparison
    	# bne $a0, $t1, roof_wall	     # if the ball is not in the most left column, check if its hitting top wall
    	# beq $a1, $t2, corner_case # if the ball is in the farthest left column, check if its in the top left corner
    	# jal bounce_side_wall	     # if ball is hitting left wall and not in the corner, side wall bounce 

    	
# check if it is hitting obstacle above
roof_wall:
    	la $t2, MY_COLOURS + 24      # $t2 = colour_address = black
    	lw $t4, 0($t2)		     # $t4 = hex code of black
    	
    	# checks value of pixel above the ball (if its grey, the ball has hit the top wall)
	la $t0, GAME_BALL
	lw $a0, 0($t0) 
    	lw $a1, 4($t0)
    	add $a1, $a1, -1
    	jal get_location_address
    	addi $t9, $v0, 0            # Put return value in $a0
    	lw $t8, 0($t9)
    	beq $t8, $t4, floor_wall    # Check if the key q was pressed
    	jal bounce_horizontal_roof
    	
    	# la $t0, GAME_BALL 	     # $t0 = address of x coord of game ball
    	# lw $a1, 4 ($t0)	     # $a1 = value of y coord of game ball
    	# li $t2, 7		     # $t2 = 7 for corner case comparison
    	# bne $a0, $t1,floor_wall    # if the ball is not in the most top row, check if its hitting floor wall
    	# jal bounce_horizontal	     # if ball is hitting top wall, horizontal bounce


# check if it is hitting the paddle or obstacle below
floor_wall:

    	la $t2, MY_COLOURS + 24      # colour_address of black
    	lw $t4, 0($t2)		     # $t4 = hex code of black
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $a1, $a1, -1	     # moving y coord to one below (if ball moves one down)
    	jal get_location_address     # getting location address of hypothetical ball position
    	addi $t9, $v0, 0             # Put location address in $t9
    	lw $t8, 512($t9)		     # getting colour of location
    	beq $t8, $t4, corner_check    # move onto next step (Check if the key q was pressed) if the ball didn't hit anything on the bottom
    	jal bounce_horizontal_floor	     # if the ball did hit something, bounce horizontally
    	
corner_check:
	la $t2, MY_COLOURS + 24      # $t2 = colour_address = black
	lw $t5, 0($t2)               # $t4 = hex code of black 
	
	# checks value of pixel to the right of the ball (if it is grey, the ball has hit the right wall)
	la $t0, GAME_BALL	     # $t0 = address of x coord of game ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of game ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of game ball
    	add $a0, $a0, -1		     # adding 1 to the x coord of game ball, into $a0
    	add $a1, $a1, -1		     # adding 1 to the x coord of game ball, into $a0
    	jal get_location_address     # getting location address of new ball coords 
    	addi $t9, $v0, 0             # $t9 = location address of ball coords
    	
    	la $t0, GAME_BALL	     # $t0 = address of x coord of game ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of game ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of game ball
    	lw $t6, 8($t0)
    	lw $t7, 12($t0)
    	add $a0, $a0, $t6		   # adding 1 to the x coord of game ball, into $a0
    	add $a1, $a1, $t7		# adding 1 to the x coord of game ball, into $a0
    	jal get_location_address     # getting location address of new ball coords 
    	addi $t8, $v0, 0             # $t9 = location address of ball coords
    	lw $t1,0($t8)
    	bne $t5, $t1, corner_case	     # branch to check left_wall if the right side of the ball if black (has not hit right wall)
    	jal check_press 	     # if ball did hit right wall, bounce    	

corner_case:
	la $t0, GAME_BALL         # getting location address of game_ball
        lw $t1, 8($t0)             # $t1: getting x-direction of game ball
        li $t3, -1             # $t3 = -1
        mul $t2, $t1, $t3         # $t2: opposite x direction of current game ball
        sw $t2, 8($t0)             # changing and updating the x-direction of the game ball

        lw $t1, 12($t0)            # $t1: getting y-direction of game ball
        mul $t2, $t1, $t3        # $t2: opposite y-direction of the game ball
        sw $t2, 12($t0)            # changing and updating y-direction of the game ball
        
        la $t2, MY_COLOURS    # get address of red
        la $t3, MY_COLOURS + 4    # get address of green
        la $t4, MY_COLOURS + 8    # get address of blue
        
        lw $t2, 0($t2)         # assigning $t2 with address of colour red
        lw $t3, 0($t3)       # assigning $t3 with address of colour green
        lw $t4, 0($t4)     # assigning $t4 with address of colour blue
        
        lw $t5, 0($t9)
        
        beq $t5, $t2, repaint_green_top_left # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_top_left # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_top_left # if pixel is green then end loop (game not over)
    	
    	lw $t5, 8($t9)
        
        beq $t5, $t2, repaint_green_top_right # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_top_right # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_top_right # if pixel is green then end loop (game not over)
    	
    	lw $t5, 256($t9)
        
        beq $t5, $t2, repaint_green_bottom_left # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_bottom_left # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_top_left # if pixel is green then end loop (game not over)
    	
    	lw $t5, 264($t9)
        
        beq $t5, $t2, repaint_green_bottom_right # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_bottom_right # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_bottom_right # if pixel is green then end loop (game not over)

        jal check_press            # moving onto next step
        
        
# change direction based on collision into side wall
bounce_side_wall:
        
	la $t0, GAME_BALL	     # getting location address of game_ball
        lw $t1, 8($t0)		     # $t1: getting x-direction of game ball
        li $t3, -1		     # $t3 = -1
        mul $t2, $t1, $t3	     # $t2: opposite x direction of current game ball
        
        sw $t2, 8($t0)		     # changing and updating the x-direction of the game ball
        
        
        la $t2, MY_COLOURS    # get address of red
        la $t3, MY_COLOURS + 4    # get address of green
        la $t4, MY_COLOURS + 8    # get address of blue
        
        lw $t2, 0($t2)         # assigning $t2 with address of colour red
        lw $t3, 0($t3)       # assigning $t3 with address of colour green
        lw $t4, 0($t4)     # assigning $t4 with address of colour blue
        
        lw $t5, 8($t9)
        
        beq $t5, $t2, repaint_green # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black # if pixel is green then end loop (game not over)
    	
    	lw $t5, 0($t9)
        
        beq $t5, $t2, repaint_green_left # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_left # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_left # if pixel is green then end loop (game not over)
    
        la $t6, MY_COLOURS + 24	     # getting address of colour black
        lw $t6, 0($t6)		     # putting hex code of black into $t6
        sw $t6, 0($t9)		     # painting current ball position black
        
  	jal check_press		     # moving onto next step
  
        
            
                                
# change direction based on collision into side wall   
bounce_horizontal_floor:
        
	la $t0, GAME_BALL	    # getting location address of game_ball
        lw $t1, 12($t0)		    # $t1: getting y-direction of game ball
        li $t3, -1		    # $t3 = -1
        mul $t2, $t1, $t3	    # $t2: opposite y-direction of the game ball
        sw $t2, 12($t0)		    # changing and updating y-direction of the game ball
        
        
        la $t2, MY_COLOURS    # get address of red
        la $t3, MY_COLOURS + 4    # get address of green
        la $t4, MY_COLOURS + 8    # get address of blue
        
        lw $t2, 0($t2)         # assigning $t2 with address of colour red
        lw $t3, 0($t3)       # assigning $t3 with address of colour green
        lw $t4, 0($t4)     # assigning $t4 with address of colour blue
        
        lw $t5, 512($t9)
        
        beq $t5, $t2, repaint_green_floor # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_floor # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_floor # if pixel is green then end loop (game not over)
        
        # painting ball black
        la $t6, MY_COLOURS + 24
        lw $t6, 0($t6)
        sw $t6, 0($t9)
        
  	jal check_press		    # moving onto next step                        
# change direction based on collision into side wall   
bounce_horizontal_roof:
        
	la $t0, GAME_BALL	    # getting location address of game_ball
        lw $t1, 12($t0)		    # $t1: getting y-direction of game ball
        li $t3, -1		    # $t3 = -1
        mul $t2, $t1, $t3	    # $t2: opposite y-direction of the game ball
        sw $t2, 12($t0)		    # changing and updating y-direction of the game ball
        
        
        la $t2, MY_COLOURS    # get address of red
        la $t3, MY_COLOURS + 4    # get address of green
        la $t4, MY_COLOURS + 8    # get address of blue
        
        lw $t2, 0($t2)         # assigning $t2 with address of colour red
        lw $t3, 0($t3)       # assigning $t3 with address of colour green
        lw $t4, 0($t4)     # assigning $t4 with address of colour blue
        
        lw $t5, 0($t9)
        
        beq $t5, $t2, repaint_green_roof # if pixel is red then end loop (game not over)
    	beq $t5, $t3, repaint_blue_roof # if pixel is green then end loop (game not over)
    	beq $t5, $t4, repaint_black_roof # if pixel is green then end loop (game not over)
    	
        
        # painting ball black
        la $t6, MY_COLOURS + 24
        lw $t6, 0($t6)
        sw $t6, 0($t9)
        
  	jal check_press		    # moving onto next step
  	
repaint_green:
    	li $t1, 0
    	la $t2, MY_COLOURS
    	lw $t2, 0($t2)
    	

repaint_green_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_green_epi
    	addi $t1, $t1, -1
    	jal repaint_green_loop
    	
	
	
repaint_green_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
##
repaint_green_left:
    	li $t1, -1
    	la $t2, MY_COLOURS
    	lw $t2, 0($t2)
    	

repaint_green_left_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_green_left_epi
    	addi $t1, $t1, -1
    	jal repaint_green_left_loop
    	
	
	
repaint_green_left_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
                            # change direction based on collision into side wall   

  	
repaint_green_floor:
    	li $t1, 0
    	la $t2, MY_COLOURS
    	lw $t2, 0($t2)
    	

repaint_green_floor_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_green_floor_epi
    	addi $t1, $t1, -1
    	jal repaint_green_floor_loop
    	
	
	
repaint_green_floor_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press                            
                                    

  	
repaint_green_roof:
    	li $t1, 0
    	la $t2, MY_COLOURS
    	lw $t2, 0($t2)
    	

repaint_green_roof_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_green_roof_epi
    	addi $t1, $t1, -1
    	jal repaint_green_roof_loop
    	
	
	
repaint_green_roof_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
	
	
###
repaint_green_top_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_green_top_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_green_bottom_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_green_bottom_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 4
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
    	
    	

	
repaint_blue:
    	li $t1, 0
    	la $t2, MY_COLOURS + 4
    	lw $t2, 0($t2)      
    	

repaint_blue_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_blue_epi
    	addi $t1, $t1, -1
    	jal repaint_blue_loop
    	
	
	
repaint_blue_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
	
#######

##
repaint_blue_left:
    	li $t1, -1
    	la $t2, MY_COLOURS + 4
    	lw $t2, 0($t2)
    	

repaint_blue_left_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_blue_left_epi
    	addi $t1, $t1, -1
    	jal repaint_blue_left_loop
    	
	
	
repaint_blue_left_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press

repaint_blue_floor:
    	li $t1, 0
    	la $t2, MY_COLOURS + 4
    	lw $t2, 0($t2)      
    	

repaint_blue_floor_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 1
    	addi $a1, $a1, 1
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_blue_floor_epi
    	addi $t1, $t1, -1
    	jal repaint_blue_floor_loop
    	
	
	
repaint_blue_floor_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
########
repaint_blue_roof:
    	li $t1, 0
    	la $t2, MY_COLOURS + 4
    	lw $t2, 0($t2)      
    	

repaint_blue_roof_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, -1
    	addi $a1, $a1, -1
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_blue_roof_epi
    	addi $t1, $t1, -1
    	jal repaint_blue_roof_loop
    	
	
	
repaint_blue_roof_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
	
	
repaint_blue_top_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_blue_top_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_blue_bottom_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_blue_bottom_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 8
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
#######   

repaint_black:
    	li $t1, 0
    	la $t2, MY_COLOURS + 8
    	lw $t2, 0($t2)      
    	

repaint_black_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_black_epi
    	addi $t1, $t1, -1
    	jal repaint_blue_loop
    	
	
	
repaint_black_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
	
#######

#######   

repaint_black_left:
    	li $t1, -1
    	la $t2, MY_COLOURS + 8
    	lw $t2, 0($t2)      
    	

repaint_black_left_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 0
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_black_left_epi
    	addi $t1, $t1, -1
    	jal repaint_black_left_loop
    	
	
	
repaint_black_left_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
	
#######

repaint_black_floor:
    	li $t1, 0
    	la $t2, MY_COLOURS + 8
    	lw $t2, 0($t2)      
    	

repaint_black_floor_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, 1
    	addi $a1, $a1, 1
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_black_floor_epi
    	addi $t1, $t1, -1
    	jal repaint_black_floor_loop
    	
	
	
repaint_black_floor_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
########
repaint_black_roof:
    	li $t1, 0
    	la $t2, MY_COLOURS + 8
    	lw $t2, 0($t2)      
    	

repaint_black_roof_loop:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	addi $t8, $a1, -1
    	addi $a1, $a1, -1
    	add $a0, $a0, $t1
	jal get_location_address     # getting location address of new ball coords 
    	addi $t6, $v0, 0             # $t9 = location address of ball coords
    	lw $t6, 0($t6)
    	bne $t2, $t6, repaint_black_roof_epi
    	addi $t1, $t1, -1
    	jal repaint_black_roof_loop
    	
	
	
repaint_black_roof_epi:
	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0)
	add $a0, $a0, $t1
	add $a0, $a0, 1
	addi $a1, $t8, 0
	jal get_location_address
	addi $a0, $v0, 0           # put current location address in $a0
	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press

repaint_black_top_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_black_top_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, -1
    	add $a1, $a1, -1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_black_bottom_left:
    	li $t1, -4
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
repaint_black_bottom_right:
    	li $t1, 1
    	la $t0, GAME_BALL	     # $t0 = address of x coord of ball
	lw $a0, 0($t0) 		     # $a0 = value of x coord of ball
    	lw $a1, 4($t0)		     # $a1 = value of y coord of ball
    	add $a0, $a0, $t1
    	addi $t8, $a1, 1
    	add $a1, $a1, 1
	jal get_location_address     # getting location address of new ball coords 
    	addi $a0, $v0, 0             # $t9 = location address of ball coords
    	la $a1, MY_COLOURS + 24
	lw $a1, 0($a1)
	jal draw_individual_brick
	jal check_press
        

        
	# 1a. Check if key has been pressed
check_press:
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
# if the game is paused then it should continue looping around check_press until a key is pressed and not allow any other printing to occur

    la $t0, GAME_STATUS	   # getting location of game_paddle
    lw $t1, 0($t0) 		   # $a0: pause status of game (1 = paused , 0 = continue)
    li $t2, 1
    beq $t1, $t2, check_press     # if $t1 == 1 then keep going back to keypress until user unpause
    
    jal ball_movement
    
   
	
    # 1b. Check which key has been pressed
keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    
# loops back to check_press such that no other keypress other than P or Q can be pressed until it is unpaused 
    beq $a0, 0x70, respond_to_P     # Check if the key a was pressed
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    
    la $t0, GAME_STATUS	   # getting location of game_paddle
    lw $t1, 0($t0) 		   # $a0: pause status of game (1 = paused , 0 = continue)
    li $t2, 1
    beq $t1, $t2, check_press     # if $t1 == 1 then keep going back to check_press until user unpause
	
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed 
    beq $a0, 0x64, respond_to_D     # Check if the key d was pressed
    beq $a0, 0x6A, respond_to_J     # Check if the key j was pressed 
    beq $a0, 0x6C, respond_to_L     # Check if the key l was pressed
    beq $a0, 0x62, respond_to_B	    # Check if the jey b was pressed
    jal ball_movement 		# jump to ball_movement if another key was pressed that was not assigned to the game

     
    
    
    
    
    

      
	
    
	# 2b. Update locations (paddle, ball)

respond_to_A:

	la $t0, GAME_PADDLE_ONE	    # get address of game_paddle_one
    	lw $a0, 0($t0) 		    # $a0: get x coord of game paddle one
    	lw $a1, 4($t0)		    # $a1: get y coord of game paddle one
    	jal get_location_address    # get location address of game paddle one
    	
    	# erasing tail of paddle to shift it
    	addi $a0, $v0, 0            # Put location address in $a0
    	la $a1, MY_COLOURS + 24     # $a1 = location address of black
    	li $a2, 2                   # Square will be 1x3
    	jal draw_rectangle          # Draw a silver 2x7 rectangle
	
	
	
	la $t0, GAME_PADDLE_ONE	    # get address of game_paddle one 
	lw $t1, 0($t0)		    # $t1: x coord of game paddle one
	li $t2, 2		    # t2 = 2
	
	#checking that the paddle one is at its leftmost state
	beq $t1, $t2, ball_movement # if not, then done
	
	
	add $t1, $t1, -3 	    # go to the left 3 pixels (faster)
	sw $t1, 0($t0)		    # shifting position of paddle to the left three pixels
	

	la $t1, GAME_BALL + 20
	lw $t2, 0($t1)
	li $t3, 1
	bne $t3, $t2, unlaunched_respond_to_A
	
	j ball_movement	    # moving onto next step
	
	unlaunched_respond_to_A:
	
	la $t0, GAME_BALL	   # get address of game_ball
	lw $a0, 0($t0) 		   # $a0: x coord of game ball
    	lw $a1, 4($t0)		   # $a1 : y coord of game ball
    	jal get_location_address   # getting current location address

    	addi $a0, $v0, 0           # put current location address in $a0
    	la $a1, MY_COLOURS + 24    # get address of black
    	li $a2, 1                  # Square will be 2x2
    	jal draw_square            # Draw a black 2x2 square (paint over current ball)
    	
    	la $t0, GAME_BALL	   # get address of game ball
	lw $t1, 0($t0) 		   # $t1: x coord of game ball
        lw $t3, 8($t0)		   # $t3: x direct of game ball
    	
        
        addi $t1, $t1, -3	   # moving the x coord of the ball by the direction
        
        la $t0, GAME_BALL	   # getting address of game ball
        
        sw $t1, 0($t0)		   # storing new x coord of game ball
	
	j draw_screen
	
	
respond_to_D:
	la $t0, GAME_PADDLE_ONE	    # get address of game_paddle one 
    	lw $a0, 0($t0) 		    # $a0: get x coord of game paddle one
    	lw $a1, 4($t0)		    # $a1: get y coord of game paddle one
    	jal get_location_address    # get location address of game paddle one
    	
    	# erasing tail to shift it
    	addi $a0, $v0, 0            # Put location address in $a0
    	la $a1, MY_COLOURS + 24     # $a1 = location address of black
    	li $a2, 2                   # Square will be 1x3
    	jal draw_rectangle          # Draw a silver 2x7 rectangle
    	
	la $t0, GAME_PADDLE_ONE	    # get address of game_paddle_one
	lw $t1, 0($t0)		    # $t1: x coord of game_paddle_one
	li $t2, 47		    # t2 = 47
	
	#checking that the paddle is at its rightmost state
	beq $t1, $t2, ball_movement # if not, then done
	add $t1, $t1, 3 	    # go to the left 3 pixels (faster)
	sw $t1, 0($t0)		    # shifting position of paddle to the left three pixels
	
	
	la $t1, GAME_BALL + 20
	lw $t2, 0($t1)
	li $t3, 1
	bne $t3, $t2, unlaunched_respond_to_D
	
	j ball_movement	    # moving onto next step
	
	unlaunched_respond_to_D:
	
	la $t0, GAME_BALL	   # get address of game_ball
	lw $a0, 0($t0) 		   # $a0: x coord of game ball
    	lw $a1, 4($t0)		   # $a1 : y coord of game ball
    	jal get_location_address   # getting current location address

    	addi $a0, $v0, 0           # put current location address in $a0
    	la $a1, MY_COLOURS + 24    # get address of black
    	li $a2, 1                  # Square will be 2x2
    	jal draw_square            # Draw a black 2x2 square (paint over current ball)
    	
    	la $t0, GAME_BALL	   # get address of game ball
	lw $t1, 0($t0) 		   # $t1: x coord of game ball
        lw $t3, 8($t0)		   # $t3: x direct of game ball
    	
        
        addi $t1, $t1, 3	   # moving the x coord of the ball by the direction
        
        la $t0, GAME_BALL	   # getting address of game ball
        
        sw $t1, 0($t0)		   # storing new x coord of game ball
	
	j draw_screen
	
	
respond_to_J:

	la $t0, GAME_PADDLE_TWO    # get address of game_paddle_two 
    	lw $a0, 0($t0) 		    # $a0: get x coord of game paddle two
    	lw $a1, 4($t0)		    # $a1: get y coord of game paddle two
    	jal get_location_address    # get location address of game paddle two
    	
    	# erasing tail to shift it
    	addi $a0, $v0, 0            # Put location address in $a0
    	la $a1, MY_COLOURS + 24     # $a1 = location address of black
    	li $a2, 2                   # Square will be 1x3
    	jal draw_rectangle          # Draw a silver 2x7 rectangle
    	
	la $t0, GAME_PADDLE_TWO	    # get address of game_paddle_two
	lw $t1, 0($t0)		    # $t1: x coord of game_paddle_two
	li $t2, 2		    # t2 = 2
	
	#checking that the paddle is at its rightmost state
	beq $t1, $t2, ball_movement # if not, then done
	add $t1, $t1, -3 	    # go to the left 3 pixels (faster)
	sw $t1, 0($t0)		    # shifting position of paddle to the left three pixels
	
	jal ball_movement	    # moving onto next step
	
respond_to_L:

	la $t0, GAME_PADDLE_TWO    # get address of game_paddle_two 
    	lw $a0, 0($t0) 		    # $a0: get x coord of game paddle two
    	lw $a1, 4($t0)		    # $a1: get y coord of game paddle two
    	jal get_location_address    # get location address of game paddle two
    	
    	# erasing tail to shift it
    	addi $a0, $v0, 0            # Put location address in $a0
    	la $a1, MY_COLOURS + 24     # $a1 = location address of black
    	li $a2, 2                   # Square will be 1x3
    	jal draw_rectangle          # Draw a silver 2x7 rectangle
    	
	la $t0, GAME_PADDLE_TWO	    # get address of game_paddle_two
	lw $t1, 0($t0)		    # $t1: x coord of game_paddle_two
	li $t2, 47		    # t2 = 47
	
	#checking that the paddle is at its rightmost state
	beq $t1, $t2, ball_movement # if not, then done
	add $t1, $t1, 3 	    # go to the left 3 pixels (faster)
	sw $t1, 0($t0)		    # shifting position of paddle to the left three pixels
	
	jal ball_movement	    # moving onto next step
	

respond_to_P:
	la $t0, GAME_STATUS	   # getting location of game_paddle
    	lw $t1, 0($t0) 		   # $a0: pause status of game (1 = paused , 0 = continue
    	li $t2, 0
    	
    	beq $t1, $t2, pause_game     # if $t1 == 0 then go to pause_game branch
    	# otherwise enter the continue_game branch
    	
respond_to_B:
	la $t1, GAME_BALL + 20
	li $t2, 1
	sw $t2, 0($t1)
	
	la $t1, GAME_BALL
	li $t2, 1
	sw $t2, 8($t1)
	li $t2, -1
	sw $t2, 12($t1)
	
	
	
    	
continue_game:
	la $t0, GAME_STATUS	   # getting location of game_paddle
	li $t1, 0 
	sw $t1, 0($t0) #setting pause status of the game to 0 (which means continue to the game / unpause)
	jal ball_movement
pause_game:
	la $t0, GAME_STATUS	   # getting location of game_paddle
	li $t1, 1 		# loading in itermediate value 1 to $t1 as a comparator (checking if status pause is already 1)
	sw $t1, 0($t0) 		 #setting pause status of the game to 1 (which means pause the game)
	jal game_loop
	
# Quit command
respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
		
# Ball Movement
ball_movement:
	la $t0, GAME_BALL	   # get address of game_ball
	lw $a0, 0($t0) 		   # $a0: x coord of game ball
    	lw $a1, 4($t0)		   # $a1 : y coord of game ball
    	jal get_location_address   # getting current location address

    	addi $a0, $v0, 0           # put current location address in $a0
    	la $a1, MY_COLOURS + 24    # get address of black
    	li $a2, 1                  # Square will be 2x2
    	jal draw_square            # Draw a black 2x2 square (paint over current ball)
    	
    	la $t0, GAME_BALL	   # get address of game ball
	lw $t1, 0($t0) 		   # $t1: x coord of game ball
        lw $t2, 4($t0)		   # $t2: y coord of game ball
        lw $t3, 8($t0)		   # $t3: x direct of game ball
        lw $t4, 12($t0)		   # $t4: y coord of game ball
    	
        
        add $t1, $t1, $t3	   # moving the x coord of the ball by the direction
        add $t2, $t2, $t4 	   # moving the y coord of the ball by the direction
        
        la $t0, GAME_BALL	   # getting address of game ball
        
        sw $t1, 0($t0)		   # storing new x coord of game ball
        sw $t2, 4($t0)		   # storing new y coord of game ball
        
        
        
 
	# 3. Draw the screen
draw_screen:

    # 2 a. DRAW PADDLE (FIRST PLAYER TOP CONTROLS (A LEFT - D RIGHT))
    la $t0, GAME_PADDLE_ONE		   # getting location of game_paddle
    lw $a0, 0($t0) 		   # $a0: x coord of game paddle
    lw $a1, 4($t0)		   # $a1 : y coord of game paddle
    jal get_location_address	   # getting location address of game paddle
    addi $a0, $v0, 0               # Putting location address in $a0
    la $a1, MY_COLOURS + 16        # colour_address = purple
    li $a2, 2                      # Square will be 1x3
    jal draw_rectangle             # Draw a silver 2x7 rectangle
    
    # 2 a. DRAW PADDLE (SECOND PLAYER TOP CONTROLS (J LEFT - L RIGHT))
    la $t0, GAME_PADDLE_TWO		   # getting location of game_paddle
    lw $a0, 0($t0) 		   # $a0: x coord of game paddle
    lw $a1, 4($t0)		   # $a1 : y coord of game paddle
    jal get_location_address	   # getting location address of game paddle
    addi $a0, $v0, 0               # Putting location address in $a0
    la $a1, MY_COLOURS + 16        # colour_address = purple
    li $a2, 2                      # Square will be 1x3
    jal draw_rectangle             # Draw a silver 2x7 rectangle
    
    
    # 3. DRAW WALLS
    
    # 3. a) TOP CEILING SILVER WALL
li $a0, 0			   # setting x coord of top wall
li $a1, 0			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 1			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 2			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 3			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 4			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 5			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

li $a0, 0			   # setting x coord of top wall
li $a1, 6			   # setting y coord of top wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting width of line to 64
jal draw_line                  # Draw silver line

    # 3. b) SIDE 2 SILVER WALLS

# drawing left wall    
li $a0, 0			   # setting x coord of left wall
li $a1, 0			   # setting y coord of left wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting height of line to 64
 jal draw_line_vert             # Draw silver line
 
li $a0, 1			   # setting x coord of left wall
li $a1, 0			   # setting y coord of left wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting height of line to 64
 jal draw_line_vert             # Draw silver line

li $a0, 2			   # setting x coord of left wall
li $a1, 0			   # setting y coord of left wall
jal get_location_address
addi $a0, $v0, 0               # getting location address of coords
la $a1, MY_COLOURS + 12        # colour_address = silver
li $a2, 64			   # setting height of line to 64
 jal draw_line_vert             # Draw silver line

# drawing right wall
li $a0, 63
    li $a1, 0
    jal get_location_address
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, MY_COLOURS + 12          # colour_address = &MY_COLOURS[3]
    li $a2, 64
    jal draw_line_vert               # Draw silver line
     li $a0, 62
    li $a1, 0
    jal get_location_address
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, MY_COLOURS + 12          # colour_address = &MY_COLOURS[3]
    li $a2, 64
    jal draw_line_vert               # Draw silver line
     li $a0, 61
    li $a1, 0
    jal get_location_address
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, MY_COLOURS + 12          # colour_address = &MY_COLOURS[3]
    li $a2, 64
    jal draw_line_vert               # Draw silver line

    
# drawing obstacle bricks

li $a0, 14
li $a1, 9
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 44
li $a1, 9
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 9
li $a1, 11
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 19
li $a1, 11
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick


li $a0, 39
li $a1, 11
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 49
li $a1, 11
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 14
li $a1, 31
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 29
li $a1, 31
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 44
li $a1, 31
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 19
li $a1, 36
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick


li $a0, 39
li $a1, 36
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick

li $a0, 29
li $a1, 41
jal get_location_address
add $a0, $v0, $0

la $t1, MY_COLOURS + 12
lw $a1, 0($t1)
jal draw_individual_brick




draw_ball:
    # 4. BALL
    
    la $t0, GAME_BALL		   # $t0: address of game_ball
    lw $a0, 0($t0) 		   # $a0: x coord of game ball
    lw $a1, 4($t0)		   # $a1: y coord of game ball
    jal get_location_address	   # getting location address of ball
    addi $a0, $v0, 0               # Putting location address in $a0
    la $a1, MY_COLOURS + 20        # colour_address = orange
    li $a2, 1                      # Square will be 1x1
    jal draw_square                # Draw an orange 1x1 square
    
    
# checking if all bricks are broken (iterate through whole screen and find colour
check_game_end:
	
	lw $t5, ADDR_DSPL	# loading current address
	li $t1, 2048		# checks top half of the screen(sinces bricks can only be found on top half)
	la $t2, MY_COLOURS    # get address of red
        la $t3, MY_COLOURS + 4    # get address of green
        la $t4, MY_COLOURS + 8    # get address of blue
        lw $t2, 0($t2)         # assigning $t2 with address of colour red
        lw $t3, 0($t3)       # assigning $t3 with address of colour green
        lw $t4, 0($t4)     # assigning $t4 with address of colour blue
  

	check_game_end_loop:
 	
    	beq $t1, $0, respond_to_Q  # if i == 0, loop ends and quit game (no colour bricks found)
    	
    	lw $t0, 0($t5)		# current pixel address colour check
    	
    	beq $t0, $t2, game_check_end_epi # if pixel is red then end loop (game not over)
    	beq $t0, $t3, game_check_end_epi # if pixel is green then end loop (game not over)
    	beq $t0, $t4, game_check_end_epi # if pixel is blue then end loop (game not over)
    	
    	
    	addi $t5, $t5, 4	# moving to the next pixel address
    	addi $t1, $t1, -1        # $t1 -= 1
    	b check_game_end_loop  # jump back to start of loop
	
	
    
    
game_check_end_epi:

	
# system sleep
	# 4. Sleep
    li $v0, 32
    li $a0, 50  # 50 milliseconds per refresh
    syscall
	

    #5. Go back to 1
    b game_loop			   # move onto next step
    

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 63, inclusive
#       - y is between 0 and 63, inclusive
get_location_address:
    # Each unit is 4 bytes. Each row has 64 units (256 bytes)
	sll 	$a0, $a0, 2		# x = x * 4
	sll 	$a1, $a1, 8             # y = y * 256

    # Calculate return value
	la 	$v0, ADDR_DSPL 		# res = address of ADDR_DSPL
    	lw      $v0, 0($v0)             # res = address of (0, 0)
	add 	$v0, $v0, $a0		# res = address of (x, 0)
	add 	$v0, $v0, $a1           # res = address of (x, y)

    jr $ra


# draw_rectangle(start, colour_address, size) -> void
#   Draw a square that is 4 x size units wide and size units high on the display using the
#   colour at colour_address and starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a size x (4 x size) rectangle
draw_rectangle:
	# PROLOGUE
    addi $sp, $sp, -20			# moving stack pointer to make space for 5 values
    sw $s3, 16($sp)			
    sw $s2, 12($sp)
    sw $s1, 8($sp)
    sw $s0, 4($sp)
    sw $ra, 0($sp)			# storing return address at top of stack

    # BODY
    # Arguments are not preserved across function calls, so we
    # save them before starting the loop
    addi $s0, $a0, 0
    addi $s1, $a1, 0
    addi $s2, $a2, 0
    

    # Iterate size ($a2) times, drawing each line
    li $s3, 0                   # i = 0
    draw_rectangle_loop:
    slt $t0, $s3, $s2           # i < size ?
    beq $t0, $0, draw_rectangle_epi	# if not, then done

        addi $a0, $s0, 0
        addi $a1, $s1, 0
        add $a2, $s2, $s2 
        add $a2, $a2, $s2
        add $a2, $a2, $s2  
        add $a2, $a2, $s2 
        add $a2, $a2, $s2 
        add $a2, $a2, $s2 
        jal draw_line

draw_rectangle_epi:
    # EPILOGUE
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    addi    $sp, $sp, 20	# restoring stack pointers

    jr $ra
    
# determine_brick_row_type (y_coord) -> type_of_row
#   Determines the type of row a brick is in depending on the y-coord (inner type row or outer type row).
#   puts 0 (outer) or 1 (inner) on the stack
determine_brick_row_type:
li $t0, 4			# load 4 into $t0 for comparisons soon
div $a0, $t0			# divide the y coord by 4
mfhi $t0			# take the modulo (remainder) into $t0

li $t1, 3			# load 3 into $t1 for comparison
li $t2, 1			# load 1 into $t2 for comparison

beq $t1, $t0, return_outer_brick_type			# if y coord modulo 4 == 3, it should be outer brick
beq $t1, $t0, return_inner_brick_type			# if y coord modulo 4 == 1, it should be inner brick

return_outer_brick_type:
sub $sp, $sp, 4			# moving stack pointer
sw $0, 0($sp)			# storing 0 onto stack pointer for outer
jr $ra				# returning

return_inner_brick_type:
sub $sp, $sp, 4			# moving stack pointer
sw $t2, 0($sp)			# storing 1 onto stack pointer for inner
jr $ra				# returning

# outer_brick_calculator (x_coord) -> brick_start_x_coord
# Determines the starting x coordinate of a brick if it hits anywhere on a brick, or 0 if it is not a brick
#
outer_brick_calculator:
li $t0, 5
div $a0, $t0
mfhi $t0

li $t1, 0
beq $t1, $t0, outer_brick_1

li $t1, 1
beq $t1, $t0, outer_brick_2

li $t1, 2
beq $t1, $t0, outer_brick_3

li $t1, 3
beq $t1, $t0, outer_brick_4

li $t1, 4
beq $t1, $t0, no_outer_brick

outer_brick_1:
add $t2, $a0, $0
j return_outer_brick_address

outer_brick_2:
addi $t2, $a0, -1
j return_outer_brick_address

outer_brick_3:
addi $t2, $a0, -2
j return_outer_brick_address

outer_brick_4:
addi $t2, $a0, -3
j return_outer_brick_address

no_outer_brick:
sub $sp, $sp, 4
sw $0, 0($sp)
jr $ra

return_outer_brick_address:
sub $sp, $sp, 4
sw $t2, 0($sp)
jr $ra


# inner_brick_calculator (x_coord) -> brick_start_x_coord
# Determines the starting x coordinate of a brick if it hits anywhere on a brick, or 0 if it is not a brick
#
inner_brick_calculator:
li $t0, 5
div $a0, $t0
mfhi $t0

li $t1, 2
beq $t1, $t0, inner_brick_1

li $t1, 3
beq $t1, $t0, inner_brick_2

li $t1, 4
beq $t1, $t0, inner_brick_3

li $t1, 0
beq $t1, $t0, inner_brick_4

li $t1, 1
beq $t1, $t0, no_inner_brick

inner_brick_1:
add $t2, $a0, $0
j return_inner_brick_address

inner_brick_2:
addi $t2, $a0, -1
j return_inner_brick_address

inner_brick_3:
addi $t2, $a0, -2
j return_inner_brick_address

inner_brick_4:
addi $t2, $a0, -3
j return_inner_brick_address

no_inner_brick:
sub $sp, $sp, 4
sw $0, 0($sp)
jr $ra

return_inner_brick_address:
sub $sp, $sp, 4
sw $t2, 0($sp)
jr $ra

    
# draw_individual_brick (start_address, colour) -> void
#   Draws a brick at the start_address, with the colour indicated by colour.
#
draw_individual_brick:
    
    sw $a1, 0($a0)		# putting colour into next four pixels
    sw $a1, 4($a0)
    sw $a1, 8($a0)
    sw $a1, 12($a0)
    
    jr $ra			# returning to called line
    
    
    
# draw_bricks_line (start, colour_address, width) -> void
#   Draw a row of bricks, with 4-pixel lines between bricks separating them. 
#   Draws the row with width units horizontally across the display, using the colour
#   at colour_address and starting from the start address + 8 pixels.
#
#   Preconditions:
#       - The start address can accomodate a line of width units
draw_bricks_line:
    # Retrieve colour
    lw $t0, 0($a1)		# colour = colour_address
    
    # Print $a2 times (iterate ($a2 +1)/5), drawing 4-pixel bricks with 1-pixel lines between them
    li $t1, 0			# loop counter
draw_bricks_line_loop:
    slt $t2, $t1, $a2		# if i < width, set $t2 = 1, continue loop
    beq $t2, $0, draw_bricks_line_epi  # if i == width, loop ends
    	
    	sw $t0, 0($a0)
    	sw $t0, 4($a0)
    	sw $t0, 8($a0)
    	sw $t0, 12($a0)
    	addi $a0, $a0, 20
    	
    	addi $t1, $t1, 5
    b draw_bricks_line_loop
draw_bricks_line_epi:
    jr $ra


# draw_line(start, colour_address, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_line_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    b draw_line_loop

draw_line_epi:
    jr $ra
    
# colour_brick(start)_address, colour_address) -> void
#   Recolour the brick at the start_address with the colour at the colour_address.
#
colour_brick:
lw $t0, 0($a1)		# $t0: desired colour

la $t1, MY_COLOURS + 24	# get colour black address into $t1
lw $t2, 0($t1)		# $t2: colour black

colour_brick_loop:
addi $a0, $a0, -4	# dmoving location address to left
lw $t4, 0($a0)		
bne $t4, $t2, colour_brick_loop

addi $a0, $a0, 4
sw $t0, 0($a0)
addi $a0, $a0, 4
sw $t0, 0($a0)
addi $a0, $a0, 4
sw $t0, 0($a0)
addi $a0, $a0, 4
sw $t0, 0($a0)

jr $ra

    
    
# draw_line_vert(start, colour_address, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line_vert:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_line_vert_loop:
    slt $t2, $t1, $a2           # i < height ?
    beq $t2, $0, draw_line_vert_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 256        # Go to next unit down

    addi $t1, $t1, 1            # i = i + 1
    b draw_line_vert_loop

draw_line_vert_epi:
    jr $ra
    
    
# draw_square(start, colour_address, size) -> void
#   Draw a square that is size units wide and high on the display using the
#   colour at colour_address and starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a size x size square
draw_square:
	# PROLOGUE
	# initializing top 5 spaces in stack to 0
	addi $sp, $sp, -20
    	sw $s3, 16($sp)
    	sw $s2, 12($sp)
    	sw $s1, 8($sp)
    	sw $s0, 4($sp)
	sw $ra, 0($sp)

    # BODY
    # Arguments are not preserved across function calls, so we
    # save them before starting the loop
    
    addi $s0, $a0, 0	# setting s0 to start argument
    addi $s1, $a1, 0	# setting s1 to colour_address argument
    addi $s2, $a2, 0	# setting s3 to size argument

    # Iterate size ($a2) times, drawing each line
    li $s3, 0                   # i = 0
    draw_square_loop:
    slt $t0, $s3, $s2           # i < size ?
    beq $t0, $0, draw_square_epi# if not, then done

        # call draw_line
        addi $a0, $s0, 0
        addi $a1, $s1, 0
        addi $a2, $s2, 0
        jal draw_line

        addi $s0, $s0, 256      # Go to next row

    addi $s3, $s3, 1            # i = i + 1
    b draw_square_loop

draw_square_epi:
    # EPILOGUE
	lw		$ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
	addi	$sp, $sp, 20

    jr $ra
