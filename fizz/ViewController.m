//
//  ViewController.m
//  fizz－pdf
//
//  Created by 陈光旭 on 15/11/12.
//  Copyright (c) 2015年 leochen. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
- (IBAction)button_Start:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *button_StartOutlet;
- (IBAction)button_He:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *label_isFuzzing;
@property (weak, nonatomic) IBOutlet UITextField *text_SleepTime;
@property (weak, nonatomic) IBOutlet UILabel *text_Mutated;
@property (weak, nonatomic) IBOutlet UITextField *text_Seed;
@property (weak, nonatomic) IBOutlet UILabel *text_tries;
@property (readwrite) BOOL fuzzing;
@property (readwrite) int sleepTime;
@property (readwrite) int seed;
@property (nonatomic)UIWebView *webView;
@end

@implementation ViewController

- (unsigned char*)addEntropy:(unsigned char*)buffer :(long)size
{
    
    long numberOfWrites = arc4random() % (size/_seed) + 1;
    for(int i = 0; i < numberOfWrites; i++)
    {
        NSInteger randomByte = arc4random() % 256;
        char rbyte = (char)randomByte;
        NSInteger randomNumber = arc4random() % size;
        buffer[randomNumber] = rbyte;
    }
    NSLog(@"[*] Mutated %ld times of %lu bytes.", numberOfWrites, size);
    
     _text_Mutated.text = [NSString stringWithFormat:@"%ld", numberOfWrites];
    
    return buffer;
}

- (NSString*)generateMutatedFile {
    
    _label_isFuzzing.text = @"Generating file...";
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *PATHS = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [PATHS objectAtIndex:0];
    NSString* PATH = [documentsDirectory stringByAppendingPathComponent:@"out.pdf"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:PATH]) {
        NSError *error;
        
        BOOL success = [fileManager removeItemAtPath:PATH error:&error];
        
        if (success) NSLog(@"[-] Removed previous mutated file.");
        else NSLog(@"[!] Could not delete file : %@ ", [error localizedDescription]);
    }
    
    PATH = [[NSBundle mainBundle] pathForResource:@"fuzzThis1" ofType:@"pdf"];
    
    FILE* filePointer;
    filePointer = fopen([PATH UTF8String], "rb");
    
    unsigned char* buffer = NULL;
    
    if(filePointer)
    {
        NSLog(@"[*] %@ loaded.", PATH);
        
        fseek(filePointer, 1, SEEK_END);
        long fileSize = ftell(filePointer);
        fseek(filePointer, 1, SEEK_SET);
        
        if(fileSize != 0)
        {
            NSLog(@"[*] File size: %lu", fileSize);
            buffer = calloc(fileSize, sizeof(unsigned char));
            
            long result = fread (buffer, 1, fileSize, filePointer);
            fclose(filePointer);
            
            if (result != 0)
            {
                NSLog(@"[*] Loaded into buffer!");
                
                buffer = [self addEntropy :buffer :fileSize];
                
                NSArray *PATHS = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [PATHS objectAtIndex:0];
                PATH = [documentsDirectory stringByAppendingPathComponent:@"out.pdf"];
                
                NSLog(@"[*] Writing to: %@", PATH);
                
                _label_isFuzzing.text = @"Saving file...";
                
                FILE* outP = fopen([PATH UTF8String], "ab+");
                
                fputc(0x0, outP); //One 0x00 byte padding (???)
                fwrite(buffer, sizeof(unsigned char), fileSize, outP);
                
                if([[NSFileManager defaultManager] fileExistsAtPath:PATH])
                    NSLog(@"[*] Mutated file written!");
                else
                    NSLog(@"[!] Mutated file NOT written.");
                
                fclose(outP);
                free(buffer);
                
            } else NSLog(@"[!] Failed to load file into buffer : %lu, %lu", result, fileSize);
            
        } else NSLog(@"[!] Failed to get file size.");
        
    } else NSLog(@"[!] %@ NOT loaded.", PATH);
    
    return PATH;
}

