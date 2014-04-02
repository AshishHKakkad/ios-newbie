#import "ViewController.h"

static float const kTileScale = 1.0;
static int const kPadding     = 2;
static int const kNumTiles    = 7;

@implementation ViewController
{
	BigTile* _bigTile;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    for (int i = 0; i < kNumTiles; i++) {
        SmallTile *tile = [[[NSBundle mainBundle] loadNibNamed:@"SmallTile"
                                                         owner:self
                                                       options:nil] firstObject];
        tile.exclusiveTouch = YES;
        [self.view addSubview:tile];
    }
    
    [self adjustZoom];
    [self adjustTiles];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self adjustZoom];
    [self adjustTiles];
}

- (void) adjustZoom
{
    float scale = _scrollView.frame.size.width / kBoardWidth;
    _scrollView.minimumZoomScale = scale;
    _scrollView.maximumZoomScale = 2 * scale;
    _scrollView.zoomScale = 2 * scale;
}

- (void) removeTiles
{
    for (UIView *subView in _contentView.subviews) {
        if (![subView isKindOfClass:[SmallTile class]])
            continue;
        
        SmallTile* tile = (SmallTile*)subView;
        [tile removeFromSuperview];
        [self.view addSubview:tile];
    }
}

- (void) adjustTiles
{
    int i = 0;
    for (UIView *subView in self.view.subviews) {
        if (![subView isKindOfClass:[SmallTile class]])
            continue;
        
        SmallTile* tile = (SmallTile*)subView;
        CGRect rect = CGRectMake(kPadding + kSmallTileWidth * kTileScale * i++,
                                self.view.bounds.size.height - kSmallTileHeight * kTileScale - kPadding,
                                kSmallTileWidth,
                                kSmallTileHeight);
        tile.frame = CGRectOffset(tile.frame, 0, -8);
        [UIView beginAnimations:@"moveDown" context:nil];
        [tile setFrame:rect];
        [UIView commitAnimations];
        //NSLog(@"tile: %@", tile);
    }
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
    return _contentView;
}

- (IBAction) scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer
{
    if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint pt = [recognizer locationInView:_contentView];
        [self zoomTo:pt];
    }
    
    [self adjustTiles];
}

- (IBAction) mainViewDoubleTapped:(UITapGestureRecognizer*)recognizer
{
    [self removeTiles];
    [self adjustTiles];
}

- (void) zoomTo:(CGPoint)pt
{
    CGFloat scale = _scrollView.maximumZoomScale;
    CGSize size = _scrollView.bounds.size;
    
    CGFloat w = size.width / scale;
    CGFloat h = size.height / scale;
    CGFloat x = pt.x - (w / 2.0f);
    CGFloat y = pt.y - (h / 2.0f);
    
    CGRect rect = CGRectMake(x, y, w, h);
    
    [_scrollView zoomToRect:rect animated:YES];
}

- (SmallTile*) findTileAtPoint:(CGPoint)point withEvent:(UIEvent*)event
{
    NSArray* children = [self.view.subviews arrayByAddingObjectsFromArray:_contentView.subviews];
    
    for (UIView* child in children) {
        CGPoint localPoint = [child convertPoint:point fromView:self.view];
        
        //NSLog(@"%s: child=%@", __PRETTY_FUNCTION__, child);
        if ([child isKindOfClass:[SmallTile class]] &&
            [child pointInside:localPoint withEvent:event]) {
            NSLog(@"%s: FOUND=%@", __PRETTY_FUNCTION__, child);
            return (SmallTile*)child;
        }
    }
    
    return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    SmallTile *tile = [self findTileAtPoint:point withEvent:event];
    if (!tile)
        return;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, tile);
    tile.alpha = 0;
    
    _bigTile = [tile cloneTile];
    _bigTile.center = [self.view convertPoint:tile.center fromView:tile.superview];
    [self.view addSubview:_bigTile];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    SmallTile *tile = [self findTileAtPoint:point withEvent:event];
    if (!tile)
        return;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, tile);

    CGPoint previous = [touch previousLocationInView:self.view];
    
    tile.frame = CGRectOffset(tile.frame,
                              (point.x - previous.x),
                              (point.y - previous.y));

    _bigTile.center = [self.view convertPoint:tile.center fromView:tile.superview];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTileReleased:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTileReleased:touches withEvent:event];
}

- (void) handleTileReleased:(NSSet*)touches withEvent:(UIEvent*)event{
    UITouch* touch = [touches anyObject];
	[_bigTile removeFromSuperview];
	_bigTile = nil;
    
    CGPoint point = [touch locationInView:self.view];
    SmallTile *tile = [self findTileAtPoint:point withEvent:event];
    if (!tile)
        return;
    
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, tile);
	tile.alpha = 1;
	
	CGPoint pt = [touch locationInView:_contentView]; // XXX remove
	CGPoint ptTransform = CGPointApplyAffineTransform(pt, _contentView.transform);
	CGPoint ptView = [touch locationInView:self.view];
	
    if (tile.superview != _contentView &&
        // Is the tile over the scoll view?
        CGRectContainsPoint(_scrollView.frame, ptView) &&
        // Is the tile still over the game board - when it is zoomed out?
        CGRectContainsPoint(_contentView.frame, ptTransform)) {
		
        // Put the tile at the game board
		[tile removeFromSuperview];
        [_contentView addSubview:tile];
        
    } else if(!CGRectContainsPoint(_scrollView.frame, ptView) ||
              !CGRectContainsPoint(_contentView.frame, ptTransform)) {
        
        // Put the tile back to the stack
        [tile removeFromSuperview];
        [self.view addSubview:tile];
        [self adjustTiles];
	}
    
    if (tile.superview == _contentView) {
        tile.center = [GameBoard snapToGrid:pt];
        
        if (_scrollView.zoomScale == _scrollView.minimumZoomScale) {
            [self zoomTo:tile.center];
        }
    }
    
    NSLog(@"%s %@", __PRETTY_FUNCTION__, tile);
}


@end
