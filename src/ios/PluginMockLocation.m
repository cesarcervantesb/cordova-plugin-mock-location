/********* CordovaDetectMockLocationPlugin.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <CoreLocation/CoreLocation.h>

@interface PluginMockLocation : CDVPlugin <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CDVInvokedUrlCommand *locationCommand;

- (void)detectMockLocation:(CDVInvokedUrlCommand *)command;
@end

@implementation PluginMockLocation

- (void)pluginInitialize {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
}

- (void)checkMockLocation:(CDVInvokedUrlCommand *)command {
    self.locationCommand = command;

    // Check if location services are enabled
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Location services are not enabled.");
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Location services are not enabled."] callbackId:command.callbackId];
        return;
    }

    // Check authorization status
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    NSLog(@"Authorization status: %ld", (long)authorizationStatus);
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        NSLog(@"Location authorization granted. Starting location updates.");
        // Start updating location
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    } else if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Requesting location authorization.");
        // Request location authorization
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        NSLog(@"Location access not authorized.");
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Location access not authorized."] callbackId:command.callbackId];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.locationCommand) {
        NSLog(@"No active call to resolve.");
        return;
    }
    CLLocation *currentLocation = [locations lastObject];
    // NSUInteger nLocations = locations.count;
    if (!currentLocation) {
        NSLog(@"Unable to fetch current location.");
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to fetch current location."] callbackId:self.locationCommand.callbackId];
        return;
    }

    NSLog(@"Location updated: %@", currentLocation);

    if (@available(iOS 15.0, *)) {
        BOOL isSimulated = currentLocation.sourceInformation.isSimulatedBySoftware;
        BOOL isProducedByAccessory = currentLocation.sourceInformation.isProducedByAccessory;

        NSLog(@"isSimulatedBySoftware: %d", isSimulated);
        NSLog(@"isProducedByAccessory: %d", isProducedByAccessory);
        
        BOOL isMockLocation = (isSimulated || isProducedByAccessory);

        NSString* args = [self.locationCommand.arguments objectAtIndex:0];
        
        NSDictionary *mockLocation = [[NSDictionary alloc] init];
        NSDictionary *gpsLocation = [[NSDictionary alloc] init];
        if (isMockLocation && [args  isEqual: @((BOOL)YES)]) {
            double latitude = currentLocation.coordinate.latitude;
            double longitude = currentLocation.coordinate.longitude;
            double altitude = currentLocation.altitude;
            
            mockLocation = @{@"latitude": @(latitude), @"longitude": @(longitude), @"altitude": @(altitude)};
        }

        // NSDictionary *result = @{@"isMockLocation": @(isMockLocation), @"mockLocation": mockLocation, @"gpsLocation": gpsLocation, @"nLocations": @(nLocations)};
        NSDictionary *result = @{@"isMockLocation": @(isMockLocation), @"mockLocation": mockLocation, @"gpsLocation": gpsLocation};
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:self.locationCommand.callbackId];
    } else {
        NSDictionary *result = @{@"isMockLocation": @(NO)};
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:self.locationCommand.callbackId];
    }

    [self.locationManager stopUpdatingLocation];
    self.locationCommand = nil;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (!self.locationCommand) {
        NSLog(@"No active call to handle authorization change.");
        return;
    }
    NSLog(@"Authorization status changed: %ld", (long)status);
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        NSLog(@"Authorization granted. Starting location updates.");
        // Start updating location
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        NSLog(@"Location access not authorized.");
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Location access not authorized."] callbackId:self.locationCommand.callbackId];
    }
}

@end
