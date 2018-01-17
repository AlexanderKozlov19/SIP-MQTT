//
//  ViewController.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 07.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#import "ViewController.h"
#import "MQTT.h"
#import "SIPpj.h"
#import "UDPSocket.h"
#import "AudioRecording.h"


float const ELEMENT_BORDER_WIDTH = 1.0;
float const ELEMENT_CORNER_RADIUS = 4.0;

#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"



@implementation ViewController

@synthesize arrayAddress;
@synthesize activeField;
@synthesize scrollOffsetPrevious;

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type == IP_ADDR_IPv4) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(updateLabelStatus:)
                                                 name: @"updateLabelStatus"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(addTopicMessage:)
                                                 name: @"addTopicMessage"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onIncomingCall:)
                                                 name: @"onIncomingCall"
                                               object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onTPState:)
                                                 name: @"onTPState"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onUDPMessage:)
                                                 name: @"onUDPMessage"
                                               object: nil];
    
    
    
    self.textViewOnTopic.layer.borderWidth = ELEMENT_BORDER_WIDTH;
    self.textViewOnTopic.layer.cornerRadius = ELEMENT_CORNER_RADIUS;
    self.textViewOnTopic.layer.borderColor = [[UIColor blackColor] CGColor];
    
    self.textViewUDPMessages.layer.borderWidth = ELEMENT_BORDER_WIDTH;
    self.textViewUDPMessages.layer.cornerRadius = ELEMENT_CORNER_RADIUS;
    self.textViewUDPMessages.layer.borderColor = [[UIColor blackColor] CGColor];
    
    self.labelStatus.layer.borderWidth = ELEMENT_BORDER_WIDTH;
    self.labelStatus.layer.cornerRadius = ELEMENT_CORNER_RADIUS;
    self.labelStatus.layer.borderColor = [[UIColor blackColor] CGColor];
    
    [self.textViewOnTopic setScrollEnabled:true];
    self.textViewOnTopic.editable = false;
    
    [self.textViewUDPMessages setScrollEnabled:true];
    self.textViewUDPMessages.editable = false;
    
    self.textviewIPs.scrollEnabled = true;
    self.textviewIPs.editable = false;
    self.textviewIPs.selectable = true;
    
    self.textviewIPs.layer.borderWidth = ELEMENT_BORDER_WIDTH;
    self.textviewIPs.layer.cornerRadius = ELEMENT_CORNER_RADIUS;
    self.textviewIPs.layer.borderColor = [[UIColor blackColor] CGColor];
    
    NSDictionary *dictAddress = [self getIPAddresses];
    
    self.arrayAddress = [[NSMutableArray alloc] init];
    for ( NSString *key in dictAddress.keyEnumerator ) {
        [self.arrayAddress addObject:dictAddress[key]];
    }
    
    self.pickerIP.dataSource = self;
    self.pickerIP.delegate = self;
    
    [self registerForKeyboardNotifications];
    
    self.textIP.delegate = self;
    self.textPort.delegate = self;
    self.textTopic.delegate = self;
    self.textMessage.delegate = self;
    self.textSIPIP.delegate = self;
    self.textCallTo.delegate = self;
    self.nameSelf.delegate = self;
    self.textSTUNAdr.delegate = self;
    self.textUDPPortNumber.delegate = self;
    self.textUDPToIP.delegate = self;
    self.textUDPToPort.delegate = self;
    self.textUDPMessage.delegate = self;
    
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = YES;
    
    self.scrollView.contentSize = CGSizeMake( self.view.frame.size.width, self.view.frame.size.height + 300);
    
    NSArray *arTextFields = @[self.textUDPPortNumber, self.textUDPToIP, self.textUDPToPort, self.textUDPMessage ];
    
    for ( UITextField *textField in arTextFields ) {
        if ( textField.accessibilityIdentifier == nil )
            continue;
        
        id textData = [[NSUserDefaults standardUserDefaults] objectForKey:textField.accessibilityIdentifier];
        
        if ( textData != nil )
            textField.text = textData;
        
       // textField.text = textData;
    }

    
    
 //   MQTTServiceMy *myService = [MQTTServiceMy SharedCurrencyService];
  //  myService.sessionMQQT.delegate = self;
    //[[MQTTServiceMy SharedCurrencyService] setDelegate:self.handleMessage)];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)buttonConnectPressed:(id)sender {
    
   /* CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef) self.textIP.text);
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
    //if (!isSuccess) return nil;
    CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);

    
    char ipAddress[256];
    NSMutableArray *addresses = [NSMutableArray array];
    CFIndex numAddresses = CFArrayGetCount(addressesRef);
    for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
        struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addressesRef, currentIndex));
        if (address == nil) return;
        getnameinfo(address, address->sa_len, ipAddress, 256, nil, 0, NI_NUMERICHOST);
        if (ipAddress == nil) return ;
        [addresses addObject:[NSString stringWithCString:ipAddress encoding:NSASCIIStringEncoding]];
    }
    
    NSString *stNewAddress = [addresses objectAtIndex:0];
    */
    
    if ( self.switchTLS.on ) {
        NSString *certificate = [[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"crt"];
        [[MQTTServiceMy SharedCurrencyService] addCerteficate:certificate];
        CGFloat c = 1.f;
    }
        
    
    [[MQTTServiceMy SharedCurrencyService] connectToServer:self.textIP.text port:[self.textPort.text intValue] useTLS:self.switchTLS.on ];
}

