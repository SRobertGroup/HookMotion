
# HookMotion

> _Apical hook kinetics analyzer from DLhook data_

**Lead development:**  Adrien Heymans

**Coordination:** Stéphanie Robert, Sara Raggi

---

## 1. About

[**HookMotion**](https://hookmotion.serve.scilifelab.se/) is a user-friendly **Shiny app** that analize angle kinetic data from [**DLhook**](https://github.com/SRobertGroup/DLhook/) software.

Understanding plant growth requires precise phenotyping of early developmental events. One critical stage is the **apical hook**, a structure that forms after germination to protect the shoot meristem during soil emergence. This process unfolds in three phases: **formation**, **maintenance**, and **opening**.

This application helps quantify and visualize these dynamics based on angle measurements extracted from image files.

---

## 2. Installation

### Clone the repository

```bash
git clone https://github.com/SRobertGroup/HookMotion.git
cd HookMotion
```

### R Dependencies

Ensure you're using **R 4.3+**, then install required packages:

```r
install.packages(c("ggplot2", "dplyr", "tidyr", "readr", "svglite"),
                 dependencies = TRUE)
```

### Run via Docker

To run with Docker (recommended):

```bash
docker pull heymansadrien/hookmotion:0.1.5
```

Then launch it:

```bash
docker run -p 3838:3838 heymansadrien/hookmotion:0.1.5
```

App will be available at: [http://localhost:3838](http://localhost:3838)

## 3. Usage

### Step 1: Upload Data

Upload one or more .csv files containing apical hook angle data.

The structure of each CSV should be:

```{csv}
 img_name,1,2,3,...
 Col0_010.tif,-10,-5,4,...
 Col0_015.tif,8,-2,6,...
```

### Step 2: Set Time Points

You have two options:
- Automatic: Check the box to extract time from image filenames (recommended).
- Manual: Uncheck and input a comma-separated list of time points matching your images.

> 📂 File Naming Best Practices
>
> To ensure automatic time detection works properly, name your image files using the pattern:
```{}
GENOTYPE_TIME.tif
```
For example:
```{}
Col0_010.tif
Col0_015.tif
Col0_020.tif
```

## 4. Citation

> Please cite DLhook this repository if you use **HookMotion** in your work.  
> A manuscript describing the method is currently in preparation.

---

## Acknowledgments

DLhook and HookMotion were developed by members of the [**Stéphanie Robert Group**](https://srobertgroup.com/).
