// gemini generated C code for testing the binary search tree implementation in assembly
#include <stdio.h>
#include <stdlib.h>

// 1. Define the struct exactly as given
struct Node {
    int val;
    struct Node* left;
    struct Node* right;
};

// 2. Declare the external assembly functions
extern struct Node* make_node(int val);
extern struct Node* insert(struct Node* root, int val);
extern struct Node* get(struct Node* root, int val);
extern int getAtMost(int val, struct Node* root);

int main() {
    struct Node* root = NULL;

    printf("--- Testing Insert & Make Node ---\n");
    root = insert(root, 10);
    root = insert(root, 5);
    root = insert(root, 15);
    root = insert(root, 12);
    root = insert(root, 7);
    printf("Nodes inserted.\n\n");

    printf("--- Testing Get ---\n");
    struct Node* found = get(root, 12);
    if (found) {
        printf("Found node with value: %d\n", found->val);
    } else {
        printf("Node 12 not found.\n");
    }

    found = get(root, 99);
    if (found) {
        printf("Found node with value: %d\n", found->val);
    } else {
        printf("Node 99 not found.\n");
    }
    printf("\n");

    printf("--- Testing GetAtMost ---\n");
    // Should be 7 (closest value <= 8)
    printf("getAtMost(8): %d\n", getAtMost(8, root));  
    // Should be -1 (no values <= 4)
    printf("getAtMost(4): %d\n", getAtMost(4, root));  
    // Should be 15 (exact match)
    printf("getAtMost(15): %d\n", getAtMost(15, root)); 

    return 0;
}