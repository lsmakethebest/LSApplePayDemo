

//
//  InpPayViewController.m
//  applePayDemo
//
//  Created by 刘松 on 16/9/7.
//  Copyright © 2016年 liusong. All rights reserved.
//

#import "InpPayViewController.h"
#import <StoreKit/StoreKit.h>

#define ProductIdentifer @"com.kuaichengwuliu.applePayDemo.inpayCar"

@interface InpPayViewController () <SKPaymentTransactionObserver,
                                    SKProductsRequestDelegate>

@end

@implementation InpPayViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

  UIButton *btn2 = [[UIButton alloc] init];
  btn2.backgroundColor =
      [UIColor colorWithRed:0.196 green:0.371 blue:0.248 alpha:1.000];
  [btn2 setTitle:@"内购" forState:UIControlStateNormal];
  [btn2 addTarget:self
                action:@selector(inpay)
      forControlEvents:UIControlEventTouchUpInside];
  btn2.frame = CGRectMake(100, 200, 100, 50);
  [self.view addSubview:btn2];
}

- (void)inpay {
  if ([SKPaymentQueue canMakePayments]) {
    [self requestProductData:ProductIdentifer];
  } else {
    NSLog(@"不允许程序内付费");
  }
}
//请求商品
- (void)requestProductData:(NSString *)type {
  NSLog(@"-------------请求对应的产品信息----------------");

  NSArray *product = [[NSArray alloc] initWithObjects:type, nil];

  NSSet *nsset = [NSSet setWithArray:product];
  SKProductsRequest *request =
      [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
  request.delegate = self;
  [request start];
}

//收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response {
  NSLog(@"--------------收到产品反馈消息---------------------");
  NSArray *product = response.products;
  if ([product count] == 0) {
    NSLog(@"--------------没有商品------------------");
    return;
  }

  NSLog(@"productID:%@", response.invalidProductIdentifiers);
  NSLog(@"产品付费数量:%ld", [product count]);

  SKProduct *p = nil;
  for (SKProduct *pro in product) {
    NSLog(@"%@", [pro description]);
    NSLog(@"%@", [pro localizedTitle]);
    NSLog(@"%@", [pro localizedDescription]);
    NSLog(@"%@", [pro price]);
    NSLog(@"%@", [pro productIdentifier]);

    if ([pro.productIdentifier isEqualToString:ProductIdentifer]) {
      p = pro;
    }
  }

  SKPayment *payment = [SKPayment paymentWithProduct:p];

  NSLog(@"发送购买请求");
  [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
  NSLog(@"------------------错误-----------------:%@", error);
}

- (void)requestDidFinish:(SKRequest *)request {
  NSLog(@"------------反馈信息结束-----------------");
}

#pragma mark - SKPaymentTransactionObserver
//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transaction {
  for (SKPaymentTransaction *tran in transaction) {
    switch (tran.transactionState) {
    case SKPaymentTransactionStatePurchased:
      NSLog(@"交易完成");
      [self completeTransaction:tran];

      break;
    case SKPaymentTransactionStatePurchasing:
      NSLog(@"商品添加进列表");

      break;
    case SKPaymentTransactionStateRestored:
      NSLog(@"已经购买过商品");
      //完成交易必须调用此方法否则会买一次第二次买提示已经买过
      //此方法标记交易已完成从队列移除 否则每次启动进入此类都会调用
      // updatedTransactions:(NSArray *)transaction来更新交易状态
      [[SKPaymentQueue defaultQueue] finishTransaction:tran];
      break;
    case SKPaymentTransactionStateFailed:
      NSLog(@"交易失败--%@", tran.error.localizedDescription);
      [[SKPaymentQueue defaultQueue] finishTransaction:tran];
      break;
    default:
      [[SKPaymentQueue defaultQueue] finishTransaction:tran];
      break;
    }
  }
}

//交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
  NSLog(@"交易结束");
  //从沙盒中获取交易凭证并且拼接成请求体数据
  NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
  NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];

  if (!receipt) {
  }

  NSDictionary *requestContents = @{
    @"receipt-data" : [receipt base64EncodedStringWithOptions:0]
  };
  NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                        options:0
                                                          error:NULL];

  if (!requestData) { /* ... Handle error ... */
  }
  NSURL *storeURL =
      [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
  //       NSURL *storeURL = [NSURL
  //       URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
  NSMutableURLRequest *storeRequest =
      [NSMutableURLRequest requestWithURL:storeURL];
  [storeRequest setHTTPMethod:@"POST"];
  [storeRequest setHTTPBody:requestData];

  //  //创建请求到苹果官方进行购买验证
  //  //创建连接并发送同步请求
  NSError *error = nil;

  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  [NSURLConnection
      sendAsynchronousRequest:storeRequest
                        queue:queue
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *connectionError) {
              if (connectionError) {
                NSLog(@"连接过程中发生错误，错误信息：%@",
                      connectionError.localizedDescription);
              } else if (error) {
                NSLog(@"验证购买过程中发生错误，错误信息：%@",
                      error.localizedDescription);
              } else {
                NSError *error;
                NSDictionary *jsonResponse =
                    [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:&error];
                if (!jsonResponse) {
                  NSLog(@"字典解析失败");
                }

                NSLog(@"%@", jsonResponse);
                if ([jsonResponse[@"status"] intValue] == 0) {
                  NSLog(@"购买成功！");
                  NSDictionary *dicReceipt = jsonResponse[@"receipt"];
                  NSDictionary *dicInApp = [dicReceipt[@"in_app"] firstObject];
                  NSString *productIdentifier =
                      dicInApp[@"product_id"]; //读取产品标识
                  //如果是消耗品则记录购买数量，非消耗品则记录是否购买过
                  NSUserDefaults *defaults =
                    [NSUserDefaults standardUserDefaults];
                  if ([productIdentifier isEqualToString:@"123"]) {
                    long purchasedCount =
                        [defaults integerForKey:productIdentifier]; //已购买数量
                    [[NSUserDefaults standardUserDefaults]
                        setInteger:(purchasedCount + 1)
                            forKey:productIdentifier];
                  } else {
                    [defaults setBool:YES forKey:productIdentifier];
                  }
                  //在此处对购买记录进行存储，可以存储到开发商的服务器端
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                               (int64_t)(0.5 * NSEC_PER_SEC)),
                                 dispatch_get_main_queue(), ^{
                                   [[[UIAlertView alloc]
                                           initWithTitle:@"购买成功"
                                                 message:nil
                                                delegate:nil
                                       cancelButtonTitle:@"取消"
                                       otherButtonTitles:nil, nil] show];
                                   [[SKPaymentQueue defaultQueue]
                                       finishTransaction:transaction];
                                 });
                } else {
                  NSLog(@"购买失败，未通过验证！");
                  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
              }
            }];
}

- (void)dealloc {
  [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
