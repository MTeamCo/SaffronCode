package webService.webCallers
{
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.soap.Operation;
	
	import webService.WebEvent;
	import webService.WebServiceSaver;
	import webService.myWebService;
	
	/**This event dispatches when ofline or server data is ready to use.*/
	[Event(name="complete", type="flash.events.Event")]
	/**This event dispatches when there is no internet connection and there is no ofline data to use. So you have to notify user to controll internet connection.*/
	[Event(name="unload", type="flash.events.Event")]
	/**This event tells that server send an error because of wrong input datas on load() function. It can happens after register or login, because of wrong login or register information.<br><br>
	 * 
	 * This evetn will dispatches befor unload dispatches.*/
	[Event(name="error", type="flash.events.ErrorEvent")]
	/**This event dispatches when an update happend whe you used ofline datas. for example you called and service and requseted offline datas and ofline data was available and it was dispatched with COMPLETE event. then web service will try to load the server datas again and the cahnes between last data and new one is discovered. so it will update the data vlue then this event dispatches.*/
	[Event(name="change", type="flash.events.Event")]
	
	
	public class WebServiceCaller extends EventDispatcher
	{
		//private var reLoader:Timer ;
		private var timerId:uint ;
		
		public var connected:Boolean = false ;
		
		private var myToken:AsyncToken;
		
		private var myParam:Array ;
		
		//public var data:Vector.<GetPhotos>;
		
		//#0
		private var justLoadOffline:Boolean,
					offlineDataIsOK:Boolean;
					
		//private var myServiceFunction:Function ;
					
		private var myOperation:Operation ;
		
		private var myServiceName:String ;
		
		private var offlineDate:Date,
					LoadForDoubleControll:Boolean = false,
					offlineValuesToSend:String = null;//,
					//doNotDispatchEventsAgain:Boolean = false
		
		public function WebServiceCaller(myWebServiceName:String,offlineDataIsOK_v:Boolean=true,justLoadOfline_v:Boolean=false,maximomOfflineData:Date = null)
		{
			//TODO: implement function
			//#4
			offlineDate = maximomOfflineData ;
			
			myServiceName = myWebServiceName ;
			myWebService.activateOperation(myWebServiceName);
			offlineDataIsOK = offlineDataIsOK_v ;
			justLoadOffline = justLoadOfline_v ;
			super();
		}
		
		/**Make this service reloads again*/
		public function reLoad(delay:uint=10000):void
		{
			clearTimeout(timerId);
			/*if(reLoader!=null)
			{
				reLoader.reset();
			}*/
			if(delay==0)
			{
				reLoadLastRequest(/*null*/);
			}
			else
			{
				timerId = setTimeout(reLoadLastRequest,delay);
				/*reLoader = new Timer(delay,1);
				reLoader.addEventListener(TimerEvent.TIMER_COMPLETE,reLoadLastRequest);
				reLoader.start();*/
			}
		}
		
		/**It is tile to reload service*/
		private function reLoadLastRequest(/*e:TimerEvent*/):void
		{
			trace("Service reloaded");
			loadParams.apply(this,myParam);
		}
		
		/**Create load function on extended class to call this function with its own parameters*/
		protected function loadParams(...params):void
		{
			cansel();
			offlineValuesToSend = null ;
			//You have permition to dispatch events now.
			//doNotDispatchEventsAgain = false ;
			myParam = params ;
			//#1
			if(justLoadOffline)
			{
				var cashedData:String = WebServiceSaver.load(this,myParam);
				if(offlineDate!=null && cashedData!=null)
				{
					var controll:Boolean = WebServiceSaver.isExpired(this,myParam,offlineDate);
					LoadForDoubleControll = controll ;
				}
				
				if(cashedData != null)
				{
					generateDataAndDispatchEvent(cashedData,true);
					//doNotDispatchEventsAgain = true ;
					offlineValuesToSend = cashedData ;
					if(LoadForDoubleControll)
					{
	 					myWebService.Connect(onConnected,noInternet);	
					}
				}
				else
				{
 					myWebService.Connect(onConnected,noInternet);	
				}
			}
			else
			{
				myWebService.Connect(onConnected,noInternet);
			}
		}
		
		public function cansel()
		{
			//TODO: implement function
			
			clearTimeout(timerId);
			
			/*if(reLoader!=null)
			{
				reLoader.reset();
				reLoader = null ;
			}*/
			
			myWebService.eventListen.removeEventListener(WebEvent.EVENT_DISCONNECTED,noInternet);
			myWebService.eventListen.removeEventListener(WebEvent.Result,loaded);
			myWebService.Disconnect(onConnected,noInternet);
			myWebService.CanselThisToken(myToken);
		}
		
		private function onConnected()
		{
			trace("connected");
			//TODO: implement function
			myWebService.eventListen.addEventListener(WebEvent.EVENT_DISCONNECTED,noInternet);
			myWebService.eventListen.addEventListener(WebEvent.Result,loaded);
			
			myToken = myWebService.callFunction(myServiceName,myParam);
		}
		
		private function noInternet(e:WebEvent=null)
		{
			//TODO: implement function
			if(e == null || myToken == e.token)
			{
				cansel();
				
				//#2
				if(offlineDataIsOK)
				{
					generateDataAndDispatchEvent(null);
				}
				else
				{
					event_noInternet();
				}
			}
		}
		
		private function loaded(e:WebEvent)
		{
			//TODO: implement function
			if(myToken == e.token)
			{
				connected = true ;
				cansel();
				generateDataAndDispatchEvent(e.pureData);
			}
		}
		
		private function generateDataAndDispatchEvent(pureData:String,dontSaveItAgain:Boolean = false ):void
		{
			//#3
			
			if(pureData==null)
			{
				pureData = WebServiceSaver.load(this,myParam);
				//trace('cash loads : '+pureData);
			}
			else if(offlineDataIsOK && pureData!=null && !dontSaveItAgain)//dontSaveItAgain added to prevent oversaving the cashed data again. it was destroies the save date
			{
				WebServiceSaver.save(this,myParam,pureData);
			}
			if(pureData==null)
			{
				//Why did I remove this event dispatcher? It may forgoten, because it is cause of bug on no connection 
					//dispatchEveryWhere(Event.UNLOAD);
				event_noInternet();
				return ;
			}
			
			//you can even controll the data value from overrided function
			var parsedSituation:Boolean = manageData(pureData);
			
			if(parsedSituation)
			{
				//trace("Load complete");
				//trace("offlineValuesToSend : "+offlineValuesToSend);
				//trace("pureData : "+pureData);
				if(offlineValuesToSend == null && pureData!=null)
				{
					offlineValuesToSend = pureData ;
					//trace("It is the first dispatching time");
					//dispatchEveryWhere(Event.COMPLETE,false);
					event_data();
				}
				else if(offlineValuesToSend != pureData)
				{
					//There is no need to send update
					trace(">Server data is changed");
					//dispatchEveryWhere(Event.COMPLETE,true);
					event_dataUpdated()
				}
				else
				{
					trace(">Server data is steal same as old dispatched data");
				}
			}
			else
			{
				event_wrongInputs();
				event_noInternet();
				//dispatchEveryWhere(ErrorEvent.ERROR);
				//dispatchEveryWhere(Event.UNLOAD);
			}
		}
		
		/**Manage your special data here*/
		protected function manageData(pureData:String):Boolean
		{
			// TODO Auto Generated method stub
			
			//TODO: implement function
			//1- For first type of values
			//	data = Constants.checkWebServiceBoolean(pureData);
			//2- For secend type of values
			/*data = new Vector.<GetPhotos>();
			var cahsedData:Array = WebServiceParser.pars(pureData,GetPhotos);
			for(var i = 0 ; i<cahsedData.length ; i++)
			{
				data.push(cahsedData[i]);
			}*/
			return true ;
		}
		
		//private function eventDispatcher(completedAtTheFirstTime:Boolean=false,Updated:Boolean=false,DataError:Boolean){};
		
		
		
	/////////////////////////New Managed events
		private function event_noInternet():void
		{
			this.dispatchEvent(new Event(Event.UNLOAD));
		}
		
		private function event_wrongInputs():void
		{
			this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
		}
		
		private function event_dataUpdated():void
		{
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function event_data():void
		{
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		//Removed to make any situation dispatchs its own event.
		/*private function dispatchEveryWhere(eventName:String,sendChangeIfSentErlier:Boolean = false )
		{
			//below meand ofline data is not dispatched yet.
			if(offlineValuesToSend==null)//!doNotDispatchEventsAgain)
			{
				if(eventName == ErrorEvent.ERROR)
				{
					this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
				}
				else
				{
					this.dispatchEvent(new Event(eventName));
				}
			}
			else if(sendChangeIfSentErlier)
			{
				this.dispatchEvent(new Event(Event.CHANGE));
				trace("Service Content is Updated");
			}
			else
			{
				trace("I cannot dispatch my events any more : "+eventName);
			}
		}*/
	}
}