package starling.extensions.animate
{
    import starling.animation.IAnimatable;
    import starling.display.DisplayObjectContainer;
    import starling.events.Event;

    /** An Animation is similar to Flash's "MovieClip" class, as it displays the content of an
     *  Animate CC timeline. Like all Starling animatables, it needs to be added to a Juggler
     *  in order to start playing. */
    public class Animation extends DisplayObjectContainer implements IAnimatable
    {
        private var _symbol:Symbol;
        private var _behavior:MovieBehavior;
        private var _cumulatedTime:Number = 0.0;

        public function Animation(data:Object, atlas:AnimationAtlas)
        {
            _symbol = new Symbol(data, atlas);
            _symbol.update();
            addChild(_symbol);

            _behavior = new MovieBehavior(this, onFrameChanged, atlas.frameRate);
            _behavior.numFrames = _symbol.numFrames;
            _behavior.addEventListener(Event.COMPLETE, onComplete);
            play();
        }

        private function onComplete():void
        {
            dispatchEventWith(Event.COMPLETE);
        }

        private function onFrameChanged(frameIndex:int):void
        {
            _symbol.currentFrame = frameIndex;
        }

        /** Starts moving the playhead. */
        public function play():void
        {
            _behavior.play();
        }

        /** Pauses playback, while keeping the playhead at its current position. */
        public function pause():void
        {
            _behavior.pause();
        }

        /** Stops playback and resets "currentFrame" to zero. */
        public function stop():void
        {
            _behavior.stop();
        }

        /** Immediately moves the playhead to the given index or label. */
        public function gotoFrame(indexOrLabel:*):void
        {
            currentFrame = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);
        }

        /** The given function is executed when the playhead leaves the frame with the given
         *  index or label. "action" can be declared in one of the following ways:
         *
         *  <code>
         *  function(target:DisplayObject, frameID:int):void;
         *  function(target:DisplayObject):void;
         *  function():void;
         *  </code>
         */
        public function addFrameAction(indexOrLabel:*, action:Function):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.addFrameAction(frameIndex, action);
        }

        /** Removes a specific frame action at the given index or label. */
        public function removeFrameAction(indexOrLabel:*, action:Function):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.removeFrameAction(frameIndex, action);
        }

        /** Removes all frame actions at the given index or label. */
        public function removeFrameActions(indexOrLabel:*):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.removeFrameActions(frameIndex);
        }

        /** Advances the playhead by the given time in seconds. */
        public function advanceTime(time:Number):void
        {
            var frameRate:Number = _behavior.frameRate;
            var prevTime:Number = _cumulatedTime;

            _behavior.advanceTime(time);
            _cumulatedTime += time;

            if (int(prevTime * frameRate) != int(_cumulatedTime * frameRate))
                _symbol.nextFrame_MovieClips();
        }

        /** Returns the next label after the given one. Useful for looping: e.g. to loop between
         *  the label "walk" and the next label, add a frame action to "getNextLabel('walk')"
         *  that jumps back to the "walk" label.
         */
        public function getNextLabel(afterLabel:String=null):String
        {
            return _symbol.getNextLabel(afterLabel);
        }

        /** Returns the index of the frame with the given label,
         *  or '-1' if that label is not found. */
        public function getFrame(label:String):int
        {
            return _symbol.getFrame(label);
        }

        /** The current label in which the playhead is located in the timeline of the Animation
         *  instance. If the current frame has no label, currentLabel is set to the name of the
         *  previous frame that includes a label. If the current frame and previous frames do
         *  not include a label, currentLabel returns null.
         */
        public function get currentLabel():String { return _symbol.currentLabel; }

        /** The index of the frame in which the playhead is located on the timeline.
         *  Note that the very first frame has the index '0'. */
        public function get currentFrame():int { return _behavior.currentFrame; }
        public function set currentFrame(value:int):void { _behavior.currentFrame = value; }

        /** The time passed since the first frame of the timeline. */
        public function get currentTime():Number { return _behavior.currentTime; }
        public function set currentTime(value:Number):void { _behavior.currentTime = value; }

        /** The frame rate with which the animation is advancing. */
        public function get frameRate():Number { return _behavior.frameRate; }
        public function set frameRate(value:Number):void { _behavior.frameRate = value; }

        /** Indicates if the clip automatically rewinds to the first frame after reaching the
         *  last. @default true */
        public function get loop():Boolean { return _behavior.loop; }
        public function set loop(value:Boolean):void { _behavior.loop = value; }

        /** The total number of frames in the animation's timeline. */
        public function get numFrames():int { return _behavior.numFrames; }

        /** Indicates if the animation is currently being played. */
        public function get isPlaying():Boolean { return _behavior.isPlaying; }

        /** The total length of the animation in seconds. */
        public function get totalTime():Number { return _behavior.totalTime; }
    }
}
