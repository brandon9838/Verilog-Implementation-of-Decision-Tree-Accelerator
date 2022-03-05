# Verilog-Implementation-of-Decision-Tree-Accelerator
## Introduction
This repository contains a verilog implementation of decision tree accelerator. The dataset used to train the decision tree is from this [repository](https://github.com/Shayan-Asgari/ClassificationTrees). Compared with the baseline implementation, the inference time of the accelerator is ~37 times shorter (Check out DecisionTreeAccelerator.pdf for more details).  
## Usage
### Software
Make sure that you have all the dependency installed, including numpy, scikit-learn, pandas, and matplotlib. In the software folder, simply execute  
```
python dec.py
```
The hex files (data, answer, parameters) required for hardware simulation will be generated. The baseline inference time is about 1.5 ms. 
### Hardware
In the hardware/RTL folder, excecute  
```
ncverilog +notimingchecks tb_v3.v DEC.v sram_512x8.vp sram_256x8.vp +access+r
```
For synthesis and P&R, some of the required files are provided by TSMC/synopsys. I have no right to distribute them publicly. Therefore only the files for RTL simulation are provided. For details about synthesis and P&R, please refer to DecisionTreeAccelerator.pdf.
