//
//  MoveQueueProgressBar.m
//  FreshDocs
//
//  Created by bdt on 11/14/13.
//
//

#import "MoveQueueProgressBar.h"
#import "CMISObject.h"
#import "AccountManager.h"

#import "CMISFolder.h"
#import "CMISDocument.h"
#import "CMISRequest.h"

NSInteger const kMoveCounterTag =  8;

@interface MoveQueueProgressBar () {
    NSMutableArray *_movedItems;
}
@property (nonatomic, assign) BOOL  isCancel;
@property (nonatomic, strong) CMISRequest *currentRequest;

- (void) loadMoveView;
@end

@implementation MoveQueueProgressBar
@synthesize itemsToMove = _itemsToMove;
@synthesize delegate = _delegate;
@synthesize progressAlert = _progressAlert;
@synthesize progressTitle = _progressTitle;
@synthesize progressView = _progressView;
@synthesize selectedUUID = _selectedUUID;
@synthesize tenantID = _tenantID;
@synthesize targetFolder = _targetFolder;
@synthesize sourceFolderId = _sourceFolderId;

- (id)initWithItems:(NSArray *)itemsToMove targetFolder:(CMISObject*)targetFolder delegate:(id<MoveQueueDelegate>)del andMessage:(NSString *)message
{
    self = [super init];
    if (self)
    {
        self.itemsToMove = [NSMutableArray arrayWithArray:itemsToMove];
        self.delegate = del;
        self.progressTitle = message;
        self.targetFolder = targetFolder;
        self.isCancel = NO;
        _movedItems = [NSMutableArray array];
        _sourceFolderId = nil;
        [self loadMoveView];
    }
    
    return self;
}

- (void) loadMoveView {
    // create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.progressTitle
                                                    message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          otherButtonTitles:nil];
    alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
    self.progressAlert = alert;
	
	// create a progress bar and put it in the alert
	UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
    self.progressView = progress;
    [progress setProgressViewStyle:UIProgressViewStyleBar];
	[self.progressAlert addSubview:self.progressView];
	
	// create a label, and add that to the alert, too
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 90.0f, 225.0f, 40.0f)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:13.0f];
    label.text = @"x files left";
    label.tag = kMoveCounterTag;
    [self.progressAlert addSubview:label];

}

- (void) updateProgressView
{
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kMoveCounterTag];
    if([self.itemsToMove count] == 1)
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"moveprogress.file-left", @"1 item left"),
                      [self.itemsToMove count]];
    }
    else
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"moveprogress.files-left", @"x items left"),
                      [self.itemsToMove count]];
    }
}

- (void)startMoving {
    [self startMoveItem];
    [self.progressAlert show];
    [self updateProgressView];
}

- (void) startMoveItem {
    if ([self isCancel]) {
        return;
    }
    if ([self.itemsToMove count] > 0) {
        CMISFileableObject *item = [self.itemsToMove objectAtIndex:0];
        
        self.currentRequest = [item moveFromFolderWithId:_sourceFolderId toFolderWithId:self.targetFolder.identifier completionBlock:^(CMISObject* item, NSError *error) {
            if (error != nil) {
                ODSLogError(@"move folder item error:%@", error);
                [CMISUtility handleCMISRequestError:error];
            }else {
                [self saveMovedItems];
            }
            
            [self removeMovedItemFromList];
            [self updateProgressView];
            [self startMoveItem];
        }];
    }else {  //All items were moved.
        [_progressAlert dismissWithClickedButtonIndex:1 animated:NO];
        if (self.delegate && [self.delegate respondsToSelector:@selector(moveQueue:completedMoves:)])  {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate moveQueue:self completedMoves:_movedItems];
            });
        }
    }
}

- (void) saveMovedItems {
    if ([self.itemsToMove count] > 0) {
        [_movedItems addObject:[self.itemsToMove objectAtIndex:0]];
    }
}

- (void) removeMovedItemFromList {
    if ([self.itemsToMove count] > 0) {
        [self.itemsToMove removeObjectAtIndex:0];
    }
}

- (void) cancel
{
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSArray *) movedItems
{
    return [NSArray arrayWithArray:_movedItems];
}

- (void) cancelMoveOperation {
    [self setIsCancel:YES];
    if (self.currentRequest) {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
}

#pragma mark - static methods
+ (MoveQueueProgressBar *)createWithItems:(NSArray*)itemsToMove targetFolder:(CMISObject*)targetFolder delegate:(id <MoveQueueDelegate>)del andMessage:(NSString *)message {
    MoveQueueProgressBar *bar = [[MoveQueueProgressBar alloc] initWithItems:itemsToMove targetFolder:targetFolder delegate:del andMessage:message];
    return bar;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // we only cancel the connection when buttonIndex=0 (cancel)
    if (buttonIndex == 0)
    {
        [self cancelMoveOperation];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(moveQueueWasCancelled:)])
        {
            [self.delegate moveQueueWasCancelled:self];
        }
    }
}

@end
