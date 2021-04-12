#####################################################################
#
# CSCB58 Winter2021Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Chang Liu, 1005719796, liuch145
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8 (update this as needed)
# -Unit height in pixels: 8 (update this as needed)
# -Display width in pixels: 256 (update this as needed)
# -Display height in pixels: 512 (update this as needed)
# -Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave beenreached in this submission?
# (See the assignment handout for descriptions of the milestones)# -Milestone 1/2/3/4 (choose the one the applies)
#  I reach the milestone4. This program can run the basic movement and spawn enemy. 
#    Besides that, it has hp, proper end message, and some features from milestone4.
#
# Which approved features have been implementedfor milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Scoring system: add one for normal enemy and 10 for an elite
# 2. Different levels: after suviving after an elite, colors of enemy ship will change
# 3. enemy ships: there's an elite enemy, which clears all other enemy ships and move super fast. One hit will end the game.
# 4. increase in difficulty: the rate of spawning enemy continously increase
# 5. smooth graphics: In my 4-pixel enemies and user ship, I only make change to 3 of them. I think it's a try of "smooth graphics"
#... (add more if necessary)
#
# Link to video demonstration for final submission:
# -(insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
#Are you OKwith us sharing the video with people outside course staff?
# -yes / no/ yes, and please share this project githublink as well!
#
# Any additional information that the TA needs to know:
# -(write here, if any)
# the screen cleaning after the elite(big yellow enemy) is something I designed. It stands for a start of a new phase of game. 
#
#####################################################

.eqv BASE_ADDRESS 0x10008000

.text	
	# clear the screen between initialization
Scls:	li $t0, BASE_ADDRESS
	addi $t1, $t0, 8192
	li $s1, 0x000000
cls:	sw $s1, 0($t0)
	addi $t0, $t0, 4
	blt $t0, $t1, cls

	# initialize the ship
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8
	addi $t6, $t0, 0 # $t6 is the location of hp segment start point
	li $t5, 100 # $t5 stores hp, initialize to 100
	li $s1, 0xff0000 # draw the hp segment line
	addi $t1, $t0, 120
I_hp:	sw $s1, 0($t0)
	addi $t0, $t0, 4
	blt $t0, $t1, I_hp
	
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6464 # create the ship in row 50, the center point is in the mid of row
	addi $a3, $t0, 0 # store the ship spawn location in $a3
	jal createShip
	
	li $t1, 0
	sw $t1, 0($sp)
	
	li $t7, 0 # assume no elite
	li $a2, 0 # $a2 stands for the phase of game
	
	li $t4, 0 # $t4 stores the score
	
	li $t9, 0xffff0000
	
do: 	
	
	li $v0, 32
	li $a0, 25   # Wait a short time
	syscall
	
	lw $t8, 0($t9)
	sw $zero, 0($t9)
	beq $t8, 1, keypress_happened	
	
 enemy:	
 	bne $t7, 0, eliteEnemy
 	jal createEnemy
	jal EnemyMove
	
while:	j do
	
end:	li $v0, 10
	syscall
	
	
	
	
createShip:
	li $s3, 0xff00ff # set the color to purple
	sw $s3, 128($a3)
	li $s3, 0x00ff00 # set the color to green
	sw $s3, 0($a3) # color the ship
	sw $s3, 124($a3)
	sw $s3, 132($a3)
	jr $ra
	
createEnemy:
	# the spawn area is the first five rows, the enemy will be same shape as the user's one 
	# the enemy is in reversed direction, so spawn location is the bottom mid, not the upper pixel

	# limit there's at most 30 enemies at the same time
	lw $s7, 0($sp)
	bgt $s7, 30, CE_End
	blt $s7, 4, spawnEnemy
		
	# control the spawn rate
	# spawn faster when time pass
	li $v0, 42
	li $a0, 0
	li $a1, 100
	sll $s6, $a2, 3 # spawn faster when the game move forward, $s6 as temp variable
	sub $a1, $a1, $s6
	sra $a1, $a1, 2
	bgt $a1, 10, spawnEnemyCall
	li $a1, 10 
