/**
 *
 *	@file   	: EUExMQTT.m  in EUExMQTT
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

#import "EUExMQTT.h"
#import "uexMQTTClient.h"
#import "JSON.h"
@implementation EUExMQTT


#define UEX_MQTT_STR_DEF(dict,key) NSString *key = strValue(dict[@metamacro_stringify(key)])
#define UEX_MQTT_BOOL_DEF(dict,key) BOOL key = boolValue(dict[@metamacro_stringify(key)])
#define UEX_MQTT_INT_DEF(dict,key) NSInteger key = [dict[@metamacro_stringify(key)] integerValue]

- (void)test:(NSMutableArray *)inArguments{
    NSLog(@"test!!");
    [uexMQTTClient init];
    
    [UEX_MQTT_CLIENT connectWithServer:@"120.26.77.175" port:1886 username:@"test1" password:@"test1" keepAliveInterval:30 clientId:@"11111" willMsg:nil willTopic:nil willQos:0 willRetainFlag:NO];
}

- (void)init:(NSMutableArray *)inArguments{
    [uexMQTTClient init];
}


- (void)connect:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = inArguments[0];
    if ([info isKindOfClass:[NSString class]]) {
        info = [info JSONValue];
    }
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    UEX_MQTT_STR_DEF(info, clientId);
    UEX_MQTT_STR_DEF(info, server);
    UEX_MQTT_STR_DEF(info, username);
    UEX_MQTT_STR_DEF(info, password);
    UEX_MQTT_INT_DEF(info, keepAliveInterval);
    UEX_MQTT_INT_DEF(info, port);
    
    NSDictionary *LMT = nil;
    if ([info[@"LMT"] isKindOfClass:[NSDictionary class]] && boolValue(info[@"LMT"][@"enable"]) ) {
        LMT = info[@"LMT"];
    }
    UEX_MQTT_STR_DEF(LMT, topic);
    UEX_MQTT_BOOL_DEF(LMT, retainFlag);
    UEX_MQTT_INT_DEF(LMT, qos);
    NSData * data = [strValue(LMT[@"data"]) dataUsingEncoding:NSUTF8StringEncoding];
    [UEX_MQTT_CLIENT connectWithServer:server port:port username:username password:password keepAliveInterval:keepAliveInterval clientId:clientId willMsg:data willTopic:topic willQos:qos willRetainFlag:retainFlag];
}

- (void)subscribe:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = inArguments[0];
    if ([info isKindOfClass:[NSString class]]) {
        info = [info JSONValue];
    }
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    UEX_MQTT_STR_DEF(info, topic);
    UEX_MQTT_INT_DEF(info, qos);
    [UEX_MQTT_CLIENT subscribeTopic:topic qos:qos];
}

- (void)unsubscribe:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = inArguments[0];
    if ([info isKindOfClass:[NSString class]]) {
        info = [info JSONValue];
    }
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    UEX_MQTT_STR_DEF(info, topic);
    [UEX_MQTT_CLIENT unsubscibeTopic:topic];
}

- (void)publish:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = inArguments[0];
    if ([info isKindOfClass:[NSString class]]) {
        info = [info JSONValue];
    }
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    NSString *identifier = strValue(info[@"id"]);
    UEX_MQTT_STR_DEF(info, topic);
    UEX_MQTT_STR_DEF(info, data);
    UEX_MQTT_BOOL_DEF(info, retainFlag);
    UEX_MQTT_INT_DEF(info, qos);
    [UEX_MQTT_CLIENT publishDataString:data onTopic:topic qos:qos identifier:identifier retainFlag:retainFlag];
}
- (void)disconnect:(NSMutableArray *)inArguments{
    [UEX_MQTT_CLIENT disconnect];
}

static NSString * strValue(id obj){
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj stringValue];
    }
    return nil;
}

static BOOL boolValue(id obj){
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
        return [obj boolValue];
    }
    return NO;
}



@end
