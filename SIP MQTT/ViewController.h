//
//  ViewController.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 07.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MQTTSessionManager.h"

@interface ViewController : UIViewController<MQTTSessionManagerDelegate,UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textLogin;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UITextField *textIP;
@property (weak, nonatomic) IBOutlet UITextField *textPort;
@property (weak, nonatomic) IBOutlet UISwitch *switchTLS;

- (IBAction)buttonConnectPressed:(id)sender;
- (IBAction)buttonTopicRemove:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
- (IBAction)buttonDisconnectPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *textTopic;
- (IBAction)buttonTopicAdd:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonTopicRemove;
@property (weak, nonatomic) IBOutlet UITextField *textMessage;
@property (weak, nonatomic) IBOutlet UITextView *textViewOnTopic;
- (IBAction)buttonSendMesPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *textSIPIP;
- (IBAction)onButtonConnectSIP:(id)sender;
- (IBAction)onButtonDisconnectSIP:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textCallTo;
- (IBAction)buttonMakeCall:(id)sender;
- (IBAction)buttonHangup:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *textviewIPs;
@property (weak, nonatomic) IBOutlet UITextField *nameSelf;
- (IBAction)onButtonRegister:(id)sender;
@property (weak, nonatomic) IBOutlet UIPickerView *picketIP;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerIP;

@property (strong, nonatomic) NSMutableArray *arrayAddress;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) UITextField *activeField;
- (IBAction)onScrollViewTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textSTUNAdr;
@property (weak, nonatomic) IBOutlet UISwitch *useSTUN;
@property (weak, nonatomic) IBOutlet UITextField *textUDPPortNumber;
- (IBAction)buttonBindPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textUDPToIP;
@property (weak, nonatomic) IBOutlet UITextField *textUDPToPort;
@property (weak, nonatomic) IBOutlet UITextField *textUDPMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnUDPSendPressed;
@property (weak, nonatomic) IBOutlet UITextView *textViewUDPMessages;
- (IBAction)buttonSendPressed:(id)sender;
- (IBAction)btnTalkPressed:(id)sender;

@property CGPoint scrollOffsetPrevious;

@end