spawnEnemyCall:
	syscall
	bne $a0, 1, CE_End
	
spawnEnemy:
	# randomly create location of pixel, max 30
	li $v0, 42
	li $a0, 0
	li $a1, 30
	syscall
	# convert the number to relative location, which will be enemy's spawn location
	addi $s0, $a0, 33
	sll $s0, $s0, 2
	addi $s0, $s0, BASE_ADDRESS
	
	# the enemy will have the gray color initially and change through time
	addi $s3, $a2, 0
	add $s3, $s3, 0x708069
	
	# check if there's already an enemy in this location
	lw $s4, 0($s0) # first, enemy exist in 4 pxiels of new enemy
	beq $s3, $s4, CE_End
	lw $s4, -4($s0)
	beq $s3, $s4, CE_End
	lw $s4, 4($s0)
	beq $s3, $s4, CE_End
	lw $s4, 128($s0)
	beq $s3, $s4, CE_End
	lw $s4, 124($s0) # then, consider the surrounding of the enemy
	beq $s3, $s4, CE_End
	lw $s4, 132($s0) 
	beq $s3, $s4, CE_End
	lw $s4, -8($s0) 
	beq $s3, $s4, CE_End
	lw $s4, 8($s0) 
	beq $s3, $s4, CE_End
	lw $s4, 256($s0) 
	beq $s3, $s4, CE_End
	
	# randomly choose the type of enemy to spwan
	li $v0, 42
	li $a0, 0
	li $a1, 25
	syscall
	bne $a0, 1, drawEnemy
	li $t7, 1 # mark $t7 as 1 to show we have elite
	j Elite
	
 drawEnemy:
 	sw $s3, 0($s0)
	sw $s3, -4($s0)
	sw $s3, 4($s0)
	sw $s3, 128($s0)
 
  	# store the spawn information in stack 
	sw $s0, 0($sp)
	
	#counter increase one
	addi $s7, $s7, 1
	addi $sp, $sp, -4
	sw $s7, 0($sp)
	
  CE_End:
  	jr $ra

