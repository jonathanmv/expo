//  Copyright © 2021 650 Industries. All rights reserved.

#import <EXUpdates/EXUpdatesBuildData.h>
#import <EXUpdates/EXUpdatesDatabaseUtils.h>

NS_ASSUME_NONNULL_BEGIN

@implementation EXUpdatesBuildData

+ (void)ensureBuildDataIsConsistent:(EXUpdatesDatabase *)database config:(EXUpdatesConfig *)config error:(NSError ** _Nullable)error;
{
  if (!config.scopeKey) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"expo-updates was configured with no scope key. Make sure a valid URL is configured under EXUpdatesURL."
                                 userInfo:@{}];
  }
  
  NSDictionary *staticBuildData = [database staticBuildDataWithScopeKey:config.scopeKey error:nil];
  
  if(staticBuildData == nil){
    [database setStaticBuildData:[self getBuildDataFromConfig:config] withScopeKey:config.scopeKey error:nil];
  } else {
    NSDictionary *impliedStaticBuildData = [self getBuildDataFromConfig:config];
    BOOL isConsistent = [staticBuildData isEqualToDictionary:impliedStaticBuildData];
    if (!isConsistent){
      NSError *clearAllUpdatesError;
      [self clearAllUpdatesFromDatabase:database config:config];
      if(!clearAllUpdatesError){
        [database setStaticBuildData:[self getBuildDataFromConfig:config] withScopeKey:config.scopeKey error:nil];
      }
    }
  }
}

+ (nullable NSDictionary *)getBuildDataFromConfig:(EXUpdatesConfig *)config;
{
  return @{
    @"EXUpdatesURL":config.updateUrl.absoluteString,
    @"EXUpdatesReleaseChannel":config.releaseChannel,
    @"EXUpdatesRequestHeaders":config.requestHeaders,
  };
}

+ (void)clearAllUpdatesFromDatabase:(EXUpdatesDatabase *)database
                             config:(EXUpdatesConfig *)config
{
  NSError *dbError;
    NSArray<EXUpdatesUpdate *> *allUpdates = [database allUpdatesWithConfig:config error:&dbError];
    if (allUpdates || !dbError) {
      [database deleteUpdates:allUpdates error:&dbError];
    }
  if (dbError){
    NSLog(@"Error clearing all updates from database: %@", dbError);
  }
}

@end

NS_ASSUME_NONNULL_END
