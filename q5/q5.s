.section .data
filename: .asciz "input.txt"
yes_msg:  .asciz "Yes\n"
no_msg:   .asciz "No\n"

.section .bss
# We allocate exactly 1 byte of space for reading characters. O(1) space complexity
char_buf: .space 1  

.section .text
.global main

main:
    # PROLOGUE 
    # Save the return address (ra) and callee-saved registers (s0, s1, s2) 
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    sd s1, 8(sp)
    sd s2, 0(sp)

    li a0, -100         # a0 = AT_FDCWD (tells OS to look in current directory)
    la a1, filename     # a1 = pointer to the string "input.txt"
    li a2, 0            # a2 = flags (0 means O_RDONLY, read-only)
    li a7, 56           # a7 = syscall number for openat
    ecall

    mv s0, a0

    # We use the 'lseek' syscall (62 in RISC-V Linux)
    # a0 = file descriptor
    # a1 = offset (how many bytes to move)
    # a2 = whence (where to start moving from: 2 means SEEK_END)
    
    mv a0, s0           # Bring back our file descriptor into a0
    li a1, 0            # Offset is 0
    li a2, 2            # 2 = SEEK_END (end of the file)
    li a7, 62           # a7 = syscall number for lseek
    ecall
    
    # After this ecall, a0 contains the total size of the file in bytes.
    # Now we set up our two indices (pointers):
    # s1 will be our left index
    # s2 will be our right index
    
    li s1, 0            # left index starts at 0
    addi s2, a0, -1     # right index starts at (file_size - 1)

    # (Edge case note: If the file size is 0 or less, s2 will become negative.
    # We will handle the crossing of these pointers in our loop).

loop_start:
    # If left >= right, the string is a palindrome.
    bge s1, s2, is_palindrome

    # Read the left character
    
    # 1. lseek to left (s1)
    mv a0, s0           # a0 = file descriptor
    mv a1, s1           # a1 = offset (our left index)
    li a2, 0            # a2 = 0 means SEEK_SET (absolute position from start)
    li a7, 62           # a7 = syscall lseek
    ecall

    # 2. read 1 byte
    # In RISC-V Linux, 'read' is syscall 63
    mv a0, s0           # a0 = file descriptor
    la a1, char_buf     # a1 = address of our 1-byte buffer
    li a2, 1            # a2 = number of bytes to read
    li a7, 63           # a7 = syscall read
    ecall

    # 3. load the byte from memory into a temporary register (t1)
    la t0, char_buf
    lb t1, 0(t0)        # t1 now holds the left character


    # Read the right character
    
    # 1. lseek to right (s2)
    mv a0, s0           # a0 = file descriptor
    mv a1, s2           # a1 = offset (our right index)
    li a2, 0            # a2 = 0 (SEEK_SET)
    li a7, 62           # a7 = syscall lseek
    ecall

    # 2. read 1 byte 
    mv a0, s0           # a0 = file descriptor
    la a1, char_buf     # a1 = address of our 1-byte buffer
    li a2, 1            # a2 = number of bytes to read
    li a7, 63           # a7 = syscall read
    ecall

    # 3. load the byte from memory into a temporary register (t2)
    la t0, char_buf
    lb t2, 0(t0)        # t2 now holds the right character


    # Compare the two characters
    
    # If t1 != t2, it is not a palindrome. Break out of the loop.
    bne t1, t2, not_palindrome

    # Update pointers and repeat
    
    addi s1, s1, 1      # increment left pointer (left++)
    addi s2, s2, -1     # decrement right pointer (right--)
    
    j loop_start        # jump back to the start of the loop

is_palindrome:
    # Print "Yes\n"
    li a0, 1            # a0 = file descriptor 1 (standard output)
    la a1, yes_msg      # a1 = address of the "Yes\n" string
    li a2, 4            # a2 = length of the string (4 bytes)
    li a7, 64           # a7 = syscall number for 'write'
    ecall
    j exit_program      # jump to the exit routine

not_palindrome:
    # Print "No\n"
    li a0, 1            # a0 = file descriptor 1 (standard output)
    la a1, no_msg       # a1 = address of the "No\n" string
    li a2, 3            # a2 = length of the string (3 bytes)
    li a7, 64           # a7 = syscall number for 'write'
    ecall
    # Falls right through into exit_program

exit_program:
    # Close the file 
    mv a0, s0           # a0 = our input.txt file descriptor
    li a7, 57           # a7 = syscall number for 'close'
    ecall

    # EPILOGUE 
    # Exit the program cleanly by returning to C runtime
    # (Replaces original ecall 93 exit)
    li a0, 0            # a0 = exit code 0 (success)
    
    ld s2, 0(sp)
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret