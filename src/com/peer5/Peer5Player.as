package com.peer5 {
    import flash.external.ExternalInterface;
    import flash.display.*;
    import flash.utils.setTimeout;
    import flash.events.*;
    import org.mangui.hls.utils.*;
    import flash.geom.Rectangle;
    import flash.system.Security;

    import org.mangui.hls.event.HLSEvent;
    import org.mangui.chromeless.ChromelessPlayer;
    import com.peer5.Peer5URLStream;
    import com.peer5.PlaybackIdHolder;

    public class Peer5Player extends ChromelessPlayer {
        private var idHolder:PlaybackIdHolder;
        private var _timeHandlerCalled:Number = 0;

        public function Peer5Player() {
            super();
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");
            ExternalInterface.call("console.log", "Peer5 Player (0.0.6)");
            idHolder = PlaybackIdHolder.getInstance();
            idHolder.playbackId = LoaderInfo(this.root.loaderInfo).parameters.playbackId;
            setTimeout(flashReady, 50);
        }

        private function _triggerEvent(eventName: String, param:String=null):void {
            var event:String = idHolder.playbackId + ":" + eventName;
            ExternalInterface.call('Clappr.Mediator.trigger', event, param);
        }

        protected function flashReady(): void {
            _triggerEvent('flashready');
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

        override protected function _stateHandler(event : HLSEvent) : void {
            _triggerEvent('playbackstate', event.state);
        }

        override protected function _mediaTimeHandler(event : HLSEvent) : void {
            _duration = event.mediatime.duration;
            _media_position = event.mediatime.position;
            _timeHandlerCalled += 1;

            var videoWidth : int = _video ? _video.videoWidth : _stageVideo.videoWidth;
            var videoHeight : int = _video ? _video.videoHeight : _stageVideo.videoHeight;

            if (videoWidth && videoHeight) {
                var changed : Boolean = _videoWidth != videoWidth || _videoHeight != videoHeight;
                if (changed) {
                    _videoHeight = videoHeight;
                    _videoWidth = videoWidth;
                    _resize();
                    if (videoHeight >= 720) {
                        _triggerEvent('highdefinition', "true");
                    } else {
                        _triggerEvent('highdefinition', "false");
                    }
                }
            }
            if (_timeHandlerCalled == 10) {
                _triggerEvent('timeupdate', _duration + "," + _hls.position);
                _timeHandlerCalled = 0;
            }
        }
    }
}
