//
//  ViewController.m
//  applePayDemo
//
//  Created by 刘松 on 16/9/5.
//  Copyright © 2016年 liusong. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>
#import "InpPayViewController.h"

#import <StoreKit/StoreKit.h>
@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>
{
    NSMutableArray *summaryItems;
    NSMutableArray *shippingMethods;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    UIButton *btn=[[UIButton alloc]init];
    btn.backgroundColor=[UIColor colorWithRed:0.196 green:0.371 blue:0.248 alpha:1.000];
    [btn setTitle:@"ApplePay" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(buyNow) forControlEvents:UIControlEventTouchUpInside];
    btn.frame=CGRectMake(100, 100, 100, 50);
    [self.view addSubview:btn];
   
    UIButton *btn2=[[UIButton alloc]init];
    btn2.backgroundColor=[UIColor colorWithRed:0.196 green:0.371 blue:0.248 alpha:1.000];
    [btn2 setTitle:@"内购" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(inpay) forControlEvents:UIControlEventTouchUpInside];
    btn2.frame=CGRectMake(100, 200, 100, 50);
    [self.view addSubview:btn2];
    
    
    
    UIButton *btn3=[[UIButton alloc]init];
    btn3.backgroundColor=[UIColor colorWithRed:0.196 green:0.371 blue:0.248 alpha:1.000];
    [btn3 setTitle:@"内嵌应用商店" forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(appstore) forControlEvents:UIControlEventTouchUpInside];
    btn3.frame=CGRectMake(100, 300, 150, 50);
    [self.view addSubview:btn3];
    
}

#pragma mark ---------------  内购 ------------------
-(void)inpay
{
    [self.navigationController pushViewController:[[InpPayViewController alloc]init] animated:YES];
    
}
#pragma mark - 内嵌应用商店
-(void)appstore
{
    SKStoreProductViewController *storeProductVC = [[SKStoreProductViewController alloc] init];
    storeProductVC.delegate = self;
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:@"333206289" forKey:SKStoreProductParameterITunesItemIdentifier];
    [storeProductVC loadProductWithParameters:dict completionBlock:^(BOOL result, NSError *error) {
        if (result) {
            [self presentViewController:storeProductVC animated:YES completion:nil];
        }
    }];

}
#pragma mark - SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:^{
    }];
}




#pragma mark ---------------  ApplePay  --------------
 