EnemyMove:
	# we need to read all infomation of location in stack and make all enemies move down 1 pixel
	
	li $t1, 0 # use $t1 to mark if the collision happens, 1 means happen
	lw $s7, 0($sp) # get the number of enemies from stack
	sll $s7, $s7, 2
	add $sp, $sp, $s7 # set the stack starting point to the first enemy
	srl $s7, $s7, 2
	
	li $s6, 0
 
  L_E:	lw $s0, 0($sp) # load the information
 	beq $s0, $s7, FinishE# doens't finish if $s0 is still a piece of information for enemy
 
	# check if the enemy reaches the bottom boundary, which is the last one row by default
	addi $s4, $s0, -BASE_ADDRESS # $s4 is the relative location of $s0 based on BASE_ADDRESS
	addi $s4, $s4, 128 # $s4 now is the lowest pixel of enermy
	bgt $s4, 8192, Erase # 8192 is the relative location of the last row's first element	
	
  	# update enemy location on graph 
	addi $s6, $s6, 1 # counter increase 1
	# erase enemy on graph, doesn't do erase if the pixel if the collision part, keep that in red
	li $s3, 0x000000 # $s3 is used to refill the pixel in black
	addi $s4, $a2, 0
	addi $s4, $s4, 0x708069 # $s4 is the color of ememy, which we want to erase
				# the color of enemy depends on the order of when it's created
  high:	lw $s5, 0($s0)
  	bne $s4, $s5, left
	sw $s3, 0($s0)
  left:	lw $s5, -4($s0)
  	bne $s4, $s5, right
	sw $s3, -4($s0)
  right:lw $s5, 4($s0)
  	bne $s4, $s5, move_down
	sw $s3, 4($s0)
  
  move_down:
	addi $s0, $s0, 128 # move down 

	addi $s3, $s4, 0 # $s3 is now used to fill the new pixels of enemy
	li $s4, 0x000000 # $s4 is the color of background, which allow us to display enemy
  high2:lw $s5, 0($s0)
  	bne $s4, $s5, left2
	sw $s3, 0($s0)
  left2:lw $s5, -4($s0)
  	bne $s4, $s5, right2
	sw $s3, -4($s0)
  right2:lw $s5, 4($s0)
  	bne $s4, $s5, low2
	sw $s3, 4($s0)
  low2:	lw $s5, 128($s0)
  	bne $s4, $s5, collisionCheck # go to next part to check collision
	sw $s3, 128($s0)
	
	# check if collison happens
  collisionCheck:
  	sw $s0, 0($sp) # first store the enemy current location in stack
	# $s4 stands for enemy location information
	# $s5 stands for ship location information
	addi $s4, $s0, 128
	addi $s5, $a3, -4
	beq $s4, $s5, collisionHappen # the lowest pixel of enemy collide with leftest pixel of ship
		# at the same time, the rightest pixel of enemy collide with highest pixel of ship 
	addi $s5, $a3, 4
	beq $s4, $s5, collisionHappen # the lowest pixel of enemy collide with rightest pixel of ship
		# at the same time, the leftest pixel of enemy collide with highest pixel of ship 
	addi $s5, $a3, -128
	beq $s4, $s5, collisionHappen # the lowest pixel of enemy collide with highest pixel of ship
	addi $s5, $a3, 0
	beq $s4, $s5, collisionHappen # the lowest pixel of enemy collide with lowest pixel of ship
		# at the same time, the highest pixel of enemy collide with highest pixel of ship 
	addi $s4, $s0, -4
	addi $s5, $a3, 4
	beq $s4, $s5, collisionHappen # the leftest pixel of enemy collide with rightest pixel of ship
	addi $s4, $s0, 4
	addi $s5, $a3, -4
	beq $s4, $s5, collisionHappen # the rightest pixel of enemy collide with leftest pixel of ship
	addi $s4, $s0, 0
	addi $s5, $a3, -4
	beq $s4, $s5, collisionHappen # the highest pixel of enemy collide with leftest pixel of ship
		# at the same time, the rightest pixel of enemy collide with lowest pixel of ship 
	addi $s4, $s0, 0
	addi $s5, $a3, 0
	beq $s4, $s5, collisionHappen # the highest pixel of enemy collide with lowest pixel of ship
		# at the same time, the rightest pixel of enemy collide with rightest pixel of ship 
		# at the same time, the leftest pixel of enemy collide with leftest pixel of ship 
	addi $s4, $s0, 0
	addi $s5, $a3, 4
	beq $s4, $s5, collisionHappen # the highest pixel of enemy collide with rightest pixel of ship
		# at the same time, the leftest pixel of enemy collide with lowest pixel of ship 
	j ELoop
  collisionHappen: # if collides, mark it
  	li $t1, 1
	
  ELoop:addi $sp, $sp, -4 # move the next enemy	
	j L_E

  Erase:# reach the bottom boundary
  	# erase enemy on graph
	li $s3, 0x000000 # $s3 is used to refill the pixel in black
	sw $s3, 0($s0)
	sw $s3, -4($s0)
	sw $s3, 4($s0)
	sw $s3, 128($s0)
	# erase enemy on stack
	addi $s1, $sp, 0 # copy current index in $s1
	
    doE:
	lw $s2, -4($sp)
	sw $s2, 0($sp)
	addi $sp, $sp, -4
    whileE:
	bne $s2, $s7, doE
	addi $sp, $s1, 0 # set the value of $sp back to right
	addi $t4, $t4, 1 # add 1 to score for erasing one enemy
	j L_E
	
  FinishE:
	beq $t1, 0, FinishE2
  	li $s3, 0xff0000 # set the color to red
	sw $s3, 0($a3) # color the ship
	sw $s3, 124($a3)
	sw $s3, 128($a3)
	sw $s3, 132($a3)
	li $v0, 32
	li $a0, 100   # Wait a short time
	syscall
	# color the ship back
	li $s3, 0xff00ff # set the color to purple
	sw $s3, 128($a3)
	li $s3, 0x00ff00 # set the color to green
	sw $s3, 0($a3) # color the ship
	sw $s3, 124($a3)
	sw $s3, 132($a3)
	
	addi $t5, $t5, -10 # after one collision, hp -10; for each enemy, very likely to have two collison in total
	li $s3, 0x000000 # make change in the hp segment 
	sw $s3, 0($t6)
	sw $s3, 4($t6)
	sw $s3, 8($t6)
	addi $t6, $t6, 12
	bgt $t5, 0, FinishE2
	
  lost:	# draw 'lost' on the screen with score and wait for "p" from keyboard
	# first clean the screen
	li $t0, BASE_ADDRESS 
	addi $t1, $t0, 8192
	li $s1, 0x000000
 cls2:	sw $s1, 0($t0)
	addi $t0, $t0, 4
	blt $t0, $t1, cls2
	
	# print the message "lost"
	li $s3, 0xff0000
	li $t0, BASE_ADDRESS 
	addi $t0, $t0, 1424
	# draw "L"
	sw $s3, 0($t0)
	sw $s3, 128($t0)
	sw $s3, 256($t0)
	sw $s3, 384($t0)
	sw $s3, 512($t0)
	sw $s3, 516($t0)
	sw $s3, 520($t0)
	
	# draw "o"
	sw $s3, 28($t0)
	sw $s3, 152($t0)
	sw $s3, 276($t0)
	sw $s3, 408($t0)
	sw $s3, 540($t0)
	sw $s3, 416($t0)
	sw $s3, 292($t0)
	sw $s3, 160($t0)
	
	# draw "s"
	sw $s3, 60($t0)
	sw $s3, 56($t0)
	sw $s3, 52($t0)
	sw $s3, 180($t0)
	sw $s3, 308($t0)
	sw $s3, 312($t0)
	sw $s3, 316($t0)
	sw $s3, 444($t0)
	sw $s3, 572($t0)
	sw $s3, 568($t0)
	sw $s3, 564($t0)
	
	# draw "T"
	sw $s3, 76($t0)
	sw $s3, 80($t0)
	sw $s3, 84($t0)
	sw $s3, 88($t0)
	sw $s3, 92($t0)
	sw $s3, 212($t0)
	sw $s3, 340($t0)
	sw $s3, 468($t0)
	sw $s3, 596($t0)
	
	# print the message "press p"
	li $t0, BASE_ADDRESS 
	addi $t0, $t0, 2692
	
	# draw "P"
	sw $s3, 0($t0)
	sw $s3, 4($t0)
	sw $s3, 8($t0)
	sw $s3, 128($t0)
	sw $s3, 136($t0)
	sw $s3, 256($t0)
	sw $s3, 260($t0)
	sw $s3, 264($t0)
	sw $s3, 384($t0)
	sw $s3, 512($t0)
	
	# draw "R"
	sw $s3, 16($t0)
	sw $s3, 20($t0)
	sw $s3, 24($t0)
	sw $s3, 144($t0)
	sw $s3, 152($t0)
	sw $s3, 272($t0)
	sw $s3, 276($t0)
	sw $s3, 280($t0)
	sw $s3, 400($t0)
	sw $s3, 528($t0)
	sw $s3, 404($t0)
	sw $s3, 536($t0)
	
	# draw "E"
	sw $s3, 40($t0)
	sw $s3, 36($t0)
	sw $s3, 32($t0)
	sw $s3, 160($t0)
	sw $s3, 288($t0)
	sw $s3, 292($t0)
	sw $s3, 296($t0)
	sw $s3, 416($t0)
	sw $s3, 544($t0)
	sw $s3, 548($t0)
	sw $s3, 552($t0)
	
	# draw "s"
	sw $s3, 56($t0)
	sw $s3, 52($t0)
	sw $s3, 48($t0)
	sw $s3, 176($t0)
	sw $s3, 304($t0)
	sw $s3, 308($t0)
	sw $s3, 312($t0)
	sw $s3, 440($t0)
	sw $s3, 568($t0)
	sw $s3, 564($t0)
	sw $s3, 560($t0)
	
	# draw "s"
	sw $s3, 72($t0)
	sw $s3, 68($t0)
	sw $s3, 64($t0)
	sw $s3, 192($t0)
	sw $s3, 320($t0)
	sw $s3, 324($t0)
	sw $s3, 328($t0)
	sw $s3, 456($t0)
	sw $s3, 584($t0)
	sw $s3, 580($t0)
	sw $s3, 576($t0)
	
	# draw "P"
	sw $s3, 108($t0)
	sw $s3, 112($t0)
	sw $s3, 116($t0)
	sw $s3, 236($t0)
	sw $s3, 244($t0)
	sw $s3, 364($t0)
	sw $s3, 368($t0)
	sw $s3, 372($t0)
	sw $s3, 492($t0)
	sw $s3, 620($t0)
	
	# print the score 
	jal printScore
	
	# wait for user to press 'p'
 doWaitP:
 	li $v0, 32
	li $a0, 50   # Wait a short time
	syscall
	
	lw $t8, 0($t9)
	sw $zero, 0($t9)
	beq $t8, 0, doWaitP
	lw $t2, 4($t9) #read $t9's next memory to get the keyboard input
	beq $t2, 0x70, respond_to_p # check if the input is P
 	j doWaitP

  FinishE2:
  	sw $s6, 0($sp)
  	jr $ra



