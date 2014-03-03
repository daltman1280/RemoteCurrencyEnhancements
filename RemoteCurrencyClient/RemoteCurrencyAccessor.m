//
//  RemoteCurrencyAccessor.m
//  RemoteCurrencyClient
//
//  Created by daltman on 3/2/14.
//
//

#import "RemoteCurrencyAccessor.h"
#import "RemoteCurrencyClientConnection.h"

@interface RemoteCurrencyAccessor () <RemoteCurrencyClientConnectionDelegate>

// read/write versions of public properties

@property (nonatomic, assign, readwrite) RemoteCurrencyAccessorStatus      status;
@property (nonatomic, assign, readwrite) BOOL                               networkActive;
@property (nonatomic, assign, readwrite) BOOL                               finished;
@property (nonatomic, copy,   readwrite) NSMutableArray *                         result;

// private properties

@property (nonatomic, retain, readwrite) RemoteCurrencyClientConnection *   connection;
@property (nonatomic, copy,   readwrite) NSString *                         pendingCommand;

@property (nonatomic, retain, readwrite) NSTimer *                          dummyConversionTimer;

@end

@implementation RemoteCurrencyAccessor

@synthesize status        = status_;
@synthesize netService    = netService_;
@synthesize networkActive = networkActive_;
@synthesize result        = result_;
@synthesize finished      = finished_;

@synthesize connection     = connection_;
@synthesize pendingCommand = pendingCommand_;

@synthesize dummyConversionTimer = dummyConversionTimer_;

- (id)initWithNetService:(NSNetService *)netService
{
    assert(netService != nil);
    self = [super init];
    if (self != nil) {
        self->status_ = kRemoteCurrencyAccessorInitialised;
        self->netService_ = [netService retain];
    }
    return self;
}

- (void)dealloc
{
    // All of the following should have be cleaned up by -stopConverting
    // (actually, either -networkStopConverting or -dummyStopConverting).
    assert(self->connection_ == nil);
    assert(self->pendingCommand_ == nil);
    assert(self->dummyConversionTimer_ == nil);
    
    [self->netService_ release];
    [self->result_ release];
    
    [super dealloc];
}

#pragma mark * Network core conversion

+ (NSString *)nextConnectionName
{
    static NSUInteger sConnectionSequenceNumber;
    NSString *  result;
    
    result = [NSString stringWithFormat:@"%zu", (size_t) sConnectionSequenceNumber];
    sConnectionSequenceNumber += 1;
    return result;
}

- (void)startAccessingCurrencies
{
	NSString *command;
	if (self.connection == nil) {
		NSInputStream *input;
		NSOutputStream *output;
		[self.netService getInputStream:&input outputStream:&output];
		self.connection = [[[RemoteCurrencyClientConnection alloc] initWithInputStream:input outputStream:output] autorelease];
		self.connection.clientDelegate = self;
		self.connection.name = [[self class] nextConnectionName];
		[self.connection open];
		[input release];
		[output release];
		self.status = kRemoteCurrencyAccessorIdle;
	}
	assert((self.status == kRemoteCurrencyAccessorIdle || (self.status == kRemoteCurrencyAccessorAccessing)));
	command = @"currencies";
	switch (self.status) {
		case kRemoteCurrencyAccessorIdle: {
			assert(self.pendingCommand == nil);
			[self.connection sendRequest:command];
			self.networkActive = YES;
			self.finished = NO;
			self.status = kRemoteCurrencyAccessorAccessing;
		} break;
		case kRemoteCurrencyAccessorAccessing: {
			self.pendingCommand = command;
		} break;
		default: {
			assert(NO);
		} break;
	}
}

- (void)networkFailedAccessing
{
    if (self.connection != nil) {
        self.connection.delegate = nil;
        [self.connection close];
        self.connection = nil;
    }
    self.pendingCommand = nil;
    self.status = kRemoteCurrencyAccessorFailed;
    self.networkActive = NO;
    self.finished = NO;
}

- (void)stopAccessing
// The network implementation of -stopConverting, for which you should see the comments in the header.
{
    if (self.connection != nil) {
        self.connection.delegate = nil;
        [self.connection close];
        self.connection = nil;
    }
    self.pendingCommand = nil;
    self.status = kRemoteCurrencyAccessorClosed;
    self.networkActive = NO;
    self.finished = NO;
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection willCloseWithError:(NSError *)error
// Called by the network connection when the connection tears. The current implementation
// just shuts everything down and leaves it up to the user to trigger a retry.
{
    assert(connection == self.connection);
#pragma unused(error)
    // error may be nil
    [self networkFailedAccessing];
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveResponse:(NSString *)response lines:(NSArray *)lines
// Called by the network connection when it receives a valid response from the server.
// This parses the response to extract the converted value and then passes that
// back up to the user interface.  Also, if there is a pending conversion, it kicks
// that off.
{
    BOOL            success;
    NSScanner *     scanner;
	NSMutableArray *value;
    
    assert(self.status == kRemoteCurrencyAccessorAccessing);
    
    assert(connection == self.connection);
    assert(response != nil);
    assert(lines != nil);
    
    success = NO;
    if ([response caseInsensitiveCompare:@"OK"] == NSOrderedSame) {
		value = [[[NSMutableArray alloc] init] autorelease];
		for (NSString *line in lines) {
			scanner = [NSScanner scannerWithString:line];
			assert(scanner != nil);
			NSString *currencyName;
			success = [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&currencyName];
			if (success) {
				[value addObject:currencyName];
			}
		}
		if (success) {
			success = [scanner isAtEnd];
		}
    }
    if (success) {
		self.result = value;
        
        // If a subsequent conversion got queued behind this one, start it.
        // Otherwise all our conversions are done and we can set finished,
        // which triggers a UI update.
        
        if (self.pendingCommand != nil) {
            NSString *  command;
            
            command = [[self.pendingCommand retain] autorelease];
            self.pendingCommand = nil;
			
            [self.connection sendCommandLine:command];
        } else {
            self.networkActive = NO;
            self.finished = YES;
            self.status = kRemoteCurrencyAccessorIdle;
        }
    } else {
        [self networkFailedAccessing];
    }
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveError:(NSString *)errorResponse
// Called by the network connection it receives an error response from the server.
// The current implementation just shuts everything down and leaves it up to the user
// to trigger a retry.
{
    assert(connection == self.connection);
    assert(errorResponse != nil);
    [self networkFailedAccessing];
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString *  str;
    assert(connection != nil);
    assert( (self.connection == nil) || (connection == self.connection) );          // self.connection can be nil during shut down
    assert(format != nil);
    
    str = [[NSString alloc] initWithFormat:format arguments:argList];
    assert(str != nil);
    NSLog(@"control-%@ %@", connection.name, str);
    [str release];
}


@end
