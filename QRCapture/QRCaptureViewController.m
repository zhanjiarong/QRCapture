//
//  ViewController.m
//  QRCapture
//
//  Created by 湛家荣 on 15/5/28.
//  Copyright (c) 2015年 Zhan. All rights reserved.
//

#import "QRCaptureViewController.h"
#import "QRCapturePreview.h"

#import <AVFoundation/AVFoundation.h>

#define JR_OS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

@interface QRCaptureViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>

/** 显示摄像头获取的内容的视图 */
@property (weak, nonatomic) IBOutlet QRCapturePreview *preview;

@property (nonatomic) dispatch_queue_t sessionQueue;

/** 所有输入输出对象都是由这个session管理 */
@property (nonatomic) AVCaptureSession *session;
/** 设备输入对象 */
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
/** 元数据输出对象 */
@property (nonatomic) AVCaptureMetadataOutput *QRcodeOutput;

@property (nonatomic, getter=isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter=isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;

@end

@implementation QRCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 检查权限
    [self checkDeviceAuthorizationStatus];
    
    [self setupAVFoundation];
}

/** session是否正在运行及验证权限 */
- (BOOL)isSessionRunningAndDeviceAuthorized {
    return [self.session isRunning] && [self isDeviceAuthorized];
}

/** 配置所需的AVFoundation中的类实例 */
- (void)setupAVFoundation {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    
    [self.preview setSession:session];
    
    
    dispatch_queue_t queue = dispatch_queue_create("com.jrcapture.session", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:queue];
    
    dispatch_async(queue, ^{
        NSError *error;
        // 创建视频设备对象
        AVCaptureDevice *videoDevice = [[self class] deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
        // 创建设备输入对象
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        
        if ([self.session canAddInput:videoDeviceInput]) {
            // 设备输入对象加入到session
            [self.session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 设置内容显示方向，和屏幕方向一致
                [[(AVCaptureVideoPreviewLayer *)self.preview.layer connection] setVideoOrientation:[self orientation]];
            });
        }
        
        // 元数据输出对象
        AVCaptureMetadataOutput *QRCodeOutput = [[AVCaptureMetadataOutput alloc] init];
        if ([self.session canAddOutput:QRCodeOutput]) {
            // 加入到session
            [self.session addOutput:QRCodeOutput];
            
            // 设置元数据类型为QRCode（二维码）
            [QRCodeOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            // 设置输出代理
            [QRCodeOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            
            [self setQRcodeOutput:QRCodeOutput];
        }
        
        [self.session startRunning];
        
    });
}

/** 获取设备 */
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

/** 由设备方向得到视频方向 */
- (AVCaptureVideoOrientation)orientation {
    return (AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation];
}

/** 验证访问照相机的权限 */
- (void)checkDeviceAuthorizationStatus {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [self setDeviceAuthorized:YES];
        }
        else
        {
            [self setDeviceAuthorized:NO];
        }
    }];
}

/** iOS 2.0~8.0 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // 设置内容显示方向，和屏幕方向一致
    [[(AVCaptureVideoPreviewLayer *)self.preview.layer connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

/** iOS 8.0+ */
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // 设置内容显示方向，和屏幕方向一致
    [[(AVCaptureVideoPreviewLayer *)self.preview.layer connection] setVideoOrientation:[self orientation]];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate方法
// 扫描到二维码就会调用这个方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            [self.session stopRunning];
            
            if (JR_OS_VERSION >= 8.0) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"扫描到的信息" message:metadata.stringValue preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self.session startRunning];
                }];
                UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.session startRunning];
                }];
                
                [alertController addAction:action1];
                [alertController addAction:action2];
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else
            {
                // iOS 8.0以下
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描到的信息" message:metadata.stringValue delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                [alert show];
            }

        }
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.session startRunning];
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    [self.session startRunning];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
