/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
 package org.mangui.hls.controller {
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.getTimer;
    import flash.utils.Timer;
    import org.mangui.hls.constant.HLSPlayStates;
    import org.mangui.hls.event.HLSEvent;
    import org.mangui.hls.HLS;
    CONFIG::LOGGING {
        import org.mangui.hls.utils.Log;
    }
    /*
     * class that control/monitor FPS
     */
    public class FPSController {
      /** Reference to the HLS controller. **/
      private var _hls : HLS;
      private var _timer : Timer;
      private var _ticker:Timer;
      private var _lastTimer : int = 0;
      private var _lastTick:int = 0;
      private var _lastFrames:int = 0;
      private var _lastDroppedFrames : int = 0;
      private var _hiddenVideo : Boolean = false;
      private var _totalFrames:int = 0;
      private var _activeCounter:int = 0;

      public function FPSController(hls : HLS) {
          _hls = hls;
          _hls.addEventListener(HLSEvent.PLAYBACK_STATE, _playbackStateHandler);
          _timer = new Timer(1000,0);
          _timer.addEventListener(TimerEvent.TIMER, _checkFPS);
          _ticker = new Timer(0, 0);
          _ticker.addEventListener(TimerEvent.TIMER, _tick);
          _ticker.start();
      }

      public function dispose() : void {
          _hls.removeEventListener(HLSEvent.PLAYBACK_STATE, _playbackStateHandler);
          _hls.stage.removeEventListener(Event.ENTER_FRAME, _enterFrame);
      }

      private function _playbackStateHandler(event : HLSEvent) : void {
        switch(event.state) {
          case HLSPlayStates.PLAYING:
            // start fps check timer when switching to playing state
            _lastTimer = getTimer();
            _hiddenVideo = false;
            _timer.start();
            break;
          default:
            if(_timer.running)  {
              // stop it in all other cases
              _lastTimer = getTimer();
              _hiddenVideo = true;
              _timer.stop();
              CONFIG::LOGGING {
                Log.info("video not playing, stop monitoring dropped FPS");
              }
            }
            break;
        }
      }

      private function _checkFPS(e : Event) : void {
        var now:int = getTimer();
        var currentDroppedFrames:int = _hls.stream.info.droppedFrames;
        var deltaDroppedFrames:int = currentDroppedFrames - _lastDroppedFrames;
        var deltaTime:int = now - _lastTimer;
        var deltaFrames:int = _totalFrames - _lastFrames;
        var realFPS:Number = (deltaFrames / deltaTime) * 1000;
        var droppedFPS:Number = (deltaDroppedFrames / deltaTime) * 1000;
        var sum:Number = realFPS + droppedFPS;
        var ratio:Number = droppedFPS / sum;


        if (_active) {
          if (ratio > 0.2) {
            _hls.dispatchEvent(new HLSEvent(HLSEvent.FPS_DROP, realFPS, droppedFPS));
            CONFIG::LOGGING {
              Log.warn('FPS drop - current: ' + realFPS + ', dropped: ' + droppedFPS);
            }
          }
        }

        _lastTimer = now;
        _lastFrames = _totalFrames;
        _lastDroppedFrames = currentDroppedFrames;
      }

      private function _enterFrame(e:Event):void {
        _totalFrames++;
      }

      private function _tick(e:Event):void {
        var now:int = getTimer();
        var delta:int = now - _lastTick;

        if (delta > 60) {
          _hiddenVideo = false;
          _activeCounter = 0;
        } else if (_active == false) { // delta <= 60
          _activeCounter++;

          if (_activeCounter == 50) {
            _hiddenVideo = true;
            _activeCounter = 0;
          }
        }
        _lastTick = now;
      }
  }
}
