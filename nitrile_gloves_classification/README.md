# Nitrile Glove Defect Detection - Member 3

## Folder Structure

```
nitrile_gloves_classification/
├── member3_nitrile_defect_analysis.m   # Main detection pipeline
├── NitrileDefectDetectionGUI.m          # GUI application
└── NitrileConfig.m                      # Configuration parameters

logs/
└── gloves_dataset/
    └── nitrile gloves/
        ├── Normal/
        ├── InsideOut/
        ├── ImproperRoll/
        └── NotWorn/
```

## Usage

### Option 1: GUI (Recommended)
```matlab
NitrileDefectDetectionGUI
```
Click "Upload Image" → Select image → Click "Classify Defects"

### Option 2: Batch Processing
```matlab
member3_nitrile_defect_analysis
```
Processes all images in dataset and saves results to logs/

## Detection Methods

### Not Worn
- Checks number of boundaries (worn glove has multiple boundaries)
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
- `processed/` - Preprocessed images
- `logs/` - Detection results and CSV statistics
- Visualizations with bounding boxes

## Tuning Tips

**To increase sensitivity:**
- Lower NOT_WORN_MIN_BOUNDARIES
- Increase IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Decrease INSIDE_OUT_PERIMETER_RATIO_THRESHOLD

**To reduce false positives:**
- Increase NOT_WORN_MIN_BOUNDARIES
- Decrease IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Increase INSIDE_OUT_PERIMETER_RATIO_THRESHOLD
