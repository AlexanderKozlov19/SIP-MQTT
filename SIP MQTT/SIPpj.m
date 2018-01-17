//
//  SIPpj.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 16.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import "SIPpj.h"
#include <pjsua-lib/pjsua.h>

@implementation SIPpj

@synthesize sessionSIP;

static pjsua_acc_id acc_id;
static pjsua_acc_id curCallID;

const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void error_exit(const char *title, pj_status_t status);
//static void on_tp_state_callback(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info);

//static int startPjsip(char *sipUser, char* sipDomain);

+ (id)SharedCurrencyService {
    static SIPpj *sharedCurrencyService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCurrencyService = [[self alloc] init];
        sharedCurrencyService.sessionSIP = [[SIPpj alloc] init];
        //sharedCurrencyService.sessionMQQT.delegate = self;
        
    });
    return sharedCurrencyService;
    
    
}
 void on_transport_state(pjsip_transport *tp,
                               pjsip_transport_state state,
                               const pjsip_transport_state_info *info) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary *dictError = [NSDictionary dictionaryWithObject: @(state) forKey:@"state"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onTPState" object:nil userInfo:dictError];
    });
    
}


static pjsua_acc_id the_acc_id;
static pjsip_transport *the_transport;
static char sipId[MAX_SIP_ID_LENGTH];
static char regUri[MAX_SIP_REG_URI_LENGTH];
static bool bUseServerSave;

static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info)
{
  
    struct pjsip_regc_cbparam *rp = info->cbparam;
    pjsip_tp_state_callback addr = pjsip_tpmgr_get_state_cb( rp->rdata->tp_info.transport->tpmgr);
    pjsip_tp_state_listener_key *temp;
    pj_status_t res = pjsip_transport_add_state_listener( rp->rdata->tp_info.transport, &on_transport_state, NULL, &temp );
    int a = 1;
    return;
    //pjsip_tpmgr_get_state_cb
    
   // ...
  //  if (acc_id != the_acc_id)
  //      return;
    
    if (rp->code/100 == 2 && rp->expiration > 0 && rp->contact_cnt > 0) {
        /* Registration success */
        if (the_transport) {
        //    PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
            pjsip_transport_dec_ref(the_transport);
            the_transport = NULL;
        }
        /* Save transport instance so that we can close it later when
         * new IP address is detected.
         */
     //   PJ_LOG(3,(THIS_FILE, "xxx: Saving transport.."));
        the_transport = rp->rdata->tp_info.transport;
        pjsip_transport_add_ref(the_transport);
    } else {
        if (the_transport) {
       //     PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
            pjsip_transport_dec_ref(the_transport);
            the_transport = NULL;
        }
    }
   // ...
}


 void on_pj_stun_resolve_cb(const pj_stun_resolve_result *result)
{
    pj_status_t status;
    pjsua_transport_id udpTransID;
    
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, &udpTransID);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
        
        
    }
    /*
     // Add TCP transport.
     {
     // Init transport config structure
     pjsua_transport_config cfg;
     pjsua_transport_config_default(&cfg);
     cfg.port = 5060;
     
     // Add TCP transport.
     status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
     if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
     }
     */
    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        cfg.sip_stun_use = PJSUA_STUN_USE_DEFAULT;
        cfg.media_stun_use = PJSUA_STUN_USE_DEFAULT;

        
        
        //char sipId[MAX_SIP_ID_LENGTH];
       
        cfg.id = pj_str(sipId);
        
        //char regUri[MAX_SIP_REG_URI_LENGTH];
        //sprintf(regUri, "sip:%s", sipDomain);
        cfg.reg_uri = pj_str(regUri);
        
        
        if ( bUseServerSave )
            status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        else
            status = pjsua_acc_add_local(udpTransID, PJ_TRUE, &acc_id);
        if (status != PJ_SUCCESS) error_exit("Error adding account", status);
    }
}