- (void)doFuzzing {
    _label_isFuzzing.text = @"Fuzzing...";
    NSArray *PATHS = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [PATHS objectAtIndex:0];
    NSString* PATH = [documentsDirectory stringByAppendingPathComponent:@"out.pdf"];
    NSURL* URL = [NSURL fileURLWithPath: PATH];
    
    [self generateMutatedFile];
    
    NSLog(@"[DONE] Generated file! Playing: %s", [URL.absoluteString UTF8String]);
    
    _label_isFuzzing.text = @"Fuzzing file...";
    
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 10, 300, 300)];
    }
    
    NSURL *targetURL = [NSURL URLWithString:PATH];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    [_webView loadRequest:request];
    [self.view addSubview:_webView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (_sleepTime) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _text_tries.text = [NSString stringWithFormat:@"%d", [_text_tries.text intValue]+1];
        [_webView removeFromSuperview];
        if(_fuzzing == TRUE) [self doFuzzing];
    });
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if TARGET_IPHONE_SIMULATOR == 0
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
#endif
    
    _sleepTime = [[_text_SleepTime text] intValue];
    _seed = [[_text_Seed text] intValue];
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = @[[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelNumberPad)],
                            [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)]];
    [numberToolbar sizeToFit];
    
    UIToolbar* numberToolbar2 = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar2.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar2.items = @[[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelNumberPad2)],
                            [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad2)]];
    [numberToolbar2 sizeToFit];

    _text_SleepTime.inputAccessoryView = numberToolbar;
    _text_Seed.inputAccessoryView = numberToolbar2;
    
    _fuzzing = FALSE;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)cancelNumberPad {
    [_text_SleepTime resignFirstResponder];
    _text_SleepTime.text = @"";
}

-(void)doneWithNumberPad {
    _sleepTime = [[_text_SleepTime text] intValue];
    _text_SleepTime.text = [NSString stringWithFormat:@"%d", _sleepTime];
    [_text_SleepTime resignFirstResponder];
}


-(void)cancelNumberPad2 {
    [_text_Seed resignFirstResponder];
    _text_Seed.text = @"";
}

-(void)doneWithNumberPad2 {
    _seed = [[_text_Seed text] intValue];
    _text_Seed.text = [NSString stringWithFormat:@"%d", _seed];
    [_text_Seed resignFirstResponder];
}


- (IBAction)button_Start:(id)sender {
    
    if(_sleepTime <= 0 || _seed <= 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Whoops..."
                                                       message: @"Please make sure you have a sleep time and seed that are greater than 0."
                                                      delegate: self
                                             cancelButtonTitle: NULL
                                             otherButtonTitles: @"OK",nil];
        
        [alert show];
    } else {
        if(!_fuzzing) {
            _fuzzing = TRUE;
            _text_tries.text = @"0";
            _text_Mutated.text = @"0";
            [_button_StartOutlet setTitle:@"Stop" forState:UIControlStateNormal];
            
            [_webView removeFromSuperview];
            _webView = nil;
            [self doFuzzing];
        } else {
            _fuzzing = FALSE;
            [_button_StartOutlet setTitle:@"Start" forState:UIControlStateNormal];
            _label_isFuzzing.text = @"Not fuzzing...";
            [_webView removeFromSuperview];
            _webView = nil;

        }
    }
}

- (IBAction)button_He:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Fizz - A shitty iOS Fuzzing Application"
                                                   message: @"Sleep time:\nTells the application how long you want to fuzz the file. 10 seconds is the default and seems to work well...\n\nSeed:\nThe seed determines the entropy of the data changes. The lower the seed the higher the mutation (WIP).\n\nJust hit start and see if it crashes. If it does it should generate a crash report, if you're lucky a panic report (mediaserverd is the target). If not, oh well. The chances are slim... This is just a PoC~\n"
                                                  delegate: self
                                         cancelButtonTitle: NULL
                                         otherButtonTitles: @"Dismiss",nil];
    
    [alert show];
}
@end
