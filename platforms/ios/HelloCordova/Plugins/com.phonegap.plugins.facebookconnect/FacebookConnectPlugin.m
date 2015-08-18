//
//  FacebookConnectPlugin.m
//  GapFacebookConnect
//
//  Created by Jesse MacFadyen on 11-04-22.
//  Updated by Mathijs de Bruin on 11-08-25.
//  Updated by Christine Abernathy on 13-01-22
//  Copyright 2011 Nitobi, Mathijs de Bruin. All rights reserved.
//

#import "FacebookConnectPlugin.h"

@interface FacebookConnectPlugin ()

@property (strong, nonatomic) NSString *userid;
@property (strong, nonatomic) NSString* loginCallbackId;
@property (strong, nonatomic) NSString* dialogCallbackId;
@property (strong, nonatomic) NSString* graphCallbackId;

@end

@implementation FacebookConnectPlugin



- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView {
    NSLog(@"Init FacebookConnect Session");
    self = (FacebookConnectPlugin *)[super initWithWebView:theWebView];
    self.userid = @"";
  
    _login = [[FBSDKLoginManager alloc] init];
  
  
  
    // Add notification listener for tracking app activity with FB Events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    /*
    // Add notification listener for handleOpenURL
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openURL:)
                                                 name:CDVPluginHandleOpenURLNotification object:nil];
     */

    return self;
}


/*
- (void)openURL:(NSNotification *)notification {
    // NSLog(@"handle url: %@", [notification object]);
    NSURL *url = [notification object];

    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }

    //[FBSession.activeSession handleOpenURL:url];
}
*/

- (void)applicationDidBecomeActive {
    // Call the 'activateApp' method to log an app event for use in analytics and advertising reporting.
    [FBSDKAppEvents activateApp];
}
 

/*
 * Check if a permision is a read permission.
 */

- (BOOL)isPublishPermission:(NSString*)permission {
    return [permission hasPrefix:@"publish"] ||
    [permission hasPrefix:@"manage"] ||
    [permission isEqualToString:@"ads_management"] ||
    [permission isEqualToString:@"create_event"] ||
    [permission isEqualToString:@"rsvp_event"];
}


/*
 * Check if all permissions are read permissions.
 */

- (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions {
    for (NSString *permission in permissions) {
        if ([self isPublishPermission:permission]) {
            return NO;
        }
    }
    return YES;
}


/*
 * Handling facebook login result
 */
- (void)handleFacebookLoginResult:(FBSDKLoginManagerLoginResult *)result
                        loginType:(NSString* ) loginType
                            error:(NSError *)error {
  
  
  NSString *alertMessage = nil;
  if (error) {
    // Process error
    NSLog(@"Facebook login with %@ permission error: %@", loginType, [error userInfo]);
    alertMessage = [NSString stringWithFormat:@"Error. Please try again later. error: %@", [error userInfo]];
    
    if (alertMessage && self.loginCallbackId) {
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:alertMessage];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loginCallbackId];
    }
    
  
  // The user has cancelled a login. You can inspect the error
  // for more context. In the plugin, we will simply ignore it.
  } else if (result.isCancelled) {
    // Handle cancellations
    NSLog(@"Facebook login with %@ permission cancelled", loginType);
    
    alertMessage = @"Permission denied.";
    if (alertMessage && self.loginCallbackId) {
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:alertMessage];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loginCallbackId];
    }
  } else {
    // If you ask for multiple permissions at once, you
    // should check if specific permissions missing
    
    NSLog(@"Facebook login with %@ permission granted: %@", loginType, result.grantedPermissions);
    
    if ([result.grantedPermissions containsObject:@"email"]) {
      FBSDKAccessToken* currentAccessToken = [FBSDKAccessToken currentAccessToken];
      self.userid = (currentAccessToken)?[currentAccessToken userID]:@"";
      
      // Do work
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                    messageAsDictionary:[self responseObject]];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loginCallbackId];
    }
  }

}



