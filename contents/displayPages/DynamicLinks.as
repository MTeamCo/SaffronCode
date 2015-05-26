/***Version
 * 	1.1 : Save the last position of the scrollMT for each pageID to load it from that position later
 * 	1.1.1 : when the menu was empty, it will cause an error on leave stage.
 * 	1.2 : 	add function added to add linkData to old link datas
 * 			DynamicLinks can request more links. you can set this on setUp function at the beggining.
 * 			3 new functions : canGetMore, addLinks, noMoreLinks
 * 	1.3 : revertY Activated. if the 0,0 point for the menu is bottom of the movieClip, it will generate reverted menu like Viber text messages page
 * 	1.3.1 : dynamic deltaY is created by MyDeltaY value
 * 
 * 
 */


package contents.displayPages
	//contents.displayPages.DynamicLinks
{
	import contents.LinkData;
	import contents.PageData;
	import contents.interFace.DisplayPageInterface;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class DynamicLinks extends MovieClip implements DisplayPageInterface
	{
		public static const UPDATE_LINKS_POSITION:String = "UPDATE_LINKS_POSITION" ;
		
		
		private static var scrollPosesObject:Object = {} ;
		
		private const backAlpha:Number = 0 ;
		
		protected var myPageData:PageData ;
		
		protected var sampleLink:LinkItem,
					linkClass:Class;
					
		protected var 	linkScroller:ScrollMT,
						areaRect:Rectangle,
						linksContainer:Sprite,
						linksSensor:Sprite ;
						
		/**This is the list of creted linkItems on the stage.*/
		private var linksInterfaceStorage:Vector.<LinkItem> ;
					
		protected var lastGeneratedLinkIndes:uint ;
		
		public static var deltaY:Number = 20 ;
		
		public var myDeltaY:Number ;
		
		private var noLinksMC:MovieClip ;
		
		//New values
		/**It will call the parent for more links if there is and until then, it will shows preloader*/
		private var requestMore:Function;
		
		/**Preloader for more datas*/
		private var requestPreLoader:Sprite ;
		/**This will prevent scroller to have animation if there is.*/
		public var acceptAnimation:Boolean = true;
		
		private var reverted:Boolean = false ;
		
		/**returns Y direction by reverted value*/
		protected function get Ydirection():int
		{
			if(reverted)
			{
				return -1 ;
			}
			else
			{
				return 1 ;
			}
		}
		
		/**1-Cereate LinkItem on this pages<br>
		 * 2- Draw a shape to define scrollArea in this object*/
		public function DynamicLinks()
		{
			super();
			
			this.addEventListener(UPDATE_LINKS_POSITION,updateLinksPosition);
			
			myDeltaY = deltaY ;
			
			//This will automaticaly removes at the last line
			noLinksMC = Obj.get("no_link_mc",this);
			
			areaRect = this.getBounds(this);
			
			sampleLink = Obj.findThisClass(LinkItem,this,true);
			if(sampleLink ==null)
			{
				throw "Dynamic manu class shouldent be empty of linkItem!";
			}
			
			linkClass = getDefinitionByName(getQualifiedClassName(sampleLink)) as Class;
			trace('link class is : '+linkClass);
			
			//Controll it by it's height to prevent revert activating at most of times.
			if(this.getBounds(this).y<this.height/-2)
			{
				trace("*****Reverted menu activated******");
				reverted = true ;
			}
			
			this.removeChildren();
		}
		
		
		/**This will change the scroll area value but you have to call setUp after this functin*/
		public function chageHeight(newValue:Number):void
		{
			if(reverted)
			{
				trace("**********************Revert added");
				areaRect.top = newValue*-1 ;
				areaRect.bottom = 0 ;
			}
			else
			{
				areaRect.height = newValue ;
			}
		}
		
		override public function set height(value:Number):void
		{
			chageHeight(value);
		}
		
		override public function get width():Number
		{
			return areaRect.width ;
		}
		
		override public function set width(value:Number):void
		{
			areaRect.width = value ;
		}
		
		override public function get height():Number
		{
			if(areaRect == null )
			{
				return super.height;
			}
			else
			{
				return areaRect.height ;
			}
		}
		
		/**Call this after setUp*/
		public function canGetMore(youCanRequestForMore:Function,preLoaderObject:Sprite):void
		{
			requestMore = youCanRequestForMore ;
			requestPreLoader = preLoaderObject ;
		}
		
		public function setUp(pageData:PageData):void
		{
			//new functions
			if(requestPreLoader==null)
			{
				requestPreLoader = new Sprite(); 
			}
			if(requestMore==null)
			{
				requestMore = new Function() ;
			}
			
			//reset cashed list
			linksInterfaceStorage = new  Vector.<LinkItem>();
			
			//trace("current page data is : "+pageData.export());
			this.removeChildren();
			myPageData = pageData;
			if(pageData.links1.length == 0 && noLinksMC!=null)
			{
				this.addChild(noLinksMC);
			}
			else
			{
				createLinks();
			}
			this.addEventListener(Event.REMOVED_FROM_STAGE,saveLastY);
			this.addEventListener(Event.REMOVED_FROM_STAGE,saveLastY);
		}
		
		private function saveLastY(event:Event):void
		{
			// TODO Auto-generated method stub
			if(linksContainer!=null && myPageData.id!='')
			{
				//trace("*.Last Y : "+linksContainer.y);
				if(myPageData.id!='')
				{
					scrollPosesObject[myPageData.id] = linksContainer.y ;
				}
			}
		}
		
		private function createLinks()
		{
			trace("Creat links");
			lastGeneratedLinkIndes = 0 ;
			/*Bellow movieClips are allready removed by removeAllChildren() function by setUp function.
			if(linkScroller!=null)
			{
				linkScroller.reset();
			}
			
			if(linksContainer!=null)
			{
				this.removeChild(linksContainer);
			}	*/
			
			
			linksContainer = new Sprite();
			linksContainer.x = areaRect.x ;
			if(reverted)
			{
				linksContainer.y = areaRect.y+areaRect.height ;
			}
			else
			{
				linksContainer.y = areaRect.y ;
			}
			linksContainer.graphics.beginFill(0,backAlpha) ;
			linksContainer.graphics.drawRect(0,0,areaRect.width,areaRect.height*Ydirection) ;
			
			this.addChild(linksContainer);
		
			
			linksSensor = new Sprite();
			linksSensor.y = deltaY*Ydirection ;
			linksSensor.graphics.beginFill(0xff0000,0);
			linksSensor.graphics.drawRect(0,0,areaRect.width,areaRect.height/2*Ydirection);
			linksSensor.mouseChildren = false ;
			linksSensor.mouseEnabled = false ;
			
			linksContainer.addChild(linksSensor);
			
			if(myPageData.id!='' && scrollPosesObject[myPageData.id]!=null)
			{
				linksContainer.y = scrollPosesObject[myPageData.id];
				controllSensor();
			}
			
			linkScroller = new ScrollMT(linksContainer,areaRect,/*areaRect*/null,true,false,acceptAnimation&&!reverted,reverted);
			if(myPageData.id!='' && scrollPosesObject[myPageData.id]!=null)
			{
				if(scrollPosesObject[myPageData.id]<areaRect.y-1)
				{
					linkScroller.stopFloat();
				}
				linkScroller.setPose(areaRect.x,scrollPosesObject[myPageData.id]);
				controllSensor();
			}
			
			this.addEventListener(Event.ENTER_FRAME,controllSensor);
			this.addEventListener(Event.REMOVED_FROM_STAGE,unLoad);
		}
		
		/**Adds more links to links list. but if there is no link any more, you have to call noMoreLinks() funcion to remove preloader*/
		public function addLink(listOfLinks:Vector.<LinkData>):void
		{
			trace("controll again");
			myPageData.links1 = myPageData.links1.concat(listOfLinks);
			
			this.addEventListener(Event.ENTER_FRAME,controllSensor);
			this.addEventListener(Event.REMOVED_FROM_STAGE,unLoad);
		}
		
		
		
		/**This will returns my links length*/
		public function get length():uint
		{
			if(myPageData == null || myPageData.links1 == null)
			{
				return 0 ;
			}
			return myPageData.links1.length  ;
		}
		
		private function unLoad(ev:Event=null)
		{
			this.removeEventListener(Event.ENTER_FRAME,controllSensor) ;
			this.removeEventListener(Event.REMOVED_FROM_STAGE,unLoad) ;
		}
		
		private function controllSensor(ev:Event=null)
		{
			var sens:Rectangle = linksSensor.getBounds(this);
			if((!reverted && sens.top<areaRect.bottom) || (reverted && sens.bottom>areaRect.top))
			{
				var ifTherIs:Boolean = creatOneLink();
				if(ifTherIs)
				{
					requestPreLoader.visible = false ;
					//Call this recursive function after preloader is invisible
					controllSensor();
				}
				else
				{
					unLoad();
					linksContainer.addChild(requestPreLoader);
					requestPreLoader.y = linksSensor.y ;
					requestPreLoader.x = areaRect.width/2 ;
					requestPreLoader.visible = true ;
					//Call below function after preloader added.
					requestMore();
				}
			}
		}
		
		/**This will just remove preloader from list*/
		public function noMoreLinks():void
		{
			//linksContainer.removeChild(requestPreLoader);
			requestPreLoader.visible = false ;
			
			//New lines to prevent any more requests till canGetMore functin calls again.
			requestMore = new Function() ;
			requestPreLoader = new Sprite() ;
			
		}
		
		private function creatOneLink():Boolean
		{
			// TODO Auto Generated method stub
			if(lastGeneratedLinkIndes<myPageData.links1.length)
			{
				for(var i = 0 ; i<howManyLinksGenerates && lastGeneratedLinkIndes<myPageData.links1.length ; i++)
				{
					var newLink:LinkItem = new linkClass() ;
					linksContainer.addChild(newLink) ;
					newLink.setUp(myPageData.links1[lastGeneratedLinkIndes]) ;
					
					createLinkOn(newLink,linksSensor);
					
					linksInterfaceStorage.push(newLink);
					
					linksContainer.graphics.clear();
					linksContainer.graphics.beginFill(0,backAlpha) ;
					linksContainer.graphics.drawRect(0,0,areaRect.width,linksSensor.y) ;
					
					lastGeneratedLinkIndes++ ;
				}
				return true ;
			}
			else
			{
				return false ;
			}
		}
		
		
		/**This will update links position from 0*/
		public function updateLinksPosition(e:Event=null):void
		{
			if(e!=null)
			{
				e.stopImmediatePropagation();
			}
			var l:uint = linksInterfaceStorage.length ;
			//var Y:Number = myDeltaY*Ydirection ;
			for(var i = 1 ; i<l ; i++)
			{
				linksInterfaceStorage[i].y = linksInterfaceStorage[i-1].y+(linksInterfaceStorage[i-1].height+myDeltaY)*Ydirection;
			}
			linksSensor.y = linksInterfaceStorage[i-2].y+(linksInterfaceStorage[i-2].height+myDeltaY)*Ydirection;
		}
		
		
		/**Return the number of generated links for each lik generation*/
		protected function get howManyLinksGenerates():uint
		{
			return 1 ;
		}
		
		/**use currentLinksSensor to move it down and use its position and to know menuWidth from currentLinksSensor.width<br>
		 * DONT FORGET TO MOVE currentLinksSensor DOWN WHEN YOU USE IT<br>
		 *  newLink.x = (areaRect.width-newLink.width)/2 ;<br>
			newLink.y = linksSensor.y ;<br>
			linksSensor.y += newLink.height+deltaY ;<br>*/
		protected function createLinkOn(newLink:LinkItem,currentLinksSensor:Sprite):void
		{
			newLink.x = (areaRect.width-newLink.width)/2 ;
			if(reverted)
			{
				newLink.y = linksSensor.y-newLink.height ;
			}
			else
			{
				newLink.y = linksSensor.y ;
			}
			linksSensor.y += (newLink.height+myDeltaY)*Ydirection ;
			//trace(" linksSensor.y : "+linksSensor.y) ;
		}
	}
}