int startPjsip(char *sipUser, char* sipDomain, bool bUseServer, char *stunServer, bool bUseSTUN )
{
    pjsua_state curState = pjsua_get_state();
    
    
    pj_status_t status = PJ_SUCCESS;
    
    // Create pjsua first
    if ( curState == PJSUA_STATE_NULL )
      status = pjsua_create();
    if (status != PJ_SUCCESS) error_exit("Error in pjsua_create()", status);
    
    if ( bUseServer )
        sprintf(sipId, "sip:%s@%s", sipUser, sipDomain);
    else
        sprintf(sipId, "sip:%s", sipDomain);
    
    sprintf(regUri, "sip:%s", sipDomain);
    
    bUseServerSave = bUseServer;
    
    // Init pjsua
    {
        // Init the config structure
        pjsua_config cfg;
        pjsua_config_default (&cfg);
        
        cfg.cb.on_incoming_call = &on_incoming_call;
        cfg.cb.on_call_media_state = &on_call_media_state;
        cfg.cb.on_call_state = &on_call_state;
      //  cfg.cb.on_reg_state2 = &on_reg_state2;
        cfg.cb.on_transport_state = (pjsip_tp_state_callback)&on_transport_state;
        cfg.cb.on_stun_resolution_complete = &on_pj_stun_resolve_cb;
       // cfg.cb.on_reg_started = &on_reg_started;
        
        
        
        if ( bUseSTUN ) {
            cfg.stun_srv_cnt = 1;
            cfg.stun_srv[0] = pj_str(stunServer);
        }
        
        
        
        // Init the logging config structure
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
        
        // Init the pjsua
        curState = pjsua_get_state();
        if ( curState < PJSUA_STATE_INIT )
          status = pjsua_init(&cfg, &log_cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error in pjsua_init()", status);
    }
    if ( bUseSTUN ) return 0;
    
    // Add UDP transport.
    pjsua_transport_id udpTransID;
    
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, &udpTransID);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
        
      
    }
    /*
    // Add TCP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    */
    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        if ( bUseSTUN ) {
            cfg.sip_stun_use = PJSUA_STUN_USE_DEFAULT;
            cfg.media_stun_use = PJSUA_STUN_USE_DEFAULT;
        }
        else {
            cfg.sip_stun_use = PJSUA_STUN_USE_DISABLED;
            cfg.media_stun_use = PJSUA_STUN_USE_DISABLED;
        }

        
        //char sipId[MAX_SIP_ID_LENGTH];
        //if ( bUseServer )
        //    sprintf(sipId, "sip:%s@%s", sipUser, sipDomain);
        //else
        //    sprintf(sipId, "sip:%s", sipDomain);
        cfg.id = pj_str(sipId);
        
        //char regUri[MAX_SIP_REG_URI_LENGTH];
        //sprintf(regUri, "sip:%s", sipDomain);
        cfg.reg_uri = pj_str(regUri);
        
        
        if ( bUseServer )
            status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        else
            status = pjsua_acc_add_local(udpTransID, PJ_TRUE, &acc_id);
        if (status != PJ_SUCCESS) error_exit("Error adding account", status);
    }
    
    return 0;
}

-(void)startSIP:(NSString*)stringUser domain:(NSString*)stringDomain useServer:(BOOL)bUseServer srvSTUN:(NSString*)stunServer useSTUN:(BOOL)bUseSTUN {
    startPjsip( [stringUser UTF8String], [stringDomain UTF8String], bUseServer, [stunServer UTF8String], bUseSTUN);
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    
    pjsua_call_get_info(call_id, &ci);
    
    curCallID = call_id;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary *dictError = [NSDictionary dictionaryWithObject:[NSString stringWithCString: ci.remote_info.ptr encoding:NSASCIIStringEncoding] forKey:@"ID"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onIncomingCall" object:nil userInfo:dictError];
    });
    
    
    // PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
    //           (int)ci.remote_info.slen,
    //           ci.remote_info.ptr));
    
    /* Automatically answer incoming calls with 200/OK */
    //pjsua_call_answer(call_id, 200, NULL, NULL);
}

-(void)answerCall {
   pjsua_call_answer(curCallID, 200, NULL, NULL);
}

-(void)hangUpCall {
   // pjsua_call_hangup(curCallID, 300, NULL, NULL);
    endCall();
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(e);
    
    pjsua_call_get_info(call_id, &ci);
    //  PJ_LOG(3,(THIS_FILE, "Call %d state=%.*s", call_id,
    //             (int)ci.state_text.slen,
    //             ci.state_text.ptr));
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

/* Display error and exit application */
static void error_exit(const char *title, pj_status_t status)
{
    //  pjsua_perror(THIS_FILE, title, status);
    pjsua_destroy();
    exit(1);
}

void makeCall(char* destUri)
{
    pj_status_t status;
    pj_str_t uri = pj_str(destUri);
    
    pjsua_call_setting settings;
    

    pjsua_call_setting_default( &settings );
    settings.vid_cnt = 0;
    
    status = pjsua_call_make_call(acc_id, &uri, 0, &settings, NULL, NULL);
    if (status != PJ_SUCCESS) error_exit("Error making call", status);
}

void endCall()
{
    pjsua_call_hangup_all();
}

pj_bool_t showNotification(pjsua_call_id call_id) {
    BOOL bYes = YES;
    
    return FALSE;
}

-(void)makeCall:(NSString*)callTo {
    makeCall( [callTo UTF8String]);
}

-(void)stopSIP {
    pjsua_destroy();
}


@end
