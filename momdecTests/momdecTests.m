//
//  momdecTests.m
//  momdecTests
//
//  Created by Tom Harrington on 4/9/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "momdecTests.h"
#import <CoreData/CoreData.h>
#import "NSManagedObjectModel+xmlElement.h"

@implementation momdecTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testDecompile
{
    NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];

    // Get the compiled model and decompile it.
    NSURL *momURL = [selfBundle URLForResource:@"momdecTests" withExtension:@"momd"];
    NSManagedObjectModel *compiledModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    NSXMLDocument *decompiledModelDocument = [compiledModel xmlDocument];
    
    // Write the decompiled model to a temprary file
    NSString *momdecTestDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"momdecTests-%d", getpid()]];
    NSString *decompiledModelContainerPath = [momdecTestDir stringByAppendingPathComponent:@"momdecTests.xcdatamodel"];
    [[NSFileManager defaultManager] createDirectoryAtPath:decompiledModelContainerPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSData *decompiledModelXMLData = [decompiledModelDocument XMLDataWithOptions:NSXMLNodePrettyPrint|NSXMLNodeCompactEmptyElement|NSXMLDocumentIncludeContentTypeDeclaration];
    NSString *decompiledModelPath = [decompiledModelContainerPath stringByAppendingPathComponent:@"contents"];
    [decompiledModelXMLData writeToFile:decompiledModelPath atomically:YES];

    // Compile the temporary file copy
    NSString *recompiledModelPath = [momdecTestDir stringByAppendingPathComponent:@"momdecTests.momd"];
    NSTask *compileTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/xcrun" arguments:@[@"momc", decompiledModelContainerPath, recompiledModelPath]];
    [compileTask waitUntilExit];
    
    // Load the recompiled model
    NSManagedObjectModel *recompiledModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:recompiledModelPath]];
    
    // Compare the original compiled model with the recompiled version.
    NSDictionary *originalEntities = [compiledModel entitiesByName];
    NSDictionary *recompiledEntities = [recompiledModel entitiesByName];
    
    for (NSEntityDescription *originalEntityName in originalEntities) {
        NSEntityDescription *originalEntity = [originalEntities objectForKey:originalEntityName];
        NSEntityDescription *recompiledEntity = [recompiledEntities objectForKey:originalEntityName];
        if (![originalEntity isEqual:recompiledEntity]) {
            STFail(@"Entities do not match: %@", originalEntityName);
        }
    }
}

@end