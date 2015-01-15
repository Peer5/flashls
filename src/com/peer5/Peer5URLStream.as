package com.peer5 {
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.external.ExternalInterface;
    import org.mangui.chromeless.JSURLStream;
    import com.peer5.PlaybackIdHolder;

    public class Peer5URLStream extends JSURLStream {
        private var idHolder:PlaybackIdHolder;
        private var playbackId:String;
        private var currentUrl:String;

        public function Peer5URLStream(type:String) {
            super();
            idHolder = PlaybackIdHolder.getInstance();
            playbackId = idHolder.playbackId;
            if (type == 'chunk') {
                ExternalInterface.addCallback("resourceLoaded", resourceLoaded);
                ExternalInterface.addCallback("resourceLoadingError", resourceLoadingError);
                ExternalInterface.addCallback("contentLoaded", contentLoaded);
            } else {
                ExternalInterface.addCallback("playlistLoaded", contentLoaded);
            }
        }

        override public function load(request:URLRequest):void {
            currentUrl = request.url;
            _triggerEvent("requestresource", request.url);
            dispatchEvent(new Event(Event.OPEN));
        }

        private function _triggerEvent(eventName: String, param:String=null):void {
            var event:String = playbackId + ":" + eventName;
            ExternalInterface.call('Clappr.Mediator.trigger', event, param);
        }

        override protected function resourceLoadingError() : void {
            super.resourceLoadingError();
            _triggerEvent("decodeerror");
        }

        override protected function resourceLoadingSuccess() : void {
            super.resourceLoadingSuccess();
            _triggerEvent("decodesuccess");
        }

        public function resourceAsString():String {
            return _resource.toString();
        }

        public function contentLoaded(url:String, base64Resource : String):void {
            if (url == currentUrl) {
                this.resourceLoaded(base64Resource);
            }
        }
    }
}

