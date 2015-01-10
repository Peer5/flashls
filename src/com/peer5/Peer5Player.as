package com.peer5 {
    import flash.external.ExternalInterface;
    import flash.display.*;
    import flash.utils.setTimeout;
    import flash.events.*;
    import org.mangui.hls.utils.*;
    import flash.geom.Rectangle;
    import flash.system.Security;

    import org.mangui.chromeless.ChromelessPlayer;
    import com.peer5.Peer5URLStream;
    import com.peer5.PlaybackIdHolder;

    public class Peer5Player extends ChromelessPlayer {
        private var idHolder:PlaybackIdHolder;

        public function Peer5Player() {
            super();
            ExternalInterface.call("console.log", "Peer5 Player (0.0.1)");
            idHolder = PlaybackIdHolder.getInstance();
            idHolder.playbackId = LoaderInfo(this.root.loaderInfo).parameters.playbackId;
        }

        override protected function _setupExternalGetters():void {
            ExternalInterface.addCallback("globoGetDuration", _getDuration);
            ExternalInterface.addCallback("globoGetState", _getPlaybackState);
            ExternalInterface.addCallback("globoGetPosition", _getPosition);
            ExternalInterface.addCallback("globoGetType", _getType);
            ExternalInterface.addCallback("globoGetLevel", _getLevel);
            ExternalInterface.addCallback("globoGetLevels", _getLevels);
            ExternalInterface.addCallback("globoGetbufferLength", _getbufferLength);
            ExternalInterface.addCallback("globoGetAutoLevel", _getAutoLevel);
            ExternalInterface.addCallback("getmaxBufferLength", _getmaxBufferLength);
            ExternalInterface.addCallback("getminBufferLength", _getminBufferLength);
            ExternalInterface.addCallback("getlowBufferLength", _getlowBufferLength);
        }

        override protected function _setupExternalCallers():void {
            ExternalInterface.addCallback("globoPlayerLoad", _load);
            ExternalInterface.addCallback("globoPlayerPlay", _play);
            ExternalInterface.addCallback("globoPlayerPause", _pause);
            ExternalInterface.addCallback("globoPlayerResume", _resume);
            ExternalInterface.addCallback("globoPlayerSeek", _seek);
            ExternalInterface.addCallback("globoPlayerStop", _stop);
            ExternalInterface.addCallback("globoPlayerVolume", _volume);
            ExternalInterface.addCallback("globoPlayerSetLevel", _setLevel);
            ExternalInterface.addCallback("globoPlayerSmoothSetLevel", _smoothSetLevel);
            ExternalInterface.addCallback("globoPlayerSetflushLiveURLCache", _setflushLiveURLCache);
            ExternalInterface.addCallback("globoPlayerSetmaxBufferLength", _setmaxBufferLength);
            ExternalInterface.addCallback("globoPlayerSetminBufferLength", _setminBufferLength);
            ExternalInterface.addCallback("globoPlayerSetlowBufferLength", _setlowBufferLength);
            ExternalInterface.addCallback("globoPlayerCapLeveltoStage", _setCapLeveltoStage);
        }

        override protected function _onStageVideoState(event : StageVideoAvailabilityEvent) : void {
            super._onStageVideoState(event);
            _hls.URLstream = Peer5URLStream as Class;
        }
    }
}
