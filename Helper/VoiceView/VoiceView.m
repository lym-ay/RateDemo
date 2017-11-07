//
//  VoiceView.m
//  RateDemo
//
//  Created by olami on 2017/11/7.
//  Copyright © 2017年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "VoiceView.h"
#import "Macro.h"
#import "OlamiRecognizer.h"
#import "YSCVolumeQueue.h"
#import "YSCVoiceWaveView.h"


#define OLACUSID   @"a674855f-909c-454e-8e3f-1f10c94f22f4"
#define APPKEY @"d63f8238c7ec421bb9827c70d448ac44"
#define APPSECRET @"f94109d9eece44b2ba0fbbfa23511e84"


@interface VoiceView () <OlamiRecognizerDelegate> {
    OlamiRecognizer *olamiRecognizer;
    
}


@property (strong, nonatomic) NSMutableDictionary *slotDic;//保存slot的值
@property (copy, nonatomic)   NSString *api;
@property (assign, nonatomic) long start_time;
@property (assign, nonatomic) long end_time;


@property (nonatomic, strong) YSCVoiceWaveView *voiceWaveView;
@property (nonatomic,strong)  UIView *voiceWaveParentView;
 


@end

@implementation VoiceView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
    }
    
    return self;
}




- (void)setupData {
    olamiRecognizer= [[OlamiRecognizer alloc] init];
    olamiRecognizer.delegate = self;
    [olamiRecognizer setAuthorization:APPKEY
                                  api:@"asr" appSecret:APPSECRET cusid:OLACUSID];
    
    [olamiRecognizer setLocalization:LANGUAGE_SIMPLIFIED_CHINESE];//设置语系，这个必须在录音使用之前初始化
    _slotDic = [[NSMutableDictionary alloc] init];
    
    
   
    
}


- (void)setupUI {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, Kwidth, 20)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = COLOR(255, 255, 255, 1);
    label.font = [UIFont fontWithName:FONTFAMILY size:18];
    label.text = @"请说出货币的名称";
    [self addSubview:label];
    
    
    [self insertSubview:self.voiceWaveParentView atIndex:0];
    [self.voiceWaveView showInParentView:self.voiceWaveParentView];
    [self.voiceWaveView startVoiceWave];

}






- (void)start {
    [olamiRecognizer start];
}

- (void)stop {
    if (olamiRecognizer.isRecording) {
        [olamiRecognizer stop];
    }
}

- (BOOL)isRecording{
    return [olamiRecognizer isRecording];
}
- (void)onResult:(NSData *)result {
    NSError *error;
    __weak typeof(self) weakSelf = self;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:result
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    if (error) {
        NSSLog(@"error is %@",error.localizedDescription);
    }else{
        NSString *jsonStr=[[NSString alloc]initWithData:result
                                               encoding:NSUTF8StringEncoding];
        NSLog(@"jsonStr is %@",jsonStr);
        NSString *ok = [dic objectForKey:@"status"];
        if ([ok isEqualToString:@"ok"]) {
            NSDictionary *dicData = [dic objectForKey:@"data"];
            NSDictionary *asr = [dicData objectForKey:@"asr"];
            if (asr) {//如果asr不为空，说明目前是语音输入
                [weakSelf processASR:asr];
            }
            NSDictionary *nli = [[dicData objectForKey:@"nli"] objectAtIndex:0];
            NSDictionary *desc = [nli objectForKey:@"desc_obj"];
            int status = [[desc objectForKey:@"status"] intValue];
            if (status != 0) {// 0 说明状态正常,非零为状态不正常或者result为空
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"noresult" object:nil userInfo:nil]];
                
            }else{
                NSDictionary *semantic = [[nli objectForKey:@"semantic"]
                                          objectAtIndex:0];
                [weakSelf processSemantic:semantic];
                NSString *result = [desc objectForKey:@"result"];
                [self.delegate onResult:result];
                
            }
            
        }else{
            
        }
    }
    
    
    
}

- (void)onBeginningOfSpeech {
    [self.delegate onBeginningOfSpeech];
}

- (void)onEndOfSpeech {
    [self.delegate onEndOfSpeech];
    
}


- (void)onError:(NSError *)error {
    [self.delegate onError:error];
}

-(void)onCancel {
    [self.delegate onCancel];
}

- (void)voiceRecognizeFailure {
    [self.delegate voiceFailure];
}

- (void)voiceRecognizeSuccess {
    [self.delegate voiceSuccess];
}


#pragma mark -- 处理语音和语义的结果

//处理modify
- (void)processModify:(NSString*) str {
    
}





 

//处理ASR节点
- (void)processASR:(NSDictionary*)asrDic {
    NSString *result  = [asrDic objectForKey:@"result"];
    if (result.length == 0) { //如果结果为空，则弹出警告框
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"noresult" object:nil userInfo:nil]];
    } 
    
}

//处理Semantic节点
- (void)processSemantic:(NSDictionary*)semanticDic {
    NSArray *slot = [semanticDic objectForKey:@"slots"];
    
    [_slotDic removeAllObjects];
    if (slot.count != 0) {
        for (NSDictionary *dic in slot) { 
            NSString* name = [dic objectForKey:@"name"];
            NSString* value = [dic objectForKey:@"value"];
            [_slotDic setObject:value forKey:name];//保存slot的值和value
        }
        
    }
    
    NSArray *modify = [semanticDic objectForKey:@"modifier"];
    if (modify.count != 0) {
        for (NSString *s in modify) {
            [self processModify:s];
            
        }
        
    }
    
}

//调节声音
- (void)onUpdateVolume:(float)volume {
     CGFloat normalizedValue = volume/100;
    [_voiceWaveView changeVolume:normalizedValue];

}



- (void)sendText:(NSString *)text  {
  [olamiRecognizer sendText:text];
}



//#############################################
- (YSCVoiceWaveView *)voiceWaveView
{
    if (!_voiceWaveView) {
        self.voiceWaveView = [[YSCVoiceWaveView alloc] init];
    }
    
    return _voiceWaveView;
}

- (UIView *)voiceWaveParentView
{
    if (!_voiceWaveParentView) {
        self.voiceWaveParentView = [[UIView alloc] init];
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        _voiceWaveParentView.frame = CGRectMake(0, -10 , screenSize.width, 200*nKheight);
       
    }
    
    return _voiceWaveParentView;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

 




@end
