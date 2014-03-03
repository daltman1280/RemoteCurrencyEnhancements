//
//  RemoteCurrencyServer_Tests.m
//  RemoteCurrencyServer Tests
//
//  Created by daltman on 3/2/14.
//
//

#import <XCTest/XCTest.h>
#import "RemoteCurrencyServerConnection.h"
#import "RemoteCurrencyServer.h"

@interface RemoteCurrencyServer_Tests : XCTestCase

@property (nonatomic, retain, readwrite) RemoteCurrencyServer *server;

@end

@implementation RemoteCurrencyServer_Tests

- (void)setUp
{
    [super setUp];
	self.server = [[RemoteCurrencyServer alloc] init];
	[self.server run];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCurrenciesNotNil
{
	NSArray *availableCurrencies = [self.server availableCurrencies];
	XCTAssertNotNil(availableCurrencies, @"Nil availableCurrencies");
}

- (void)testCurrenciesEqualArray
{
	NSArray *availableCurrencies = [self.server availableCurrencies];
	NSArray *sample = @[@"USD", @"EUR", @"GBP", @"JPY", @"AUD", @"RUS"];
	XCTAssertEqualObjects(availableCurrencies, sample, "Failed");
}

- (void)testExchangeRates
{
	NSArray *exchangeRates = [self.server exchangeRates];
	XCTAssertNotNil(exchangeRates, @"Nil exchangeRates");
}

- (void)testCurrenciesCommand
{
	NSScanner *scanner = [NSScanner scannerWithString:@"currencies"];
	NSString *commandStr = @"currencies";
	BOOL success = [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&commandStr];
#pragma unused(success)
//	[self.server remoteCurrencyServerConnection:self.server currenciesCommand:scanner];
	XCTAssert(false, @"false");
}

@end