- (void)getLoginStatus:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:[self responseObject]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)getAccessToken:(CDVInvokedUrlCommand *)command {
    // Return access token if available
    CDVPluginResult *pluginResult;
  
    FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
  
    // Check if the session is open or not
    if (accessToken) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:
                        [accessToken tokenString]];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:
                        @"Access token is empty"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)logEvent:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 0) {
        // Not enough arguments
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid arguments"];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        return;
    }
    [self.commandDelegate runInBackground:^{
        // For more verbose output on logging uncomment the following:
        // [FBSettings setLoggingBehavior:[NSSet setWithObject:FBLoggingBehaviorAppEvents]];
        NSString *eventName = [command.arguments objectAtIndex:0];
        CDVPluginResult *res;
        NSDictionary *params;
        double value;

        if ([command.arguments count] == 1) {
            [FBSDKAppEvents logEvent:eventName];
        } else {
            // argument count is not 0 or 1, must be 2 or more
            params = [command.arguments objectAtIndex:1];
            if ([command.arguments count] == 2) {
                // If count is 2 we will just send params
                [FBSDKAppEvents logEvent:eventName parameters:params];
            }
            if ([command.arguments count] == 3) {
                // If count is 3 we will send params and a value to sum
                value = [[command.arguments objectAtIndex:2] doubleValue];
                [FBSDKAppEvents logEvent:eventName valueToSum:value parameters:params];
            }
        }
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}



- (void)logPurchase:(CDVInvokedUrlCommand *)command {
    /*
     While calls to logEvent can be made to register purchase events,
     there is a helper method that explicitly takes a currency indicator.
     */
 
    CDVPluginResult *res;
    if ([command.arguments count] != 2) {
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid arguments"];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        return;
    }
    double value = [[command.arguments objectAtIndex:0] doubleValue];
    NSString *currency = [command.arguments objectAtIndex:1];
    [FBSDKAppEvents logPurchase:value currency:currency];

    res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}




- (void)login:(CDVInvokedUrlCommand *)command {
    BOOL permissionsAllowed = YES;
    NSString *permissionsErrorMessage = @"";
    NSArray *permissions = nil;
    CDVPluginResult *pluginResult;
    if ([command.arguments count] > 0) {
        permissions = command.arguments;
    }
    if (permissions == nil) {
        // We need permissions
        permissionsErrorMessage = @"No permissions specified at login";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:permissionsErrorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    // save the callbackId for the login callback
    self.loginCallbackId = command.callbackId;
  
  
    // Check if the session is open or not
    if (![FBSDKAccessToken currentAccessToken]) {
        // Reauthorize if the session is already open.
        // In this instance we can ask for publish type
        // or read type only if taking advantage of iOS6.
        // To mix both, we'll use deprecated methods
        BOOL publishPermissionFound = NO;
        BOOL readPermissionFound = NO;
        
        for (NSString *p in permissions) {
            if ([self isPublishPermission:p]) {
                publishPermissionFound = YES;
            } else {
                readPermissionFound = YES;
            }
            
            // If we've found one of each we can stop looking.
            if (publishPermissionFound && readPermissionFound) {
                break;
            }
        }
        
        if (publishPermissionFound && readPermissionFound) {
          // Mix of permissions, not allowed
          permissionsAllowed = NO;
          permissionsErrorMessage = @"Your app can't ask for both read and write permissions.";
        } else if (publishPermissionFound) {
          // Only publish permissions
          [_login logInWithPublishPermissions:permissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            [self handleFacebookLoginResult:result loginType:@"publish" error:error];
          }];
          
        } else {
          // Only read permissions
          [_login logInWithReadPermissions:permissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            [self handleFacebookLoginResult:result loginType:@"read" error:error];
          }];

        }
  
    } else {
        // Initial log in, can only ask to read
        // type permissions
        if ([self areAllPermissionsReadPermissions:permissions]) {
            [_login logInWithReadPermissions:permissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
              [self handleFacebookLoginResult:result loginType:@"read" error:error];
            }];
          
        } else {
            permissionsAllowed = NO;
            permissionsErrorMessage = @"You can only ask for read permissions initially";
        }
    }
  
    
    if (!permissionsAllowed) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:permissionsErrorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loginCallbackId];
    }
  
}

