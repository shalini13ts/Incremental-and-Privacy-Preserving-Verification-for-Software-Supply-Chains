pragma circom 2.1.6;
include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";

template OrReduce(n) {
    signal input in[n];
    signal output out;
    
    signal intermediate[n];
    intermediate[0] <== in[0];
    
    for (var i = 1; i < n; i++) {
        intermediate[i] <== intermediate[i-1] + in[i] - (intermediate[i-1] * in[i]);
    }
    
    out <== intermediate[n-1];
}

template IsEqualVec(n) {
    signal input a[n];
    signal input b[n];
    signal output out;
    
    component eqs[n];
    for (var i = 0; i < n; i++) {
        eqs[i] = IsEqual();
        eqs[i].in[0] <== a[i];
        eqs[i].in[1] <== b[i];
    }
    
    component and = AndReduce(n);
    for (var i = 0; i < n; i++) {
        and.in[i] <== eqs[i].out;
    }
    out <== and.out;
}

template AndReduce(n) {
    signal input in[n];
    signal output out;
    signal intermediate[n];
    intermediate[0] <== in[0];
    for (var i = 1; i < n; i++) {
        intermediate[i] <== intermediate[i-1] * in[i];
    }
    out <== intermediate[n-1];
}

template AND() {
    signal input a;
    signal input b;
    signal output out;
    out <== a * b;
}

template Add() {
    signal input in[2];
    signal output out;
    out <== in[0] + in[1];
}

template NOT() {
    signal input in;
    signal output out;
    out <== 1 - in;
}


template MerkleTree(levels) {
    signal input leaves[2**levels];
    signal output root;
    
    // Total hashers needed: (2^levels - 1)
    component hashers[2**levels - 1];
    
    // Initialize all hashers
    for (var i = 0; i < 2**levels - 1; i++) {
        hashers[i] = Poseidon(2);
    }
    
    // Connect leaves (bottom level)
    var leaf_hashers = 2**(levels-1);
    for (var i = 0; i < leaf_hashers; i++) {
        hashers[i].inputs[0] <== leaves[2*i];
        hashers[i].inputs[1] <== leaves[2*i+1];
    }
    
    // Connect internal nodes
    var nodes_processed = 0;
    var nodes_in_level = leaf_hashers / 2;
    
    while (nodes_in_level >= 1) {
        for (var i = 0; i < nodes_in_level; i++) {
            var parent_idx = leaf_hashers + nodes_processed + i;
            var left_child = nodes_processed * 2 + i * 2;
            var right_child = left_child + 1;
            
            hashers[parent_idx].inputs[0] <== hashers[left_child].out;
            hashers[parent_idx].inputs[1] <== hashers[right_child].out;
        }
        nodes_processed += nodes_in_level;
        nodes_in_level = nodes_in_level / 2;
    }
    
    // The root is the last hasher
    root <== hashers[2**levels - 2].out;
}

