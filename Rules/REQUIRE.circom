pragma circom 2.1.6;

template RequireRule(maxRows, targetCols, matrixCols, idx1, idx2) {
    signal input expectedArtifact[targetCols];
    signal input artifacts[maxRows][matrixCols];
    signal input numRows;
    signal input usedRows[maxRows];
    signal output found;
    signal output rowSelector[maxRows];
    
    component isActive[maxRows];
    component elem1[maxRows];
    component elem2[maxRows];
    component isZero;
    signal skipIndex1;
    signal intermediate[maxRows];
    signal rowResults[maxRows];
    signal temp1[maxRows];
    signal activeAndUnused[maxRows]; // New signal to break down the constraint

    isZero = IsZero();
    isZero.in <== expectedArtifact[idx1];
    skipIndex1 <== isZero.out;
    
    for (var i = 0; i < maxRows; i++) {
        isActive[i] = LessThan(32);
        isActive[i].in[0] <== i;
        isActive[i].in[1] <== numRows;
        
        // Break down into quadratic constraints
        activeAndUnused[i] <== isActive[i].out * (1 - usedRows[i]);
        
        elem1[i] = IsEqual();
        elem1[i].in[0] <== expectedArtifact[idx1];
        elem1[i].in[1] <== artifacts[i][idx1];
        
        elem2[i] = IsEqual();
        elem2[i].in[0] <== expectedArtifact[idx2];
        elem2[i].in[1] <== artifacts[i][idx2];
        
        temp1[i] <== (1 - skipIndex1) * elem1[i].out;
        intermediate[i] <== activeAndUnused[i] * (skipIndex1 + temp1[i]);
        rowResults[i] <== intermediate[i] * elem2[i].out;
        rowSelector[i] <== rowResults[i];
    }
    
    component orReducer = OrReduce(maxRows);
    for (var i = 0; i < maxRows; i++) {
        orReducer.in[i] <== rowResults[i];
    }
    found <== orReducer.out;
}