- (IBAction)buttonTopicRemove:(id)sender {
    [[MQTTServiceMy SharedCurrencyService] unsubscribeFromTopic:self.textTopic.text ];
}

- (IBAction)buttonTopicAdd:(id)sender {
    [[MQTTServiceMy SharedCurrencyService] subscribeToTopic:self.textTopic.text ];
}
- (IBAction)buttonSendMesPressed:(id)sender {
    [[MQTTServiceMy SharedCurrencyService] publishData:self.textMessage.text topic:self.textTopic.text retainedMsg:YES];
}

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
   // NSString *senderString = [topic substringFromIndex:self.base.length + 1];
    
    //[self.chat insertObject:[NSString stringWithFormat:@"%@:\n%@", senderString, dataString] atIndex:0];
    //[self.tableView reloadData];
}

-(void)updateLabelStatus:(NSNotification *)statusNotification{
    self.labelStatus.text = statusNotification.userInfo[@"status"];
}
- (IBAction)buttonDisconnectPressed:(id)sender {
    [[MQTTServiceMy SharedCurrencyService] disconnect ];
}

-(void)addTopicMessage:(NSNotification *)statusNotification{
    self.textViewOnTopic.text = [self.textViewOnTopic.text stringByAppendingString:statusNotification.userInfo[@"data"]];
    
    if(self.textViewOnTopic.text.length > 0 ) {
        NSRange bottom = NSMakeRange(self.textViewOnTopic.text.length -1, 1);
        [self.textViewOnTopic scrollRangeToVisible:bottom];
    }
   
}
- (IBAction)onButtonConnectSIP:(id)sender {
    [[SIPpj SharedCurrencyService] startSIP:self.nameSelf.text domain:self.textSIPIP.text useServer:TRUE srvSTUN:self.textSTUNAdr.text useSTUN:self.useSTUN.on ];
}

- (IBAction)onButtonDisconnectSIP:(id)sender {
     [[SIPpj SharedCurrencyService] stopSIP ];
}

-(void)onIncomingCall:(NSNotification *)callInfo{
    
    NSMutableString *mesText = [[NSMutableString alloc] initWithString:callInfo.userInfo[@"ID"]];
    [mesText insertString:@"From " atIndex:0];
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Incoming call"
                                 message:mesText
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [[SIPpj SharedCurrencyService] answerCall];
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                    [[SIPpj SharedCurrencyService] hangUpCall];
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)buttonMakeCall:(id)sender {
    [[SIPpj SharedCurrencyService] makeCall:self.textCallTo.text ];
}

