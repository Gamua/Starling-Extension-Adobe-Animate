package starling.extensions.animate
{
    import starling.animation.IAnimatable;
    import starling.display.DisplayObjectContainer;
    import starling.events.Event;

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

        public function play():void
        {
            _behavior.play();
        }

        public function pause():void
        {
            _behavior.pause();
        }

        public function stop():void
        {
            _behavior.stop();
        }

        public function gotoFrame(indexOrLabel:*):void
        {
            currentFrame = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);
        }

        public function addFrameAction(indexOrLabel:*, action:Function):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.addFrameAction(frameIndex, action);
        }

        public function removeFrameAction(indexOrLabel:*, action:Function):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.removeFrameAction(frameIndex, action);
        }

        public function removeFrameActions(indexOrLabel:*):void
        {
            var frameIndex:int = indexOrLabel is String ?
                _symbol.getFrame(indexOrLabel as String) : int(indexOrLabel);

            _behavior.removeFrameActions(frameIndex);
        }

        public function advanceTime(time:Number):void
        {
            var frameRate:Number = _behavior.frameRate;
            var prevTime:Number = _cumulatedTime;

            _behavior.advanceTime(time);
            _cumulatedTime += time;

            if (int(prevTime * frameRate) != int(_cumulatedTime * frameRate))
                _symbol.nextFrame_MovieClips();
        }

        public function getNextLabel(afterLabel:String=null):String
        {
            return _symbol.getNextLabel(afterLabel);
        }

        public function getFrame(label:String):int
        {
            return _symbol.getFrame(label);
        }

        public function get currentLabel():String { return _symbol.currentLabel; }

        public function get currentFrame():int { return _behavior.currentFrame; }
        public function set currentFrame(value:int):void { _behavior.currentFrame = value; }

        public function get currentTime():Number { return _behavior.currentTime; }
        public function set currentTime(value:Number):void { _behavior.currentTime = value; }

        public function get frameRate():Number { return _behavior.frameRate; }
        public function set frameRate(value:Number):void { _behavior.frameRate = value; }

        public function get loop():Boolean { return _behavior.loop; }
        public function set loop(value:Boolean):void { _behavior.loop = value; }

        public function get numFrames():int { return _behavior.numFrames; }
        public function get isPlaying():Boolean { return _behavior.isPlaying; }
        public function get totalTime():Number { return _behavior.totalTime; }
    }
}
