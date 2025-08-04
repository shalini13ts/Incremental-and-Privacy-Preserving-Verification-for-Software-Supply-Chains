pragma circom 2.1.6;

template ArtifactMatch(expectedCols, expectedRows) {
    signal input expectedArtifact[expectedCols];
    signal input materials[expectedRows][expectedCols];
    signal output found;
    
    component matches[expectedRows];
    signal matchResults[expectedRows];
    
    for (var k = 0; k < expectedRows; k++) {
        matches[k] = IsEqualVec(expectedCols);
        matches[k].a <== expectedArtifact;
        matches[k].b <== materials[k];
        matchResults[k] <== matches[k].out;
    }
    
    component anyMatch = OrReduce(expectedRows);
    for (var k = 0; k < expectedRows; k++) {
        anyMatch.in[k] <== matchResults[k];
    }
    found <== anyMatch.out;
}

template CreateRule(maxRows, expectedCols, productsCols, idx1, idx2, compareRows) {
    signal input expectedArtifact[expectedCols];
    signal input products[maxRows][productsCols];
    signal input numRows;
    signal input materials[compareRows][productsCols];
    signal input usedProductRows[maxRows];
    signal input usedMaterialRows[compareRows];
    
    // Outputs
    signal output result;
    signal output matchedProductRow[productsCols];
    signal output newUsedProductRows[maxRows];
    signal output newUsedMaterialRows[compareRows];
    
    // Internal signals
    signal productFound;
    signal materialFound;
    signal rowSelector[maxRows];
    signal activeProductRows[maxRows];
    
    // Calculate active product rows (not used before and within numRows)
    component isActive[maxRows];
    for (var i = 0; i < maxRows; i++) {
        isActive[i] = LessThan(32);
        isActive[i].in[0] <== i;
        isActive[i].in[1] <== numRows;
        
        activeProductRows[i] <== (1 - usedProductRows[i]) * isActive[i].out;
    }
    
    // Check if expectedArtifact exists in products (only unused rows)
    component productMatcher = RequireRule(maxRows, expectedCols, productsCols, idx1, idx2);
    productMatcher.expectedArtifact <== expectedArtifact;
    productMatcher.artifacts <== products;
    productMatcher.numRows <== numRows;
    productMatcher.usedRows <== usedProductRows; // Connect usedRows input
    
    // Combine with active rows
    signal activeRowResults[maxRows];
    for (var i = 0; i < maxRows; i++) {
        activeRowResults[i] <== productMatcher.rowSelector[i] * activeProductRows[i];
    }
    
    component orReducer = OrReduce(maxRows);
    for (var i = 0; i < maxRows; i++) {
        orReducer.in[i] <== activeRowResults[i];
    }
    productFound <== orReducer.out;
    
    // Get the matched product row
    signal partialSum[maxRows+1][productsCols];
    for (var j = 0; j < productsCols; j++) {
        partialSum[0][j] <== 0;
    }
    for (var i = 0; i < maxRows; i++) {
        rowSelector[i] <== activeRowResults[i];
        for (var j = 0; j < productsCols; j++) {
            partialSum[i+1][j] <== partialSum[i][j] + (rowSelector[i] * products[i][j]);
        }
    }
    for (var j = 0; j < productsCols; j++) {
        matchedProductRow[j] <== partialSum[maxRows][j];
    }
    
    // Update used product rows
    for (var i = 0; i < maxRows; i++) {
        newUsedProductRows[i] <== usedProductRows[i] + rowSelector[i];
    }
    
    // Check if expectedArtifact exists in materials (only unused rows)
    component materialMatcher = ArtifactMatch(productsCols, compareRows);
    materialMatcher.expectedArtifact <== matchedProductRow;
    
    // Create materials array with unused rows only
    signal activeMaterials[compareRows][productsCols];
    for (var k = 0; k < compareRows; k++) {
        for (var j = 0; j < productsCols; j++) {
            activeMaterials[k][j] <== materials[k][j] * (1 - usedMaterialRows[k]);
        }
    }
    materialMatcher.materials <== activeMaterials;
    materialFound <== materialMatcher.found;
    
    // Components for material row tracking (declared outside loop)
    component isMatchedMat[compareRows];
    component isRowUsed[compareRows];
    signal materialRowUsed[compareRows];
    
    for (var k = 0; k < compareRows; k++) {
        // Check if material was matched
        isMatchedMat[k] = IsEqual();
        isMatchedMat[k].in[0] <== materialMatcher.found;
        isMatchedMat[k].in[1] <== 1;
        
        // Check if row should be marked as used
        isRowUsed[k] = AND();
        isRowUsed[k].a <== isMatchedMat[k].out;
        isRowUsed[k].b <== (1 - usedMaterialRows[k]);
        
        materialRowUsed[k] <== isRowUsed[k].out;
        newUsedMaterialRows[k] <== usedMaterialRows[k] + materialRowUsed[k];
    }
    
    // Final output logic: 0 if present in both, 1 otherwise
    result <== 1 - (productFound * materialFound);
}
