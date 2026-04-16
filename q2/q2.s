.data
fmt_int: .string "%d"
fmt_space: .string " "
fmt_newline: .string "\n"

.text
.globl main

main:
    # save preserved registers before doing anything
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    sd s1, 40(sp)
    sd s2, 32(sp)
    sd s3, 24(sp)
    sd s4, 16(sp)
    sd s5, 8(sp)
    sd s6, 0(sp)

    addi s0, a0, -1      # s0 = n = argc - 1
    blez s0, exit        # If n <= 0 (no elements provided), just exit

    mv s4, a1            # s4 = argv base pointer (save it for later)
    slli t0, s0, 2       # t0 = n * 4 (shift left by 2 is multiplying by 4)

    # Allocate 'arr' array
    mv a0, t0            # Set a0 to number of bytes to allocate
    call malloc          # ecall 9 is sbrk (allocate heap memory)
    mv s1, a0            # s1 = base address of 'arr'

    # Allocate 'result' array
    mv a0, t0            # a0 is still n * 4
    call malloc
    mv s2, a0            # s2 = base address of 'result'

    # Allocate 'stack' array
    mv a0, t0            # a0 is still n * 4
    call malloc
    mv s3, a0            # s3 = base address of 'stack'

    li s5, 0             # s5 = i (loop counter, starts at 0)

parse_loop:
    bge s5, s0, parse_done # If i >= n, we are done parsing

    # Get the pointer to argv[i + 1] (skipping argv[0] which is "./a.out")
    addi t0, s5, 1       # t0 = i + 1
    slli t0, t0, 3       # t0 = (i + 1) * 8 (byte offset for pointer array)
    add t1, s4, t0       # t1 = address of argv[i + 1]
    ld a0, 0(t1)         # Load actual string pointer directly into a0 for atoi

    # Convert string to integer (atoi)
    call atoi            # Use standard library atoi (handles negative numbers)
    mv t3, a0            # Move result to t3 to match your original store logic

    # Store the finished integer into arr[i]
    slli t0, s5, 2       # t0 = i * 4 (byte offset for integers)
    add t1, s1, t0       # t1 = base address of arr + offset
    sw t3, 0(t1)         # arr[i] = calculated integer (t3)

    addi s5, s5, 1       # i++
    j parse_loop         # Go parse the next argument

parse_done:
    addi s5, s0, -1      # s5 = i = n - 1 (Start from the last element)
    li s6, 0             # s6 = stack size (starts at 0, meaning empty)

core_loop:
    bltz s5, print_results # If i < 0, we are done! Move to printing.

    # Get arr[i] 
    slli t1, s5, 2       # t1 = i * 4
    add t2, s1, t1       # t2 = address of arr[i]
    lw t0, 0(t2)         # t0 = arr[i] (We will compare this against stack elements)

while_loop:
    beqz s6, end_while   # while (!stack.empty()) -> if size == 0, break while

    # Get stack.top() 
    addi t3, s6, -1      # t3 = stack_size - 1 (index of the top element)
    slli t3, t3, 2       # Multiply by 4 for byte offset
    add t4, s3, t3       # t4 = address of stack.top()
    lw t5, 0(t4)         # t5 = stack.top() (Remember: This is an INDEX, not the value)

    # Get arr[stack.top()] 
    slli t6, t5, 2       # Multiply index by 4
    add t6, s1, t6       # Address of arr[stack.top()]
    lw t6, 0(t6)         # t6 = arr[stack.top()] (The actual value to compare)

    # Compare arr[stack.top()] <= arr[i] 
    bgt t6, t0, end_while # If arr[stack.top()] > arr[i], break while loop!

    # stack.pop() 
    addi s6, s6, -1      # Just decrement the size to "pop" it
    j while_loop         # Repeat the while loop

end_while:
    # Set result[i] 
    li t3, -1            # Default value is -1
    beqz s6, store_result # If stack is empty, keep -1

    # If stack is NOT empty, result[i] = stack.top()
    addi t4, s6, -1      # Top index
    slli t4, t4, 2
    add t4, s3, t4
    lw t3, 0(t4)         # t3 = stack.top()

store_result:
    slli t4, s5, 2       # t4 = i * 4
    add t4, s2, t4       # t4 = address of result[i]
    sw t3, 0(t4)         # result[i] = t3 (either -1 or the top index)

    # stack.push(i)
    slli t4, s6, 2       # Byte offset for current stack size
    add t4, s3, t4       # Address of stack[stack_size]
    sw s5, 0(t4)         # Store 'i' (s5) onto the stack
    addi s6, s6, 1       # stack_size++

    # Loop control 
    addi s5, s5, -1      # i--
    j core_loop          # Go to the next element

print_results:
    li s5, 0             # Reset loop counter: s5 = i = 0

print_loop:
    bge s5, s0, exit     # If i >= n, we have printed everything. Go to exit.

    # 1. Load result[i] 
    slli t0, s5, 2       # t0 = i * 4 (byte offset)
    add t1, s2, t0       # t1 = base address of result (s2) + offset
    lw a0, 0(t1)         # Load the integer directly into a0 for printing

    # 2. Print the integer 
    mv a1, a0            # Move integer to a1 for printf
    la a0, fmt_int       # Load format string
    call printf          # ecall code 1: print integer

    # Check if this is the last element to avoid printing the trailing space
    addi t6, s0, -1      # t6 = n - 1
    beq s5, t6, skip_space 

    # 3. Print a space 
    la a0, fmt_space     # 32 is the ASCII code for a space character ' '
    call printf          # ecall code 11: print character

skip_space:
    # 4. Move to next element 
    addi s5, s5, 1       # i++
    j print_loop         # Repeat for the next number

exit:
    # Print a final newline character just to keep the terminal clean
    la a0, fmt_newline   # 10 is the ASCII code for newline '\n'
    call printf          # ecall code 11: print character

    # Exit the program
    ld ra, 56(sp)        # GCC ABI: Restore registers
    ld s0, 48(sp)
    ld s1, 40(sp)
    ld s2, 32(sp)
    ld s3, 24(sp)
    ld s4, 16(sp)
    ld s5, 8(sp)
    ld s6, 0(sp)
    addi sp, sp, 64
    
    li a0, 0             # Return 0 (Success)
    ret                  # ecall code 10: exit