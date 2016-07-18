/**
 *
 *	@file   	: uexMQTTClient.h  in EUExMQTT
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
 
#import <Foundation/Foundation.h>
#import <MQTTClient/MQTTClient.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#define UEX_MQTT_CLIENT ([uexMQTTClient sharedClient])


@interface uexMQTTClient : NSObject




+ (instancetype)sharedClient;

+ (void)init;


- (void)connectWithServer:(NSString *)server
                     port:(UInt16)port
                 username:(NSString *)username
                 password:(NSString *)password
        keepAliveInterval:(UInt16)keepAliveInterval
                 clientId:(NSString *)clientId
                  willMsg:(NSData *)willMsg
                willTopic:(NSString *)willTopic
                  willQos:(MQTTQosLevel)willQos
           willRetainFlag:(BOOL)willRetainFlag;

- (void)disconnect;

- (void)publishDataString:(NSString *)dataStr
                  onTopic:(NSString *)topic
                      qos:(MQTTQosLevel)qos
               identifier:(NSString *)identifier
               retainFlag:(BOOL)retainFlag;

- (void)subscribeTopic:(NSString *)topic qos:(MQTTQosLevel)qos;

- (void)unsubscibeTopic:(NSString *)topic;

@end
