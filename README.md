# PatchMatch对齐多曝光图像

实现环境： matlab R2019b

算法实现了不同曝光情况下，多目图像的匹配对齐，得到对齐到所选参考视角的不同曝光图像。

测试数据选用了middlebury数据集（http://vision.middlebury.edu/stereo/data/）。

输入图像在data文件夹下(不同曝光的输入图像及其曝光信息，基线大小)，结果保存在alignSave文件夹下。

测试运行TestDemo.m即可。

### 参考

PatchMatch: A Randomized Correspondence Algorithm for Structural Image Editing