- (void) logout:(CDVInvokedUrlCommand*)command
{
    [_login logOut];
  
    // Else just return OK we are already logged out
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) showDialog:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult;
    // Save the callback ID
    self.dialogCallbackId = command.callbackId;
    
    NSMutableDictionary *options = [[command.arguments lastObject] mutableCopy];
    NSString* method = [[NSString alloc] initWithString:[options objectForKey:@"method"]];
    if ([options objectForKey:@"method"]) {
        [options removeObjectForKey:@"method"];
    }
    __block BOOL paramsOK = YES;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            params[key] = obj;
        } else {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization
                                dataWithJSONObject:obj
                                options:0
                                error:&error];
            if (!jsonData) {
                paramsOK = NO;
                // Error
                *stop = YES;
            }
            params[key] = [[NSString alloc]
                           initWithData:jsonData
                           encoding:NSUTF8StringEncoding];
        }
    }];
  
  
    FBSDKAccessToken* currentAccessToken = [FBSDKAccessToken currentAccessToken];
    if(!currentAccessToken || ![[currentAccessToken permissions] containsObject:@"publish"]) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Messaging unavailable."];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:self.dialogCallbackId];
      return;
    }

  
  
    if (!paramsOK) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:@"Error completing dialog."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.dialogCallbackId];
    } else {
        // Check method
        if ([method isEqualToString:@"send"]) {
            // Send private message dialog
            // Create native params
            FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
            content.contentURL = [NSURL URLWithString:[params objectForKey:@"link"]];
            content.contentTitle = [params objectForKey:@"name"];
            content.imageURL = [NSURL URLWithString:[params objectForKey:@"picture"]];
            content.contentDescription = [params objectForKey:@"description"];

          
          
    
            [FBSDKShareDialog showFromViewController: [self viewController]
                                         withContent:content
                                            delegate:self];
           
          
            return;
        } else if ([method isEqualToString:@"share"] || [method isEqualToString:@"share_open_graph"]) {
            // Create native params
            FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
            content.contentURL = [NSURL URLWithString:[params objectForKey:@"href"]];
            content.contentTitle = [params objectForKey:@"name"];
            content.imageURL = [NSURL URLWithString:[params objectForKey:@"picture"]];
            content.contentDescription = [params objectForKey:@"description"];


            [FBSDKShareAPI shareWithContent:content delegate:self];
            return;
        } // Else we run through into the WebDialog
    }
  
  
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentTitle = [params objectForKey:@"name"];
    content.contentDescription = [params objectForKey:@"description"];
    [FBSDKShareAPI shareWithContent:content delegate:self];


  
  
    NSLog(@"Unsupported sharing method: %@", method);
    NSLog(@"Unsupported sharing params: %@", params);
  
    // For optional ARC support
    #if __has_feature(objc_arc)
    #else
        [method release];
        [params release];
        [options release];
    #endif
}

/***** facebook share dialog delegate ****/

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
  NSLog(@"Facebook share dialog is success!");
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:self.dialogCallbackId];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
   NSLog(@"Facebook share dialog is error: %@", [error userInfo]);
  
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:
                                   CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Error: %@", error.description]];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:self.dialogCallbackId];
  
}

/*!
 @abstract Sent to the delegate when the sharer is cancelled.
 @param sharer The FBSDKSharing that completed.
 */
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
   NSLog(@"Facebook share dialog is canceled");
  
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:
                                   CDVCommandStatus_ERROR messageAsString:@"User cancelled."];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:self.dialogCallbackId];
}



