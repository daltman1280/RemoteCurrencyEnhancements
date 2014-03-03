//
//  RemoteCurrencyAccessor.h
//  RemoteCurrencyClient
//
//  Created by daltman on 3/2/14.
//
//

#import <Foundation/Foundation.h>

enum RemoteCurrencyAccessorStatus {
    kRemoteCurrencyAccessorInitialised,
    kRemoteCurrencyAccessorIdle,
    kRemoteCurrencyAccessorAccessing,
    kRemoteCurrencyAccessorClosed,
    kRemoteCurrencyAccessorFailed
};
typedef enum RemoteCurrencyAccessorStatus RemoteCurrencyAccessorStatus;

@interface RemoteCurrencyAccessor : NSObject

- (id)initWithNetService:(NSNetService *)netService;

// properties set up by the init method

@property (nonatomic, retain, readonly ) NSNetService *     netService;

// properties that change by themselves

@property (nonatomic, assign, readonly ) RemoteCurrencyAccessorStatus  status; // observable

@property (nonatomic, assign, readonly ) BOOL               networkActive;      // observable

// core conversion engine

//- (void)startConvertingValue:(double)value fromCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency;
- (void)startAccessingCurrencies;
- (void)stopAccessing;


@property (nonatomic, assign, readonly ) BOOL               finished;           // observable
@property (nonatomic, copy,   readonly ) NSMutableArray *   result;             // observable

// IMPORTANT: result is observable, but it's better to observe finished so that you don't
// see any intermediate results.

@end
