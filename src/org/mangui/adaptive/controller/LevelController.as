/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.mangui.adaptive.controller {
    import org.mangui.adaptive.Adaptive;
    import org.mangui.adaptive.AdaptiveSettings;
    import org.mangui.adaptive.constant.MaxLevelCappingMode;
    import org.mangui.adaptive.event.AdaptiveEvent;
    import org.mangui.adaptive.model.Level;

    CONFIG::LOGGING {
        import org.mangui.adaptive.utils.Log;
    }
    /** Class that manages auto level selection
     *
     * this is an implementation based on Serial segment fetching method from
     * http://www.cs.tut.fi/~moncef/publications/rate-adaptation-IC-2011.pdf
     */
    public class LevelController {
        /** Reference to the Adaptive controller. **/
        private var _adaptive : Adaptive;
        /** switch up threshold **/
        private var _switchup : Vector.<Number> = null;
        /** switch down threshold **/
        private var _switchdown : Vector.<Number> = null;
        /** bitrate array **/
        private var _bitrate : Vector.<Number> = null;
        /** vector of levels with unique dimension with highest bandwidth **/
        private var _maxUniqueLevels : Vector.<Level> = null;
        /** nb level **/
        private var _nbLevel : int = 0;
        private var _last_segment_duration : Number;
        private var _last_fetch_duration : Number;
        private var  last_bandwidth : Number;

        /** Create the loader. **/
        public function LevelController(adaptive : Adaptive) : void {
            _adaptive = adaptive;
            _adaptive.addEventListener(AdaptiveEvent.MANIFEST_LOADED, _manifestLoadedHandler);
            _adaptive.addEventListener(AdaptiveEvent.FRAGMENT_LOADED, _fragmentLoadedHandler);
        }
        ;

        public function dispose() : void {
            _adaptive.removeEventListener(AdaptiveEvent.MANIFEST_LOADED, _manifestLoadedHandler);
            _adaptive.removeEventListener(AdaptiveEvent.FRAGMENT_LOADED, _fragmentLoadedHandler);
        }

        private function _fragmentLoadedHandler(event : AdaptiveEvent) : void {
            last_bandwidth = event.loadMetrics.bandwidth;
            _last_segment_duration = event.loadMetrics.frag_duration;
            _last_fetch_duration = event.loadMetrics.frag_processing_time;
        }

        /** Store the manifest data. **/
        private function _manifestLoadedHandler(event : AdaptiveEvent) : void {
            var levels : Vector.<Level> = event.levels;
            var maxswitchup : Number = 0;
            var minswitchdwown : Number = Number.MAX_VALUE;
            _nbLevel = levels.length;
            _bitrate = new Vector.<Number>(_nbLevel, true);
            _switchup = new Vector.<Number>(_nbLevel, true);
            _switchdown = new Vector.<Number>(_nbLevel, true);
            _last_segment_duration = 0;
            _last_fetch_duration = 0;
            last_bandwidth = 0;

            var i : int;

            for (i = 0; i < _nbLevel; i++) {
                _bitrate[i] = levels[i].bitrate;
            }

            for (i = 0; i < _nbLevel - 1; i++) {
                _switchup[i] = (_bitrate[i + 1] - _bitrate[i]) / _bitrate[i];
                maxswitchup = Math.max(maxswitchup, _switchup[i]);
            }
            for (i = 0; i < _nbLevel - 1; i++) {
                _switchup[i] = Math.min(maxswitchup, 2 * _switchup[i]);

                CONFIG::LOGGING {
                    Log.debug("_switchup[" + i + "]=" + _switchup[i]);
                }
            }

            for (i = 1; i < _nbLevel; i++) {
                _switchdown[i] = (_bitrate[i] - _bitrate[i - 1]) / _bitrate[i];
                minswitchdwown = Math.min(minswitchdwown, _switchdown[i]);
            }
            for (i = 1; i < _nbLevel; i++) {
                _switchdown[i] = Math.max(2 * minswitchdwown, _switchdown[i]);

                CONFIG::LOGGING {
                    Log.debug("_switchdown[" + i + "]=" + _switchdown[i]);
                }
            }

            if (AdaptiveSettings.capLevelToStage) {
                _maxUniqueLevels = _maxLevelsWithUniqueDimensions;
            }
            var level : int;
            if (_adaptive.autolevel) {
                level = _adaptive.startlevel;
            } else {
                level = _adaptive.manuallevel;
            }
            // always dispatch level after manifest load
            _adaptive.dispatchEvent(new AdaptiveEvent(AdaptiveEvent.LEVEL_SWITCH, level));
        }
        ;

        public function getbestlevel(download_bandwidth : Number) : int {
            var max_level : int = _max_level;
            for (var i : int = max_level; i >= 0; i--) {
                if (_bitrate[i] <= download_bandwidth) {
                    return i;
                }
            }
            return 0;
        }

        private function get _maxLevelsWithUniqueDimensions() : Vector.<Level> {
            var filter : Function = function(l : Level, i : int, v : Vector.<Level>) : Boolean {
                if (l.width > 0 && l.height > 0) {
                    if (i + 1 < v.length) {
                        var nextLevel : Level = v[i + 1];
                        if (l.width != nextLevel.width && l.height != nextLevel.height) {
                            return true;
                        }
                    } else {
                        return true;
                    }
                }
                return false;
            };

            return _adaptive.levels.filter(filter);
        }

        private function get _max_level() : int {
            if (AdaptiveSettings.capLevelToStage) {
                var maxLevelsCount : int = _maxUniqueLevels.length;

                if (_adaptive.stage && maxLevelsCount) {
                    var maxLevel : Level = this._maxUniqueLevels[0], maxLevelIdx : int = maxLevel.index, sWidth : Number = this._adaptive.stage.stageWidth, sHeight : Number = this._adaptive.stage.stageHeight, lWidth : int, lHeight : int, i : int;

                    switch (AdaptiveSettings.maxLevelCappingMode) {
                        case MaxLevelCappingMode.UPSCALE:
                            for (i = maxLevelsCount - 1; i >= 0; i--) {
                                maxLevel = this._maxUniqueLevels[i];
                                maxLevelIdx = maxLevel.index;
                                lWidth = maxLevel.width;
                                lHeight = maxLevel.height;
                                CONFIG::LOGGING {
                                    Log.debug("stage size: " + sWidth + "x" + sHeight + " ,level" + maxLevelIdx + " size: " + lWidth + "x" + lHeight);
                                }
                                if (sWidth >= lWidth || sHeight >= lHeight) {
                                    break;
                                    // from for loop
                                }
                            }
                            break;
                        case MaxLevelCappingMode.DOWNSCALE:
                            for (i = 0; i < maxLevelsCount; i++) {
                                maxLevel = this._maxUniqueLevels[i];
                                maxLevelIdx = maxLevel.index;
                                lWidth = maxLevel.width;
                                lHeight = maxLevel.height;
                                CONFIG::LOGGING {
                                    Log.debug("stage size: " + sWidth + "x" + sHeight + " ,level" + maxLevelIdx + " size: " + lWidth + "x" + lHeight);
                                }
                                if (sWidth <= lWidth || sHeight <= lHeight) {
                                    break;
                                    // from for loop
                                }
                            }
                            break;
                    }
                    CONFIG::LOGGING {
                        Log.debug("max capped level idx: " + maxLevelIdx);
                    }
                }
                return maxLevelIdx;
            } else {
                return _nbLevel - 1;
            }
        }

        /** Update the quality level for the next fragment load. **/
        public function getnextlevel(current_level : int, buffer : Number) : int {
            if (_last_fetch_duration == 0 || _last_segment_duration == 0) {
                return 0;
            }

            /* rsft : remaining segment fetch time : available time to fetch next segment
            it depends on the current playback timestamp , the timestamp of the first frame of the next segment
            and TBMT, indicating a desired latency between the time instant to receive the last byte of a
            segment to the playback of the first media frame of a segment
            buffer is start time of next segment
            TBMT is the buffer size we need to ensure (we need at least 2 segments buffered */
            var rsft : Number = 1000 * buffer - 2 * _last_fetch_duration;
            var sftm : Number = Math.min(_last_segment_duration, rsft) / _last_fetch_duration;
            var max_level : Number = _max_level;
            var switch_to_level : int = current_level;
            // CONFIG::LOGGING {
            // Log.info("rsft:" + rsft);
            // Log.info("sftm:" + sftm);
            // }
            // }
            /* to switch level up :
            rsft should be greater than switch up condition
             */
            if ((current_level < max_level) && (sftm > (1 + _switchup[current_level]))) {
                CONFIG::LOGGING {
                    Log.debug("sftm:> 1+_switchup[_level]=" + (1 + _switchup[current_level]));
                }
                switch_to_level = current_level + 1;
            }

            /* to switch level down :
            rsft should be smaller than switch up condition,
            or the current level is greater than max level
             */ else if ((current_level > max_level && current_level > 0) || (current_level > 0 && (sftm < 1 - _switchdown[current_level]))) {
                CONFIG::LOGGING {
                    Log.debug("sftm < 1-_switchdown[current_level]=" + _switchdown[current_level]);
                }
                var bufferratio : Number = 1000 * buffer / _last_segment_duration;
                /* find suitable level matching current bandwidth, starting from current level
                when switching level down, we also need to consider that we might need to load two fragments.
                the condition (bufferratio > 2*_levels[j].bitrate/_last_bandwidth)
                ensures that buffer time is bigger than than the time to download 2 fragments from level j, if we keep same bandwidth.
                 */

                for (var j : int = current_level - 1; j >= 0; j--) {
                    if (_bitrate[j] <= last_bandwidth && (bufferratio > 2 * _bitrate[j] / last_bandwidth)) {
                        switch_to_level = j;
                        break;
                    }
                    if (j == 0) {
                        switch_to_level = 0;
                    }
                }
            }

            // Then we should check if selected level is higher than max_level if so, than take the min of those two
            switch_to_level = Math.min(max_level, switch_to_level);

            CONFIG::LOGGING {
                if (switch_to_level != current_level) {
                    Log.debug("switch to level " + switch_to_level);
                }
            }

            return switch_to_level;
        }

        public function get startlevel() : int {
            var start_level : int = -1;
            var levels : Vector.<Level> = _adaptive.levels;
            if (levels) {
                if (AdaptiveSettings.startFromLevel === -1 && AdaptiveSettings.startFromBitrate === -1) {
                    /* if startFromLevel is set to -1, it means that effective startup level
                     * will be determined from first segment download bandwidth
                     * let's use lowest bitrate for this download bandwidth assessment
                     * this should speed up playback start time
                     */
                    return 0;
                }

                // set up start level as being the lowest non-audio level.
                for (var i : int = 0; i < levels.length; i++) {
                    if (!levels[i].audio) {
                        start_level = i;
                        break;
                    }
                }
                // in case of audio only playlist, force startLevel to 0
                if (start_level == -1) {
                    CONFIG::LOGGING {
                        Log.info("playlist is audio-only");
                    }
                    start_level = 0;
                } else {
                    if (AdaptiveSettings.startFromBitrate > 0) {
                        start_level = findIndexOfClosestLevel(AdaptiveSettings.startFromBitrate);
                    } else if (AdaptiveSettings.startFromLevel > 0) {
                        // adjust start level using a rule by 3
                        start_level += Math.round(AdaptiveSettings.startFromLevel * (levels.length - start_level - 1));
                    }
                }
            }
            CONFIG::LOGGING {
                Log.debug("start level :" + start_level);
            }
            return start_level;
        }

        /**
         * @param desiredBitrate
         * @return The index of the level that has a bitrate closest to the desired bitrate.
         */
        private function findIndexOfClosestLevel(desiredBitrate : Number) : int {
            var levelIndex : int = -1;
            var minDistance : Number = Number.MAX_VALUE;
            var levels : Vector.<Level> = _adaptive.levels;

            for (var index : int = 0; index < levels.length; index++) {
                var level : Level = levels[index];

                var distance : Number = Math.abs(desiredBitrate - level.bitrate);

                if (distance < minDistance) {
                    levelIndex = index;
                    minDistance = distance;
                }
            }
            return levelIndex;
        }

        public function get seeklevel() : int {
            var seek_level : int = -1;
            var levels : Vector.<Level> = _adaptive.levels;
            if (AdaptiveSettings.seekFromLevel == -1) {
                // keep last level
                return _adaptive.level;
            }

            // set up seek level as being the lowest non-audio level.
            for (var i : int = 0; i < levels.length; i++) {
                if (!levels[i].audio) {
                    seek_level = i;
                    break;
                }
            }
            // in case of audio only playlist, force seek_level to 0
            if (seek_level == -1) {
                seek_level = 0;
            } else {
                if (AdaptiveSettings.seekFromLevel > 0) {
                    // adjust start level using a rule by 3
                    seek_level += Math.round(AdaptiveSettings.seekFromLevel * (levels.length - seek_level - 1));
                }
            }
            CONFIG::LOGGING {
                Log.debug("seek level :" + seek_level);
            }
            return seek_level;
        }
    }
}