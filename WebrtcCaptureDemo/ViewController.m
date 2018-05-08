//
//  ViewController.m
//  WebrtcCaptureDemo
//
//  Created by tangzhixin on 2018/5/7.
//  Copyright © 2018年 tangzhixin. All rights reserved.
//

#define WEBRTC_IOS

#import "ViewController.h"

#import <WebRTC/RTCCameraPreviewView.h>
//#import <WebRTC/RTCEAGLVideoView.h>

#import "WebRTC/RTCCameraVideoCapturer.h"

@interface ViewController () {
    RTCCameraPreviewView *localVideoView;
    RTCCameraVideoCapturer *capturer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:localVideoView];
    
    capturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:self];
    
    localVideoView.captureSession = capturer.captureSession;
    
    [self startCapture ];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startCapture {
    BOOL _usingFrontCamera = YES;
    AVCaptureDevicePosition position =
    _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self findDeviceForPosition:position];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
    
    if (format == nil) {
        NSLog(@"No valid formats for device %@", device);
        NSAssert(NO, @"");
        
        return;
    }
    
    NSInteger fps = 20;//[self selectFpsForFormat:format];
    
    [capturer startCaptureWithDevice:device format:format fps:fps];
}

- (void)stopCapture {
    [capturer stopCapture];
}

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    int targetWidth = 1280;//[_settings currentVideoResolutionWidthFromStore];
    int targetHeight = 720;//[_settings currentVideoResolutionHeightFromStore];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        FourCharCode pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        } else if (diff == currentDiff && pixelFormat == [capturer preferredOutputPixelFormat]) {
            selectedFormat = format;
        }
    }
    
    return selectedFormat;
}

- (NSInteger)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
    Float64 maxFramerate = 0;
    for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
        maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
    }
    return maxFramerate;
}

@end