- (void)buyNow{
    

    if (![PKPaymentAuthorizationViewController class]) {
        //PKPaymentAuthorizationViewController需iOS8.0以上支持
        NSLog(@"操作系统不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return;
    }
    //检查当前设备是否可以支付
    if (![PKPaymentAuthorizationViewController canMakePayments]) {
        //支付需iOS9.0以上支持
        NSLog(@"设备不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return;
    }
    //检查用户是否可进行某种卡的支付，是否支持Amex、MasterCard、Visa与银联四种卡，根据自己项目的需要进行检测
    NSArray *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard,PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay];
    if (![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
        NSLog(@"没有绑定支付卡");
        return;
    }
    NSLog(@"可以支付，开始建立支付请求");
    //设置币种、国家码及merchant标识符等基本信息
    PKPaymentRequest *payRequest = [[PKPaymentRequest alloc]init];
    payRequest.countryCode = @"CN";     //国家代码
    payRequest.currencyCode = @"CNY";       //RMB的币种代码
    payRequest.merchantIdentifier = @"merchant.com.kuaichengwuliu";  //申请的merchantID
    payRequest.supportedNetworks = supportedNetworks;   //用户可进行支付的银行卡
    payRequest.merchantCapabilities = PKMerchantCapability3DS|PKMerchantCapabilityEMV;      //设置支持的交易处理协议，3DS必须支持，EMV为可选，目前国内的话还是使用两者吧
    
    
    //如果需要邮寄账单可以选择进行设置，默认PKAddressFieldNone(不邮寄账单)
    //    payRequest.requiredBillingAddressFields = PKAddressFieldEmail;
    
    //楼主感觉账单邮寄地址可以事先让用户选择是否需要，否则会增加客户的输入麻烦度，体验不好，
    //送货地址信息，这里设置需要地址和联系方式和姓名，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
//    payRequest.requiredShippingAddressFields = PKAddressFieldPostalAddress|PKAddressFieldPhone|PKAddressFieldName;
    
    
    //设置两种配送方式 用户可以手动选择
    PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"包邮" amount:[NSDecimalNumber zero]];
    freeShipping.identifier = @"freeshipping";
    freeShipping.detail = @"6-8 天 送达";
    
    PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"极速送达" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    expressShipping.identifier = @"expressshipping";
    expressShipping.detail = @"2-3 小时 送达";
    shippingMethods = [NSMutableArray arrayWithArray:@[freeShipping, expressShipping]];
    //shippingMethods为配送方式列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行配送方式的调整。
    payRequest.shippingMethods = shippingMethods;
    
    
    //配置价格 优惠价格
    NSDecimalNumber *subtotalAmount = [NSDecimalNumber decimalNumberWithMantissa:1275 exponent:-2 isNegative:NO];   //12.75
    PKPaymentSummaryItem *subtotal = [PKPaymentSummaryItem summaryItemWithLabel:@"商品价格" amount:subtotalAmount];
    
    NSDecimalNumber *discountAmount = [NSDecimalNumber decimalNumberWithString:@"-12.74"];      //-12.74
    PKPaymentSummaryItem *discount = [PKPaymentSummaryItem summaryItemWithLabel:@"优惠折扣" amount:discountAmount];
    
    NSDecimalNumber *methodsAmount = [NSDecimalNumber zero];
    PKPaymentSummaryItem *methods = [PKPaymentSummaryItem summaryItemWithLabel:@"包邮" amount:methodsAmount];
    
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    totalAmount = [totalAmount decimalNumberByAdding:subtotalAmount];
    totalAmount = [totalAmount decimalNumberByAdding:discountAmount];
    totalAmount = [totalAmount decimalNumberByAdding:methodsAmount];
    
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"ls" amount:totalAmount];  //最后这个是支付给谁。哈哈，快支付给我
    
    summaryItems = [NSMutableArray arrayWithArray:@[subtotal, discount, methods, total]];
    //summaryItems为账单列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行支付金额的调整。
    payRequest.paymentSummaryItems = summaryItems;
    
    
    //ApplePay控件
    PKPaymentAuthorizationViewController *view = [[PKPaymentAuthorizationViewController alloc]initWithPaymentRequest:payRequest];
    view.delegate = self;
    [self presentViewController:view animated:YES completion:nil];
    
}
#pragma mark - PKPaymentAuthorizationViewControllerDelegate
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //contact送货地址信息，PKContact类型
    NSPersonNameComponents *name = contact.name;                //联系人姓名
    CNPostalAddress *postalAddress = contact.postalAddress;     //联系人地址
    NSString *emailAddress = contact.emailAddress;              //联系人邮箱
    CNPhoneNumber *phoneNumber = contact.phoneNumber;           //联系人手机
    NSString *supplementarySubLocality = contact.supplementarySubLocality;  //补充信息,iOS9.2及以上才有
    
    //送货信息选择回调，如果需要根据送货地址调整送货方式，比如普通地区包邮+极速配送，偏远地区只有付费普通配送，进行支付金额重新计算，可以实现该代理，返回给系统：shippingMethods配送方式，summaryItems账单列表，如果不支持该送货信息返回想要的PKPaymentAuthorizationStatus
    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //配送方式回调，如果需要根据不同的送货方式进行支付金额的调整，比如包邮和付费加速配送，可以实现该代理
    PKShippingMethod *oldShippingMethod = [summaryItems objectAtIndex:2];
    PKPaymentSummaryItem *total = [summaryItems lastObject];
    total.amount = [total.amount decimalNumberBySubtracting:oldShippingMethod.amount];
    total.amount = [total.amount decimalNumberByAdding:shippingMethod.amount];
    
    [summaryItems replaceObjectAtIndex:2 withObject:shippingMethod];
    [summaryItems replaceObjectAtIndex:3 withObject:total];
    
    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //支付银行卡回调，如果需要根据不同的银行调整付费金额，可以实现该代理
    completion(summaryItems); 
}
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingAddress:(ABRecordRef)address completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //送货地址回调，已弃用
}
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    
    PKPaymentToken *payToken = payment.token;
    //支付凭据，发给服务端进行验证支付是否真实有效
    PKContact *billingContact = payment.billingContact;     //账单信息
    PKContact *shippingContact = payment.shippingContact;   //送货信息
    PKContact *shippingMethod = payment.shippingMethod;     //送货方式
    
    // 这里需要将Token和地址信息发送到自己的服务器上，进行订单处理，处理之后，根据自己的服务器返回的结果调用completion()代码块，根据传进去的参数界面的显示结果会不同
    //等待服务器返回结果后再进行系统block调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //模拟服务器通信
        completion(PKPaymentAuthorizationStatusSuccess);
    });
    
    
}
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