Elite:
	# first clean the screen
	li $t0, BASE_ADDRESS 
	addi $t0, $t0, 128 # keep the hp segment unchanged
	addi $t1, $t0, 8064
	li $s1, 0x000000
  cls3:	sw $s1, 0($t0)
	addi $t0, $t0, 4
	blt $t0, $t1, cls3
	
	jal createShip # recreate the ship after cls
	
  createElite:
	# the spawn area is the first five rows, the enemy will be same shape as the user's one 
	# the enemy is in reversed direction, so spawn location is the bottom mid, not the upper pixel

	# clear enemy's information in stack
	lw $s7, 0($sp)
	sll $s6, $s7, 2
	sub $sp, $sp, $s6
	# reset the counter
	li $s7, 0
	sw $s7, 0($sp)

	# randomly create location of pixel, max 4
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	# convert the number to relative location, which will be elite's spawn location
	sll $a0, $a0, 5
	addi $s0, $a0, 156
	addi $s0, $s0, BASE_ADDRESS
	
	li $s3, 0xFFFF00 # the elite will have the yellow color
	
 	sw $s3, 0($s0)
	sw $s3, -4($s0)
	sw $s3, -8($s0)
	sw $s3, -12($s0)
	sw $s3, -16($s0)
	sw $s3, -20($s0)
	sw $s3, -24($s0)
	sw $s3, 4($s0)
	sw $s3, 8($s0)
	sw $s3, 12($s0)
	sw $s3, 16($s0)
	sw $s3, 20($s0)
	sw $s3, 24($s0)
	sw $s3, 120($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	sw $s3, 136($s0)
	sw $s3, 256($s0)
	
	# $s6 is the limit for $s0
	addi $s6, $s0, 8064
 	
  eliteMove:
    doElite:
    	li $v0, 32
	li $a0, 50   # Wait a short time
	syscall
	
	# erase the previous location
	li $s3, 0x000000
	sw $s3, 0($s0)
	sw $s3, -4($s0)
	sw $s3, -8($s0)
	sw $s3, -12($s0)
	sw $s3, -16($s0)
	sw $s3, -20($s0)
	sw $s3, -24($s0)
	sw $s3, 4($s0)
	sw $s3, 8($s0)
	sw $s3, 12($s0)
	sw $s3, 16($s0)
	sw $s3, 20($s0)
	sw $s3, 24($s0)
	sw $s3, 120($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	sw $s3, 136($s0)
	sw $s3, 256($s0)
	# move down three rows one time
	addi $s0, $s0, 384
	# check if elite move pass the bottom boundary
	blt $s0, $s6, EliteCase2
	li $t7, 0 # set the mark of elite back to 0 
	addi $t4, $t4, 10 # add 10 to score for suviving an elite enemy
	addi $a2, $a2, 100 # move the next phase of game
	j do
	
	
    EliteCase2:
	# update the location on display
	li $s3, 0xFFFF00
	sw $s3, 0($s0)
	sw $s3, -4($s0)
	sw $s3, -8($s0)
	sw $s3, -12($s0)
	sw $s3, -16($s0)
	sw $s3, -20($s0)
	sw $s3, -24($s0)
	sw $s3, 4($s0)
	sw $s3, 8($s0)
	sw $s3, 12($s0)
	sw $s3, 16($s0)
	sw $s3, 20($s0)
	sw $s3, 24($s0)
	sw $s3, 120($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	sw $s3, 136($s0)
	sw $s3, 256($s0)
	
	# lost if the collision happens
	lw $s3, 0($a3)
	beq $s3, 0xFFFF00, lost
	lw $s3, -4($a3)
	beq $s3, 0xFFFF00, lost
	lw $s3, 4($a3)
	beq $s3, 0xFFFF00, lost
	lw $s3, -128($a3)
	beq $s3, 0xFFFF00, lost
	
	# allow the ship move
	lw $t8, 0($t9)
	sw $zero, 0($t9)
	addi $s7, $s0, 0 # store $s0 before entering keypress_happened
	beq $t8, 1, keypress_happened	
eliteEnemy:
	addi $s0, $s7, 0 # get $s0 back
	
    whileElite: j doElite
    
    
    
    


keypress_happened:	
	lw $t2, 4($t9) #read $t9's next memory to get the keyboard input
	beq $t2, 0x77, respond_to_w# check if the input is W
	beq $t2, 0x61, respond_to_a# check if the input is A
	beq $t2, 0x73, respond_to_s# check if the input is S
	beq $t2, 0x64, respond_to_d# check if the input is D
	beq $t2, 0x70, respond_to_p# check if the input is P
	j enemy
	
respond_to_w:
	addi $s0, $a3, 0 # load spwan location information in $s0
	
	# check if the ship reaches the upper boundary, which is first five rows by default
	addi $s4, $s0, -BASE_ADDRESS # $s4 is the relative location of highest pixel based on BASE_ADDRESS
	addi $s4, $s4, -128
	blt $s4, 640, NoUp # 640 is the relative location of the sixth row's first element
	
	#clear the previous ship
	li $s3, 0x000000 #$s3 is used to refill the pixel in black
	sw $s3, 0($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	
	# move the ship to current position if it doesn't reach the upper boundary
	addi $a3, $a3, -128
	jal createShip	#spawn the ship in the new spawn location
	j enemy # go back for next instruction from the keyboard
		
  NoUp:	# reach the upper boundary
	j enemy # go back for next instruction from the keyboard

		
respond_to_a:
	addi $s0, $a3, 0 # load spwan location information in $s0
	
	# check if the ship reaches the left boundary
	addi $s4, $s0, 124 # $s4 is the leftest pixel of the ship
	addi $s5, $s4, 0 # copy the value of $s4 in $s5
	srl $s4, $s4, 7
	sll $s4, $s4, 7
	beq $s4, $s5, NoLeft
	
	#clear the previous ship
	li $s3, 0x000000 #$s3 is used to refill the pixel in black
	sw $s3, 0($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	
	# move the ship to current position if it doesn't reach the left boundary
	addi $a3, $a3, -4
	jal createShip	#spawn the ship in the new spawn location
	j enemy # go back for next instruction from the keyboard
	
  NoLeft:# reach the left boundary
	j enemy # go back for next instruction from the keyboard
	

respond_to_s:
	addi $s0, $a3, 0 # load spwan location information in $s0
	
	# check if the ship reaches the bottom boundary, which is the last one row by default
	addi $s4, $s0, -BASE_ADDRESS # $s4 is the relative location of $s0 based on BASE_ADDRESS
	addi $s4, $s4, 128 # $s4 now is the lowest pixel of ship
	bgt $s4, 8064, NoDown # 8064 is the upper limit for relative location
	
	#clear the previous ship
	li $s3, 0x000000 #$s3 is used to refill the pixel in black
	sw $s3, 0($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	
	# move the ship to current position if it doesn't reach the bottom boundary
	addi $a3, $a3, 128
	jal createShip	#spawn the ship in the new spawn location
	j enemy # go back for next instruction from the keyboard
		
  NoDown:# reach the bottom boundary
	j enemy # go back for next instruction from the keyboard
	

respond_to_d:
	addi $s0, $a3, 0 # load spwan location information in $s0
	
	# check if the ship reaches the right boundary
	addi $s4, $s0, 132 # $s4 is the rightest pixel of the ship
	addi $s4, $s4, 4 # for convience, we check if the next pixel is on left boundary
	addi $s5, $s4, 0 # copy the value of $s4 in $s5
	srl $s4, $s4, 7
	sll $s4, $s4, 7
	beq $s4, $s5, NoRight
	
	#clear the previous ship
	li $s3, 0x000000 #$s3 is used to refill the pixel in black
	sw $s3, 0($s0)
	sw $s3, 124($s0)
	sw $s3, 128($s0)
	sw $s3, 132($s0)
	
	# move the ship to current position if it doesn't reach the right boundary
	addi $a3, $a3, 4 # the ship now move right
	jal createShip	#spawn the ship in the new spawn location
	j enemy # go back for next instruction from the keyboard
	
  NoRight:# reach the right boundary
	j enemy # go back for next instruction from the keyboard
	
	
respond_to_p:
	# the program should reset immediately after receving p from keyboard
	j Scls # jump to the beginning of the program



printScore:
	# 0-9 assemble for printing the score
	li $t0, BASE_ADDRESS 
	addi $t0, $t0, 4584
	li $s3, 0x00FF00
	li $t5, 10 # $t5 is previously used to store hp value, we don't need that when printing the ending message
  
  PrintScoreLoop:
  	div $t4, $t5
  	mfhi $t4 # get the remainer mod 10, which is the last digit of score
  	beq $t4, 0, Print0
  	beq $t4, 1, Print1
  	beq $t4, 2, Print2
  	beq $t4, 3, Print3
  	beq $t4, 4, Print4
  	beq $t4, 5, Print5
  	beq $t4, 6, Print6
  	beq $t4, 7, Print7
  	beq $t4, 8, Print8
  	beq $t4, 9, Print9
    nextDigit:
  	subi $t0, $t0, 24
  	mflo $t4
  	bne $t4, 0, PrintScoreLoop
	
	jr $ra
		
  Print0:# print number "0"
	sw $s3, 4($t0)
	sw $s3, 8($t0)
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 256($t0)
	sw $s3, 384($t0)
	sw $s3, 512($t0)
	sw $s3, 528($t0)
	sw $s3, 640($t0)
	sw $s3, 656($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	sw $s3, 144($t0)
	sw $s3, 272($t0)
	sw $s3, 400($t0)
	sw $s3, 516($t0)
	sw $s3, 392($t0)
	sw $s3, 268($t0)
	j nextDigit
	
  Print1:# print number "1"
	sw $s3, 8($t0)
	sw $s3, 136($t0)
	sw $s3, 132($t0)
	sw $s3, 264($t0)
	sw $s3, 392($t0)
	sw $s3, 520($t0)
	sw $s3, 648($t0)
	sw $s3, 776($t0)
	sw $s3, 772($t0)
	sw $s3, 780($t0)
	j nextDigit
	
  Print2:# print number "2"
	sw $s3, 4($t0)
	sw $s3, 8($t0)	
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 144($t0)
	sw $s3, 272($t0)
	sw $s3, 396($t0)
	sw $s3, 520($t0)
	sw $s3, 644($t0)
	sw $s3, 768($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	sw $s3, 784($t0)
	j nextDigit
	
  Print3:# print number "3"
	sw $s3, 4($t0)
	sw $s3, 8($t0)	
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 144($t0)
	sw $s3, 272($t0)
	sw $s3, 396($t0)
	sw $s3, 392($t0)
	sw $s3, 528($t0)
	sw $s3, 656($t0)
	sw $s3, 640($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	j nextDigit
	
  Print4:# print number "4"
	sw $s3, 12($t0)
	sw $s3, 136($t0)
	sw $s3, 140($t0)
	sw $s3, 260($t0)
	sw $s3, 268($t0)
	sw $s3, 384($t0)
	sw $s3, 396($t0)
	sw $s3, 512($t0)
	sw $s3, 516($t0)
	sw $s3, 520($t0)
	sw $s3, 524($t0)
	sw $s3, 528($t0)
	sw $s3, 652($t0)
	sw $s3, 780($t0)
	j nextDigit
	
  Print5:# print number "5"
	sw $s3, 0($t0)
	sw $s3, 4($t0)
	sw $s3, 8($t0)
	sw $s3, 12($t0)
	sw $s3, 16($t0)
	sw $s3, 128($t0)
	sw $s3, 256($t0)
	sw $s3, 260($t0)
	sw $s3, 264($t0)
	sw $s3, 268($t0)
	sw $s3, 400($t0)
	sw $s3, 528($t0)
	sw $s3, 656($t0)
	sw $s3, 768($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	j nextDigit
	
  Print6:# print number "6"
	sw $s3, 4($t0)
	sw $s3, 8($t0)	
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 144($t0)
	sw $s3, 256($t0)
	sw $s3, 384($t0)
	sw $s3, 388($t0)
	sw $s3, 396($t0)
	sw $s3, 392($t0)
	sw $s3, 528($t0)
	sw $s3, 656($t0)
	sw $s3, 640($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	sw $s3, 512($t0)
	j nextDigit
	
  Print7:# print number "7"
	sw $s3, 0($t0)
	sw $s3, 4($t0)
	sw $s3, 8($t0)
	sw $s3, 12($t0)
	sw $s3, 16($t0)
	sw $s3, 144($t0)
	sw $s3, 268($t0)
	sw $s3, 392($t0)
	sw $s3, 520($t0)
	sw $s3, 648($t0)
	sw $s3, 776($t0)
	j nextDigit
	
  Print8:# print number "8"
	sw $s3, 4($t0)
	sw $s3, 8($t0)	
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 144($t0)
	sw $s3, 256($t0)
	sw $s3, 272($t0)
	sw $s3, 388($t0)
	sw $s3, 396($t0)
	sw $s3, 392($t0)
	sw $s3, 528($t0)
	sw $s3, 656($t0)
	sw $s3, 640($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	sw $s3, 512($t0)
	j nextDigit
	
  Print9:# print number "9"
	sw $s3, 4($t0)
	sw $s3, 8($t0)	
	sw $s3, 12($t0)
	sw $s3, 128($t0)
	sw $s3, 144($t0)
	sw $s3, 256($t0)
	sw $s3, 272($t0)
	sw $s3, 388($t0)
	sw $s3, 396($t0)
	sw $s3, 392($t0)
	sw $s3, 400($t0)
	sw $s3, 528($t0)
	sw $s3, 656($t0)
	sw $s3, 640($t0)
	sw $s3, 772($t0)
	sw $s3, 776($t0)
	sw $s3, 780($t0)
	j nextDigit