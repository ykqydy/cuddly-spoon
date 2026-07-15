# 调试记录

## 1. 开发环境

| 项目 | 内容 |
|------|------|
| 开发工具 | Visual Studio 2022 |
| NX 版本 | NX 2306 |
| 编程语言 | C++ (NX Open) |
| UI 框架 | NX Block UI Styler |
| 操作系统 | Windows 11 |
| 生成配置 | Debug / Release x64 |

## 2. 项目概述

**插件名称：** MoveandCut

**功能描述：**
在 NX 环境中选择一个实体（Body），通过设定起始点和终止点的位置，实现实体的 **移动（Move）** 或 **复制（Copy）** 操作。

**界面布局：**
- 操作模式选择：Move / Copy 按钮
- 体选择：选择目标实体
- 起始点设定：支持手动点选或自动选择（顶面中心、体中心、底面中心）
- 终止点设定：支持手动点选或自动选择（原点、WCS、体中心等）

## 3. 核心逻辑

选择实体 -> 读取起始点/终止点 -> 计算位移向量 delta -> 创建 MoveObjectBuilder -> 设置变换参数 -> 提交更新 -> 刷新显示

### 关键代码流程

1. 用户选择实体，插件获取 Body Tag
2. 读取起始点坐标（手动输入或枚举模式自动计算）
3. 读取终止点坐标（手动输入或枚举模式自动计算）
4. 计算位移向量：delta = endPt - startPt
5. 创建 MoveObjectBuilder 并设置变换参数
6. 根据模式（Move/Copy）设置关联性和结果类型
7. 提交 Commit -> DoUpdate -> 刷新显示

## 4. 编译步骤

### 4.1 环境配置

```
set UGII_USER_DIR=E:\NX\custom
set UGII_BASE_DIR=C:\Program Files\Siemens\NX2306
```

### 4.2 编译方法

在 Visual Studio 中打开 MoveandCut.sln，选择 x64 Release 配置，生成解决方案即可。

编译产物位于 x64/Release/ 目录。

### 4.3 部署说明

将 x64/Release/ 下的 MoveandCut.dlx 和 MoveandCut.dll 复制到 NX 可识别的 application 目录中，在 NX 中通过 File -> Execute -> NX Open 运行。

## 5. 运行测试记录

| 测试编号 | 测试内容 | 操作模式 | 起始点 | 终止点 | 结果 | 备注 |
|---------|----------|----------|--------|--------|------|------|
| 1 | 基本移动 | Move | 体中心 | WCS | 通过 | 实体按预期移动 |
| 2 | 基本复制 | Copy | 体中心 | WCS | 通过 | 生成副本实体 |
| 3 | 顶面中心到原点 | Move | 顶面中心 | 原点 | 通过 | 位移正确 |
| 4 | 手动点选 | Copy | 手动拾取 | 体中心 | 通过 | 坐标读取正常 |
| 5 | 多体选择 | Move | 体中心 | WCS | 通过 | 多体同步变换 |

## 6. 遇到的问题及解决

| 问题 | 原因 | 解决方法 |
|------|------|----------|
| DLX 加载失败 | DLX 路径未正确设置 | 使用 GetModuleFileNameA 自动定位 DLX 路径 |
| 枚举值读取异常 | NX API 版本差异 | 改用 ValueAsString + GetEnumMembers 方式 |
| Copy 模式关联问题 | 关联性设置冲突 | 分别处理 Move/Copy 的参数配置 |

## 7. 构建产物

| 文件 | 说明 |
|------|------|
| x64/Release/MoveandCut.dlx | NX Block UI Styler 界面文件（可运行插件） |
| x64/Release/MoveandCut.dll | 插件动态链接库 |
| x64/Release/MoveandCut.pdb | 调试符号文件 |
