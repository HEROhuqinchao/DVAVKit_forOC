//
//  GPUImagePicture+TextureSubimage.h
//  GPUImage
//
//  Created by Jack Wu on 2014-05-28.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#if __has_include(<GPUImage/GPUImageFramework.h>)

#import <GPUImage/GPUImagePicture.h>

#else
#import "GPUImagePicture.h"
#endif

@interface GPUImagePicture (TextureSubimage)

- (void)replaceTextureWithSubimage:(UIImage*)subimage;
- (void)replaceTextureWithSubCGImage:(CGImageRef)subimageSource;

- (void)replaceTextureWithSubimage:(UIImage*)subimage inRect:(CGRect)subRect;
- (void)replaceTextureWithSubCGImage:(CGImageRef)subimageSource inRect:(CGRect)subRect;

@end
