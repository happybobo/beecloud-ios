//
//  BCAliPayAdapter.m
//  BeeCloud
//
//  Created by Ewenlong03 on 15/9/9.
//  Copyright (c) 2015年 BeeCloud. All rights reserved.
//

#import "BCAliPayAdapter.h"
#import "BeeCloudAdapterProtocol.h"
#import <AlipaySDK/AlipaySDK.h>

@interface BCAliPayAdapter ()<BeeCloudAdapterDelegate>

@end

@implementation BCAliPayAdapter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BCAliPayAdapter *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BCAliPayAdapter alloc] init];
    });
    return instance;
}

- (void)setBeeCloudDelegate:(id<BeeCloudDelegate>)delegate {
    [BCAliPayAdapter sharedInstance].aliBeeCloudDelegate = delegate;
}

- (BOOL)handleOpenUrl:(NSURL *)url {
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        [[BCAliPayAdapter sharedInstance] processOrderForAliPay:resultDic];
    }];
    return YES;
}

- (void)aliPay:(NSMutableDictionary *)dic {
  
    NSString *orderString = [dic objectForKey:@"order_string"];
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:dic[@"scheme"]
                                callback:^(NSDictionary *resultDic) {
                                    [[BCAliPayAdapter sharedInstance] processOrderForAliPay:resultDic];
                                }];
}

#pragma mark - Implementation AliPayDelegate

- (void)processOrderForAliPay:(NSDictionary *)resultDic {
    int status = [resultDic[@"resultStatus"] intValue];
    NSString *strMsg;
    int errcode = 0;
    switch (status) {
        case 9000:
            strMsg = @"支付成功";
            errcode = BCSuccess;
            break;
        case 4000:
        case 6002:
            strMsg = @"支付失败";
            errcode = BCErrCodeSentFail;
            break;
        case 6001:
            strMsg = @"支付取消";
            errcode = BCErrCodeUserCancel;
            break;
        default:
            strMsg = @"未知错误";
            errcode = BCErrCodeUnsupport;
            break;
    }
    BCPayResp *resp = [[BCPayResp alloc] init];
    resp.result_code = errcode;
    resp.result_msg = strMsg;
    resp.err_detail = strMsg;
    resp.paySource = resultDic;
    if (_aliBeeCloudDelegate && [_aliBeeCloudDelegate respondsToSelector:@selector(onBeeCloudResp:)]) {
        [_aliBeeCloudDelegate onBeeCloudResp:resp];
    }
}

@end
