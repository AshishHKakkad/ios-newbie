#import "SmallTile.h"

int const kSmallTileWidth       = 45;
int const kSmallTileHeight      = 45;

static NSString* const kLetters = @"ABCDEFGHIJKLMNOPQRSTUWVXYZ";
static NSDictionary* letterValues;
static NSMutableArray* grid;
static NSArray* spiral;

@implementation SmallTile

+ (void)initialize
{
    if (self != [SmallTile class])
        return;
    
    letterValues = @{
         @"A": @1,
         @"B": @4,
         @"C": @4,
         @"D": @2,
         @"E": @1,
         @"F": @4,
         @"G": @3,
         @"H": @3,
         @"I": @1,
         @"J": @10,
         @"K": @5,
         @"L": @2,
         @"M": @4,
         @"N": @2,
         @"O": @1,
         @"P": @4,
         @"Q": @10,
         @"R": @1,
         @"S": @1,
         @"T": @1,
         @"U": @2,
         @"V": @5,
         @"W": @4,
         @"X": @8,
         @"Y": @3,
         @"Z": @10,
    };
    
    spiral = @[
               @[@0, @0],
               @[@1, @0],
               @[@0, @1],
               @[@-1, @0],
               @[@0, @-1],
               @[@1, @1],
               @[@-1, @1],
               @[@-1, @-1],
               @[@1, @-1],
    ];
    
    grid = [[NSMutableArray alloc] init];
    for (int i = 0; i < 15; i++) {
        NSMutableArray *row = [[NSMutableArray alloc] init];
        for (int j = 0; j < 15; j++) {
            [row addObject:[NSNull null]];
        }
        [grid addObject:row];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSString* randomLetter = [kLetters substringWithRange:
                              [kLetters rangeOfComposedCharacterSequenceAtIndex:arc4random_uniform(kLetters.length)]];
    int letterValue = [letterValues[randomLetter] integerValue];
    _letter.text = randomLetter;
    _value.text = [NSString stringWithFormat:@"%d", letterValue];
    _col = -1;
    _row = -1;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"SmallTile %@ %@ %@ %@",
            _letter.text,
            _value.text,
            NSStringFromCGPoint(self.frame.origin),
            NSStringFromCGSize(self.frame.size)];
}

- (BigTile*)cloneTile
{
	BigTile *tile = [[[NSBundle mainBundle] loadNibNamed:@"BigTile"
												   owner:self
											     options:nil] firstObject];
	tile.letter.text = _letter.text;
    tile.value.text = _value.text;

	return tile;
}

- (NSInteger)limit:(NSInteger)n
{
    if (n < 0)
        return 0;
    if (n > 14)
        return 14;
    return n;
}

- (BOOL)addToGrid
{
    NSInteger i = floorf((self.center.x - kBoardLeft) / kSmallTileWidth);
    NSInteger j = floorf((self.center.y - kBoardTop) / kSmallTileHeight);
    
    for (NSArray* arr in spiral) {
        NSInteger col = [self limit:i + [arr[0] integerValue]];
        NSInteger row = [self limit:j + [arr[1] integerValue]];
        
        // if found a free cell
        if (grid[col][row] == [NSNull null]) {
            _col = col;
            _row = row;
            grid[_col][_row] = self;
            
            CGFloat x = kBoardLeft + (.5 + _col) * kSmallTileWidth;
            CGFloat y = kBoardTop  + (.5 + _row) * kSmallTileHeight;
            self.center = CGPointMake(x, y);
            
            [self adaptTile];
            
            return YES;
        }
    }
    
    return NO;
}

- (void)adaptTile
{
    if (_col - 1 < 0 || grid[_col - 1][_row] == [NSNull null]) {
        _imgW.image = [UIImage imageNamed:@"8.png"];
    } else {
        _imgW.image = [UIImage imageNamed:@"0.png"];
    }
    
    if (_col + 1 > 14 || grid[_col + 1][_row] == [NSNull null]) {
        _imgW.image = [UIImage imageNamed:@"4.png"];
    } else {
        _imgW.image = [UIImage imageNamed:@"0.png"];
    }

}

- (void)removeFromGrid
{
    if (_col >= 0 &&
        _col <= 14 &&
        _row >= 0 &&
        _row <= 14) {
        grid[_col][_row] = [NSNull null];
    }
    
    _col = -1;
    _row = -1;
}

@end
