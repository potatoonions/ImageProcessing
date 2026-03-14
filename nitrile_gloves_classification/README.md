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

### Option 1: GUI (Interactive + Batch)
```bash
matlab -r "cd nitrile_gloves_classification; NitrileDefectDetectionGUI"
```
**GUI Features:**
- **Upload Image**: Test single image with adjustable parameters
- **Classify**: Run detection with current settings
- **Run Batch**: Process entire dataset (or subset) from GUI
- **Verify Result**: Manually check accuracy for single image
- **Preprocessing View**: See grayscale, HSV, mask, isolated glove
- **Settings Panel**: Adjust all detection thresholds

### Option 2: Batch Only
```bash
# Full dataset
matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis; exit;"

# Subset (e.g., 10 images per class)
matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis(10); exit;"
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

## Accuracy Evaluation

**Metrics calculated:**
- **True Positives (TP)**: Correctly detected defects
- **False Positives (FP)**: Incorrectly detected defects
- **True Negatives (TN)**: Correctly detected normal
- **False Negatives (FN)**: Missed defects
- **Accuracy**: (TP + TN) / Total
- **Precision**: TP / (TP + FP)
- **Recall**: TP / (TP + FN)
- **F1-Score**: 2 × (Precision × Recall) / (Precision + Recall)

**Target accuracy: 90%** (adjust thresholds if not achievable)

## Configuration

Edit parameters in NitrileDefectDetectionGUI.m or member3_nitrile_defect_analysis.m:

| Parameter | Default | Range | GUI Location | Script Location |
|-----------|---------|-------|---------------|----------------|
| NOT_WORN_MIN_BOUNDARIES | 2 | 1-5 | Settings → Not Worn Settings | line 22 |
| IMPROPER_ROLL_CONVEXITY_THRESHOLD | 0.82 | 0.5-1.0 | Settings → Improper Roll Settings | line 23 |
| INSIDE_OUT_PERIMETER_RATIO_THRESHOLD | 3.5 | 2.0-5.0 | Settings → Inside Out Settings | line 24 |
| MIN_BLOB_AREA | 500 | 100-2000 | Settings → Preprocessing Settings | line 18 |
| CLOSE_RADIUS | 5 | 1-10 | Settings → Preprocessing Settings | line 19 |

## Output

### Batch Processing
- `processed/` - Preprocessed images (resized, grayscale, masks, isolated)
- `logs/dataset_stats.csv` - Dataset information
- `logs/notworn_detection_stats.csv` - Not worn detection results
- `logs/improperroll_detection_stats.csv` - Improper roll detection results
- `logs/insideout_detection_stats.csv` - Inside out detection results
- `logs/accuracy_summary.csv` - **Overall accuracy metrics**

### GUI
- Left panel: Detection results with bounding boxes
- Right panel: Preprocessing visualization (4 sub-panels)
- Settings panel: All adjustable parameters
- Accuracy display: Real-time accuracy tracking

## Tuning Tips

**To increase sensitivity (detect more defects):**
- Lower NOT_WORN_MIN_BOUNDARIES
- Decrease IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Decrease INSIDE_OUT_PERIMETER_RATIO_THRESHOLD
- Lower MIN_BLOB_AREA

**To reduce false positives (detect fewer defects):**
- Increase NOT_WORN_MIN_BOUNDARIES
- Increase IMPROPER_ROLL_CONVEXITY_THRESHOLD
- Increase INSIDE_OUT_PERIMETER_RATIO_THRESHOLD
- Increase MIN_BLOB_AREA

## Important Notes

✅ **Image Processing Toolbox Required**
   - All toolbox functions used directly (bwboundaries, regionprops, etc.)
   - No fallback values - errors halt execution
   - Figures set to 'Visible', 'off' to prevent windows
   - Code aligns with course material (Chapters 7-8-10-11-12_13)

⚠️ **Batch Mode**: 
   - `set(0, 'DefaultFigureVisible', 'off')` prevents figure windows
   - May still see brief flashes on some systems
   - All outputs saved to CSV files in logs/
