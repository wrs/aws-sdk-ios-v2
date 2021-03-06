/*
 * Copyright 2010-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AIInsightsContextBuilder.h"
#import "AWSMobileAnalyticsContext.h"
#import "AWSMobileAnalyticsSDKInfo.h"
#import "AWSMobileAnalyticsClientContext.h"

@interface AIInsightsContextBuilder()
@property(nonatomic) NSString* appKey;
@property(nonatomic) NSString* privateKey;
@property(nonatomic) NSString * credentials;
@property(nonatomic) NSString* sdkName;
@property(nonatomic) NSString* sdkVersion;
@property(nonatomic) NSString* uniqueId;
@property(nonatomic) NSString* platformVersion;
@property(nonatomic) NSString* platform;
@property(nonatomic) NSString* manufacturer;
@property(nonatomic) NSString* model;
@property(nonatomic) NSString* locale;
@property(nonatomic) NSString* appVersion;
@property(nonatomic) NSString* appBuild;
@property(nonatomic) NSString* appPackageName;
@property(nonatomic) NSString* appName;

@property(nonatomic) id<AWSMobileAnalyticsConfiguration> configuration;
@property(nonatomic) id<AWSMobileAnalyticsHttpClient> httpClient;
@property(nonatomic) id<AWSMobileAnalyticsPreferences> preferences;
@property(nonatomic) id<AWSMobileAnalyticsFileManager> fileManager;
@property(nonatomic) id<AWSMobileAnalyticsConnectivity> connectivity;
@property(nonatomic) id<AWSMobileAnalyticsLifeCycleManager> lifeCycleManager;
@property(nonatomic) id<AWSMobileAnalyticsClientContext> clientContext;
@end

@implementation AIInsightsContextBuilder

+(AIInsightsContextBuilder*)builder
{
    return [[self alloc] init];
}


-(id)init
{
    if(self = [super init])
    {
        self.appKey = @"";
        self.privateKey = @"";
        self.sdkName = @"";
        self.sdkVersion = @"";
        self.uniqueId = @"";
        self.credentials = nil;
        self.platformVersion = nil;
        self.platform = nil;
        self.manufacturer = nil;
        self.model = nil;
        self.locale = nil;
        self.appVersion = nil;
        self.appBuild = nil;
        self.appPackageName = nil;
        self.clientContext = nil;

        
        self.configuration = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsConfiguration)];
        self.httpClient = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsHttpClient)];
        self.preferences = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsPreferences)];
        self.fileManager = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsFileManager)];
        self.connectivity = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsConnectivity)];
        
    }
    return self;
}

// returns back a mock
-(id<AWSMobileAnalyticsContext>)build
{
    id mockCredentials = self.credentials;
    if(mockCredentials == nil)
    {
        mockCredentials = self.appKey;
    }
    
    id clientContext = self.clientContext;
    if(clientContext == nil) {
        clientContext = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsClientContext)];
        [[[clientContext stub] andReturn:self.appVersion] appVersion];
        [[[clientContext stub] andReturn:self.appBuild] appBuild];
        [[[clientContext stub] andReturn:self.appPackageName] appPackageName];
        [[[clientContext stub] andReturn:self.appName] appName];
        [[[clientContext stub] andReturn:self.manufacturer] deviceManufacturer];
        [[[clientContext stub] andReturn:self.platform] devicePlatform];
        [[[clientContext stub] andReturn:self.platformVersion] devicePlatformVersion];
        [[[clientContext stub] andReturn:@"1.XX"] deviceModelVersion];
        [[[clientContext stub] andReturn:self.model] deviceModel];
        [[[clientContext stub] andReturn:self.locale] deviceLocale];
    }

    id mockSDKInfo = [OCMockObject niceMockForClass:[AWSMobileAnalyticsSDKInfo class]];
    [[[mockSDKInfo stub] andReturn:self.sdkName] sdkName];
    [[[mockSDKInfo stub] andReturn:self.sdkVersion] sdkVersion];
    
    id mockSystem = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsSystem)];
    [[[mockSystem stub] andReturn:self.fileManager] fileManager];
    [[[mockSystem stub] andReturn:self.preferences] preferences];
    [[[mockSystem stub] andReturn:self.connectivity] connectivity];
    [[[mockSystem stub] andReturn:self.lifeCycleManager] lifeCycleManager];
    
    id mockContext = [OCMockObject niceMockForProtocol:@protocol(AWSMobileAnalyticsContext)];
    [[[mockContext stub] andReturn:mockSDKInfo] sdkInfo];
    [[[mockContext stub] andReturn:mockCredentials] identifier];
    [[[mockContext stub] andReturn:mockSystem] system];
    [[[mockContext stub] andReturn:clientContext] clientContext];
    [[[mockContext stub] andReturn:self.configuration] configuration];
    [[[mockContext stub] andReturn:self.uniqueId] uniqueId];
    [[[mockContext stub] andReturn:self.httpClient] httpClient];

    
    return mockContext;
}

-(AIInsightsContextBuilder*)withAppKey:(NSString*)appKey
{
    self.appKey = appKey;
    return self;
}

-(AIInsightsContextBuilder*)withPrivateKey:(NSString*)privateKey
{
    self.privateKey = privateKey;
    return self;
}

-(AIInsightsContextBuilder*)withCredentials:(NSString *)credentials
{
    self.credentials = credentials;
    return self;
}

-(AIInsightsContextBuilder*)withSdkName:(NSString*)sdkName andSDKVersion:(NSString*)sdkVersion
{
    self.sdkName = sdkName;
    self.sdkVersion = sdkVersion;
    return self;
}

-(AIInsightsContextBuilder*)withPlatformVersion:(NSString*)platformVersion
                                   withPlatform:(NSString*)platform
                               withManufacturer:(NSString*)manufacturer
                                      withModel:(NSString*)model
                                     withLocale:(NSString *)locale
{
    self.platformVersion = platformVersion;
    self.platform = platform;
    self.manufacturer = manufacturer;
    self.model = model;
    self.locale = locale;
    return self;
}

-(AIInsightsContextBuilder*)withApplicationVersion:(NSString*)appVersion
                                         withBuild:(NSString*)appBuild
                                   withPackageName:(NSString*)appPackageName
{
    return [self withApplicationVersion:appVersion
                              withBuild:appBuild
                        withPackageName:appPackageName
                            withAppName:@"APP-NAME"];
}

-(AIInsightsContextBuilder*)withApplicationVersion:(NSString*)appVersion
                                         withBuild:(NSString*)appBuild
                                   withPackageName:(NSString*)appPackageName
                                       withAppName:(NSString*)appName
{
    self.appVersion = appVersion;
    self.appBuild = appBuild;
    self.appPackageName = appPackageName;
    self.appName = appName;
    return self;
}



-(AIInsightsContextBuilder*)withUniqueId:(NSString*)uniqueId
{
    self.uniqueId = uniqueId;
    return self;
}



-(AIInsightsContextBuilder*)withConfiguration:(id<AWSMobileAnalyticsConfiguration>)configuration
{
    self.configuration = configuration;
    return self;
}

-(AIInsightsContextBuilder*)withHttpClient:(id<AWSMobileAnalyticsHttpClient>)httpClient
{
    self.httpClient = httpClient;
    return self;
}

-(AIInsightsContextBuilder*)withPreferences:(id<AWSMobileAnalyticsPreferences>)preferences
{
    self.preferences = preferences;
    return self;
}

-(AIInsightsContextBuilder*)withLifeCycleManager:(id<AWSMobileAnalyticsLifeCycleManager>)lifeCycleManager
{
    self.lifeCycleManager = lifeCycleManager;
    return self;
}

-(AIInsightsContextBuilder*)withFileManager:(id<AWSMobileAnalyticsFileManager>)fileManager
{
    self.fileManager = fileManager;
    return self;
}


-(AIInsightsContextBuilder*)withConnectivity:(id<AWSMobileAnalyticsConnectivity>)connectivity
{
    self.connectivity = connectivity;
    return self;
}

@end
