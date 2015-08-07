//
//  QRCapturePreview.m
//  QRCapture
//
//  Created by 湛家荣 on 15/5/28.
//  Copyright (c) 2015年 Zhan. All rights reserved.
//

#import "QRCapturePreview.h"
#import <AVFoundation/AVFoundation.h>

@implementation QRCapturePreview

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
