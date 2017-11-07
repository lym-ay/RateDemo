//
//  VoiceView.h
//  RateDemo
//
//  Created by olami on 2017/11/7.
//  Copyright © 2017年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//


//这个页面定义了 语音输入的页面
#import <UIKit/UIKit.h>

@protocol VoiceViewDelegate <NSObject>

//返回内容
- (void)onResult:(id)result;

//取消本次会话
- (void)onCancel;

//识别失败
- (void)onError:(NSError *)error;

//开始录音
- (void)onBeginningOfSpeech;

//结束录音
- (void)onEndOfSpeech;

//语音识别失败
- (void)voiceFailure;

//语音识别成功
- (void)voiceSuccess;

@end



@interface VoiceView : UIView
@property (nonatomic, weak) id<VoiceViewDelegate> delegate;
@property (nonatomic, assign) BOOL isRecording;
 
- (void)sendText:(NSString*)text;//发送文本请求
- (void)start;
- (void)stop;
 
@end
