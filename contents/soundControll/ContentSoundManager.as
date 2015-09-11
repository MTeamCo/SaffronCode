package contents.soundControll
{
	import contents.Contents;
	
	import flash.display.Stage;
	import flash.net.SharedObject;
	
	import soundPlayer.SoundPlayer;

	public class ContentSoundManager
	{
		public static const MusicID:uint = 1001,
							MusicID2:uint = 1004,
							EffectsID:uint = 1002,
							NarationID:uint = 1003;
		
		private static var lastMusicState:SharedObject = SharedObject.getLocal('lastMusicState','/');
		
		/**This is the last playing music*/
		private static var lastPlayingMusic:String ;
		
		/**2 sound id to swap musics smoothly*/
		private static var currentSoundId:uint,
							otherSoundId:uint;
							
		public static function setUp(myStage:Stage)
		{
			currentSoundId = Contents.id_music ;
			otherSoundId = Contents.id_music2 ;
			
			SoundPlayer.setUp(myStage,true,false);
			//SoundPlayer.addSound(Contents.homePage.musicURL,Contents.id_music,true,1);
			changeMainMusic();
			
			if(lastMusicState.data.state == undefined)
			{
				lastMusicState.data.state = true ;
				lastMusicState.flush();
			}
			
			if(lastMusicState.data.state)
			{
				SoundPlayer.play(currentSoundId);
			}
		}
		
		public static function get MusicIsPlaying():Boolean
		{
			//Forgotten ! befor the return solved on 94-06-20
			return !SoundPlayer.getStatuse_pause(currentSoundId);
		}
		
		public static function startMusic()
		{
			SoundPlayer.play(currentSoundId);
			lastMusicState.data.state = true ;
			lastMusicState.flush();
		}
		
		public static function pauseMusic()
		{
			SoundPlayer.pause(currentSoundId);
			lastMusicState.data.state = false ;
			lastMusicState.flush();
		}
		
		public static function muteMusic()
		{
			SoundPlayer.volumeContril(currentSoundId,0);
		}
		
		public static function unMuteMusit()
		{
			SoundPlayer.volumeContril(currentSoundId,1);
		}
		
		/**This will change the current playing music ( not tested yet )*/
		public static function changeMainMusic(musicURL:String='',volume:Number=1):void
		{
			// TODO Auto Generated method stub
			//SoundPlayer.pause(currentSoundId);
			var musicWasPlaying:Boolean = MusicIsPlaying ;
			if(musicURL=='')
			{
				musicURL = Contents.homePage.musicURL ;
			}
			if(lastPlayingMusic == musicURL)
			{
				trace("Music is duplicated on ContentSoundManager.changeMainMusic : "+musicURL);
				return ;
			}
			
			trace("Change the music to : "+musicURL);
			trace("Change volume to : "+volume);
			
			SoundPlayer.pause(currentSoundId);
			SoundPlayer.addSound(musicURL,otherSoundId,true,volume);
			if(lastPlayingMusic==null || musicWasPlaying)
			{
				trace("lastPlayingMusic : "+lastPlayingMusic);
				trace("musicWasPlaying : "+musicWasPlaying);
				SoundPlayer.play(otherSoundId);
			}
			
			lastPlayingMusic = musicURL ;
			
			otherSoundId = otherSoundId+currentSoundId ;
			currentSoundId = otherSoundId-currentSoundId ;
			otherSoundId = otherSoundId-currentSoundId;
		}
	}
}