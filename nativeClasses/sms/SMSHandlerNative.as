package nativeClasses.sms
{
	//import com.doitflash.air.extensions.sms.SMS;
	//import com.doitflash.air.extensions.sms.SMSEvent;
	
	import com.doitflash.air.extensions.sms.SMS;
	import com.doitflash.air.extensions.sms.SMSEvent;
	
	import dataManager.GlobalStorage;
	
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	
	//import com.doitflash.air.extensions.sms.SMS;
	
	public class SMSHandlerNative
	{
		/**com.doitflash.air.extensions.sms.SMS*/
		private static var smsClass:Class ;
		
		/**com.doitflash.air.extensions.sms.SMSEvent*/
		private static var smsEventObject:Class ;
		
		private static var sms:SMS ;
		
		private static const smsid:String = '468456456';
		
		private static var 	onDone:Function,
							onFaild:Function,
							
							onMessageReceived:Function;

		private static var lastSMSId:uint;
		
		private static const id_lastsms_id:String = "id_lastsms_id" ;
		
		private static var 	_smsArray:Array = [] ,
							_conversationArray:Array = [] ;
		
		public static function setUp():void
		{
			lastSMSId = uint(GlobalStorage.load(id_lastsms_id));
			if(sms==null && DevicePrefrence.isAndroid())
			{
				try
				{
					smsClass = getDefinitionByName("com.doitflash.air.extensions.sms.SMS") as Class;
					smsEventObject = getDefinitionByName("com.doitflash.air.extensions.sms.SMSEvent") as Class;
					sms = new smsClass();
				}
				catch(e)
				{
					smsClass = null ;
					trace("com.doitflash.air.extensions.sms.SMS is not imported : "+e);
				}
			}
		}
		
		
	///////////////////////////////////////////////////////////////////////////////////////
		
		/**Be ready to get message*/
		public static function listenToGetMessage(onGet:Function,myNumberToListen:uint=785180):void
		{
			if(sms==null)
			{
				trace("SMS native is not supports on this device");
				return ;
			}
			onMessageReceived = onGet ;
			
			sms.addEventListener(SMSEvent.NEW_RECEIVED_SMS, receivedSMS);
			
			// ok, user has started your app but has not received your sms information yet, set the needed parameters
			if (_smsArray.length == 0) 
			{
				trace("Listen to sms receive...");
				sms.addEventListener(SMSEvent.ALL_SMS, allSms);
				sms.addEventListener(SMSEvent.NEW_PERIOD_SMS, allSmsPeriod);
				sms.allSms();
			}
		}
		
		private static function receivedSMS(e:SMSEvent):void
		{
			sms.addEventListener(SMSEvent.ALL_SMS, allSms);
			sms.addEventListener(SMSEvent.NEW_PERIOD_SMS, allSmsPeriod);
			trace("receivedSMS >>", e.param);
			/* if you like you can update information by one of the methods mentioned above
			*/
		}
		
		
				private static function allSms(e:SMSEvent):void
				{
					sms.removeEventListener(SMSEvent.ALL_SMS, allSms);
					sms.removeEventListener(SMSEvent.NEW_PERIOD_SMS, allSmsPeriod);
					_smsArray = e.param;
					_conversationArray = sms.conversation(8);
					trace("received all SMS");
				}
				
				private static function allSmsPeriod(e:SMSEvent):void
				{
					var arr:Array = e.param;
					trace("All sms Period loaded");
				}
		
		public static function canselListenToGetMessage():void
		{
			if(sms==null)
			{
				trace("SMS native is not supports on this device");
				return ;
			}
			
			trace("Cansel listening to sms");
			
			sms.removeEventListener((smsEventObject as Object).SMS_RECEIVED,controllReceivedSMS);
			sms.removeEventListener((smsEventObject as Object).NEW_RECEIVED_SMS,controllReceivedSMS);
			sms.removeEventListener((smsEventObject as Object).NEW_PERIOD_SMS,controllReceivedSMS);
			onMessageReceived = null ;
		}
		
		/**SMS received- if you whant to cansel listening to it, call CanselListenToGetMessage()*/
		protected static function controllReceivedSMS(event:*):void
		{
			trace("SMSs2 are : "+JSON.stringify(sms.smsArrayAfterId));
			//clearInterval(intervalId);
			trace("receved sms is : "+JSON.stringify(event.param,null,' '));
			onMessageReceived();//Dont delete this functin, more sms may come to
		}
	
	///////////////////////////////////////////////////////////////////////////////////////
		
		public static function sendMessage(phoneNumber:String,body:String,onDoneFunction:Function,onFaildFunction:Function):void
		{
			setUp();
			
			onDone = onDoneFunction ;
			onFaild = onFaildFunction ;
			if(sms)
			{
				sms.addEventListener((smsEventObject as Object).SEND_ERROR,sendingFaild);
				sms.addEventListener((smsEventObject as Object).DELIVERY_FAILED,sendingFaild);
				sms.addEventListener((smsEventObject as Object).SEND_SUCCESS,listenToAnswer);
				
				sms.sendSms(phoneNumber,body,smsid);
			}
		}
		
		protected static function listenToAnswer(event:*):void
		{
			trace("SmS snet..."+JSON.stringify(event.param,null,' '));
			trace("SMSs1 are : "+JSON.stringify(sms.smsArray));
			sms.removeEventListener((smsEventObject as Object).SEND_SUCCESS,listenToAnswer);
			
			onFaild = null ;
			calAndDeletFunction(onDone) ;
		}
		
		protected static function sendingFaild(event:Event):void
		{
			trace("Sending fails");
			sms.removeEventListener((smsEventObject as Object).SEND_ERROR,sendingFaild);
			sms.removeEventListener((smsEventObject as Object).DELIVERY_FAILED,sendingFaild);
			sms.removeEventListener((smsEventObject as Object).SEND_SUCCESS,listenToAnswer);
			onDone = null ;
			calAndDeletFunction(onFaild);
		}
		
	////////////////////////////////////////////////////////////
		
		/**Call and delete this function*/
		private static function calAndDeletFunction(func:Function,params:String=null):void
		{
			var cashedFunc:Function = func ;
			func = null ;
			if(params!=null && cashedFunc.length>0)
			{
				cashedFunc(params);
			}
			else
			{
				cashedFunc();
			}
		}
	}
}