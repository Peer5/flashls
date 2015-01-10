package tv.bem {
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
            super._setupExternalGetters();
            ExternalInterface.addCallback("getmaxBufferLength", _getmaxBufferLength);
            ExternalInterface.addCallback("getminBufferLength", _getminBufferLength);
            ExternalInterface.addCallback("getlowBufferLength", _getlowBufferLength);
        }

        override protected function _setupExternalCallers():void {
            super._setupExternalCallers();
            ExternalInterface.addCallback("playerSetmaxBufferLength", _setmaxBufferLength);
            ExternalInterface.addCallback("playerSetminBufferLength", _setminBufferLength);
            ExternalInterface.addCallback("playerSetlowBufferLength", _setlowBufferLength);
        }

        override protected function _onStageVideoState(event : StageVideoAvailabilityEvent) : void {
            super._onStageVideoState(event);
            _hls.URLstream = Peer5URLStream as Class;
        }
    }
}
