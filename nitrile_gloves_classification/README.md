# Nitrile Glove Defect Detection - Member 3

## Folder Structure

```
nitrile_gloves_classification/
├── member3_nitrile_defect_analysis.m   # Main detection pipeline
├── NitrileDefectDetectionGUI.m          # GUI application
└── NitrileConfig.m                      # Configuration parameters

logs/
└── gloves_dataset/
    └── Nitrile gloves/                  # Dataset (uploaded)
        ├── Normal/
        ├── inside out/
        ├── improper roll/
        └── not worn/
```

## Usage

### Option 1: GUI (Interactive)
```bash
matlab -r "cd nitrile_gloves_classification; NitrileDefectDetectionGUI"
```
Click "Upload Image" → Select image → Click "Classify Defects"

### Option 2: Batch Processing

**Full dataset:**
```bash
matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis; exit;"
```

**Subset (e.g., 5 images per class):**
```bash
matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis(5); exit;"
```

## Detection Methods

### Not Worn
- Checks number of boundaries (worn glove has hand + glove = 2+, unworn = 1)
- Threshold: < 2 boundaries = not worn
- Features: boundary count, convexity, perimeter/area ratio

### Improper Roll
- Detects irregular cuff shape using convexity
- Threshold: convexity < 0.82
- Cuff region analysis with morphological operations

### Inside Out
- Measures perimeter/area ratio (inside-out has higher ratio)
- Threshold: perimeter/area > 3.5
- Shape analysis on entire glove

## Configuration

Edit NitrileConfig.m to adjust thresholds:
```matlab
NitrileConfig.printConfig()  % View current settings
```

## Output

Batch processing creates:
- `processed/` - Preprocessed images (resized, grayscale, masks, isolated)
- `logs/` - Detection results and CSV statistics
- Visualizations with bounding boxes and labels

## Tuning Tips

**To increase sensitivity:**
- Lower NOT_WORN_MIN_BOUNDARIES
- Increase IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Decrease INSIDE_OUT_PERIMETER_RATIO_THRESHOLD

**To reduce false positives:**
- Increase NOT_WORN_MIN_BOUNDARIES
- Decrease IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Increase INSIDE_OUT_PERIMETER_RATIO_THRESHOLD

## Important Notes

⚠️ **MATLAB Toolbox**: Code has fallbacks for missing Image Processing Toolbox functions.
   - Advanced functions may not work optimally
   - Basic functionality is preserved
   - Consider installing Image Processing Toolbox for best results

⚠️ **Small Datasets**: Some defect types have few images:
   - inside out: 6 images
   - improper roll: 5 images
   - May need more data for robust training/tuning
