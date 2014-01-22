#import <CommonCrypto/CommonDigest.h>
#import "ViewController.h"
#import "DetailViewController.h"
#import "User.h"

static NSString* const kAppId =    @"217129728";
static NSString* const kPublic =   @"CBAECCPNABABABABA";
static NSString* const kSecret =   @"EE9D964651AE21C64F74D094";
static NSString* const kAuthUrl =  @"http://www.odnoklassniki.ru/oauth/authorize?response_type=code&display=touch&layout=m&client_id=%@&redirect_uri=%@";
static NSString* const kRedirect = @"http://connect.mail.ru/oauth/success.html";
static NSString* const kTokenUrl = @"http://api.odnoklassniki.ru/oauth/token.do";
static NSString* const kBody =     @"grant_type=authorization_code&code=%@&client_id=%@&redirect_uri=%@&client_secret=%@";
static NSString* const kParams =   @"application_key=%@format=JSONmethod=users.getCurrentUser";
static NSString* const kMe =       @"http://api.odnoklassniki.ru/fb.do?application_key=%@&format=JSON&method=users.getCurrentUser&access_token=%@&sig=%@";

static User *_user;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *redirect = [kRedirect stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *str = [NSString stringWithFormat:kAuthUrl, kAppId, redirect];
    
    NSURL *url = [NSURL URLWithString:str];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    NSLog(@"%s: req=%@", __PRETTY_FUNCTION__, req);
    [_webView loadRequest:req];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSURL *url = [webView.request mainDocumentURL];
    NSLog(@"%s: url=%@", __PRETTY_FUNCTION__, url);
    NSString *str = [url absoluteString];
    NSString *code = [self extractValueFrom:str ForKey:@"code"];
    NSLog(@"%s: code=%@", __PRETTY_FUNCTION__, code);
    
    if (code) {
        [self fetchOdnoklassnikiWithCode:code];
    }
}

- (NSString*)extractValueFrom:(NSString*)str ForKey:(NSString*)key
{
    NSString *value = nil;
    NSString *pattern = [key stringByAppendingString:@"=([^?&=]+)"];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                      options:0
                                                                        error:nil];
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSTextCheckingResult* result = [regex firstMatchInString:str options:0 range:searchRange];

    if (result) {
        value = [str substringWithRange:[result rangeAtIndex:1]];
        NSLog(@"%s: value=%@", __PRETTY_FUNCTION__, value);
    }
    
    return value;
}

- (void)fetchOdnoklassnikiWithCode:(NSString*)code
{
    NSString *redirect = [kRedirect stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:kTokenUrl];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    
    NSString *body = [NSString stringWithFormat:kBody,
                      code, kAppId, redirect, kSecret];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"%s: req=%@", __PRETTY_FUNCTION__, req);
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection
     sendAsynchronousRequest:req
     queue:queue
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error) {
         
         if (error == nil && [data length] > 0) {
             id json = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:nil];
             NSLog(@"json=%@", json);
             
             
             if (![json isKindOfClass:[NSDictionary class]]) {
                 NSLog(@"Parsing response failed");
                 return;
             }
             
             NSDictionary *dict = json;
             NSString *token = dict[@"access_token"];
             NSLog(@"token=%@", token);
             [self fetchOdnoklassnikiWithToken:token];
         } else {
             NSLog(@"Download failed: %@", error);
         }
     }];
}


- (void)fetchOdnoklassnikiWithToken:(NSString*)token
{
    NSString *params = [NSString stringWithFormat:kParams, kPublic];

    NSString *sig = [self md5:[NSString stringWithFormat:@"%@%@", token, kSecret]];
    sig = [self md5:[NSString stringWithFormat:@"%@%@", params, sig]];

    NSString *str = [NSString stringWithFormat:kMe, kPublic, token, sig];
    NSURL *url = [NSURL URLWithString:str];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSLog(@"%s: url=%@", __PRETTY_FUNCTION__, url);
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection
     sendAsynchronousRequest:req
     queue:queue
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error) {
         
         if (error == nil && [data length] > 0) {
             id json = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:nil];
             NSLog(@"json = %@", json);
             
             if (![json isKindOfClass:[NSDictionary class]]) {
                 NSLog(@"Parsing response failed");
                 return;
             }
             
             NSDictionary *dict = json;
             
             _user = [[User alloc] init];
             _user.userId    = dict[@"uid"];
             _user.firstName = dict[@"first_name"];
             _user.lastName  = dict[@"last_name"];
             _user.city      = dict[@"location"][@"city"];
             _user.avatar    = dict[@"pic_2"];
             _user.female    = ([@"female" caseInsensitiveCompare:dict[@"gender"]] == NSOrderedSame);
             
             dispatch_async(dispatch_get_main_queue(), ^(void) {
                 [self performSegueWithIdentifier: @"pushDetailViewController" sender: self];
             });
         } else {
             NSLog(@"Download failed: %@", error);
         }
     }];
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"pushDetailViewController"]) {
        DetailViewController *dvc = segue.destinationViewController;
        [dvc setUser:_user];
    }
}

- (NSString *) md5:(NSString *)input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest);
    
    NSMutableString *str = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [str appendFormat:@"%02x", digest[i]];
    
    return str;
}

@end
