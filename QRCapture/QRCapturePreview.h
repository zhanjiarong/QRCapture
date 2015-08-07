//
//  QRCapturePreview.h
//  QRCapture
//
//  Created by 湛家荣 on 15/5/28.
//  Copyright (c) 2015年 Zhan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface QRCapturePreview : UIView

@property (nonatomic) AVCaptureSession *session;

@end
