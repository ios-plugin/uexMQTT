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

@implementation EUExMQTT


#define UEX_MQTT_STR_DEF(dict,key) NSString *key = stringArg(dict[@metamacro_stringify(key)])
#define UEX_MQTT_BOOL_DEF(dict,key) BOOL key = numberArg(dict[@metamacro_stringify(key)]).boolValue
#define UEX_MQTT_INT_DEF(dict,key) NSInteger key = numberArg(dict[@metamacro_stringify(key)]).integerValue


- (void)init:(NSMutableArray *)inArguments{
    [uexMQTTClient init];
}


- (void)connect:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;

    UEX_MQTT_STR_DEF(info, clientId);
    UEX_MQTT_STR_DEF(info, server);
    UEX_MQTT_STR_DEF(info, username);
    UEX_MQTT_STR_DEF(info, password);
    UEX_MQTT_INT_DEF(info, keepAliveInterval);
    UEX_MQTT_INT_DEF(info, port);
    
    NSDictionary *LMT = dictionaryArg(info[@"LMT"]);
    if (!numberArg(LMT[@"enable"]).boolValue) {
        LMT = nil;
    }
    UEX_MQTT_STR_DEF(LMT, topic);
    UEX_MQTT_BOOL_DEF(LMT, retainFlag);
    UEX_MQTT_INT_DEF(LMT, qos);
    NSData * data = [stringArg(LMT[@"data"]) dataUsingEncoding:NSUTF8StringEncoding];
    [UEX_MQTT_CLIENT connectWithServer:server port:port username:username password:password keepAliveInterval:keepAliveInterval clientId:clientId willMsg:data willTopic:topic willQos:qos willRetainFlag:retainFlag callback:callback];
}

- (void)subscribe:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    
    UEX_MQTT_STR_DEF(info, topic);
    UEX_MQTT_INT_DEF(info, qos);
    [UEX_MQTT_CLIENT subscribeTopic:topic qos:qos callback:callback];
}

- (void)unsubscribe:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    
    UEX_MQTT_STR_DEF(info, topic);
    [UEX_MQTT_CLIENT unsubscibeTopic:topic callback:callback];
}

- (NSNumber *)publish:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    
    NSString *identifier = stringArg(info[@"id"]);
    UEX_MQTT_STR_DEF(info, topic);
    UEX_MQTT_STR_DEF(info, data);
    UEX_MQTT_BOOL_DEF(info, retainFlag);
    UEX_MQTT_INT_DEF(info, qos);
    UInt16 mid = [UEX_MQTT_CLIENT publishDataString:data onTopic:topic qos:qos identifier:identifier retainFlag:retainFlag callback:callback];
    return @(mid);
}
- (void)disconnect:(NSMutableArray *)inArguments{
    ACArgsUnpack(ACJSFunctionRef *callback) = inArguments;
    [UEX_MQTT_CLIENT disconnect];
    [callback executeWithArguments:ACArgsPack(kUexNoError)];
}




@end
