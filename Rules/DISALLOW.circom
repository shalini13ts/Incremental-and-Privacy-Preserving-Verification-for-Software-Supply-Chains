pragma circom 2.1.6;

template DisallowRule(maxRows, cols) {
    signal input artifacts[maxRows][cols];
    signal input numRows;
    signal input usedRows[maxRows];
    signal output found;
    
    component isActive[maxRows];
    for (var i = 0; i < maxRows; i++) {
        isActive[i] = LessThan(32);
        isActive[i].in[0] <== i;
        isActive[i].in[1] <== numRows;
    }
    
    // Find unconsumed rows
    signal unconsumedRows[maxRows];
    for (var i = 0; i < maxRows; i++) {
        unconsumedRows[i] <== (1 - usedRows[i]) * isActive[i].out;
    }
    
    // Check if any unconsumed rows exist
    component hasUnconsumed = OrReduce(maxRows);
    for (var i = 0; i < maxRows; i++) {
        hasUnconsumed.in[i] <== unconsumedRows[i];
    }
    
    // Final output: 1 if no unconsumed rows, 0 otherwise
    component notHasUnconsumed = NOT();
    notHasUnconsumed.in <== hasUnconsumed.out;
    found <== notHasUnconsumed.out;
}
