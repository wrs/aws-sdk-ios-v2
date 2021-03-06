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

#if AWS_TEST_KINESIS

#import <XCTest/XCTest.h>
#import "Kinesis.h"
#import "AWSTestUtility.h"

NSString *const AWSKinesisTestStream = @"AWSSDKForiOSv2Test";

@interface AWSKinesisTests : XCTestCase

@end

@implementation AWSKinesisTests

static NSString *testStreamName = nil;

+ (void)setUp {
    [super setUp];
    [AWSTestUtility setupCognitoCredentialsProvider];

    NSTimeInterval timeIntervalSinceReferenceDate = [NSDate timeIntervalSinceReferenceDate];
    testStreamName = [NSString stringWithFormat:@"%@-%f", AWSKinesisTestStream, timeIntervalSinceReferenceDate];

    [[self createTestStream] waitUntilFinished];
}

+ (void)tearDown {
    [[self deleteTestStream] waitUntilFinished];
    [super tearDown];
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

+ (BFTask *)createTestStream {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    AWSKinesisCreateStreamInput *createStreamInput = [AWSKinesisCreateStreamInput new];
    createStreamInput.streamName = testStreamName;
    createStreamInput.shardCount = @1;

    return [[kinesis createStream:createStreamInput] continueWithSuccessBlock:^id(BFTask *task) {
        return [self waitForStreamToBeReady];
    }];
}

+ (BFTask *)waitForStreamToBeReady {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    AWSKinesisDescribeStreamInput *describeStreamInput = [AWSKinesisDescribeStreamInput new];
    describeStreamInput.streamName = testStreamName;

    return [[kinesis describeStream:describeStreamInput] continueWithSuccessBlock:^id(BFTask *task) {
        AWSKinesisDescribeStreamOutput *describeStreamOutput = task.result;
        if (describeStreamOutput.streamDescription.streamStatus != AWSKinesisStreamStatusActive) {
            sleep(10);
            return [self waitForStreamToBeReady];
        }

        return nil;
    }];
}

+ (BFTask *)deleteTestStream {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    AWSKinesisDeleteStreamInput *deleteStreamInput = [AWSKinesisDeleteStreamInput new];
    deleteStreamInput.streamName = testStreamName;

    return [kinesis deleteStream:deleteStreamInput];
}

- (void)testListStreams {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    AWSKinesisListStreamsInput *listStreamsInput = [AWSKinesisListStreamsInput new];
    [[[kinesis listStreams:listStreamsInput] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }

        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSKinesisListStreamsOutput class]]);
            AWSKinesisListStreamsOutput *listStreamsOutput = task.result;
            XCTAssertNotNil(listStreamsOutput.streamNames);
        }

        return nil;
    }] waitUntilFinished];
}

- (void)testAll {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    NSMutableArray *tasks = [NSMutableArray new];

    for (int32_t i = 0; i < 100; i++) {
        AWSKinesisPutRecordInput *putRecordInput = [AWSKinesisPutRecordInput new];
        putRecordInput.streamName = testStreamName;
        putRecordInput.data = [[NSString stringWithFormat:@"TestString-%02d", i] dataUsingEncoding:NSUTF8StringEncoding];
        putRecordInput.partitionKey = @"test-partition-key";

        [tasks addObject:[kinesis putRecord:putRecordInput]];
    }

    [[[[[[BFTask taskForCompletionOfAllTasks:tasks] continueWithSuccessBlock:^id(BFTask *task) {
        sleep(10);
        AWSKinesisDescribeStreamInput *describeStreamInput = [AWSKinesisDescribeStreamInput new];
        describeStreamInput.streamName = testStreamName;
        return [kinesis describeStream:describeStreamInput];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        AWSKinesisDescribeStreamOutput *describeStreamOutput = task.result;
        XCTAssertTrue(1 == [describeStreamOutput.streamDescription.shards count]);
        AWSKinesisShard *shard = describeStreamOutput.streamDescription.shards[0];

        AWSKinesisGetShardIteratorInput *getShardIteratorInput = [AWSKinesisGetShardIteratorInput new];
        getShardIteratorInput.streamName = testStreamName;
        getShardIteratorInput.shardId = shard.shardId;
        getShardIteratorInput.shardIteratorType = AWSKinesisShardIteratorTypeAtSequenceNumber;
        getShardIteratorInput.startingSequenceNumber = shard.sequenceNumberRange.startingSequenceNumber;

        return [kinesis getShardIterator:getShardIteratorInput];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        AWSKinesisGetShardIteratorOutput *getShardIteratorOutput = task.result;

        AWSKinesisGetRecordsInput *getRecordsInput = [AWSKinesisGetRecordsInput new];
        getRecordsInput.shardIterator = getShardIteratorOutput.shardIterator;
        return [kinesis getRecords:getRecordsInput];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        } else {
            AWSKinesisGetRecordsOutput *getRecordsOutput = task.result;
            int32_t i = 0;
            for (AWSKinesisRecord *record in getRecordsOutput.records) {
                XCTAssertTrue([[[NSString alloc] initWithData:record.data encoding:NSUTF8StringEncoding] hasPrefix:@"TestString-"]);
                i++;
            }
            XCTAssertTrue(i > 90);
        }

        return nil;
    }] waitUntilFinished];
}

- (void)testDescribeStreamFailed {
    AWSKinesis *kinesis = [AWSKinesis defaultKinesis];

    AWSKinesisDescribeStreamInput *describeStreamInput = [AWSKinesisDescribeStreamInput new];
    describeStreamInput.streamName = @"invalidStreamName"; //streamName is empty

    [[[kinesis describeStream:describeStreamInput] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error, @"expected error but got nil");
        XCTAssertEqual(AWSKinesisErrorResourceNotFound, task.error.code, @"expected AWSKinesisErrorResourceNotFound(6) but got %ld",(long)task.error.code);
        return nil;
        
    }] waitUntilFinished];
    
}

@end

#endif
