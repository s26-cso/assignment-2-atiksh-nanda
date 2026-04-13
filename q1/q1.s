.globl make_node
.globl insert
.globl get
.globl getAtMost

.text

# struct Node* make_node(int val)
# a0 = val
# Returns: a0 = pointer to new node

make_node:
    # Prologue 
    # Allocate 16 bytes on the stack (must be multiple of 16 for alignment)
    addi sp, sp, -16
    sd ra, 8(sp)        # Save return address
    sd s0, 0(sp)        # Save s0 (we'll use it to hold 'val')

    # Body 
    mv s0, a0           # Safely tuck 'val' into s0 so malloc doesn't destroy it

    li a0, 24           # Argument for malloc: 12 bytes
    call malloc         # Call malloc. a0 now holds the pointer to the new memory!

    # Now populate the struct at the address in a0
    sw s0, 0(a0)        # node->val = val
    sd zero, 8(a0)      # node->left = NULL (zero register holds 0)
    sd zero, 16(a0)     # node->right = NULL

    # Epilogue 
    ld s0, 0(sp)        # Restore s0
    ld ra, 8(sp)        # Restore return address
    addi sp, sp, 16     # Deallocate stack frame
    
    ret

# struct Node* get(struct Node* root, int val)
# a0 = root pointer
# a1 = val to find
# Returns: a0 = pointer to the node, or NULL (0) if not found

get:
get_loop:
    # 1. Base case: If root is NULL (0), we reached the bottom and didn't find it.
    # a0 already holds 0, which is exactly what we want to return!
    beqz a0, get_end

    # 2. Load root->val into a temporary register (t0)
    # The value is at offset 0 of the struct
    lw t0, 0(a0)

    # 3. Base case: Did we find the value? (root->val == val)
    # If so, a0 already holds the correct node pointer, just return.
    beq t0, a1, get_end

    # 4. If val < root->val, we need to go left.
    blt a1, t0, get_go_left

get_go_right:
    # 5. Otherwise (val > root->val), we go right.
    # Load the right child pointer (offset 8) into a0 and loop
    ld a0, 16(a0)
    j get_loop

get_go_left:
    # 6. Go left logic. 
    # Load the left child pointer (offset 4) into a0 and loop
    ld a0, 8(a0)
    j get_loop

get_end:
    ret

# struct Node* insert(struct Node* root, int val)
# a0 = root pointer
# a1 = val to insert
# Returns: a0 = root pointer (updated if tree was empty)

insert:
    # --- Prologue ---
    addi sp, sp, -32
    sd ra, 24(sp)       # Save return address (crucial because we call make_node)
    sd s0, 16(sp)       # s0 will hold the original 'root'
    sd s1, 8(sp)        # s1 will hold 'val'
    sd s2, 0(sp)        # s2 will hold our moving 'curr' pointer

    # Save arguments into our saved registers
    mv s0, a0           # s0 = root
    mv s1, a1           # s1 = val

    # 1. Base case: Is the tree completely empty?
    bnez s0, insert_traverse
    
    # If tree is empty: create node and return it as the new root
    mv a0, s1           # set argument for make_node
    call make_node      # a0 now holds the new node
    j insert_end        # Jump to epilogue (a0 is already the correct return value)

insert_traverse:
    # 2. Setup for traversal
    mv s2, s0           # curr = root

insert_loop:
    lw t0, 0(s2)        # t0 = curr->val
    
    # 3. If val == curr->val, it's a duplicate. (We'll just ignore and return)
    beq s1, t0, insert_done
    
    # 4. If val < curr->val, we need to go left
    blt s1, t0, insert_go_left

insert_go_right:
    # 5. val > curr->val (Go right)
    ld t1, 16(s2)       # t1 = curr->right
    beqz t1, do_insert_right  # If right child is NULL, we found our spot!
    
    # Otherwise, keep moving right
    mv s2, t1           # curr = curr->right
    j insert_loop

do_insert_right:
    mv a0, s1           # Argument: val
    call make_node      # a0 = new node pointer
    sd a0, 16(s2)       # curr->right = new node
    j insert_done

insert_go_left:
    # 6. val < curr->val (Go left)
    ld t1, 8(s2)        # t1 = curr->left
    beqz t1, do_insert_left   # If left child is NULL, we found our spot!
    
    # Otherwise, keep moving left
    mv s2, t1           # curr = curr->left
    j insert_loop

do_insert_left:
    mv a0, s1           # Argument: val
    call make_node      # a0 = new node pointer
    sd a0, 8(s2)        # curr->left = new node
    # Fall through to insert_done

insert_done:
    # Restore the original root pointer to return it
    mv a0, s0           

insert_end:
    # --- Epilogue ---
    ld s2, 0(sp)
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret

# int getAtMost(int val, struct Node* root)
# a0 = val to compare against
# a1 = root pointer
# Returns: a0 = greatest value <= val, or -1 if none exists

getAtMost:
    # 1. Initialize our 'best' tracking variable to -1
    li t2, -1

getAtMost_loop:
    # 2. Base case: If root is NULL, we are done searching.
    beqz a1, getAtMost_end

    # 3. Load curr->val into t0
    lw t0, 0(a1)

    # 4. If curr->val == val, it's an exact match! 
    # This is the best possible answer.
    beq t0, a0, getAtMost_exact_match

    # 5. If curr->val > val, the current node is too big.
    # We MUST go left to find smaller values.
    bgt t0, a0, getAtMost_go_left

getAtMost_go_right:
    # 6. If we reach here, curr->val < val.
    # This means it's a valid candidate! Save it as our new 'best'.
    mv t2, t0

    # However, there might be a larger valid value down the right subtree.
    # So, go right: root = root->right
    ld a1, 16(a1)
    j getAtMost_loop

getAtMost_go_left:
    # 7. Go left: root = root->left
    ld a1, 8(a1)
    j getAtMost_loop

getAtMost_exact_match:
    # Update 'best' with the exact match
    mv t2, t0

getAtMost_end:
    # Move our 'best' value into a0 so it gets returned
    mv a0, t2
    ret