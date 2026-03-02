# Test Instructions for Nitrile Glove Defect Detection

## Changes Made

### 1. Updated AGENTS.md
Added subset processing command:
- `member3_nitrile_defect_analysis_subset(5)` - Process only 5 images per class

### 2. Subset Processing Support
Modified `member3_nitrile_defect_analysis.m` to:
- Accept optional `subsetSize` parameter
- Limit processing to specified number of images per defect type
- Figures already have 'Visible', 'off' (no popup windows)

### 3. Fixed Glove Type
Changed `"nitrile gloves"` → `"Nitrile gloves"` to match dataset structure

## Current Dataset Structure

Your dataset has:
```
logs/gloves_dataset/Nitrile gloves/
├── Hole/           (not used by member3)
├── Normal/         (663 images - available)
└── Stain/          (not used by member3)
```

**Note:** Member3 needs these folders (currently missing):
- InsideOut/
- ImproperRoll/
- NotWorn/

## Testing Instructions

### Test with Normal Images (Available)
In MATLAB, run:
```matlab
% Test with 2 images to verify it works
member3_nitrile_defect_analysis_subset(2)
```

Expected output:
- Should create `processed/` directory structure
- Should process 2 Normal images
- Should skip missing folders (InsideOut, ImproperRoll, NotWorn)
- Should save results to `logs/`

### Full Run (After Gathering Complete Dataset)
```matlab
% Process all images
member3_nitrile_defect_analysis

% Or process specific number per class
member3_nitrile_defect_analysis_subset(10)
```

### Test GUI
```matlab
NitrileDefectDetectionGUI
```

## Expected Output

### Directory Structure Created:
```
processed/
├── resized/Nitrile gloves/Normal/
├── gray/Nitrile gloves/Normal/
├── filtered_gaussian/Nitrile gloves/Normal/
├── filtered_median/Nitrile gloves/Normal/
├── masks/Nitrile gloves/Normal/
└── isolated/Nitrile gloves/Normal/

logs/
├── notworn_detection/Nitrile gloves/Normal/
├── improperroll_detection/Nitrile gloves/Normal/
├── insideout_detection/Nitrile gloves/Normal/
└── dataset_stats.csv
```

## Troubleshooting

### Issue: "Folder not found" warnings
- **Cause:** Missing defect type folders
- **Solution:** Gather dataset for InsideOut, ImproperRoll, NotWorn

### Issue: No detections found
- **Normal for now:** Normal images should not trigger defect detection
- **Expected behavior:** Statistics CSVs will be created but may be empty for defect detection

### Issue: Popup windows appear
- **Not an issue:** Code uses 'Visible', 'off' for all figures
- Figures should only appear for GUI, not batch processing

## Next Steps

1. ✅ Code is ready for testing
2. ⏳ Gather dataset for 3 defect types (InsideOut, ImproperRoll, NotWorn)
3. ⏳ Run test with subset (2-3 images per type)
4. ⏳ Adjust thresholds in NitrileConfig.m if needed
5. ⏳ Run full batch processing on complete dataset
