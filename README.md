# Light-Sheet Z-Stack Processing Tool

Interactive MATLAB workflows for brightness normalization, histogram matching, and adaptive histogram equalization (CLAHE) of 16-bit TIFF image series acquired by light-sheet fluorescence microscopy.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20645469.svg)](https://doi.org/10.5281/zenodo.20645469)

---

## Overview

This repository contains MATLAB scripts for the visualization-oriented preprocessing of volumetric microscopy datasets stored as individual TIFF slices.

The workflow allows users to:

* Load and visualize TIFF image series as a Z-stack.
* Select a representative reference slice.
* Perform interactive brightness normalization using user-defined intensity limits.
* Apply histogram matching using the selected reference image.
* Apply adaptive histogram equalization (CLAHE / `adapthisteq`) with interactive parameter optimization.
* Save processed image series together with metadata describing the applied processing parameters.
* Optionally accelerate processing using MATLAB's Parallel Computing Toolbox.

The scripts were originally developed for processing light-sheet fluorescence microscopy datasets but can be applied to any image stack stored as sequential TIFF images.

---

## Available Scripts

### `LightSheet_ZStack_Processing.m`

Standard implementation of the workflow.

Recommended for:

* Small to medium image stacks
* Systems without Parallel Computing Toolbox
* Maximum compatibility

### `LightSheet_ZStack_Processing_Parallel.m`

Parallelized implementation of the workflow.

Recommended for:

* Large volumetric datasets
* High-resolution image stacks
* Computationally intensive CLAHE processing
* Multi-core workstations

The script automatically initializes a parallel worker pool when available and distributes computationally intensive image-processing operations across multiple CPU cores.

---

## Feature Comparison

| Feature                              | Standard     | Parallel |
| ------------------------------------ | ------------ | -------- |
| TIFF Z-stack loading                 | ✓            | ✓        |
| Interactive brightness normalization | ✓            | ✓        |
| Brightness preview                   | ✓            | ✓        |
| Histogram matching                   | ✓            | ✓        |
| CLAHE (`adapthisteq`)                | ✓            | ✓        |
| Metadata export                      | ✓            | ✓        |
| Save brightness-adjusted stack       | ✓            | ✓        |
| Parallel processing                  | ✗            | ✓        |
| Parallel Computing Toolbox           | Not required | Optional |

---

## Workflow

### 1. Select image folder

Choose a folder containing a TIFF image series representing a Z-stack.

### 2. Visualize the raw stack

The complete image series is loaded and displayed using MATLAB's `sliceViewer`.

### 3. Select a reference slice

Choose a representative image that will be used for brightness normalization and histogram-based processing.

### 4. Interactive brightness adjustment

Define lower and upper intensity limits.

The script displays:

* Original reference image
* Brightness-adjusted preview

Parameters can be refined until satisfactory.

### 5. Apply brightness normalization

The selected brightness limits are applied consistently to every slice in the stack.

### 6. Review and optionally save

The brightness-adjusted stack can be reviewed and optionally saved.

A metadata file containing processing parameters is automatically generated.

### 7. Optional histogram processing

Choose one of:

#### Histogram Matching

Matches the intensity distribution of each slice to the selected reference image.

#### Adaptive Histogram Equalization (CLAHE)

Uses MATLAB's `adapthisteq()` function with user-defined:

* `NumTiles`
* `ClipLimit`

An interactive preview is provided before processing the entire stack.

### 8. Save final processed stack

The processed image series is saved to a dedicated output folder.

---

## Output Structure

### Brightness-adjusted stack

```text
sample_folder_brightAdj/
├── image001_brightAdj.tif
├── image002_brightAdj.tif
├── ...
└── brightness_parameters.txt
```

### Final processed stack

```text
sample_folder_processed/
├── image001_processed.tif
├── image002_processed.tif
├── ...
```

---

## Metadata

When brightness-adjusted images are saved, a text file is generated automatically:

```text
brightness_parameters.txt
```

The file records:

* Input folder
* Output folder
* Reference slice
* Reference image
* Lower intensity limit
* Upper intensity limit
* Processing date
* Processing description

This enables reproducibility and documentation of image-processing parameters.

---

## Requirements

### Standard Version

* MATLAB R2026a (or compatible version)
* Image Processing Toolbox

### Parallel Version

* MATLAB R2026a (or compatible version)
* Image Processing Toolbox
* Parallel Computing Toolbox (optional)

If the Parallel Computing Toolbox is unavailable, use the standard implementation.

---

## Intended Use

These scripts are intended for visualization-oriented preprocessing of microscopy image stacks.

Typical applications include:

* Dataset inspection
* Brightness normalization
* Contrast enhancement
* Figure preparation
* Exploratory image analysis

### Important Note

Histogram matching and CLAHE modify image intensity distributions and are primarily intended for visualization and presentation purposes.

For quantitative fluorescence measurements, image analysis should generally be performed using the original unprocessed data.

---

## Repository

GitHub:

https://github.com/JuanEdo-LSFM/LightSheet-ZStack-Processing

Zenodo DOI:

https://doi.org/10.5281/zenodo.20645469

---

## Citation

If you use this software in your research, please cite:

Rodriguez-Gatica JE.

*Light-Sheet Z-Stack Processing Tool* (Version 1.0).

Zenodo.

https://doi.org/10.5281/zenodo.20645469

---

## Author

Juan Eduardo Rodriguez-Gatica

Functional Neuroconnectomics Workgroup

Institute of Experimental Epileptology and Cognition Research (IEECR)

University Hospital Bonn

Bonn, Germany

Contact: [je.rodriguez-gatica@.uni-bonn.de](mailto:je.rodriguez-gatica@uni-bonn.de)

---

## License

This project is released under the MIT License.

See the LICENSE file for details.
