# MTImagePickerController

### 简介
   本文档为美图app相册组件**MTPhotoLibrary** 以及Demo的说明文档
   
#### SDK联系人
|联系人|角色|QQ|邮箱|
|:-:|:-:|:-:|:-:|
|彭浩|iOS组件负责人|496124577|ph@meitu.com|
|刘晨迪|iOS组件负责人|122167358|lcd1@meitu.com|

### 功能
   **MTPhotoLibrary** 基于系统相册库封装的组件，提供相册模块数据层。
   
   **MTImagePickerControllerDemo** 提供MTPhotoLibrary的简单使用。
   
   MTPhotoLibrary只提供基于数据层的接口，具体界面层以及api使用参考MTImagePickerControllerDemo

### 使用说明
### 环境要求
* iOS版本要求: >= 7.0
	+	iOS7基于AssetsLibrary.framework封装
	+	iOS8以上基于Photos.framework封装
    
    
### 接入步骤

以Pod方式引入,在项目podfile文件中加入

```
#podfile顶部需要引入Techgit仓库地址
source 'http://techgit.meitu.com/iosmodules/specs.git' 

pod 'MTPhotoLibrary', '~> 1.0.4'
```	
> 注意事项：项目统一使用pod引入使用指定正式tag，开发期间使用beta版本的tag。
> 

### 注意事项
1.相册页获取照片缩略图需要调用**MTImageManager**对缩略图缓存，避免滑动卡顿
  
2.长的大图度（图片长宽比例1：6或6：1以上）为保存缩略图有一点的清晰度，获取到的缩略图会较大，在低端机器上遇到长图较多情况可能出现内存不足crash

### 参考资料
1.[iOS7 AssetsLibrary的Bug](http://www.cnblogs.com/sohobloo/p/3988990.html)

## 维护信息
项目如果需要扩展组件功能或者遇到bug等问题，可以先行开个人fix分支进行修正后，发起merge给组件维护人员进行review后合并。


### 已接入产品
+	tag1.0.3.2

	+	美妆相机
	
+	tag1.0.3.1
	
	+	美颜相机
	+	潮自拍
	+	美拍
	

	

### 版本更新历史
+	1.0.4
	+	feature:
		+	新增MTUIButton, 获取相册最新的一张照片。
	+	bugfix: 
		+	修复photoLibraryDidChange回调方法里面崩溃问题
		+	照片数量为空无法获取postImage问题
		+	MTPhotoAsset内存泄漏
		+	照片数量为1的时候删除崩溃问题
+ 	1.0.3.5
	+	bugfix: 修正相册里照片数量为0无法遍历相册问题
+	1.0.3.4
	+	bugfix: 修正MTPhotoAlbum类indexOfAsset方法里判断NSURL的相等的方式为isEqual。
+   1.0.3.2
    +    1.bugfix：修正IOS8以上系统无相册权限进入相册页后退出时，缩略图缓存类MTImageManager导致崩溃的问题。
	+    2.bugfix：修正保存照片到相册接口存在崩溃问题
+	1.0.3 MTPhotoAlbum添加reloadALAssetsWith:completionBlock接口。（修改IOS7界面刷新时与底层数据不同步bug）
+	1.0.2 相册demo替换新接口
+	1.0.1 修正相册图片排序方式属性设置无效问题