- (void) graphApi:(CDVInvokedUrlCommand *)command
{
    // Save the callback ID
    self.graphCallbackId = command.callbackId;
    
    NSString *graphPath = [command argumentAtIndex:0];
    NSArray *permissionsNeeded = [command argumentAtIndex:1];
    
    // We will store here the missing permissions that we will have to request
    NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
  
  
    FBSDKAccessToken* currentAccessToken = [FBSDKAccessToken currentAccessToken];
    if(!currentAccessToken) {
      NSLog(@"Graph api without access token, unable to preceed");
      return;
    }
  
  
  
    // Check if all the permissions we need are present in the user's current permissions
    // If they are not present add them to the permissions to be requested
    for (NSString *permission in permissionsNeeded){
        if (![[currentAccessToken permissions] containsObject:permission]) {
            [requestPermissions addObject:permission];
        }
    }
    
    // If we have permissions to request
    if ([requestPermissions count] > 0){
        // Ask for the missing permissions
        [_login logInWithReadPermissions:requestPermissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
           // Permission granted
          if(!error) {
            // We can request the user information
            [self makeGraphCall:graphPath];
          } else {
            // error occured
            NSLog(@"Graph api permission request error occured: %@", [error userInfo]);
            [self handleFacebookLoginResult:result loginType:@"graph_api" error:error];
          }
        }];
      
      
    } else {
        // Permissions are present
        // We can request the user information
        [self makeGraphCall:graphPath];
    }
}


- (void) makeGraphCall:(NSString *)graphPath
{
    
    NSLog(@"Graph Path = %@", graphPath);
    FBSDKAccessToken* currentAccessToken = [FBSDKAccessToken currentAccessToken];
    if(!currentAccessToken) {
      NSLog(@"Graph api make graph call without access token, unable to preceed");
      return;
    }
  
   [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:nil]
    startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        CDVPluginResult* pluginResult = nil;
        if (!error) {
          NSDictionary *response = (NSDictionary *) result;
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
        } else {
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                        messageAsString:[error localizedDescription]];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.graphCallbackId];
   }];
  
  
  
}

- (NSDictionary *)responseObject {
    NSString *status = @"unknown";
    NSString *expiresIn = @"0";
    NSDictionary *sessionDict = nil;

    FBSDKAccessToken* currentAccessToken = [FBSDKAccessToken currentAccessToken];
  
    if(currentAccessToken) {
    
      NSTimeInterval expiresTimeInterval = [[currentAccessToken expirationDate] timeIntervalSinceNow];
      if (expiresTimeInterval > 0) {
        expiresIn = [NSString stringWithFormat:@"%0.0f", expiresTimeInterval];
      }

      status = @"connected";
      sessionDict = @{
                      @"accessToken" : [currentAccessToken tokenString],
                      @"expiresIn" : expiresIn,
                      @"secret" : @"...",
                      @"session_key" : [NSNumber numberWithBool:YES],
                      @"sig" : @"...",
                      @"userID" : self.userid
                      };
    
    }
  
    NSMutableDictionary *statusDict = [NSMutableDictionary dictionaryWithObject:status forKey:@"status"];
    if (nil != sessionDict) {
        [statusDict setObject:sessionDict forKey:@"authResponse"];
    }
        
    return statusDict;
}


/**
 * A method for parsing URL parameters.
 */

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSString *regexStr = @"^(.+)\\[(.*)\\]$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:0 error:nil];

    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [pairs enumerateObjectsUsingBlock:
     ^(NSString *pair, NSUInteger idx, BOOL *stop) {
         NSArray *kv = [pair componentsSeparatedByString:@"="];
         NSString *key = [kv[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         NSString *val = [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

         NSArray *matches = [regex matchesInString:key options:0 range:NSMakeRange(0, [key length])];
         if ([matches count] > 0) {
             for (NSTextCheckingResult *match in matches) {

                 NSString *newKey = [key substringWithRange:[match rangeAtIndex:1]];

                 if ([[params allKeys] containsObject:newKey]) {
                     NSMutableArray *obj = [params objectForKey:newKey];
                     [obj addObject:val];
                     [params setObject:obj forKey:newKey];
                 } else {
                     NSMutableArray *obj = [NSMutableArray arrayWithObject:val];
                     [params setObject:obj forKey:newKey];
                 }
             }
         } else {
             params[key] = val;
         }
         // params[kv[0]] = val;
    }];
    return params;
}


@end
