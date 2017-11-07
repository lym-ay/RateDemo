//
//  ViewController.m
//  RateDemo
//
//  Created by olami on 2017/11/7.
//  Copyright © 2017年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "ViewController.h"
#import "VoiceView.h"
#import "Macro.h"
#import "NetWorkAction.h"
#import "AFNetworkReachabilityManager.h"
#import "JMCircleAnimationView.h"
#import <AVFoundation/AVSpeechSynthesis.h>
#import <AVFoundation/AVAudioSession.h>
#import "MBProgressHUD.h"


@interface ViewController ()<VoiceViewDelegate,UITextViewDelegate,
                            VoiceViewDelegate,UITableViewDelegate,AVSpeechSynthesizerDelegate> {
    NetWorkAction *networkAction;
    NSMutableDictionary *dicCode;
    MBProgressHUD *hub;
    NSArray *resultArry;
    AVSpeechSynthesizer*av;
    AVSpeechUtterance *utterance;
}
@property (nonatomic, strong) VoiceView       *voiceView;
@property (weak, nonatomic) IBOutlet UIView *voiceBackView;
@property (nonatomic, strong) JMCircleAnimationView* circleView;//语音识别的动画
@property (weak, nonatomic) IBOutlet UIButton *voiceButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;


 


 
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupData];
    [self setupUI];
}


- (void)setupUI {
    _voiceView = [[VoiceView alloc] initWithFrame:_voiceView.frame];
    _voiceBackView.backgroundColor = COLOR(24, 49, 69, 1);
    _voiceView.delegate = self;
    [_voiceBackView addSubview:_voiceView];
    
    av= [[AVSpeechSynthesizer alloc]init];
    
    av.delegate=self;//挂上代理
    
    
}

- (void)setupData {
    networkAction = [[NetWorkAction alloc] init];
}

- (void)speakText:(NSString*)text {
    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if (!ret) {
        NSLog(@"设置声音环境失败");
        return;
    }
    
    //启用audio session
    ret = [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (!ret)
    {
        NSLog(@"启动失败");
        return;
    }
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:text];//需要转换的文字
    
    utterance.rate=0.5;// 设置语速，范围0-1，注意0最慢，1最快；AVSpeechUtteranceMinimumSpeechRate最慢，AVSpeechUtteranceMaximumSpeechRate最快
    
    AVSpeechSynthesisVoice*voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-TW"];//设置发音，这是中文普通话
    
    utterance.voice= voice;
    
    [av speakUtterance:utterance];//开始
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
 
- (IBAction)voiceButtonAction:(id)sender {
    if (self.voiceView.isRecording) {
        [self.voiceView stop];
        
    }else{
        [self.voiceView start];
        
    }
}

#pragma mark--懒加载
- (JMCircleAnimationView *)circleView
{
    if (!_circleView) {
        _circleView = [JMCircleAnimationView viewWithButton:self.voiceButton];
        [self.voiceButton addSubview:_circleView];
    }
    return _circleView;
}

#pragma mark --Voice delegate
- (void)onUpdateVolume:(float)volume {
    
}

- (void)onEndOfSpeech {
    //录音结束的时候，让button按钮为空
    [_voiceButton setEnabled:NO];
    [self.circleView startAnimation];
}

-(void)onBeginningOfSpeech {
    
}

-(void)onCancel {
    
}

//识别失败
- (void)voiceFailure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_voiceButton setEnabled:YES];
        [self.circleView removeFromSuperview];
        self.circleView = nil;
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"识别失败！"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        [self presentViewController:alertController animated:YES completion:^{
            dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC);
            dispatch_after(time, dispatch_get_main_queue(), ^{
                [alertController dismissViewControllerAnimated:YES completion:nil];
                
            });
            
        }];
        
        
    });
    
    
}

//识别成功
- (void)voiceSuccess {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.circleView removeFromSuperview];
        self.circleView = nil;
        [_voiceButton setEnabled:YES];
    });
}



- (void)onError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        hub.label.text = @"网络出错，请稍后再试";
        hub.mode = MBProgressHUDModeText;
        [hub showAnimated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [hub hideAnimated:YES];
        });
        
    });
    
    if (error) {
        NSSLog(@"voice reconginze error is %@",error.localizedDescription);
    }
}

//弹出对话框，警告用户
- (void)openAlertView {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"没有数据，请重试！"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [self presentViewController:alertController animated:YES completion:^{
        dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC);
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [alertController dismissViewControllerAnimated:YES completion:nil];
            
        });
        
    }];
}


- (void)onResult:(id)result {
    NSString *text = (NSString*)result;
    _textView.text = text;
    
    //[self speakText:text];

}

#pragma mark--AVSpeechSynthesizer delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didStartSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---开始播放");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---完成播放");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---播放中止");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---恢复播放");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---播放取消");
    
}



@end
