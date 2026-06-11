# Light-Sheet Z-Stack Processing Tool

Interactive MATLAB workflow for processing 16-bit TIFF image series acquired by light-sheet microscopy.

## Features

- Load and visualize TIFF Z-stacks.
- Select a representative reference slice.
- Interactive brightness normalization.
- Preview-based parameter optimization.
- Optional histogram matching.
- Optional adaptive histogram equalization (CLAHE / adapthisteq).
- Save brightness-adjusted stacks separately.
- Automatic metadata generation for reproducibility.
- Save processed images as a new TIFF series.

## Workflow

1. Select a folder containing TIFF images.
2. Visualize the raw Z-stack.
3. Select a reference slice.
4. Adjust brightness using lower and upper intensity limits.
5. Preview the result and refine parameters if necessary.
6. Apply brightness normalization to the entire stack.
7. Optionally save the brightness-adjusted stack.
8. Optionally apply:
   - Histogram Matching
   - Adaptive Histogram Equalization (CLAHE)
9. Visualize the final processed stack.
10. Save the processed images.

## Output

### Brightness-adjusted stack

```
sample_folder_brightAdj/
├── image001_brightAdj.tif
├── image002_brightAdj.tif
├── ...
└── brightness_parameters.txt
```

### Final processed stack

```
sample_folder_processed/
├── image001_processed.tif
├── image002_processed.tif
└── ...
```

## Metadata

A text file containing processing parameters is automatically generated:

```text
brightness_parameters.txt
```

This file records:

- Input folder
- Reference slice
- Reference image
- Brightness limits
- Processing date
- Processing method

## Requirements

- MATLAB R2026a (or compatible version)
- Image Processing Toolbox

## Intended Use

This tool is designed for visualization-oriented preprocessing of light-sheet fluorescence microscopy datasets stored as individual TIFF slices.

Typical applications include:

- Dataset inspection
- Figure preparation
- Brightness normalization
- Contrast enhancement
- Exploratory image analysis

## Notes

Histogram matching and CLAHE modify image intensity distributions and are primarily intended for visualization. For quantitative fluorescence measurements, use the original data whenever possible.
