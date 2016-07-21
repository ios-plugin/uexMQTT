/**
 *
 *	@file   	: uexMQTTClient.m  in EUExMQTT
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/7/15.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "uexMQTTClient.h"

#import "JSON.h"
#import "EUtility.h"


@interface uexMQTTClient()<MQTTSessionDelegate>
@property (nonatomic,strong)MQTTSession *mqtt;
@property (nonatomic,strong)RACCompoundDisposable *cleanDisposables;
@end


@implementation uexMQTTClient

static NSString *const kUexMQTTErrorCodeKey = @"errCode";
static NSString *const kUexMQTTErrorStringKey = @"errStr";
static NSString *const kUexMQTTIsSuccessKey = @"isSuccess";
static NSString *const kUexMQTTTopicKey = @"topic";




static uexMQTTClient *client = nil;

+ (instancetype)sharedClient{
    return client;
}

+ (void)init{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[self alloc] init];
        NSDictionary *dict = @{@"status":@(MQTTSessionStatusCreated)};
        [client callbackWithKeyPath:@"onStatusChange" object:dict];
    });
}




- (void)connectWithServer:(NSString *)server port:(UInt16)port username:(NSString *)username password:(NSString *)password keepAliveInterval:(UInt16)keepAliveInterval clientId:(NSString *)clientId willMsg:(NSData *)willMsg willTopic:(NSString *)willTopic willQos:(MQTTQosLevel)willQos willRetainFlag:(BOOL)willRetainFlag{
    if (self.mqtt.status == MQTTSessionStatusConnecting ||
        self.mqtt.status == MQTTSessionStatusConnected) {
        NSMutableDictionary *dict = [self resultDictWithError:connectAlreadyExistError()];
        [self callbackWithKeyPath:@"cbConnect" object:dict];
        return;
    }
    [self reset];
    MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
    transport.host = server;
    transport.port = port;
    self.mqtt.transport = transport;
    if (username && password) {
        self.mqtt.userName = username;
        self.mqtt.password = password;
    }
    if (willMsg && willTopic) {
        self.mqtt.willTopic = willTopic;
        self.mqtt.willMsg = willMsg;
        self.mqtt.willQoS = willQos;
        self.mqtt.willRetainFlag = willRetainFlag;
        self.mqtt.willFlag = YES;
    }
    
    self.mqtt.clientId = clientId;
    self.mqtt.keepAliveInterval = keepAliveInterval;
    @weakify(self);
    [self.mqtt connectWithConnectHandler:^(NSError *error) {
        @strongify(self);
        NSMutableDictionary *dict = [self resultDictWithError:error];
        [self callbackWithKeyPath:@"cbConnect" object:dict];
    }];
    
    [self.cleanDisposables addDisposable:[[self rac_signalForSelector:@selector(newMessage:data:onTopic:qos:retained:mid:) fromProtocol:@protocol(MQTTSessionDelegate)] subscribeNext:^(RACTuple *msgTuple) {
        @strongify(self);
        RACTupleUnpack(__unused MQTTSession *session,NSData *data,NSString *topic,NSNumber *qosNum,NSNumber *retainFlag,NSNumber *mid) = msgTuple;
        NSString *dataStr  = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:dataStr forKey:@"data"];
        [dict setValue:topic forKey:kUexMQTTTopicKey];
        [dict setValue:qosNum forKey:@"qos"];
        [dict setValue:retainFlag forKey:@"retainFlag"];
        [dict setValue:mid forKey:@"mid"];
        [self callbackWithKeyPath:@"onNewMessage" object:dict];
    }]];

    [self.cleanDisposables addDisposable:[[RACObserve(self.mqtt, status)
       filter:^BOOL(id value) {
           NSArray *filter = @[@(MQTTSessionStatusError),@(MQTTSessionStatusCreated)];
           return ![filter containsObject:value];
    }].distinctUntilChanged
       subscribeNext:^(NSNumber *status) {
        @strongify(self);
        NSDictionary *dict = @{@"status":status};
        [self callbackWithKeyPath:@"onStatusChange" object:dict];
    }]];
}

- (void)disconnect{
    [self.mqtt disconnect];
    [self callbackWithKeyPath:@"cbDisconnect" object:@{kUexMQTTIsSuccessKey:@(YES)}];
    
}


- (void)publishDataString:(NSString *)dataStr onTopic:(NSString *)topic qos:(MQTTQosLevel)qos identifier:(NSString *)identifier retainFlag:(BOOL)retainFlag{
    @weakify(self);
    __block UInt16 pubmid = [self.mqtt publishData:[dataStr dataUsingEncoding:NSUTF8StringEncoding]
                                           onTopic:topic
                                            retain:retainFlag
                                               qos:qos
                                    publishHandler:^(NSError *error) {
                                        @strongify(self);
                                        NSMutableDictionary *dict = [self resultDictWithError:error];
                                        [dict setValue:identifier forKey:@"id"];
                                        [dict setValue:@(pubmid) forKey:@"mid"];
                                        [dict setValue:topic forKey:kUexMQTTTopicKey];
                                        [dict setValue:dataStr forKey:@"data"];
                                        [self callbackWithKeyPath:@"cbPublish" object:dict];
                                    }];
}


- (void)subscribeTopic:(NSString *)topic qos:(MQTTQosLevel)qos{
    @weakify(self);
    [self.mqtt subscribeToTopic:topic atLevel:qos subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss) {
        @strongify(self);
        NSMutableDictionary *dict = [self resultDictWithError:error];
        [dict setValue:gQoss forKey:@"grantedQoss"];
        [dict setValue:topic forKey:kUexMQTTTopicKey];
        [self callbackWithKeyPath:@"cbSubscribe" object:dict];
    }];
}

- (void)unsubscibeTopic:(NSString *)topic{
    @weakify(self);
    [self.mqtt unsubscribeTopic:topic unsubscribeHandler:^(NSError *error) {
        @strongify(self);
        NSMutableDictionary *dict = [self resultDictWithError:error];
        [dict setValue:topic forKey:kUexMQTTTopicKey];
        [self callbackWithKeyPath:@"cbUnsubscribe" object:dict];
    }];
    

}



#pragma mark - Privete

- (void)callbackWithKeyPath:(NSString *)keyPath object:(NSDictionary *)obj{
    NSString *jsStr = [NSString stringWithFormat:@"if(uexMQTT.%@){uexMQTT.%@(%@);}",keyPath,keyPath,obj.JSONFragment];
    [EUtility evaluatingJavaScriptInRootWnd:jsStr];
}

- (NSMutableDictionary *)resultDictWithError:(NSError *)error{
    BOOL isSuccess = YES;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (error) {
        isSuccess = NO;
        error = uexError(error);
        [dict setValue:@(error.code) forKey:kUexMQTTErrorCodeKey];
        [dict setValue:error.localizedDescription forKey:kUexMQTTErrorStringKey];
    }
    [dict setValue:@(isSuccess) forKey:kUexMQTTIsSuccessKey];
    return dict;

}


- (void)reset{
    [self.cleanDisposables dispose];
    self.cleanDisposables = [RACCompoundDisposable compoundDisposable];
    [self.cleanDisposables addDisposable:[RACDisposable disposableWithBlock:^{
        [self.mqtt close];
        self.mqtt = nil;
    }]];
}



- (MQTTSession *)mqtt{
    if (!_mqtt) {
        _mqtt = [[MQTTSession alloc] init];
        _mqtt.delegate = self;
    }
    return _mqtt;
}

#pragma mark - Error


static NSString *const kUexMQTTErrorDomain = @"com.appcan.uexMQTT.errorDomain";
typedef NS_ENUM(NSInteger, uexMQTTCustomError){
    uexMQTTCustomErrorUnknown = -255,
    uexMQTTCustomErrorSocketError = -6,
    uexMQTTCustomErrorConnectionAlreadyExist = -5,
    uexMQTTCustomErrorConnectionRefused = -4,
    uexMQTTCustomErrorNoResponse = -3,
    uexMQTTCustomErrorInvalidConnackReceived = -2,
    uexMQTTCustomErrorNoConnackReceived = -1,
};


static NSError * uexError(NSError *err){
    if (!err) {
        return nil;
    }
    if (err.code > 0) {
        //MQTT Protocol Error
        return err;
    }
    if ([err.domain isEqual:kUexMQTTErrorDomain]) {
        return err;
    }
    MQTTSessionError errCode = err.code;
    switch (errCode) {
        case MQTTSessionErrorConnectionRefused: {
            return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorConnectionRefused userInfo:err.userInfo];
        }
        case MQTTSessionErrorNoResponse: {
            return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorNoResponse userInfo:err.userInfo];
        }
        case MQTTSessionErrorEncoderNotReady: {
            return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorSocketError userInfo:err.userInfo];
        }
        case MQTTSessionErrorInvalidConnackReceived: {
            return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorInvalidConnackReceived userInfo:err.userInfo];
        }
        case MQTTSessionErrorNoConnackReceived: {
            return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorNoConnackReceived userInfo:err.userInfo];
        }
        default:{
            break;
        }
    }
    return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorUnknown userInfo:@{NSLocalizedDescriptionKey : @"Unknown Error"}];
}

static NSError *connectAlreadyExistError(){
    return [NSError errorWithDomain:kUexMQTTErrorDomain code:uexMQTTCustomErrorConnectionAlreadyExist userInfo:@{NSLocalizedDescriptionKey : @"Connection Already Exist"}];
}

@end