- (IBAction)buttonHangup:(id)sender {
    [[SIPpj SharedCurrencyService] hangUpCall ];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event {
    
    [ self.view endEditing:YES];
}
- (IBAction)onButtonRegister:(id)sender {
    NSString *ipAddr = self.arrayAddress[ [self.pickerIP selectedRowInComponent:0] ];
    [[SIPpj SharedCurrencyService] startSIP:self.nameSelf.text domain:ipAddr useServer:FALSE srvSTUN:self.textSTUNAdr.text useSTUN:self.useSTUN.on ];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.arrayAddress.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.arrayAddress[row];
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* pickerLabel = (UILabel*)view;
    
    if (!pickerLabel)
    {
        pickerLabel = [[UILabel alloc] init];
        
        pickerLabel.font = [UIFont systemFontOfSize:14.0];
        
        pickerLabel.textAlignment=NSTextAlignmentCenter;
    }
    [pickerLabel setText:self.arrayAddress[row]];
    
    return pickerLabel;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
   
}


// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
   /* NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:activeField.frame animated:NO];
    }*/
    CGRect mainFrame = activeField.superview.superview.frame;
    CGRect elementFrame = activeField.frame;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
   // CGRect bkgndRect = activeField.superview.frame;
    
    if ( ( elementFrame.origin.y + elementFrame.size.height ) > ( mainFrame.size.height - kbSize.height ) ) {
        
        
        [self.scrollView setContentOffset:CGPointMake(0.0, elementFrame.origin.y + elementFrame.size.height - 50.0) animated:YES];
    }
        
    
    //bkgndRect.size.height += kbSize.height;
    //[activeField.superview setFrame:bkgndRect];
    
    //int b = kbSize.height;
    
   
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    /*UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
     */
     //[self.scrollView setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
    [self.scrollView setContentOffset:scrollOffsetPrevious animated:YES];
    
    self.scrollView.contentSize = CGSizeMake( self.view.frame.size.width, self.view.frame.size.height + 300);
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    scrollOffsetPrevious = self.scrollView.contentOffset;
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
    [textField resignFirstResponder];
    if ( textField.accessibilityIdentifier != nil )
        [self saveUserDefaults:textField.accessibilityIdentifier data:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


- (IBAction)onScrollViewTapped:(id)sender {
    [self.view endEditing:YES];
}

-(void)onTPState:(NSNotification *)tpInfo{
    int tpState = tpInfo.userInfo[@"state"];
    int a = 1;
}

-(void)appendStringToUDPMessages:(NSString*)appendString {
    appendString = [ appendString stringByAppendingString:@"\r\n"];
    self.textViewUDPMessages.text = [self.textViewUDPMessages.text stringByAppendingString:appendString];
    
    if(self.textViewUDPMessages.text.length > 0 ) {
        NSRange bottom = NSMakeRange(self.textViewUDPMessages.text.length -1, 1);
        [self.textViewUDPMessages scrollRangeToVisible:bottom];
    }
}

- (IBAction)buttonBindPressed:(id)sender {
    
    [[UDPSocket SharedUDPSocket] setUdpPortNumber:self.textUDPPortNumber.text.intValue];
    BOOL bResult = [[UDPSocket SharedUDPSocket] initUDPSocket];
    if ( !bResult )
        [self appendStringToUDPMessages:@"Failed to Bind!"];
    else
    {
        int iPort = [[UDPSocket SharedUDPSocket] askForBindedPort];
        NSString *string = [[NSString alloc] initWithFormat:@"Binded UDP Port = %d", iPort ];
        [self appendStringToUDPMessages: string];
        
    }
    
    
    
    
}
- (IBAction)buttonSendPressed:(id)sender {
    [[UDPSocket SharedUDPSocket] sendText:self.textUDPMessage.text toIP:self.textUDPToIP.text toPort:self.textUDPToPort.text.intValue];
    
}

- (IBAction)btnTalkPressed:(id)sender {
    if ( [[AudioRecording SharedAudioRecord] isRecording] == NO) {
        [[UDPSocket SharedUDPSocket] sendText:@"STARTT" toIP:self.textUDPToIP.text toPort:self.textUDPToPort.text.intValue];
        
        [[UDPSocket SharedUDPSocket] setUdpPortToNumber:self.textUDPToPort.text.intValue];
        [[UDPSocket SharedUDPSocket] setUdpIPTo:self.textUDPToIP.text];
        [[AudioRecording SharedAudioRecord] startRecord ];
    }
    else {
      
        [[UDPSocket SharedUDPSocket] sendText:@"STOPP" toIP:self.textUDPToIP.text toPort:self.textUDPToPort.text.intValue];
          [[AudioRecording SharedAudioRecord] stopRecord];
    }
    
    
}

-(void)onUDPMessage:(NSNotification *)tpInfo{
    NSString *stringInfo = [[NSString alloc] initWithFormat:@"%@:%@ %@", tpInfo.userInfo[@"hostFrom"], tpInfo.userInfo[@"postFrom"], tpInfo.userInfo[@"message"]];
    
    [self appendStringToUDPMessages: stringInfo];
                            
    
}

-(void)saveUserDefaults:(NSString*)idName data:(id)idData {
    
    [[NSUserDefaults standardUserDefaults] setObject:idData forKey:idName];
    [[NSUserDefaults standardUserDefaults] synchronize];

}
@end
